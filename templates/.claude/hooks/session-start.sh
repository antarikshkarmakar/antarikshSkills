#!/bin/bash
# session-start.sh -- Auto-loads the Second Brain into context on session start/resume,
# so the agent doesn't have to be told to read these files every time (RULESET.md
# section 4, Start-of-Session Loop steps 1-6).

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-${CODEX_PROJECT_DIR:-.}}"
cd "$PROJECT_DIR" || exit 0

echo "## Second Brain (auto-loaded by SessionStart hook)"

if [ -f "memory/handoff.md" ]; then
    echo ""
    echo "### memory/handoff.md (previous session's handoff -- read, then clear it once acted on)"
    cat "memory/handoff.md"
fi

if [ -f "MEMORY.md" ]; then
    echo ""
    echo "### MEMORY.md"
    cat "MEMORY.md"
fi

if [ -f "task.md" ]; then
    echo ""
    echo "### task.md (Active Checklist)"
    cat "task.md"
fi

if [ -f "memory/local_env.md" ]; then
    echo ""
    echo "### memory/local_env.md"
    cat "memory/local_env.md"
fi

if [ -f "AGENTS.md" ]; then
    echo ""
    echo "### AGENTS.md"
    cat "AGENTS.md"
fi

if [ -f "GLOSSARY.md" ]; then
    echo ""
    echo "### GLOSSARY.md"
    cat "GLOSSARY.md"
fi

# Project context validation check
PROJECT_NAME=$(basename "$PWD")
PROJECT_FILE="memory/projects/${PROJECT_NAME}.md"
if [ -f "$PROJECT_FILE" ]; then
    echo ""
    echo "### $PROJECT_FILE"
    cat "$PROJECT_FILE"
else
    # Fallback to any project file that exists under memory/projects/
    ANY_PROJECT=$(find memory/projects -maxdepth 1 -name "*.md" ! -name "template.md" 2>/dev/null | head -n 1)
    if [ -n "$ANY_PROJECT" ]; then
        echo ""
        echo "### $ANY_PROJECT"
        cat "$ANY_PROJECT"
    else
        echo ""
        echo "### Context Validation Warning"
        echo "WARNING: memory/projects/ context file not found! You must alert the user and run /ak-grok to build the repository context before coding."
    fi
fi

# Load last 5 daily logs (sorted, last 5)
if [ -d "memory/daily" ]; then
    LOGS=$(find memory/daily -maxdepth 1 -name "*.md" ! -name "template.md" 2>/dev/null | sort | tail -n 5)
    if [ -n "$LOGS" ]; then
        echo ""
        echo "### Recent Daily Logs (last 5 entries)"
        for log in $LOGS; do
            echo ""
            echo "#### $log"
            cat "$log"
        done
    fi
fi

exit 0
