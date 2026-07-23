#!/bin/bash
# test_installer.sh -- Test installer script behavior for fresh and existing repositories.
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

echo "=== Running Installer Tests (Bash) ==="

# Create temporary directories
TMP_FRESH=$(mktemp -d -t fresh_repo_XXXXXX)
TMP_GIT=$(mktemp -d -t git_repo_XXXXXX)
TMP_HOOKS=$(mktemp -d -t hooks_repo_XXXXXX)
TMP_OPTIONAL=$(mktemp -d -t optional_repo_XXXXXX)
TMP_OPTIONAL_HOME=$(mktemp -d -t optional_home_XXXXXX)
TMP_OPTIONAL_BIN=$(mktemp -d -t optional_bin_XXXXXX)

cleanup() {
    rm -rf "$TMP_FRESH"
    rm -rf "$TMP_GIT"
    rm -rf "$TMP_HOOKS"
    rm -rf "$TMP_OPTIONAL"
    rm -rf "$TMP_OPTIONAL_HOME"
    rm -rf "$TMP_OPTIONAL_BIN"
    echo "Temporary test directories cleaned up."
}
trap cleanup EXIT

# Scenario 1: Rules-Only Install on Fresh Dir
echo "Running Scenario 1: --rules-only on fresh directory..."
(cd "$ROOT_DIR" && bash install.sh --target "$TMP_FRESH" --rules-only)

# Verify only rule files and cursor rules are generated
if [ ! -f "$TMP_FRESH/CLAUDE.md" ] || [ ! -f "$TMP_FRESH/AGENTS.md" ]; then
    echo "Scenario 1 FAIL: Missing CLAUDE.md or AGENTS.md"
    exit 1
fi
if [ -d "$TMP_FRESH/memory" ]; then
    echo "Scenario 1 FAIL: Scaffolding memory directory created despite --rules-only flag"
    exit 1
fi
if [ ! -f "$TMP_FRESH/.cursor/rules/core.mdc" ] || [ ! -f "$TMP_FRESH/.cursor/rules/commands.mdc" ]; then
    echo "Scenario 1 FAIL: Missing .cursor/rules/core.mdc or commands.mdc"
    exit 1
fi

# Verify core.mdc contents (should contain philosophies and second brain protocol, NOT slash commands)
if grep -q "| /ak-align" "$TMP_FRESH/.cursor/rules/core.mdc"; then
    echo "Scenario 1 FAIL: core.mdc contains slash commands table instead of being in commands.mdc"
    exit 1
fi
if ! grep -q "Ponytail Lazy Developer Ladder" "$TMP_FRESH/.cursor/rules/core.mdc"; then
    echo "Scenario 1 FAIL: core.mdc is missing philosophies"
    exit 1
fi
if ! grep -q "Second Brain Protocol" "$TMP_FRESH/.cursor/rules/core.mdc"; then
    echo "Scenario 1 FAIL: core.mdc is missing Second Brain section"
    exit 1
fi

# Verify commands.mdc contents (should contain slash commands)
if ! grep -q "/ak-align" "$TMP_FRESH/.cursor/rules/commands.mdc"; then
    echo "Scenario 1 FAIL: commands.mdc is missing slash commands"
    exit 1
fi
if grep -q "Ponytail Lazy Developer Ladder" "$TMP_FRESH/.cursor/rules/commands.mdc"; then
    echo "Scenario 1 FAIL: commands.mdc contains philosophies"
    exit 1
fi

echo "Scenario 1 Passed."

# Scenario 2: Full Scaffolding on Fresh/Non-Git Dir
echo "Running Scenario 2: Full scaffolding on non-Git directory..."
TMP_NESTED="$TMP_FRESH/nested/fresh/repo&ops"
(cd "$ROOT_DIR" && bash install.sh "$TMP_NESTED" --force)

if [ ! -d "$TMP_NESTED/memory" ] || [ ! -d "$TMP_NESTED/memory/daily" ] || [ ! -d "$TMP_NESTED/memory/projects" ]; then
    echo "Scenario 2 FAIL: Memory subdirectories were not created"
    exit 1
fi

# Verify memory/handoff.md is NOT created
if [ -f "$TMP_NESTED/memory/handoff.md" ]; then
    echo "Scenario 2 FAIL: memory/handoff.md was created during installation"
    exit 1
fi

# Verify today's daily log exists and does NOT contain examples or TEMPLATE_DO_NOT_USE warning
TODAY=$(date +%Y-%m-%d)
DAILY_FILE="$TMP_NESTED/memory/daily/$TODAY.md"
if [ ! -f "$DAILY_FILE" ]; then
    echo "Scenario 2 FAIL: Today's daily log $DAILY_FILE was not created"
    exit 1
fi
if grep -q "Initialized session and loaded memory" "$DAILY_FILE"; then
    echo "Scenario 2 FAIL: Today's daily log contains template example log entries!"
    exit 1
fi
if grep -q "TEMPLATE_DO_NOT_USE" "$DAILY_FILE"; then
    echo "Scenario 2 FAIL: Today's daily log contains TEMPLATE_DO_NOT_USE marker"
    exit 1
fi

# Verify project memory file is created and has NO TEMPLATE_DO_NOT_USE warning
PROJECT_FILE="$TMP_NESTED/memory/projects/$(basename "$TMP_NESTED").md"
if [ ! -f "$PROJECT_FILE" ]; then
    echo "Scenario 2 FAIL: Project context file $PROJECT_FILE was not created"
    exit 1
fi
if grep -q "TEMPLATE_DO_NOT_USE" "$PROJECT_FILE"; then
    echo "Scenario 2 FAIL: Project context file contains TEMPLATE_DO_NOT_USE marker"
    exit 1
fi
if ! grep -qF "# Project Context: $(basename "$TMP_NESTED")" "$PROJECT_FILE"; then
    echo "Scenario 2 FAIL: Project context file did not preserve escaped project name"
    exit 1
fi

# Verify task.md exists and has NO TEMPLATE_DO_NOT_USE warning
TASK_FILE="$TMP_NESTED/task.md"
if [ ! -f "$TASK_FILE" ]; then
    echo "Scenario 2 FAIL: task.md was not created"
    exit 1
fi
if grep -q "TEMPLATE_DO_NOT_USE" "$TASK_FILE"; then
    echo "Scenario 2 FAIL: task.md contains TEMPLATE_DO_NOT_USE marker"
    exit 1
fi

# Verify skill observation backlog exists with the public/internal safety fields
SKILL_OBSERVATIONS="$TMP_NESTED/memory/skill-observations.md"
if [ ! -f "$SKILL_OBSERVATIONS" ]; then
    echo "Scenario 2 FAIL: memory/skill-observations.md was not created"
    exit 1
fi
if ! grep -q "Suggested improvement" "$SKILL_OBSERVATIONS" || ! grep -q "public-safe" "$SKILL_OBSERVATIONS" || ! grep -q "internal" "$SKILL_OBSERVATIONS" || ! grep -q "memory/skill-observations.archive.md" "$SKILL_OBSERVATIONS"; then
    echo "Scenario 2 FAIL: skill-observations.md is missing observation safety/archive fields"
    exit 1
fi

# Verify Sentry Org/Token statuses are Configured/Not Configured rather than FILL_ME in memory/local_env.md
LOCAL_ENV="$TMP_NESTED/memory/local_env.md"
if [ ! -f "$LOCAL_ENV" ]; then
    echo "Scenario 2 FAIL: memory/local_env.md was not created"
    exit 1
fi
if grep -q "TEMPLATE_DO_NOT_USE" "$LOCAL_ENV"; then
    echo "Scenario 2 FAIL: local_env.md contains TEMPLATE_DO_NOT_USE marker"
    exit 1
fi
if grep -q "FILL_ME_IF_USING_SENTRY" "$LOCAL_ENV" || grep -q "\[SENTRY_AUTH_TOKEN\]" "$LOCAL_ENV"; then
    echo "Scenario 2 FAIL: local_env.md still contains raw Sentry secrets placeholders"
    exit 1
fi
if ! grep -q "Headroom:" "$LOCAL_ENV" || grep -q "\[HEADROOM_STATUS\]" "$LOCAL_ENV"; then
    echo "Scenario 2 FAIL: local_env.md is missing resolved Headroom status"
    exit 1
fi
if grep -q "\[GRAPHIFY_STATUS\]" "$LOCAL_ENV" || grep -q "\[CODEGRAPH_STATUS\]" "$LOCAL_ENV" || grep -q "\[CAVEMAN_STATUS\]" "$LOCAL_ENV" || grep -q "\[SENTRY_STATUS\]" "$LOCAL_ENV" || grep -q "\[DETECTED_SKILLS\]" "$LOCAL_ENV"; then
    echo "Scenario 2 FAIL: local_env.md contains unresolved status placeholders"
    exit 1
fi
if [ ! -f "$TMP_NESTED/.agents/scripts/scan-secrets.sh" ] || [ ! -f "$TMP_NESTED/.agents/scripts/scan-secrets.ps1" ]; then
    echo "Scenario 2 FAIL: shared secrets scan scripts were not installed"
    exit 1
fi
if [ -f "$TMP_NESTED/.agents/scripts/test_installer.sh" ] || [ -f "$TMP_NESTED/.agents/scripts/validate_manifests.py" ]; then
    echo "Scenario 2 FAIL: repository maintenance scripts leaked into target .agents/scripts"
    exit 1
fi

echo "Scenario 2 Passed."

# Scenario 3: Installer on Existing Git repository
echo "Running Scenario 3: Full scaffolding on existing Git directory..."
(cd "$TMP_GIT" && git init -b main && git config user.name "Test" && git config user.email "test@example.com")
(cd "$ROOT_DIR" && bash install.sh --target "$TMP_GIT" --force)

if [ ! -f "$TMP_GIT/.gitignore" ]; then
    echo "Scenario 3 FAIL: .gitignore was not created in Git repository"
    exit 1
fi

# Check that the baseline block is appended
if ! grep -q "# Antariksh Unified Framework" "$TMP_GIT/.gitignore"; then
    echo "Scenario 3 FAIL: .gitignore is missing the Antariksh baseline block"
    exit 1
fi
if ! grep -q "^task.md$" "$TMP_GIT/.gitignore"; then
    echo "Scenario 3 FAIL: .gitignore is missing task.md working-memory rule"
    exit 1
fi

echo "Scenario 3 Passed."

# Scenario 4: Optional hooks install path
echo "Running Scenario 4: Optional hooks installation..."
(cd "$ROOT_DIR" && bash install.sh --target "$TMP_HOOKS" --force --hooks)

for required_file in \
    "$TMP_HOOKS/.claude/hooks/session-start.sh" \
    "$TMP_HOOKS/.claude/hooks/stop-check.sh" \
    "$TMP_HOOKS/.codex/hooks/session-start.sh" \
    "$TMP_HOOKS/.codex/hooks/stop-check.sh" \
    "$TMP_HOOKS/.claude/settings.json" \
    "$TMP_HOOKS/.codex/hooks.json"; do
    if [ ! -f "$required_file" ]; then
        echo "Scenario 4 FAIL: Missing hook artifact $required_file"
        exit 1
    fi
done

if command -v jq >/dev/null 2>&1; then
    claude_session_count=$(jq '[.hooks.SessionStart[]?.hooks[]? | select(.command | contains(".claude/hooks/session-start.sh"))] | length' "$TMP_HOOKS/.claude/settings.json")
    claude_stop_count=$(jq '[.hooks.Stop[]?.hooks[]? | select(.command | contains(".claude/hooks/stop-check.sh"))] | length' "$TMP_HOOKS/.claude/settings.json")
    codex_session_count=$(jq '[.hooks.SessionStart[]?.hooks[]? | select(.command | contains(".codex/hooks/session-start.sh"))] | length' "$TMP_HOOKS/.codex/hooks.json")
    codex_stop_count=$(jq '[.hooks.Stop[]?.hooks[]? | select(.command | contains(".codex/hooks/stop-check.sh"))] | length' "$TMP_HOOKS/.codex/hooks.json")

    if [ "$claude_session_count" -ne 1 ] || [ "$claude_stop_count" -ne 1 ] || [ "$codex_session_count" -ne 1 ] || [ "$codex_stop_count" -ne 1 ]; then
        echo "Scenario 4 FAIL: Hook settings JSON does not contain exactly one Claude/Codex SessionStart and Stop command"
        exit 1
    fi

    (cd "$ROOT_DIR" && bash install.sh --target "$TMP_HOOKS" --hooks)

    claude_session_count=$(jq '[.hooks.SessionStart[]?.hooks[]? | select(.command | contains(".claude/hooks/session-start.sh"))] | length' "$TMP_HOOKS/.claude/settings.json")
    claude_stop_count=$(jq '[.hooks.Stop[]?.hooks[]? | select(.command | contains(".claude/hooks/stop-check.sh"))] | length' "$TMP_HOOKS/.claude/settings.json")
    codex_session_count=$(jq '[.hooks.SessionStart[]?.hooks[]? | select(.command | contains(".codex/hooks/session-start.sh"))] | length' "$TMP_HOOKS/.codex/hooks.json")
    codex_stop_count=$(jq '[.hooks.Stop[]?.hooks[]? | select(.command | contains(".codex/hooks/stop-check.sh"))] | length' "$TMP_HOOKS/.codex/hooks.json")

    if [ "$claude_session_count" -ne 1 ] || [ "$claude_stop_count" -ne 1 ] || [ "$codex_session_count" -ne 1 ] || [ "$codex_stop_count" -ne 1 ]; then
        echo "Scenario 4 FAIL: Re-running hook install duplicated hook commands"
        exit 1
    fi
else
    echo "Scenario 4 note: jq not found; verified hook files and initial settings only."
fi

echo "Scenario 4 Passed."

# Scenario 5: Optional accelerator install branch is opt-in and dry-run testable
echo "Running Scenario 5: Optional accelerator install dry-run..."
cat > "$TMP_OPTIONAL_BIN/python3" <<'EOF'
#!/bin/sh
if [ "$1" = "-m" ] && [ "$2" = "graphify" ]; then
    exit 1
fi
if [ "$1" = "-m" ] && [ "$2" = "pip" ] && [ "$3" = "--version" ]; then
    echo "pip 0.0"
    exit 0
fi
exit 1
EOF
cat > "$TMP_OPTIONAL_BIN/claude" <<'EOF'
#!/bin/sh
echo "fake claude"
exit 0
EOF
cat > "$TMP_OPTIONAL_BIN/graphify" <<'EOF'
#!/bin/sh
exit 1
EOF
cat > "$TMP_OPTIONAL_BIN/codegraph" <<'EOF'
#!/bin/sh
exit 1
EOF
cat > "$TMP_OPTIONAL_BIN/sentry" <<'EOF'
#!/bin/sh
exit 1
EOF
cat > "$TMP_OPTIONAL_BIN/sentry-cli" <<'EOF'
#!/bin/sh
exit 1
EOF
cat > "$TMP_OPTIONAL_BIN/headroom" <<'EOF'
#!/bin/sh
exit 1
EOF
cat > "$TMP_OPTIONAL_BIN/uv" <<'EOF'
#!/bin/sh
exit 1
EOF
cat > "$TMP_OPTIONAL_BIN/pipx" <<'EOF'
#!/bin/sh
exit 1
EOF
cat > "$TMP_OPTIONAL_BIN/npm" <<'EOF'
#!/bin/sh
if [ "$1" = "--version" ]; then
    echo "0.0.0"
    exit 0
fi
exit 0
EOF
chmod +x "$TMP_OPTIONAL_BIN/python3" "$TMP_OPTIONAL_BIN/claude" "$TMP_OPTIONAL_BIN/graphify" \
    "$TMP_OPTIONAL_BIN/codegraph" "$TMP_OPTIONAL_BIN/sentry" "$TMP_OPTIONAL_BIN/sentry-cli" \
    "$TMP_OPTIONAL_BIN/headroom" "$TMP_OPTIONAL_BIN/uv" "$TMP_OPTIONAL_BIN/pipx" "$TMP_OPTIONAL_BIN/npm"

optional_output=$(
    cd "$ROOT_DIR" && \
    HOME="$TMP_OPTIONAL_HOME" \
    PATH="$TMP_OPTIONAL_BIN:$PATH" \
    VIRTUAL_ENV="$TMP_OPTIONAL_HOME/venv" \
    ANTARIKSH_INSTALL_OPTIONAL_DRY_RUN=1 \
    bash install.sh --target "$TMP_OPTIONAL" --rules-only --install-optional
)
echo "$optional_output"

if ! echo "$optional_output" | grep -q "Optional accelerator install requested"; then
    echo "Scenario 5 FAIL: Optional install branch did not run"
    exit 1
fi
if ! echo "$optional_output" | grep -q "DRY RUN: would run 'python3 -m pip install graphifyy' then 'graphify install'"; then
    echo "Scenario 5 FAIL: Graphify optional install command was not selected"
    exit 1
fi
if ! echo "$optional_output" | grep -q "DRY RUN: would run 'claude plugin marketplace add JuliusBrussee/caveman'"; then
    echo "Scenario 5 FAIL: Caveman optional plugin install command was not selected"
    exit 1
fi
if ! echo "$optional_output" | grep -q "DRY RUN: would run 'npm install -g @colbymchenry/codegraph' then 'codegraph install'"; then
    echo "Scenario 5 FAIL: CodeGraph optional install command was not selected"
    exit 1
fi
if ! echo "$optional_output" | grep -q "DRY RUN: would run 'npm install -g sentry'"; then
    echo "Scenario 5 FAIL: Sentry CLI optional install command was not selected"
    exit 1
fi
if ! echo "$optional_output" | grep -q "DRY RUN: would run 'python3 -m pip install \"headroom-ai\[all\]\"'"; then
    echo "Scenario 5 FAIL: Headroom optional install command was not selected"
    exit 1
fi

echo "Scenario 5 Passed."
echo "=== ALL BASH INSTALLER TESTS PASSED SUCCESSFULLY ==="
