#!/bin/bash
# install.sh -- Antariksh Unified Skill Deployer for macOS/Linux/WSL
# Usage: ./install.sh [target_directory] [--force] [--rules-only] [--hooks] [--install-optional]

TARGET_DIR="."
FORCE=false
RULES_ONLY=false
WITH_HOOKS=false
INSTALL_OPTIONAL=false
OPTIONAL_INSTALL_DRY_RUN="${ANTARIKSH_INSTALL_OPTIONAL_DRY_RUN:-false}"

# Escape helper for sed replacements
escape_sed() {
    # Escape backslash first, then ampersand, then delimiter (#)
    printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/&/\\&/g' -e 's/#/\\#/g'
}

# Robust argument parsing
while [ "$#" -gt 0 ]; do
    case "$1" in
        --force|-f)
            FORCE=true
            shift
            ;;
        --rules-only|-r)
            RULES_ONLY=true
            shift
            ;;
        --hooks|-k)
            WITH_HOOKS=true
            shift
            ;;
        --install-optional)
            INSTALL_OPTIONAL=true
            shift
            ;;
        --target|-t)
            if [ -n "$2" ] && [ "${2#-}" = "$2" ]; then
                TARGET_DIR="$2"
                shift 2
            else
                echo -e "\033[31mError: --target requires a directory path argument.\033[0m"
                exit 1
            fi
            ;;
        -*)
            echo -e "\033[31mError: Unknown option $1\033[0m"
            echo "Usage: ./install.sh [target_directory] [--target <directory>] [--force] [--rules-only] [--hooks] [--install-optional]"
            exit 1
            ;;
        *)
            TARGET_DIR="$1"
            shift
            ;;
    esac
done

# Create target directory if it doesn't exist to ensure it can be resolved
if [ ! -d "$TARGET_DIR" ]; then
    if ! mkdir -p "$TARGET_DIR"; then
        echo -e "\033[31mError: failed to create target directory: $TARGET_DIR\033[0m"
        exit 1
    fi
    echo -e "\033[32mCreated target directory: $TARGET_DIR\033[0m"
fi

# Resolve absolute path of Target Dir using standard cd && pwd
if ! TARGET_PATH=$(cd "$TARGET_DIR" && pwd); then
    echo -e "\033[31mError: failed to resolve target directory: $TARGET_DIR\033[0m"
    exit 1
fi
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

echo -e "\033[36mTarget: $TARGET_PATH\033[0m"

# Detect installed agent skills and optional accelerators. By default this is
# read-only. --install-optional can install the small set with known safe commands.
SKILLS_DIR="$HOME/.claude/skills"
PLUGINS_REGISTRY="$HOME/.claude/plugins/installed_plugins.json"
DETECTED_SKILLS=""
GRAPHIFY_INSTALLED=false
CAVEMAN_INSTALLED=false
CODEGRAPH_INSTALLED=false
SENTRY_INSTALLED=false
HEADROOM_INSTALLED=false
PYTHON_CMD=""

detect_python() {
    PYTHON_CMD=""
    if command -v python3 >/dev/null 2>&1; then
        PYTHON_CMD="python3"
    elif command -v python >/dev/null 2>&1; then
        PYTHON_CMD="python"
    fi
}

has_npm() {
    command -v npm >/dev/null 2>&1 && npm --version >/dev/null 2>&1
}

has_uv() {
    command -v uv >/dev/null 2>&1 && uv --version >/dev/null 2>&1
}

has_pipx() {
    command -v pipx >/dev/null 2>&1 && pipx --version >/dev/null 2>&1
}

python_in_venv() {
    if [ -n "${VIRTUAL_ENV:-}" ]; then
        return 0
    fi
    [ -n "$PYTHON_CMD" ] && "$PYTHON_CMD" -c 'import sys; raise SystemExit(0 if sys.prefix != getattr(sys, "base_prefix", sys.prefix) else 1)' >/dev/null 2>&1
}

python_scripts_dir() {
    [ -n "$PYTHON_CMD" ] && "$PYTHON_CMD" -c 'import sysconfig; print(sysconfig.get_path("scripts") or "")' 2>/dev/null
}

find_python_cli() {
    local cmd="$1"
    local scripts_dir user_base candidate
    if command -v "$cmd" >/dev/null 2>&1 && "$cmd" --help >/dev/null 2>&1; then
        command -v "$cmd"
        return 0
    fi
    scripts_dir=""
    user_base=""
    if [ -n "$PYTHON_CMD" ]; then
        scripts_dir=$(python_scripts_dir)
        user_base=$("$PYTHON_CMD" -m site --user-base 2>/dev/null || true)
    fi
    for candidate in \
        "$HOME/.local/bin/$cmd" \
        "$HOME/.local/bin/$cmd.exe" \
        "$HOME/.local/bin/$cmd.cmd" \
        "$scripts_dir/$cmd" \
        "$scripts_dir/$cmd.exe" \
        "$scripts_dir/$cmd.cmd" \
        "$user_base/bin/$cmd" \
        "$user_base/bin/$cmd.exe" \
        "$user_base/bin/$cmd.cmd"; do
        if [ -n "$candidate" ] && [ -x "$candidate" ] && "$candidate" --help >/dev/null 2>&1; then
            printf '%s\n' "$candidate"
            return 0
        fi
    done
    return 1
}

has_codegraph() {
    command -v codegraph >/dev/null 2>&1 && codegraph --version >/dev/null 2>&1
}

has_sentry() {
    if command -v sentry >/dev/null 2>&1 && sentry --version >/dev/null 2>&1; then
        return 0
    fi
    command -v sentry-cli >/dev/null 2>&1 && sentry-cli --version >/dev/null 2>&1
}

has_headroom() {
    command -v headroom >/dev/null 2>&1 && headroom --version >/dev/null 2>&1
}

detect_optional_accelerators() {
    DETECTED_SKILLS=""
    GRAPHIFY_INSTALLED=false
    CAVEMAN_INSTALLED=false
    CODEGRAPH_INSTALLED=false
    SENTRY_INSTALLED=false
    HEADROOM_INSTALLED=false
    GRAPHIFY_STATUS="Graphify: not found under $SKILLS_DIR and no graphify CLI detected -- /grok will fall back to a manual directory/stack scan."
    if [ -d "$SKILLS_DIR" ]; then
        # shellcheck disable=SC2012
        DETECTED_SKILLS=$(ls "$SKILLS_DIR" 2>/dev/null | tr '\n' ',' | sed 's/,$//' | sed 's/,/, /g')
    fi
    if [ -f "$SKILLS_DIR/graphify/SKILL.md" ]; then
        VERSION="unknown version"
        if [ -f "$SKILLS_DIR/graphify/.graphify_version" ]; then
            VERSION=$(cat "$SKILLS_DIR/graphify/.graphify_version")
        fi
        GRAPHIFY_STATUS="Graphify: detected ($VERSION) at $SKILLS_DIR/graphify/SKILL.md -- /grok will use it to build the repo's knowledge graph."
        GRAPHIFY_INSTALLED=true
    else
        if command -v graphify >/dev/null 2>&1 && graphify --help >/dev/null 2>&1; then
            GRAPHIFY_STATUS="Graphify: detected on PATH -- /grok can use it even without a Claude skill folder."
            GRAPHIFY_INSTALLED=true
        fi
    fi

    CAVEMAN_STATUS="Caveman: not installed -- Philosophy V falls back to manual terse-style instructions. Run with --install-optional to install supported optional accelerators after confirmation."
    if [ -f "$PLUGINS_REGISTRY" ] && grep -qF '"caveman@caveman"' "$PLUGINS_REGISTRY"; then
        CAVEMAN_STATUS="Caveman: installed -- Philosophy V and /compact delegate to /caveman and /caveman-compress."
        CAVEMAN_INSTALLED=true
    fi

    CODEGRAPH_STATUS="CodeGraph: not found on PATH -- /grok and /audit-arch fall back to graphify/Understand-Anything/manual scan."
    if has_codegraph; then
        CODEGRAPH_STATUS="CodeGraph: detected on PATH -- /grok and /audit-arch can delegate to it for call-graph/blast-radius queries."
        CODEGRAPH_INSTALLED=true
    fi

    SENTRY_STATUS="Sentry: not found -- /diagnose falls back to manual reproduction script or log-tracing."
    if has_sentry; then
        SENTRY_STATUS="Sentry: detected on PATH -- /diagnose can pull telemetry and crash traces directly using the CLI or REST API."
        SENTRY_INSTALLED=true
    fi

    HEADROOM_STATUS="Headroom: not found on PATH -- /ak-headroom and Cache Optimization fall back to uncompressed context."
    if has_headroom; then
        HEADROOM_STATUS="Headroom: detected on PATH -- /ak-headroom and Cache Optimization can delegate to it for reversible compression."
        HEADROOM_INSTALLED=true
    fi
}

confirm_optional_install() {
    local name="$1"
    if [ "$OPTIONAL_INSTALL_DRY_RUN" = "1" ] || [ "$OPTIONAL_INSTALL_DRY_RUN" = "true" ]; then
        return 0
    fi
    printf '\033[33mInstall optional accelerator %s now? This downloads third-party code. Review DEPENDENCIES.md first. [y/N] \033[0m' "$name"
    read -r answer
    case "$answer" in
        y|Y|yes|YES) return 0 ;;
        *) echo -e "\033[33mSkipped optional accelerator: $name\033[0m"; return 1 ;;
    esac
}

install_graphify_optional() {
    if [ "$GRAPHIFY_INSTALLED" = true ]; then
        return
    fi

    if has_uv; then
        if ! confirm_optional_install "Graphify (uv tool package graphifyy + graphify install)"; then
            return
        fi
        if [ "$OPTIONAL_INSTALL_DRY_RUN" = "1" ] || [ "$OPTIONAL_INSTALL_DRY_RUN" = "true" ]; then
            echo -e "\033[36mDRY RUN: would run 'uv tool install graphifyy' then 'graphify install'\033[0m"
            return
        fi
        uv tool install graphifyy \
            || { echo -e "\033[33mGraphify optional install failed. Continue with manual /ak-grok fallback.\033[0m"; return; }
    elif has_pipx; then
        if ! confirm_optional_install "Graphify (pipx package graphifyy + graphify install)"; then
            return
        fi
        if [ "$OPTIONAL_INSTALL_DRY_RUN" = "1" ] || [ "$OPTIONAL_INSTALL_DRY_RUN" = "true" ]; then
            echo -e "\033[36mDRY RUN: would run 'pipx install graphifyy' then 'graphify install'\033[0m"
            return
        fi
        pipx install graphifyy \
            || { echo -e "\033[33mGraphify optional install failed. Continue with manual /ak-grok fallback.\033[0m"; return; }
    else
        detect_python
        if [ -z "$PYTHON_CMD" ]; then
            echo -e "\033[33mGraphify optional install skipped: uv, pipx, and python3/python not found. See DEPENDENCIES.md.\033[0m"
            return
        fi
        if ! "$PYTHON_CMD" -m pip --version >/dev/null 2>&1; then
            echo -e "\033[33mGraphify optional install skipped: pip is not available for $PYTHON_CMD. See DEPENDENCIES.md.\033[0m"
            return
        fi
        if ! confirm_optional_install "Graphify (python package graphifyy)"; then
            return
        fi
        if python_in_venv; then
            if [ "$OPTIONAL_INSTALL_DRY_RUN" = "1" ] || [ "$OPTIONAL_INSTALL_DRY_RUN" = "true" ]; then
                echo -e "\033[36mDRY RUN: would run '$PYTHON_CMD -m pip install graphifyy' then 'graphify install'\033[0m"
                return
            fi
            "$PYTHON_CMD" -m pip install graphifyy \
                || { echo -e "\033[33mGraphify optional install failed. Continue with manual /ak-grok fallback.\033[0m"; return; }
        else
            if [ "$OPTIONAL_INSTALL_DRY_RUN" = "1" ] || [ "$OPTIONAL_INSTALL_DRY_RUN" = "true" ]; then
                echo -e "\033[36mDRY RUN: would run '$PYTHON_CMD -m pip install --user graphifyy' then 'graphify install'\033[0m"
                return
            fi
            "$PYTHON_CMD" -m pip install --user graphifyy \
                || { echo -e "\033[33mGraphify optional install failed. Continue with manual /ak-grok fallback.\033[0m"; return; }
        fi
    fi

    GRAPHIFY_CMD=""
    GRAPHIFY_CMD=$(find_python_cli graphify || true)
    if [ -n "$GRAPHIFY_CMD" ]; then
        "$GRAPHIFY_CMD" install \
            || echo -e "\033[33mGraphify package installed, but skill registration failed. Run 'graphify install' after review.\033[0m"
    else
        echo -e "\033[33mGraphify package installed, but the graphify CLI is not on PATH. Run 'uv tool update-shell' or 'pipx ensurepath' if applicable, then run 'graphify install'.\033[0m"
    fi
}

install_caveman_optional() {
    if [ "$CAVEMAN_INSTALLED" = true ]; then
        return
    fi
    if ! command -v claude >/dev/null 2>&1; then
        echo -e "\033[33mCaveman optional install skipped: claude CLI not found. See DEPENDENCIES.md.\033[0m"
        return
    fi
    if ! confirm_optional_install "Caveman Claude Code plugin"; then
        return
    fi
    if [ "$OPTIONAL_INSTALL_DRY_RUN" = "1" ] || [ "$OPTIONAL_INSTALL_DRY_RUN" = "true" ]; then
        echo -e "\033[36mDRY RUN: would run 'claude plugin marketplace add JuliusBrussee/caveman' and 'claude plugin install caveman@caveman'\033[0m"
        return
    fi
    claude plugin marketplace add JuliusBrussee/caveman 2>/dev/null \
        || echo -e "\033[33mCaveman marketplace may already be registered; continuing.\033[0m"
    claude plugin install caveman@caveman \
        || echo -e "\033[33mCaveman optional install failed. Continue with manual terse-style fallback.\033[0m"
}

install_codegraph_optional() {
    if [ "$CODEGRAPH_INSTALLED" = true ]; then
        return
    fi
    if ! has_npm; then
        echo -e "\033[33mCodeGraph optional install skipped: npm not found. See DEPENDENCIES.md.\033[0m"
        return
    fi
    if ! confirm_optional_install "CodeGraph (npm package @colbymchenry/codegraph + codegraph install)"; then
        return
    fi
    if [ "$OPTIONAL_INSTALL_DRY_RUN" = "1" ] || [ "$OPTIONAL_INSTALL_DRY_RUN" = "true" ]; then
        echo -e "\033[36mDRY RUN: would run 'npm install -g @colbymchenry/codegraph' then 'codegraph install'\033[0m"
        return
    fi
    npm install -g @colbymchenry/codegraph \
        || { echo -e "\033[33mCodeGraph optional install failed. Continue with manual /ak-grok fallback.\033[0m"; return; }
    if has_codegraph; then
        codegraph install \
            || echo -e "\033[33mCodeGraph CLI installed, but agent registration failed. Run 'codegraph install' after review.\033[0m"
    else
        echo -e "\033[33mCodeGraph package installed, but codegraph is not on PATH. Add the npm global bin directory to PATH, then run 'codegraph install'.\033[0m"
    fi
}

install_sentry_optional() {
    if [ "$SENTRY_INSTALLED" = true ]; then
        return
    fi
    if ! has_npm; then
        echo -e "\033[33mSentry CLI optional install skipped: npm not found. See DEPENDENCIES.md.\033[0m"
        return
    fi
    if ! confirm_optional_install "Sentry CLI (npm package sentry; auth remains manual)"; then
        return
    fi
    if [ "$OPTIONAL_INSTALL_DRY_RUN" = "1" ] || [ "$OPTIONAL_INSTALL_DRY_RUN" = "true" ]; then
        echo -e "\033[36mDRY RUN: would run 'npm install -g sentry'\033[0m"
        return
    fi
    npm install -g sentry \
        || { echo -e "\033[33mSentry CLI optional install failed. Continue with manual /ak-diagnose fallback.\033[0m"; return; }
    echo -e "\033[36mSentry CLI installed. Run 'sentry auth login' when you want telemetry-backed diagnosis.\033[0m"
}

install_headroom_optional() {
    if [ "$HEADROOM_INSTALLED" = true ]; then
        return
    fi
    if has_uv; then
        if ! confirm_optional_install "Headroom CLI (uv tool package headroom-ai[all])"; then
            return
        fi
        if [ "$OPTIONAL_INSTALL_DRY_RUN" = "1" ] || [ "$OPTIONAL_INSTALL_DRY_RUN" = "true" ]; then
            echo -e "\033[36mDRY RUN: would run 'uv tool install \"headroom-ai[all]\"'\033[0m"
            return
        fi
        uv tool install "headroom-ai[all]" \
            || { echo -e "\033[33mHeadroom optional install failed. Continue with uncompressed context fallback.\033[0m"; return; }
        echo -e "\033[36mHeadroom CLI installed. Run 'uv tool update-shell' if headroom is not on PATH, then /ak-headroom for MCP/proxy setup.\033[0m"
        return
    fi

    if has_pipx; then
        if ! confirm_optional_install "Headroom CLI (pipx package headroom-ai[all])"; then
            return
        fi
        if [ "$OPTIONAL_INSTALL_DRY_RUN" = "1" ] || [ "$OPTIONAL_INSTALL_DRY_RUN" = "true" ]; then
            echo -e "\033[36mDRY RUN: would run 'pipx install \"headroom-ai[all]\"'\033[0m"
            return
        fi
        pipx install "headroom-ai[all]" \
            || { echo -e "\033[33mHeadroom optional install failed. Continue with uncompressed context fallback.\033[0m"; return; }
        echo -e "\033[36mHeadroom CLI installed. Run 'pipx ensurepath' if headroom is not on PATH, then /ak-headroom for MCP/proxy setup.\033[0m"
        return
    fi

    detect_python
    if [ -z "$PYTHON_CMD" ]; then
        echo -e "\033[33mHeadroom optional install skipped: uv, pipx, and python3/python not found. See DEPENDENCIES.md.\033[0m"
        return
    fi
    if ! "$PYTHON_CMD" -m pip --version >/dev/null 2>&1; then
        echo -e "\033[33mHeadroom optional install skipped: pip is not available for $PYTHON_CMD. See DEPENDENCIES.md.\033[0m"
        return
    fi
    if ! confirm_optional_install "Headroom CLI (python package headroom-ai[all])"; then
        return
    fi
    if python_in_venv; then
        if [ "$OPTIONAL_INSTALL_DRY_RUN" = "1" ] || [ "$OPTIONAL_INSTALL_DRY_RUN" = "true" ]; then
            echo -e "\033[36mDRY RUN: would run '$PYTHON_CMD -m pip install \"headroom-ai[all]\"'\033[0m"
            return
        fi
        "$PYTHON_CMD" -m pip install "headroom-ai[all]" \
            || { echo -e "\033[33mHeadroom optional install failed. Continue with uncompressed context fallback.\033[0m"; return; }
    else
        if [ "$OPTIONAL_INSTALL_DRY_RUN" = "1" ] || [ "$OPTIONAL_INSTALL_DRY_RUN" = "true" ]; then
            echo -e "\033[36mDRY RUN: would run '$PYTHON_CMD -m pip install --user \"headroom-ai[all]\"'\033[0m"
            return
        fi
        "$PYTHON_CMD" -m pip install --user "headroom-ai[all]" \
            || { echo -e "\033[33mHeadroom optional install failed. Continue with uncompressed context fallback.\033[0m"; return; }
    fi
    echo -e "\033[36mHeadroom CLI installed. Add the Python user scripts directory to PATH if needed, then run /ak-headroom for MCP/proxy setup.\033[0m"
}

detect_optional_accelerators
if [ "$INSTALL_OPTIONAL" = true ]; then
    echo -e "\033[36mOptional accelerator install requested. Supported: Graphify, Caveman, CodeGraph, Sentry CLI, and Headroom.\033[0m"
    install_graphify_optional
    install_caveman_optional
    install_codegraph_optional
    install_sentry_optional
    install_headroom_optional
    detect_optional_accelerators
fi

echo -e "\033[36m$GRAPHIFY_STATUS\033[0m"
if [ -n "$DETECTED_SKILLS" ]; then
    echo -e "\033[36mDetected agent skills: $DETECTED_SKILLS\033[0m"
fi
echo -e "\033[36m$CAVEMAN_STATUS\033[0m"
echo -e "\033[36m$CODEGRAPH_STATUS\033[0m"
echo -e "\033[36m$SENTRY_STATUS\033[0m"
echo -e "\033[36m$HEADROOM_STATUS\033[0m"

# Generate the portable rule files from the single canonical templates/RULESET.md.
# Each tool gets its own header; the body is shared so it can never drift.
# This includes generating SKILL.md for the agent skill system.
RULESET_PATH="$SCRIPT_DIR/templates/RULESET.md"

generate_rule_file() {
    local dest="$1"
    local header="$2"
    local label="$3"

    mkdir -p "$(dirname "$dest")"
    if [ ! -f "$dest" ] || [ "$FORCE" = true ]; then
        printf '%s' "$header" > "$dest"
        if [ "$label" != "SKILL.md" ]; then
            cat "$RULESET_PATH" >> "$dest"
        fi
        echo -e "\033[32mGenerated rules: $label\033[0m"
    else
        echo -e "\033[33mSkipped rules: $label (already exists, use --force to overwrite)\033[0m"
    fi
}

generate_rule_file "$TARGET_PATH/CLAUDE.md" "# Claude Code Guidelines (CLAUDE.md)

This project runs under the **Antariksh Unified Developer Framework**. Adhere to the following rules at all times.

---

" "CLAUDE.md"

generate_rule_file "$TARGET_PATH/AGENTS.md" "# Universal Agent Guidelines (AGENTS.md)

This repository follows the **Antariksh Unified Developer Framework**. All agents (Gemini, OpenAI, Ollama, DeepSeek, Minimax, Claude, Codex, OpenCode) must adhere to these rules.

---

" "AGENTS.md"

generate_rule_file "$TARGET_PATH/.cursorrules" "# Cursor System Rules (.cursorrules)

You are an expert developer assistant executing within Cursor. You follow the **Antariksh Unified Developer Framework**.

---

" ".cursorrules"

generate_rule_file "$TARGET_PATH/.clinerules" "# Cline/Roo-Code System Rules (.clinerules)

You are an expert developer assistant executing within Cline or Roo-Code. You follow the **Antariksh Unified Developer Framework**.

---

" ".clinerules"

generate_rule_file "$TARGET_PATH/GEMINI.md" "# Gemini CLI Guidelines (GEMINI.md)

This project runs under the **Antariksh Unified Developer Framework**. Adhere to the following rules at all times.

---

" "GEMINI.md"

generate_rule_file "$TARGET_PATH/.github/copilot-instructions.md" "# GitHub Copilot Instructions (.github/copilot-instructions.md)

This project runs under the **Antariksh Unified Developer Framework**. Adhere to the following rules at all times.

---

" ".github/copilot-instructions.md"

generate_rule_file "$TARGET_PATH/SKILL.md" "---
name: antariksh-unified-skill
description: Master developer skill combining planning, simplicity, TDD, diagnosis, devops, QA, security, and skill evolution
---

# Antariksh Unified Agent Skill (Master Developer Framework)

This is a master-skill for developer agents. When running in a toolless or web-UI interface, follow the inline loops and command workflows below.

## 1. Core Sessions Loop
- **Session Start**:
  1. Read \`memory/handoff.md\` if exists → then delete/clear it.
  2. Read \`MEMORY.md\`.
  3. Read \`memory/local_env.md\` if exists (local skills/tools).
  4. Read \`AGENTS.md\` + \`GLOSSARY.md\`.
  5. **Context Validation Check**: Check if \`memory/projects/<name>.md\` exists. If not, alert the user and advise running \`/ak-grok\` first to build the project context card and knowledge graph.
  6. **Episodic Review**: Read the last 5 daily logs (\`memory/daily/*.md\`) to gain historic execution context.
  7. **Session Boot**: Set up today's daily log and ask the user \"Is there anything new or changed before we begin?\"
- **Session End**: Run \`/ak-compact\` to summarize logs, update project lists, update MEMORY.md, record learned corrections, and append reusable skill observations to \`memory/skill-observations.md\`.

## 2. Slash Commands Index & Workflows
- **\`/ak-grill\`**: Interrogate scope, check edge cases, and output action plan → \`.agents/skills/grill/SKILL.md\`.
- **\`/ak-align\`**: Pre-coding Socratic scope alignment to agree on plans and success criteria.
- **\`/ak-align-docs\`**: Scope alignment + Shared Language glossary update + ADR generation → \`.agents/skills/align-docs/SKILL.md\`.
- **\`/ak-to-prd\`**: Scopes features with module quizzes and drafts PRD to \`memory/prds/\` → \`.agents/skills/to-prd/SKILL.md\`.
- **\`/ak-spec\`**: Spec-driven loop (specify -> clarify -> plan -> tasks -> analyze -> implement -> converge) → \`.agents/skills/spec/SKILL.md\`.
- **\`/ak-tdd\`**: Test-driven development (write tests -> run fail -> implement -> run pass).
- **\`/ak-diagnose\`**: Reproduce bug -> bisect scope -> find root cause -> surgical fix -> prevent.
- **\`/ak-bughunt\`**: Sweep recent commits for critical defects (trace callers -> concrete trigger scenario -> minimal gated fix or one-line all-clear) → \`.agents/skills/bughunt/SKILL.md\`.
- **\`/ak-devops\`**: Scaffold container/IaC files, run linters, validate dry-run setups.
- **\`/ak-ci-check\`**: Run local line ending, shellcheck, Trivy scan, secrets scan, and indentation diff checks.
- **\`/ak-security\`**: OWASP threat audit, local credentials scan, dependency CVE audit, and security report.
- **\`/ak-skillset\`**: Observation intake -> skill triage (USE_EXISTING, etc.) -> 11 lenses analysis -> XML spec -> public/internal safety sweep -> critique duel.
- **\`/ak-code\`**: Surgical minimal implementation (contracts check -> lazy ladder -> tests -> diff check).
- **\`/ak-review\`**: Adversarial attacker duel verification against edge cases and interface drift.
- **\`/ak-prreview\`**: Gated PR review creating draft reviews for explicit user approval.
- **\`/ak-worktree\`**: Worktree-isolated parallel subagent sweep orchestration.
- **\`/ak-orchestrate\`**: Fleet orchestration (plan -> decompose -> brief -> delegate -> synthesize) → \`.agents/skills/orchestrate/SKILL.md\`.
- **\`/ak-doc\`**: Direct module and interface documentation via tables and diagrams → \`.agents/skills/doc/SKILL.md\`.
- **\`/ak-grok\`**: Incremental repository scans (RAG index building/AST parsing) to map structure.
- **\`/ak-audit-arch\`**: Sweep codebase for architectural smells (god files, duplicate logic, tangles).
- **\`/ak-scratch\`**: Scaffold new projects with standard folder layouts and template configs → \`.agents/skills/scratch/SKILL.md\`.
- **\`/ak-compact\`**: Log consolidation, project facts compilation, skill-observation capture, inbox clearing, and corrections capture.
- **\`/ak-handoff\`**: Compile handoff notes to \`memory/handoff.md\` for incoming agents.
" "SKILL.md"

# Split RULESET.md into sections.
# Every time we see a line that is exactly "---" (ignoring carriage returns), we increment the counter.
section_1=""
section_2=""
section_3=""
section_4=""
section_5=""
current_section=1

while IFS= read -r line || [ -n "$line" ]; do
    clean_line=$(echo "$line" | tr -d '\r')
    if [ "$clean_line" = "---" ]; then
        current_section=$((current_section + 1))
        continue
    fi
    case $current_section in
        1) section_1="${section_1}${line}"$'\n' ;;
        2) section_2="${section_2}${line}"$'\n' ;;
        3) section_3="${section_3}${line}"$'\n' ;;
        4) section_4="${section_4}${line}"$'\n' ;;
        5) section_5="${section_5}${line}"$'\n' ;;
    esac
done < "$RULESET_PATH"

# Generate modular Cursor MDC rules under .cursor/rules/
CURSOR_RULES_DIR="$TARGET_PATH/.cursor/rules"
mkdir -p "$CURSOR_RULES_DIR"

if [ "$current_section" -ge 5 ]; then
    CORE_MDC_PATH="$CURSOR_RULES_DIR/core.mdc"
    CORE_MDC_HEADER="---
description: Core developer philosophies, fallback protocols, and Second Brain standards
globs: *
---

"
    if [ ! -f "$CORE_MDC_PATH" ] || [ "$FORCE" = true ]; then
        printf '%s' "$CORE_MDC_HEADER" > "$CORE_MDC_PATH"
        printf '%s\n\n---\n\n%s\n\n---\n\n%s\n\n---\n\n%s' "$section_1" "$section_2" "$section_3" "$section_5" >> "$CORE_MDC_PATH"
        echo -e "\033[32mGenerated Cursor MDC: core.mdc\033[0m"
    else
        echo -e "\033[33mSkipped Cursor MDC: core.mdc (already exists, use --force to overwrite)\033[0m"
    fi

    COMMANDS_MDC_PATH="$CURSOR_RULES_DIR/commands.mdc"
    COMMANDS_MDC_HEADER="---
description: Interactive agent slash commands (/ak-tdd, /ak-diagnose, /ak-align, etc.)
globs: *
---

"
    if [ ! -f "$COMMANDS_MDC_PATH" ] || [ "$FORCE" = true ]; then
        printf '%s' "$COMMANDS_MDC_HEADER" > "$COMMANDS_MDC_PATH"
        printf '%s' "$section_4" >> "$COMMANDS_MDC_PATH"
        echo -e "\033[32mGenerated Cursor MDC: commands.mdc\033[0m"
    else
        echo -e "\033[33mSkipped Cursor MDC: commands.mdc (already exists, use --force to overwrite)\033[0m"
    fi
fi

if [ "$RULES_ONLY" = true ]; then
    echo -e "\n\033[36mRules and Cursor MDC regenerated from templates/RULESET.md. Skipped memory scaffolding (--rules-only).\033[0m"
    exit 0
fi

# Copy the skills/ folder if it exists in the root
if [ -d "$SCRIPT_DIR/skills" ]; then
    if [ ! -d "$TARGET_PATH/.agents/skills" ] || [ "$FORCE" = true ]; then
        mkdir -p "$TARGET_PATH/.agents/skills"
        cp -R "$SCRIPT_DIR/skills/." "$TARGET_PATH/.agents/skills/"
        echo -e "\033[32mCreated folder: .agents/skills/ (modular agent skills)\033[0m"
    else
        echo -e "\033[33mSkipped folder: .agents/skills/ (already exists, use --force to overwrite)\033[0m"
    fi
fi

# Copy shared framework scripts needed by installed skills.
if [ -d "$SCRIPT_DIR/scripts" ]; then
    if [ ! -d "$TARGET_PATH/.agents/scripts" ] || [ "$FORCE" = true ]; then
        mkdir -p "$TARGET_PATH/.agents/scripts"
        for script_file in scan-secrets.sh scan-secrets.ps1; do
            if [ -f "$SCRIPT_DIR/scripts/$script_file" ]; then
                cp "$SCRIPT_DIR/scripts/$script_file" "$TARGET_PATH/.agents/scripts/$script_file"
            fi
        done
        if [ -f "$TARGET_PATH/.agents/scripts/scan-secrets.sh" ]; then
            chmod +x "$TARGET_PATH/.agents/scripts/scan-secrets.sh"
        fi
        echo -e "\033[32mCreated folder: .agents/scripts/ (shared framework scripts)\033[0m"
    else
        echo -e "\033[33mSkipped folder: .agents/scripts/ (already exists, use --force to overwrite)\033[0m"
    fi
fi

# Create folders
folders=("memory" "memory/daily" "memory/projects" "memory/adr" "memory/prds")
for f in "${folders[@]}"; do
    if [ ! -d "$TARGET_PATH/$f" ]; then
        mkdir -p "$TARGET_PATH/$f"
        echo -e "\033[32mCreated folder: $f/\033[0m"
    fi
done

# Copy Templates function
copy_template() {
    local src="$1"
    local dest="$2"

    if [ ! -f "$dest" ] || [ "$FORCE" = true ]; then
        cp "$src" "$dest"
        echo -e "\033[32mCreated file: $3\033[0m"
    else
        echo -e "\033[33mSkipped file: $3 (already exists, use --force to overwrite)\033[0m"
    fi
}

LOCAL_ENV_DEST="$TARGET_PATH/memory/local_env.md"
if [ ! -f "$LOCAL_ENV_DEST" ] || [ "$FORCE" = true ]; then
    SKILLS_LINE="No agent skills detected under $SKILLS_DIR."
    if [ -n "$DETECTED_SKILLS" ]; then
        SKILLS_LINE="Detected agent skills on this machine: $DETECTED_SKILLS."
    fi
    SENTRY_ORG_STATUS="Not configured"
    if [ -n "$SENTRY_ORG_SLUG" ]; then
        SENTRY_ORG_STATUS="Configured (from env)"
    fi
    SENTRY_TOKEN_STATUS="Not configured"
    if [ -n "$SENTRY_AUTH_TOKEN" ]; then
        SENTRY_TOKEN_STATUS="Configured (from env)"
    fi
    esc_graphify=$(escape_sed "$GRAPHIFY_STATUS")
    esc_codegraph=$(escape_sed "$CODEGRAPH_STATUS")
    esc_caveman=$(escape_sed "$CAVEMAN_STATUS")
    esc_sentry=$(escape_sed "$SENTRY_STATUS")
    esc_headroom=$(escape_sed "$HEADROOM_STATUS")
    esc_sentry_org=$(escape_sed "$SENTRY_ORG_STATUS")
    esc_sentry_token=$(escape_sed "$SENTRY_TOKEN_STATUS")
    esc_skills=$(escape_sed "$SKILLS_LINE")

    sed -e "s#\[GRAPHIFY_STATUS\]#$esc_graphify#" \
        -e "s#\[CODEGRAPH_STATUS\]#$esc_codegraph#" \
        -e "s#\[CAVEMAN_STATUS\]#$esc_caveman#" \
        -e "s#\[SENTRY_STATUS\]#$esc_sentry#" \
        -e "s#\[HEADROOM_STATUS\]#$esc_headroom#" \
        -e "s#\[SENTRY_ORG_SLUG_STATUS\]#$esc_sentry_org#" \
        -e "s#\[SENTRY_AUTH_TOKEN_STATUS\]#$esc_sentry_token#" \
        -e "s#\[DETECTED_SKILLS\]#$esc_skills#" \
        "$SCRIPT_DIR/templates/memory/local_env.md" | sed "/<!-- TEMPLATE_DO_NOT_USE -->/d" > "$LOCAL_ENV_DEST"
    echo -e "\033[32mCreated file: memory/local_env.md\033[0m"
else
    echo -e "\033[33mSkipped file: memory/local_env.md (already exists, use --force to overwrite)\033[0m"
fi

copy_template "$SCRIPT_DIR/templates/MEMORY.md" "$TARGET_PATH/MEMORY.md" "MEMORY.md"
copy_template "$SCRIPT_DIR/templates/GLOSSARY.md" "$TARGET_PATH/GLOSSARY.md" "GLOSSARY.md"
copy_template "$SCRIPT_DIR/templates/inbox.md" "$TARGET_PATH/inbox.md" "inbox.md"
copy_template "$SCRIPT_DIR/templates/skill-observations.md" "$TARGET_PATH/memory/skill-observations.md" "memory/skill-observations.md"

TASK_DEST="$TARGET_PATH/task.md"
if [ ! -f "$TASK_DEST" ] || [ "$FORCE" = true ]; then
    sed "/<!-- TEMPLATE_DO_NOT_USE -->/d" "$SCRIPT_DIR/templates/task.md" > "$TASK_DEST"
    echo -e "\033[32mCreated file: task.md\033[0m"
else
    echo -e "\033[33mSkipped file: task.md (already exists, use --force to overwrite)\033[0m"
fi
copy_template "$SCRIPT_DIR/templates/memory/daily/template.md" "$TARGET_PATH/memory/daily/template.md" "memory/daily/template.md"
copy_template "$SCRIPT_DIR/templates/memory/projects/template.md" "$TARGET_PATH/memory/projects/template.md" "memory/projects/template.md"
copy_template "$SCRIPT_DIR/templates/memory/adr/template.md" "$TARGET_PATH/memory/adr/template.md" "memory/adr/template.md"
copy_template "$SCRIPT_DIR/templates/memory/prds/template.md" "$TARGET_PATH/memory/prds/template.md" "memory/prds/template.md"
copy_template "$SCRIPT_DIR/templates/INTERFACES.md" "$TARGET_PATH/INTERFACES.md" "INTERFACES.md"

# Create Today's Daily Log if it doesn't exist
TODAY=$(date +%Y-%m-%d)
DAILY_LOG_DEST="$TARGET_PATH/memory/daily/$TODAY.md"
if [ ! -f "$DAILY_LOG_DEST" ]; then
    cat <<EOF > "$DAILY_LOG_DEST"
# Daily Log -- $TODAY

## Start of Day
- [ ]

## Log Entries
-

## End of Day Summary
- **Accomplishments**:
- **Key Decisions**:
- **Open Loops**:
- **Tomorrow's First Task**:
EOF
    echo -e "\033[32mCreated today's daily log: memory/daily/$TODAY.md\033[0m"
fi

# Create repository-specific project context file if it doesn't exist
PROJECT_NAME=$(basename "$TARGET_PATH")
PROJECT_FILE_DEST="$TARGET_PATH/memory/projects/${PROJECT_NAME}.md"
if [ ! -f "$PROJECT_FILE_DEST" ] || [ "$FORCE" = true ]; then
    SRC_TEMPLATE="$SCRIPT_DIR/templates/memory/projects/template.md"
    esc_project_name=$(escape_sed "$PROJECT_NAME")
    sed "s#\[Project Name\]#$esc_project_name#g" "$SRC_TEMPLATE" | sed "/<!-- TEMPLATE_DO_NOT_USE -->/d" > "$PROJECT_FILE_DEST"
    echo -e "\033[32mCreated project memory file: memory/projects/${PROJECT_NAME}.md\033[0m"
fi

# Ensure .gitignore covers secrets/junk (Philosophy VI) -- never overwrites, only
# creates if missing or appends the baseline block if an existing file lacks it.
GITIGNORE_TEMPLATE="$SCRIPT_DIR/templates/.gitignore"
GITIGNORE_DEST="$TARGET_PATH/.gitignore"
GITIGNORE_MARKER="# Antariksh Unified Framework"
if [ ! -f "$GITIGNORE_DEST" ]; then
    cp "$GITIGNORE_TEMPLATE" "$GITIGNORE_DEST"
    echo -e "\033[32mCreated file: .gitignore\033[0m"
elif ! grep -qF "$GITIGNORE_MARKER" "$GITIGNORE_DEST"; then
    printf '\n' >> "$GITIGNORE_DEST"
    cat "$GITIGNORE_TEMPLATE" >> "$GITIGNORE_DEST"
    echo -e "\033[32mAppended baseline secrets/junk rules to existing .gitignore\033[0m"
else
    echo -e "\033[33mSkipped .gitignore (baseline rules already present)\033[0m"
fi

# Optional: Claude Code hooks that mechanically enforce the Second Brain loop
# (SessionStart auto-loads memory, Stop blocks if real edits weren't logged).
# Opt-in only -- this is Claude-Code-specific and touches .claude/settings.json,
# unlike everything else this installer does.
if [ "$WITH_HOOKS" = true ]; then
    mkdir -p "$TARGET_PATH/.claude/hooks"

    for hook_script in session-start.sh stop-check.sh; do
        hook_src="$SCRIPT_DIR/templates/.claude/hooks/$hook_script"
        hook_dest="$TARGET_PATH/.claude/hooks/$hook_script"
        if [ ! -f "$hook_dest" ] || [ "$FORCE" = true ]; then
            cp "$hook_src" "$hook_dest"
            chmod +x "$hook_dest"
            echo -e "\033[32mCreated file: .claude/hooks/$hook_script\033[0m"
        else
            echo -e "\033[33mSkipped file: .claude/hooks/$hook_script (already exists, use --force to overwrite)\033[0m"
        fi
    done

    SETTINGS_TEMPLATE="$SCRIPT_DIR/templates/.claude/settings.json"
    SETTINGS_DEST="$TARGET_PATH/.claude/settings.json"

    if [ ! -f "$SETTINGS_DEST" ]; then
        cp "$SETTINGS_TEMPLATE" "$SETTINGS_DEST"
        echo -e "\033[32mCreated file: .claude/settings.json\033[0m"
    elif command -v jq >/dev/null 2>&1; then
        SESSION_CMD=$(jq -r '.hooks.SessionStart[0].hooks[0].command' "$SETTINGS_TEMPLATE")
        STOP_CMD=$(jq -r '.hooks.Stop[0].hooks[0].command' "$SETTINGS_TEMPLATE")

        jq --arg cmd "$SESSION_CMD" '
            .hooks //= {} | .hooks.SessionStart //= [] |
            if (.hooks.SessionStart | any(.hooks[]?.command == $cmd)) then .
            else .hooks.SessionStart += [{"hooks":[{"type":"command","command":$cmd,"timeout":30}]}]
            end
        ' "$SETTINGS_DEST" > "$SETTINGS_DEST.tmp" && mv "$SETTINGS_DEST.tmp" "$SETTINGS_DEST"

        jq --arg cmd "$STOP_CMD" '
            .hooks //= {} | .hooks.Stop //= [] |
            if (.hooks.Stop | any(.hooks[]?.command == $cmd)) then .
            else .hooks.Stop += [{"hooks":[{"type":"command","command":$cmd,"timeout":10}]}]
            end
        ' "$SETTINGS_DEST" > "$SETTINGS_DEST.tmp" && mv "$SETTINGS_DEST.tmp" "$SETTINGS_DEST"

        echo -e "\033[32mMerged hooks into existing .claude/settings.json\033[0m"
    else
        echo -e "\033[33m.claude/settings.json already exists and 'jq' isn't available to merge safely.\033[0m"
        echo -e "\033[33mAdd this manually under its \"hooks\" key:\033[0m"
        cat "$SETTINGS_TEMPLATE"
    fi

    echo -e "\033[36mHooks installed. Claude Code needs a bash-capable shell to run them.\033[0m"

    # Codex CLI Hooks
    mkdir -p "$TARGET_PATH/.codex/hooks"

    for hook_script in session-start.sh stop-check.sh; do
        hook_src="$SCRIPT_DIR/templates/.claude/hooks/$hook_script"
        hook_dest="$TARGET_PATH/.codex/hooks/$hook_script"
        if [ ! -f "$hook_dest" ] || [ "$FORCE" = true ]; then
            cp "$hook_src" "$hook_dest"
            chmod +x "$hook_dest"
            echo -e "\033[32mCreated file: .codex/hooks/$hook_script\033[0m"
        else
            echo -e "\033[33mSkipped file: .codex/hooks/$hook_script (already exists, use --force to overwrite)\033[0m"
        fi
    done

    CODEX_SETTINGS_TEMPLATE="$SCRIPT_DIR/templates/.claude/settings.json"
    CODEX_SETTINGS_DEST="$TARGET_PATH/.codex/hooks.json"

    if [ ! -f "$CODEX_SETTINGS_DEST" ]; then
        sed -e 's/CLAUDE_PROJECT_DIR/CODEX_PROJECT_DIR/g' -e 's/\.claude\/hooks/\.codex\/hooks/g' "$CODEX_SETTINGS_TEMPLATE" > "$CODEX_SETTINGS_DEST"
        echo -e "\033[32mCreated file: .codex/hooks.json\033[0m"
    elif command -v jq >/dev/null 2>&1; then
        SESSION_CMD=$(jq -r '.hooks.SessionStart[0].hooks[0].command' "$CODEX_SETTINGS_TEMPLATE" | sed -e 's/CLAUDE_PROJECT_DIR/CODEX_PROJECT_DIR/g' -e 's/\.claude\/hooks/\.codex\/hooks/g')
        STOP_CMD=$(jq -r '.hooks.Stop[0].hooks[0].command' "$CODEX_SETTINGS_TEMPLATE" | sed -e 's/CLAUDE_PROJECT_DIR/CODEX_PROJECT_DIR/g' -e 's/\.claude\/hooks/\.codex\/hooks/g')

        jq --arg cmd "$SESSION_CMD" '
            .hooks //= {} | .hooks.SessionStart //= [] |
            if (.hooks.SessionStart | any(.hooks[]?.command == $cmd)) then .
            else .hooks.SessionStart += [{"hooks":[{"type":"command","command":$cmd,"timeout":30}]}]
            end
        ' "$CODEX_SETTINGS_DEST" > "$CODEX_SETTINGS_DEST.tmp" && mv "$CODEX_SETTINGS_DEST.tmp" "$CODEX_SETTINGS_DEST"

        jq --arg cmd "$STOP_CMD" '
            .hooks //= {} | .hooks.Stop //= [] |
            if (.hooks.Stop | any(.hooks[]?.command == $cmd)) then .
            else .hooks.Stop += [{"hooks":[{"type":"command","command":$cmd,"timeout":10}]}]
            end
        ' "$CODEX_SETTINGS_DEST" > "$CODEX_SETTINGS_DEST.tmp" && mv "$CODEX_SETTINGS_DEST.tmp" "$CODEX_SETTINGS_DEST"

        echo -e "\033[32mMerged hooks into existing .codex/hooks.json\033[0m"
    else
        echo -e "\033[33m.codex/hooks.json already exists and 'jq' isn't available to merge safely.\033[0m"
    fi

    echo -e "\033[36mPowerShell/Bash hooks installed successfully (Claude Code + Codex CLI).\033[0m"
fi

echo -e "\n\033[36mAntariksh rules deployed. Memory folders initialized. Code safe.\033[0m"
