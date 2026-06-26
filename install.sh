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

# Create Directories
MEM_DIR="$TARGET_PATH/memory"
if [ ! -d "$MEM_DIR" ]; then
    mkdir -p "$MEM_DIR"
    echo -e "\033[32mCreated folder: memory/\033[0m"
fi

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

copy_template "$SCRIPT_DIR/templates/memory/IDENTITY.md" "$MEM_DIR/IDENTITY.md" "memory/IDENTITY.md"
copy_template "$SCRIPT_DIR/templates/memory/SEMANTIC.md" "$MEM_DIR/SEMANTIC.md" "memory/SEMANTIC.md"
copy_template "$SCRIPT_DIR/templates/memory/EPISODIC.md" "$MEM_DIR/EPISODIC.md" "memory/EPISODIC.md"
copy_template "$SCRIPT_DIR/templates/memory/WORKING.md" "$MEM_DIR/WORKING.md" "memory/WORKING.md"
copy_template "$SCRIPT_DIR/templates/INTERFACES.md" "$TARGET_PATH/INTERFACES.md" "INTERFACES.md"

# Copy Rules
rules=("AGENTS.md" "CLAUDE.md" ".cursorrules" ".clinerules")
for r in "${rules[@]}"; do
    copy_template "$SCRIPT_DIR/$r" "$TARGET_PATH/$r" "$r"
done

echo -e "\n\033[36mAntariksh rules deployed. Memory folders initialized. Code safe.\033[0m"
