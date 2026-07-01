---
name: ak-compact
description: Memory Consolidation — end-of-session: logs, project files, MEMORY.md, inbox
trigger: /ak-compact
---

# /ak-compact — Memory Consolidation

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

## 6. Concurrency & Conflict Protection
Before overwriting or updating `MEMORY.md` or other memory files, check for unstaged local edits (via `git status memory/`). If unstaged changes from concurrent sessions exist, merge or stash them before updating to prevent state loss.

## 7. Memory Archiving & Size Audits
*   If `AGENTS.md` or `MEMORY.md` exceeds 300 lines → alert the user to compress or archive.
*   **Log Archiving**: If the aggregate size of files in `memory/` exceeds 100KB or 10,000 lines, recommend moving daily log files older than 14 days to `memory/daily/archive/` to conserve prompt tokens.
*   **Memory Consolidation & Tiering (Awesome-Agent-Memory Inspiration)**: Ensure Semantic Memory files (`MEMORY.md`, `GLOSSARY.md`, `INTERFACES.md`, `memory/projects/*.md`) remain active in the workspace context. Compact and archive Episodic Memory (move logs older than 14 days, summarize ADRs/PRDs into high-level features maps) to maintain cache limits.

## 8. Caveman Plugin (if installed)
If `caveman` plugin is installed (check `MEMORY.md` under "Context Agent Needs"), run `/caveman-compress` on updated memory files as the final step.
