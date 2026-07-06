---
name: ak-spec
description: Spec-Driven Development — specify, clarify, plan, dependency-ordered tasks, cross-artifact analysis, implement, converge (inspired by GitHub spec-kit)
trigger: /ak-spec
---

# /ak-spec — Spec-Driven Development Loop

End-to-end feature delivery where the specification drives the implementation, not the other way around. Composes existing skills for the phases the framework already covers and adds three phases it didn't: dependency-ordered tasks, cross-artifact analysis, and convergence. Inspired by [GitHub spec-kit](https://github.com/github/spec-kit), rebuilt as prompt-level instructions so it works on any LLM with zero binary dependencies.

## Context Prerequisite
**Context Validation**: Refer to RULESET.md for project context validation before executing.

## Constitution
This framework's constitution already exists: the philosophies in RULESET.md. Do NOT generate a separate constitution file — every phase below inherits Philosophy I (Ponytail), II (surgical changes), VIII (action gates), and X (evidence over claims) automatically. One source of truth.

## 0. Detect Native Tooling (Optional Delegation)
If the `specify` CLI is on PATH (`specify --version` / `Get-Command specify`), the user has GitHub spec-kit installed — offer to delegate to its native `/speckit.*` commands instead of this flow, and follow its artifacts if they choose it. If it is not installed, do NOT install it; run the prompt-level flow below. Missing-tool install hints live in `DEPENDENCIES.md` — never install software yourself (Philosophy VIII).

## 1. SPECIFY
Run `/ak-to-prd`: modules-touched quiz, then a PRD at `memory/prds/<feature-slug>.md` with problem statement, goals, non-goals, and **numbered acceptance criteria** (AC-1, AC-2, …). Numbered criteria are load-bearing — later phases map to them by ID.

## 2. CLARIFY
Run the `/ak-align` Socratic loop against the draft PRD. Every `[NEEDS CLARIFICATION]` or ambiguous requirement gets resolved with the user before planning. Do not carry open ambiguity into the plan.

## 3. PLAN
Run `/ak-align-docs` for the technical plan: architecture decisions land as ADRs in `memory/adr/`, new domain terms land in `GLOSSARY.md`, and contract changes are checked against `INTERFACES.md`. The plan must state which acceptance criteria each design decision serves.

## 4. TASKS — Dependency-Ordered Breakdown
Derive tasks from the PRD + plan and write `memory/prds/<feature-slug>-tasks.md`:

```markdown
# Tasks: <feature-slug>
- [ ] T1: [action] — covers: AC-1 — blocked-by: none — verify: [check command/observable outcome]
- [ ] T2: [action] — covers: AC-2, AC-3 — blocked-by: T1 — verify: [check]
```

Rules:
- Every task names the acceptance criteria it covers and its `blocked-by` dependencies.
- Every task has exactly one verifiable check (Philosophy X) — a task you cannot verify is not a task, it is a wish.
- Order tasks so nothing appears before its dependencies. Independent tasks are candidates for `/ak-orchestrate` fan-out.

## 5. ANALYZE — Cross-Artifact Consistency
Before any implementation, audit the three artifacts against each other and report:
1. **Coverage**: every acceptance criterion in the PRD maps to ≥1 task. List uncovered criteria.
2. **Traceability**: every task traces back to the plan and PRD. List orphan tasks (work nothing asked for — YAGNI, cut them).
3. **Contract safety**: tasks touching `INTERFACES.md` contracts are flagged for the Philosophy VIII gate.
4. **Dependency sanity**: no cycles in `blocked-by`; no task verifying something a later task builds.

Fix gaps in the artifacts, not in your head. Do not start implementing until this pass is clean.

## 6. IMPLEMENT
Work the task list in dependency order:
- Each task goes through `/ak-tdd` (test-first) or `/ak-code` (surgical) as appropriate.
- Mark a task `[x]` only with its verification evidence recorded next to it — output, not claims.
- New requirements discovered mid-flight are scope changes: classify per `/ak-align` Step 5 (expand / defer / hold), update the PRD and tasks file, re-run the ANALYZE pass if the task graph changed.

## 7. CONVERGE — Spec vs Reality
After the task list is done, assess the codebase against the PRD directly (not against the tasks — tasks can be complete while the spec is not):
1. Walk each acceptance criterion; verify it against the actual code/behavior with a concrete check.
2. Unmet or partially-met criteria → append to the PRD's Open Loops section and `MEMORY.md` open loops. Do not silently close them.
3. Anything built that the spec never asked for → flag for `/ak-review` (scope creep audit).
4. Close with `/ak-compact` so decisions, drift findings, and lessons land in memory.

## Toolless Fallback
No file tools? Print each artifact (PRD, tasks file, analysis report) in markdown blocks with exact target paths for the user to save, per the Cross-LLM Tool-Fallback Protocol.

> [!TIP]
> **Right-sizing**: This full loop is for features. A bug fix needs `/ak-diagnose`, a one-file change needs `/ak-code` with the lightweight plan gate. Running seven phases on a typo is how frameworks die (Philosophy I, rung 1).
