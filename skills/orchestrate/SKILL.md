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

1. **Success is verifiable.** You can state the check — a test, a rubric, a required output, a diff — that decides whether each unit succeeded. **If success cannot be verified, do not delegate it.** An unverifiable unit does not come back wrong; it comes back *confident*, and you have no way to tell the difference. Define the check first, or keep the work yourself.
2. The work splits into **3 or more independent units** (modules, hypotheses, or file groups with no shared write surface).
3. Units do not modify the same files or contracts concurrently (check `INTERFACES.md`).
4. The task exceeds what a single session can hold in context (large refactor, migration, multi-module audit, parallel hypothesis testing).

If not, stay solo — a fleet for a small task wastes money, not saves it.

> [!WARNING]
> **Splittable is not the same as should-be-split.** Some work needs one coherent context and degrades when cut into isolated units: architecture and interface design, tightly coupled refactors, anything where the units must agree on a judgement call rather than a contract, and narrative/documentation work with a single through-line. Each child sees only its brief, so cross-unit taste and consistency are exactly what a fleet cannot supply. When the hard part is *coherence* rather than *volume*, stay solo even if the file boundaries look clean.

## 1. PLAN
Run the `/ak-align` scoping gate on the whole task first: goal, success criteria, non-goals, plan. The fleet inherits this scope; children never re-negotiate it.

### Declare the Complexity Budget Before Spending It
Decide the limits now, while the numbers are still cheap to choose — a budget decided mid-run is decided under sunk-cost pressure. They are written down in the ledger's `Budget:` field when you create it in step 2.5:

- Maximum children spawned (total) and maximum running concurrently
- Maximum fix rounds per unit (default 5 — see step 5b)
- Wall-clock ceiling, and token or cost ceiling if the runner reports them
- Minimum evidence required before a unit counts as DONE

**When the budget is exhausted, stop and report honestly**: the best current artifact, which units completed, which are unresolved, and the reason for stopping. **Do not present partial work as if it were complete** — a fluent summary over a half-finished fleet is the most expensive failure mode here, because it costs the user their chance to intervene. Budget exhaustion is a legitimate outcome; disguising it is not (Philosophy X, `/ak-verify`).

## 2. DECOMPOSE
Partition into independent work units:
- **By module** for refactors/migrations — one directory or package per child.
- **By hypothesis** for debugging/analysis — one tack per child (Philosophy IV).
- Verify no two units touch the same file or `INTERFACES.md` contract. If units overlap, merge them into one unit or re-cut the boundary.

## 2.5 LEDGER — Write Progress to Disk Before Dispatching Anything
**Conversation memory does not survive compaction.** The most expensive orchestration failure is an orchestrator that loses its place after a compaction and re-dispatches work that was already finished — paying twice and sometimes producing conflicting duplicate changes.

Before the first dispatch, create a ledger at `memory/orchestrate/<task-slug>.md`:

```markdown
# Fleet ledger — task: <task-slug>
- Plan: [one-line goal, or link to the /ak-align scope]
- Budget: [max children / max concurrent / max fix rounds / wall-clock / cost — from step 1]
- Units: [list of unit names from step 2]

## Unit: <unit-name>
- Dispatched: [what the child was told to do]
- Rounds: [fix round entries, appended as they happen]
- Result: DONE <commit-sha> | BLOCKED <reason> | (absent = not finished)
```

Rules:
- Append after every dispatch, every fix round, and every accepted result. Never rewrite history in it.
- **On resume (including after compaction): read the ledger first.** A unit with a `Result: DONE` line is finished — do not re-dispatch it. A unit whose last entry is a fix round is mid-loop; resume at the next round.
- The ledger names commits. Those commits exist in Git even when your context no longer remembers creating them. **After a compaction, trust the ledger and `git log` over your own recollection.**
- The ledger is working state, not a deliverable; `/ak-compact` distils it into `memory/projects/<name>.md` at the end and the file can then be archived.

## 2.6 PRE-FLIGHT — Check the Baseline Before Fanning Out
Run the test suite, build, and lint **once, on the untouched tree**, before dispatching anyone. Record the result in the ledger.

- **Green** → any failure a child reports is theirs, and the evidence bar in their brief is meaningful.
- **Already red** → **stop and tell the user before spending a fleet.** Every child inherits the breakage, each one "fixes" a failure it did not cause, the fix loop burns its rounds on a phantom, and the reports come back contradictory. A fleet dispatched onto a red tree is the most expensive way to discover the tree was red.
- **Red but you proceed anyway** (user's call): record exactly which checks were already failing in the ledger *and* in every brief, so children can tell inherited breakage from their own.

One cheap serial run here saves N parallel children from chasing the same ghost.

## 3. BRIEF — One Per Child
Every child gets a self-contained brief. A child must be able to work from the brief alone, without this conversation.

> [!IMPORTANT]
> **Children inherit nothing.** A spawned subagent does not receive this conversation, your session context, or the parent's auto-memory — Claude Code explicitly does not load the main conversation's auto memory into subagents (a *fork* is the only exception). Anything the child needs must be **in the brief**. A constraint that lives only in `MEMORY.md`, in this conversation, or in your head will not reach it. When a child does the wrong thing, suspect the brief before blaming the child.

Format:

```markdown
## Child Brief: <unit-name>
- **Goal**: [one sentence]
- **Bounds**: [exact directories/files the child may modify — nothing else]
- **Context**: [relevant excerpts from memory/projects/<name>.md, INTERFACES.md contracts in scope]
- **Success criteria**: [verifiable checks — tests to pass, outputs to produce]
- **Known-failing at baseline**: [checks already red before this fleet started, from step 2.6 — "none" if the tree was green. A child must not spend rounds fixing these]
- **Report format**: [see step 5 — require it explicitly]
- **Forbidden**: [contracts not to change, files not to touch, no new dependencies without flagging]
```

## 4. DELEGATE — Down, Not Sideways
- **Isolation**: Each child runs in its own Git worktree (`/ak-worktree`) or directory boundary so children cannot collide.
- **The orchestrator never executes work units itself.** It answers child blockers, judges results, and re-cuts boundaries when a child reports overlap.
- **Depth**: Keep the fleet flat (orchestrator → children). Do not let children spawn grandchildren unless a unit itself decomposes into 3+ independent sub-units.

### Model Tiering — Two Traps
If the runner supports per-agent model selection, route mechanical work (renames, mechanical migrations, test running, lint fixing) to a **cheaper/faster tier** and keep the orchestrator on the stronger tier for judgement. Two things defeat this in practice:

1. **Always name the model explicitly on every dispatch.** An omitted model silently inherits the *orchestrator's* model — usually the most capable and most expensive one. A fleet dispatched without explicit models costs more than doing the work inline, while looking like it saved money.
2. **Turn count beats token price.** Wall-clock and context cost scale with how many turns a child takes, and the cheapest tiers routinely take 2-3× the turns on multi-step work — costing more overall. Use a mid-tier model as the *floor* for reviewers and for any child working from prose. Reserve the cheapest tier for transcription-shaped work: the brief already contains the exact code or the change is a single-file mechanical edit.

Scale review models to the diff, not to habit: a small mechanical diff does not need the top tier; a subtle concurrency or auth change does.

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

### 5a. Two-Stage Review — Spec, Then Quality
Review each returned unit in two separate passes. They catch different failures and one reviewer doing both conflates them:

1. **Spec compliance** — does it do what the brief said, all of it, and nothing outside `Bounds`? A beautifully written unit that solved the wrong problem fails here.
2. **Code quality** — run `/ak-review` (adversarial duel) on the unit diff. Correct-but-unsafe code fails here.

Stage 1 first: there is no point reviewing the quality of the wrong work. Verify against the child's *evidence*, not its summary — a child reporting "success" is a claim, and the VCS diff is the proof (Philosophy X).

**Reviewers must differ from each other and from the implementer.** Parallel workers on the same model with the same prompt produce *correlated* errors — they miss the same things for the same reasons. A second reviewer that shares the first one's prompt, evidence, and role adds cost and the illusion of confirmation, not coverage. Give each reviewer a distinct **prompt, evidence set, or role** (as `/ak-review` does with its Security / Edge Case / Performance / Architecture attackers). Agreement between two identical reviewers is one opinion counted twice.

### 5b. Fix Rounds — Escalate, Then Stop
When a unit fails review, do not simply re-dispatch the same brief at the same child indefinitely. Cap it at **5 rounds** and escalate:

| Round | Action |
|---|---|
| 1-3 | Resume the same child with the specific findings. Most failures resolve here. |
| 4-5 | Dispatch a **fresh** child on a model **at least one tier above** the one that got stuck — a stuck context usually stays stuck. |
| After 5 | Stop. Adjudicate each open finding: cosmetic ones get parked in the ledger with a ruling; if any finding is load-bearing, report **BLOCKED** to the user with the evidence. |

Record every round in the ledger. If a child's finding contradicts the brief itself, the brief is the thing to fix — bring it back to the orchestrator and re-cut, do not let the child improvise (Philosophy IX: re-plan on failure).

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

Keep the ledger (step 2.5) in this mode especially — a single long session is *more* exposed to compaction than a fleet, and the ledger is what lets you resume without redoing finished units.

> [!WARNING]
> **Cost discipline**: Track how many children you spawn and record each in the ledger. Never exceed the 5-round fix cap in step 5b — uncapped retry loops across a fleet are the fastest way to burn budget. If the same unit is still failing at round 5, the boundary or the brief is wrong, not the child: pull the unit back and re-plan (Philosophy IX).
