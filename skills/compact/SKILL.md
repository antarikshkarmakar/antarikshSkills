---
name: ak-compact
description: "Memory Consolidation -- end-of-session: logs, project files, MEMORY.md, inbox, and skill observations"
trigger: /ak-compact
---

# /ak-compact -- Memory Consolidation

## 1. Consolidate Logs
Append to today's daily log (`memory/daily/YYYY-MM-DD.md`):
- What got done
- Decisions made
- Open loops
- Tomorrow's first task

## 2. Update Project Files
If new decisions or facts were verified, update `memory/projects/<name>.md`. Note reversals; do not delete old decisions.

## 3. Refine Index
Update `MEMORY.md`:
- Current status
- Client touching points
- New open loops

## 4. Learn from Corrections
If user corrected you during session, add correction as new rule in **Learned** section of `AGENTS.md`.

## 5. Skill Evolution Check
At end of session, decide whether anything reusable should improve the framework skills. Append to `memory/skill-observations.md` only when one of these happened:
- A skill rule was missed, ambiguous, too heavy, or too weak.
- The user corrected the process in a way that applies beyond this repository.
- A repeated workflow could become a new skill or a small improvement to an existing skill.
- A public/internal boundary, dependency, portability issue, or edge case surfaced.

Use the file's `Issue`, `Suggested improvement`, and `Principle` fields. Mark `Type: public-safe` only after removing client names, project names, proprietary URLs, internal terms, credentials, personal data, and traceable examples. If uncertain, mark `Type: internal`. Do not interrupt active work for this; capture it during `/ak-compact`.

## 6. Clear Inbox
Route notes from `inbox.md` to daily/projects files. Reset `inbox.md` to blank.

## 7. Concurrency & Conflict Protection
Before overwriting or updating `MEMORY.md` or other memory files, check for unstaged local edits (via `git status memory/`). If unstaged changes from concurrent sessions exist, merge or stash them before updating to prevent state loss.

## 8. Memory Archiving & Size Audits
*   If `AGENTS.md` or `MEMORY.md` exceeds 300 lines, alert the user to compress or archive.
*   **Log Archiving**: If the aggregate size of files in `memory/` exceeds 100KB or 10,000 lines, recommend moving daily log files older than 14 days to `memory/daily/archive/` to conserve prompt tokens.
*   **Skill Observation Archiving**: If `memory/skill-observations.md` exceeds 150 lines or contains more than 20 `ACTIONED`/`DECLINED` entries, move `ACTIONED`/`DECLINED` entries older than 30 days to `memory/skill-observations.archive.md`. Keep all `OPEN` observations in the active file.
*   **Memory Consolidation & Tiering (Awesome-Agent-Memory Inspiration)**: Ensure Semantic Memory files (`MEMORY.md`, `GLOSSARY.md`, `INTERFACES.md`, `memory/projects/*.md`) remain active in the workspace context. Compact and archive Episodic Memory (move logs older than 14 days, summarize ADRs/PRDs into high-level features maps) to maintain cache limits.

## 9. Caveman Plugin (if installed)
If `caveman` plugin is installed (check `MEMORY.md` under "Context Agent Needs"), run `/caveman-compress` on updated memory files as the final step.
