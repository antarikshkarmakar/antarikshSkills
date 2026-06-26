#!/bin/bash
# install.sh -- Antariksh Unified Skill Deployer for macOS/Linux
# Usage: ./install.sh [target_directory] [--force]

TARGET_DIR="."
FORCE=false

# Simple argument parsing
for arg in "$@"; do
    if [ "$arg" == "--force" ] || [ "$arg" == "-f" ]; then
        FORCE=true
    else
        TARGET_DIR="$arg"
    fi
done

# Resolve absolute path of Target Dir
TARGET_PATH=$(cd "$TARGET_DIR" 2>/dev/null && pwd || realpath "$TARGET_DIR")
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

echo -e "\033[36mTarget: $TARGET_PATH\033[0m"

# Create folders
folders=("memory" "memory/daily" "memory/projects")
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

copy_template "$SCRIPT_DIR/templates/MEMORY.md" "$TARGET_PATH/MEMORY.md" "MEMORY.md"
copy_template "$SCRIPT_DIR/templates/inbox.md" "$TARGET_PATH/inbox.md" "inbox.md"
copy_template "$SCRIPT_DIR/templates/memory/daily/template.md" "$TARGET_PATH/memory/daily/template.md" "memory/daily/template.md"
copy_template "$SCRIPT_DIR/templates/memory/projects/template.md" "$TARGET_PATH/memory/projects/template.md" "memory/projects/template.md"
copy_template "$SCRIPT_DIR/templates/INTERFACES.md" "$TARGET_PATH/INTERFACES.md" "INTERFACES.md"

# Create Today's Daily Log if it doesn't exist
TODAY=$(date +%Y-%m-%d)
DAILY_LOG_DEST="$TARGET_PATH/memory/daily/$TODAY.md"
if [ ! -f "$DAILY_LOG_DEST" ]; then
    cp "$SCRIPT_DIR/templates/memory/daily/template.md" "$DAILY_LOG_DEST"
    echo -e "\033[32mCreated today's daily log: memory/daily/$TODAY.md\033[0m"
fi

# Copy Rules
rules=("AGENTS.md" "CLAUDE.md" ".cursorrules" ".clinerules")
for r in "${rules[@]}"; do
    copy_template "$SCRIPT_DIR/$r" "$TARGET_PATH/$r" "$r"
done

echo -e "\n\033[36mAntariksh rules deployed. Memory folders initialized. Code safe.\033[0m"
