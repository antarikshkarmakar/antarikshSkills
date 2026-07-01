---
name: ak-handoff
description: Agent Handoff — compile state for next session or next agent
trigger: /ak-handoff
---

# /ak-handoff — Agent Handoff & State Compilation

Run when ending turn or transferring to another agent/session.

## 1. Compile Handoff Note
List:
- **Accomplishments** — what was completed this session
- **Active/In-Progress files** — what's being worked on
- **Open questions/blockers** — what's unresolved
- **Next action** — the single next thing the next session must start with

## 2. Write Handoff

**If tools available** → Write to `memory/handoff.md`

**If toolless** → Print handoff notes inside markdown code block for user to copy.

## 3. Clear State
After writing handoff:
- Update today's daily log with session summary
- Mark any completed todos
- Leave inbox clean for next session
