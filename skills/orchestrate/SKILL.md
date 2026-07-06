---
name: ak-orchestrate
description: Fleet Orchestration — plan, decompose, brief, delegate down, synthesize up; the orchestrator keeps context for judgement while children execute
trigger: /ak-orchestrate
---

# /ak-orchestrate — Fleet Orchestration

Coordinate a fleet of subagents for work that is too large or too parallel for one context window. The orchestrator plans, briefs, judges, and synthesizes — it does not execute. The higher your tier, the more you delegate: push execution down, keep context for judgement.

## Context Prerequisite
**Context Validation**: Refer to RULESET.md for project context validation before executing.

## 0. Gate — Is a Fleet Warranted? (Ponytail Rung 1)
Spawning agents costs tokens and coordination overhead. Only orchestrate when ALL are true:
- The work splits into **3 or more independent units** (modules, hypotheses, or file groups with no shared write surface).
- Units do not modify the same files or contracts concurrently (check `INTERFACES.md`).
- The task exceeds what a single session can hold in context (large refactor, migration, multi-module audit, parallel hypothesis testing).

If not, stay solo — a fleet for a small task wastes money, not saves it.

## 1. PLAN
Run the `/ak-align` scoping gate on the whole task first: goal, success criteria, non-goals, plan. The fleet inherits this scope; children never re-negotiate it.

## 2. DECOMPOSE
Partition into independent work units:
- **By module** for refactors/migrations — one directory or package per child.
- **By hypothesis** for debugging/analysis — one tack per child (Philosophy IV).
- Verify no two units touch the same file or `INTERFACES.md` contract. If units overlap, merge them into one unit or re-cut the boundary.

## 3. BRIEF — One Per Child
Every child gets a self-contained brief. A child must be able to work from the brief alone, without this conversation. Format:

```markdown
## Child Brief: <unit-name>
- **Goal**: [one sentence]
- **Bounds**: [exact directories/files the child may modify — nothing else]
- **Context**: [relevant excerpts from memory/projects/<name>.md, INTERFACES.md contracts in scope]
- **Success criteria**: [verifiable checks — tests to pass, outputs to produce]
- **Report format**: [see step 5 — require it explicitly]
- **Forbidden**: [contracts not to change, files not to touch, no new dependencies without flagging]
```

## 4. DELEGATE — Down, Not Sideways
- **Isolation**: Each child runs in its own Git worktree (`/ak-worktree`) or directory boundary so children cannot collide.
- **Model tiering**: If the runner supports per-agent model selection, route mechanical work (renames, mechanical migrations, test running, lint fixing) to a **cheaper/faster model tier**, and keep the orchestrator on the stronger tier for judgement. This is where the cost saving lives.
- **The orchestrator never executes work units itself.** It answers child blockers, judges results, and re-cuts boundaries when a child reports overlap.
- **Depth**: Keep the fleet flat (orchestrator → children). Do not let children spawn grandchildren unless a unit itself decomposes into 3+ independent sub-units.

## 5. COLLECT — Child Reports Become Memory
Require every child to return a structured report (this is the parent→child analog of `/ak-handoff`):

```markdown
## Child Report: <unit-name>
- **Status**: DONE | BLOCKED | PARTIAL
- **Evidence**: [test output, diff stats, verification proof — Philosophy X, claims without proof are rejected]
- **Changes**: [branch name, files touched]
- **Open issues**: [anything discovered outside bounds — flagged, not fixed]
- **Contract flags**: [any INTERFACES.md concern — stops the merge until human review]
```

The orchestrator distills accepted reports into `memory/projects/<name>.md` and today's daily log so fleet results survive the session. A child report that lacks evidence is sent back, not merged.

## 6. SYNTHESIZE
Children verify parts; only the orchestrator can verify the whole:
1. Merge child branches one at a time into an integration branch.
2. Run the full test suite and `/ak-ci-check` on the **combined** result after each merge.
3. Run `/ak-review` (adversarial duel) on the integrated diff — child-level review does not substitute for whole-system review.
4. Any `Contract flags` from step 5 → stop, human review before merge (Philosophy III/VIII).
5. Produce one unified PR.

## 7. WALKTHROUGH
Close with an evidence-backed summary to the user: what each child did, proof it works (test output, not claims), open issues queue, and cost note (units delegated vs. done inline). Then run `/ak-compact` so the fleet's learnings land in memory and `memory/skill-observations.md`.

## Toolless / Single-Agent Fallback
No subagent support in the runner? Execute the same briefs **sequentially** in one session: write all briefs first, work through them one at a time, write each child report before starting the next, then synthesize. The structure survives even when the parallelism doesn't.

> [!WARNING]
> **Cost discipline**: Track how many children you spawn. If a child fails twice on the same unit, do not re-spawn a third time — pull the unit back to the orchestrator, re-plan (Philosophy IX), and re-cut the boundary. Retry loops across a fleet are the fastest way to burn budget.
