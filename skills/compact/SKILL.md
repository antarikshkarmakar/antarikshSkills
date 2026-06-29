---
name: compact
description: Memory Consolidation — end-of-session: logs, project files, MEMORY.md, inbox
trigger: /compact
---

# /compact — Memory Consolidation

## 1. Consolidate Logs
Append to today's daily log (`memory/daily/YYYY-MM-DD.md`):
- What got done
- Decisions made
- Open loops
- Tomorrow's first task

## 2. Update Project Files
If new decisions or facts were verified, update `memory/projects/<name>.md`. Note reversals — do not delete old decisions.

## 3. Refine Index
Update `MEMORY.md`:
- Current status
- Client touching points
- New open loops

## 4. Learn from Corrections
If user corrected you during session, add correction as new rule in **Learned** section of `AGENTS.md`.

## 5. Clear Inbox
Route notes from `inbox.md` to daily/projects files. Reset `inbox.md` to blank.

## 6. Check Size
If `AGENTS.md` or `MEMORY.md` exceeds 300 lines → alert user to compress or archive.

## 7. Caveman Plugin (if installed)
If `caveman` plugin is installed (check `MEMORY.md` under "Context Agent Needs"), run `/caveman-compress` on updated memory files as the final step.
