#!/bin/bash
# test_installer.sh -- Test installer script behavior for fresh and existing repositories.
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

echo "=== Running Installer Tests (Bash) ==="

# Create temporary directories
TMP_FRESH=$(mktemp -d -t fresh_repo_XXXXXX)
TMP_GIT=$(mktemp -d -t git_repo_XXXXXX)

cleanup() {
    rm -rf "$TMP_FRESH"
    rm -rf "$TMP_GIT"
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
(cd "$ROOT_DIR" && bash install.sh --target "$TMP_FRESH" --force)

if [ ! -d "$TMP_FRESH/memory" ] || [ ! -d "$TMP_FRESH/memory/daily" ] || [ ! -d "$TMP_FRESH/memory/projects" ]; then
    echo "Scenario 2 FAIL: Memory subdirectories were not created"
    exit 1
fi

# Verify memory/handoff.md is NOT created
if [ -f "$TMP_FRESH/memory/handoff.md" ]; then
    echo "Scenario 2 FAIL: memory/handoff.md was created during installation"
    exit 1
fi

# Verify today's daily log exists and does NOT contain examples or TEMPLATE_DO_NOT_USE warning
TODAY=$(date +%Y-%m-%d)
DAILY_FILE="$TMP_FRESH/memory/daily/$TODAY.md"
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
PROJECT_FILE="$TMP_FRESH/memory/projects/$(basename "$TMP_FRESH").md"
if [ ! -f "$PROJECT_FILE" ]; then
    echo "Scenario 2 FAIL: Project context file $PROJECT_FILE was not created"
    exit 1
fi
if grep -q "TEMPLATE_DO_NOT_USE" "$PROJECT_FILE"; then
    echo "Scenario 2 FAIL: Project context file contains TEMPLATE_DO_NOT_USE marker"
    exit 1
fi

# Verify task.md exists and has NO TEMPLATE_DO_NOT_USE warning
TASK_FILE="$TMP_FRESH/task.md"
if [ ! -f "$TASK_FILE" ]; then
    echo "Scenario 2 FAIL: task.md was not created"
    exit 1
fi
if grep -q "TEMPLATE_DO_NOT_USE" "$TASK_FILE"; then
    echo "Scenario 2 FAIL: task.md contains TEMPLATE_DO_NOT_USE marker"
    exit 1
fi

# Verify Sentry Org/Token statuses are Configured/Not Configured rather than FILL_ME in memory/local_env.md
LOCAL_ENV="$TMP_FRESH/memory/local_env.md"
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
if [ ! -f "$TMP_FRESH/.agents/scripts/scan-secrets.sh" ] || [ ! -f "$TMP_FRESH/.agents/scripts/scan-secrets.ps1" ]; then
    echo "Scenario 2 FAIL: shared secrets scan scripts were not installed"
    exit 1
fi
if [ -f "$TMP_FRESH/.agents/scripts/test_installer.sh" ] || [ -f "$TMP_FRESH/.agents/scripts/validate_manifests.py" ]; then
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
echo "=== ALL BASH INSTALLER TESTS PASSED SUCCESSFULLY ==="
