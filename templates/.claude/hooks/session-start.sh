#!/bin/bash
# session-start.sh -- Auto-loads the Second Brain into context on session start/resume,
# so the agent doesn't have to be told to read these files every time (RULESET.md
# section 4, Start-of-Session Loop steps 1-3).

cd "${CLAUDE_PROJECT_DIR:-.}" || exit 0

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

if [ -f "GLOSSARY.md" ]; then
    echo ""
    echo "### GLOSSARY.md"
    cat "GLOSSARY.md"
fi

exit 0
