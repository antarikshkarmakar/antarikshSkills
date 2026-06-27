#!/bin/bash
# stop-check.sh -- Blocks ending the turn if source files were edited but the
# Second Brain (today's daily log) wasn't updated to match (RULESET.md
# End-of-Session Loop). Never blocks read-only/Q&A sessions with no real edits,
# and never blocks outside a git repo (no reliable way to detect edits there).

cd "${CLAUDE_PROJECT_DIR:-.}" || exit 0

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0

TODAY=$(date +%Y-%m-%d)
DAILY_LOG="memory/daily/$TODAY.md"

# Real-work changes = anything uncommitted outside the Second Brain's own files.
CHANGED=$(git status --porcelain 2>/dev/null | awk '{print $2}' | grep -vE '^(memory/|MEMORY\.md$|GLOSSARY\.md$|inbox\.md$)')

if [ -z "$CHANGED" ]; then
    exit 0
fi

if [ ! -f "$DAILY_LOG" ]; then
    REASON="Source files changed this session but memory/daily/$TODAY.md doesn't exist yet. Per the End-of-Session Loop, create it and summarize what got done before stopping."
    echo "{\"decision\":\"block\",\"reason\":\"$REASON\",\"hookSpecificOutput\":{\"hookEventName\":\"Stop\",\"additionalContext\":\"$REASON\"}}"
    exit 2
fi

# Block if any changed file is newer than the daily log -- i.e. code was
# touched more recently than the memory of it.
STALE=false
while IFS= read -r f; do
    if [ -n "$f" ] && [ -f "$f" ] && [ "$f" -nt "$DAILY_LOG" ]; then
        STALE=true
    fi
done <<< "$CHANGED"

if [ "$STALE" = true ]; then
    REASON="Source files were edited more recently than memory/daily/$TODAY.md. Per the End-of-Session Loop, update the daily log (and MEMORY.md if relevant) before stopping."
    echo "{\"decision\":\"block\",\"reason\":\"$REASON\",\"hookSpecificOutput\":{\"hookEventName\":\"Stop\",\"additionalContext\":\"$REASON\"}}"
    exit 2
fi

exit 0
