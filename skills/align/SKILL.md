---
name: ak-align
description: Pre-Coding Scope Alignment (Socratic Refinement) — close requirements gaps before writing anything
trigger: /ak-align
---

# /ak-align — Pre-Coding Scope Alignment

Use before starting any non-trivial change, code or non-code. Closes the requirements gap before anything is written.

## Context Prerequisite
Before executing `/ak-align`, verify that `memory/projects/<name>.md` exists (the repository context file). If it does not exist, alert the user and advise running `/ak-grok` first to build the codebase context.

## Step 1 — Interrogate
Ask targeted questions about:
- The goal — what are we actually building?
- Constraints — what's fixed, what can't change?
- What "done" looks like — how do we verify success?
- Edge cases already considered
- What's explicitly out of scope

## Step 2 — Socratic Refinement
Challenge the design. Ask:
- Why not standard library?
- Why a new dependency?
- Why a db schema change instead of simple state?
- Propose complexity reductions before settling

## Step 3 — Present Interpretations
If the request is ambiguous, list the plausible interpretations and ask which one is right. Do NOT silently pick.

## Step 4 — Confirm Scope & Plan Gate
- **Confirm Scope**: Summarize the agreed scope in 1-2 sentences. Get explicit confirmation before starting.
- **Strict Plan Gate**: Define and confirm a step-by-step implementation plan (even if brief) before execution begins. Banish the "too simple to need a design" bypass: every change requires a structured roadmap.

## Step 5 — Mid-Task Scope Changes
If new requirements surface after work started, classify before continuing:
- **Expansion** — genuinely new, separate need → new `/ak-align` pass
- **Selective Expansion** — small, directly related → confirm explicitly, then continue
- **Hold Scope** — defer it as open loop, finish agreed scope first
- **Reduction** — scope was too large → confirm smaller scope explicitly
