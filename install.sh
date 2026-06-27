#!/bin/bash
# install.sh -- Antariksh Unified Skill Deployer for macOS/Linux/WSL
# Usage: ./install.sh [target_directory] [--force] [--rules-only] [--hooks]

TARGET_DIR="."
FORCE=false
RULES_ONLY=false
WITH_HOOKS=false

# Simple argument parsing
for arg in "$@"; do
    if [ "$arg" == "--force" ] || [ "$arg" == "-f" ]; then
        FORCE=true
    elif [ "$arg" == "--rules-only" ] || [ "$arg" == "-r" ]; then
        RULES_ONLY=true
    elif [ "$arg" == "--hooks" ] || [ "$arg" == "-k" ]; then
        WITH_HOOKS=true
    else
        TARGET_DIR="$arg"
    fi
done

# Resolve absolute path of Target Dir
TARGET_PATH=$(cd "$TARGET_DIR" 2>/dev/null && pwd || realpath "$TARGET_DIR")
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

echo -e "\033[36mTarget: $TARGET_PATH\033[0m"

# Create target directory if it doesn't exist
if [ ! -d "$TARGET_PATH" ]; then
    mkdir -p "$TARGET_PATH"
    echo -e "\033[32mCreated target directory: $TARGET_PATH\033[0m"
fi

# Detect installed agent skills (read-only -- never copies or installs anything)
SKILLS_DIR="$HOME/.claude/skills"
GRAPHIFY_STATUS="Graphify: not found under $SKILLS_DIR -- /grok will fall back to a manual directory/stack scan."
DETECTED_SKILLS=""
if [ -d "$SKILLS_DIR" ]; then
    DETECTED_SKILLS=$(ls "$SKILLS_DIR" 2>/dev/null | tr '\n' ',' | sed 's/,$//' | sed 's/,/, /g')
    if [ -f "$SKILLS_DIR/graphify/SKILL.md" ]; then
        VERSION="unknown version"
        if [ -f "$SKILLS_DIR/graphify/.graphify_version" ]; then
            VERSION=$(cat "$SKILLS_DIR/graphify/.graphify_version")
        fi
        GRAPHIFY_STATUS="Graphify: detected ($VERSION) at $SKILLS_DIR/graphify/SKILL.md -- /grok will use it to build the repo's knowledge graph."
    fi
fi
echo -e "\033[36m$GRAPHIFY_STATUS\033[0m"
if [ -n "$DETECTED_SKILLS" ]; then
    echo -e "\033[36mDetected agent skills: $DETECTED_SKILLS\033[0m"
fi

# Detect the caveman plugin (read-only -- never installs anything; caveman is a
# Claude Code plugin registered in plugins/installed_plugins.json, not a skills/ folder).
PLUGINS_REGISTRY="$HOME/.claude/plugins/installed_plugins.json"
CAVEMAN_INSTALL_CMD='curl -fsSL https://raw.githubusercontent.com/JuliusBrussee/caveman/main/install.sh | bash'
CAVEMAN_STATUS="Caveman: not installed -- Philosophy V falls back to manual terse-style instructions. To install: $CAVEMAN_INSTALL_CMD"
if [ -f "$PLUGINS_REGISTRY" ] && grep -qF '"caveman@caveman"' "$PLUGINS_REGISTRY"; then
    CAVEMAN_STATUS="Caveman: installed -- Philosophy V and /compact delegate to /caveman and /caveman-compress."
fi
echo -e "\033[36m$CAVEMAN_STATUS\033[0m"

# Detect the CodeGraph CLI (read-only -- checks PATH only, never installs anything).
CODEGRAPH_STATUS="CodeGraph: not found on PATH -- /grok and /audit-arch fall back to graphify/Understand-Anything/manual scan."
if command -v codegraph >/dev/null 2>&1; then
    CODEGRAPH_STATUS="CodeGraph: detected on PATH -- /grok and /audit-arch can delegate to it for call-graph/blast-radius queries."
fi
echo -e "\033[36m$CODEGRAPH_STATUS\033[0m"

# Generate the 6 portable rule files from the single canonical templates/RULESET.md.
# Each tool gets its own header; the body is shared so it can never drift.
# SKILL.md is NOT generated here -- it's the hand-maintained, richer master skill
# definition for this framework itself, not a per-project file the installer deploys.
RULESET_PATH="$SCRIPT_DIR/templates/RULESET.md"

generate_rule_file() {
    local dest="$1"
    local header="$2"
    local label="$3"

    mkdir -p "$(dirname "$dest")"
    if [ ! -f "$dest" ] || [ "$FORCE" = true ]; then
        printf '%s' "$header" > "$dest"
        cat "$RULESET_PATH" >> "$dest"
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

if [ "$RULES_ONLY" = true ]; then
    echo -e "\n\033[36mRules regenerated from templates/RULESET.md. Skipped memory scaffolding (--rules-only).\033[0m"
    exit 0
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

MEMORY_DEST="$TARGET_PATH/MEMORY.md"
if [ ! -f "$MEMORY_DEST" ] || [ "$FORCE" = true ]; then
    SKILLS_LINE="No agent skills detected under $SKILLS_DIR."
    if [ -n "$DETECTED_SKILLS" ]; then
        SKILLS_LINE="Detected agent skills on this machine: $DETECTED_SKILLS."
    fi
    sed -e "s#\[GRAPHIFY_STATUS\]#$GRAPHIFY_STATUS#" -e "s#\[CODEGRAPH_STATUS\]#$CODEGRAPH_STATUS#" -e "s#\[CAVEMAN_STATUS\]#$CAVEMAN_STATUS#" -e "s#\[DETECTED_SKILLS\]#$SKILLS_LINE#" \
        "$SCRIPT_DIR/templates/MEMORY.md" > "$MEMORY_DEST"
    echo -e "\033[32mCreated file: MEMORY.md\033[0m"
else
    echo -e "\033[33mSkipped file: MEMORY.md (already exists, use --force to overwrite)\033[0m"
fi

copy_template "$SCRIPT_DIR/templates/GLOSSARY.md" "$TARGET_PATH/GLOSSARY.md" "GLOSSARY.md"
copy_template "$SCRIPT_DIR/templates/inbox.md" "$TARGET_PATH/inbox.md" "inbox.md"
copy_template "$SCRIPT_DIR/templates/memory/daily/template.md" "$TARGET_PATH/memory/daily/template.md" "memory/daily/template.md"
copy_template "$SCRIPT_DIR/templates/memory/projects/template.md" "$TARGET_PATH/memory/projects/template.md" "memory/projects/template.md"
copy_template "$SCRIPT_DIR/templates/memory/adr/template.md" "$TARGET_PATH/memory/adr/template.md" "memory/adr/template.md"
copy_template "$SCRIPT_DIR/templates/memory/prds/template.md" "$TARGET_PATH/memory/prds/template.md" "memory/prds/template.md"
copy_template "$SCRIPT_DIR/templates/memory/handoff.md" "$TARGET_PATH/memory/handoff.md" "memory/handoff.md"
copy_template "$SCRIPT_DIR/templates/INTERFACES.md" "$TARGET_PATH/INTERFACES.md" "INTERFACES.md"

# Create Today's Daily Log if it doesn't exist
TODAY=$(date +%Y-%m-%d)
DAILY_LOG_DEST="$TARGET_PATH/memory/daily/$TODAY.md"
if [ ! -f "$DAILY_LOG_DEST" ]; then
    sed "s/\[YYYY-MM-DD\]/$TODAY/g" "$SCRIPT_DIR/templates/memory/daily/template.md" > "$DAILY_LOG_DEST"
    echo -e "\033[32mCreated today's daily log: memory/daily/$TODAY.md\033[0m"
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
fi

echo -e "\n\033[36mAntariksh rules deployed. Memory folders initialized. Code safe.\033[0m"
