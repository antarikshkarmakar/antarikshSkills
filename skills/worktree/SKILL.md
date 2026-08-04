---
name: ak-worktree
description: Git Worktrees — manage parallel tasks in isolated workspaces without branch-switching collisions
trigger: /ak-worktree
---

# /ak-worktree — Git Worktrees

Use Git worktrees to check out and work on independent branches in separate sibling directories, allowing concurrent task execution and testing without disrupting files in the main workspace.

## 1. Create a Worktree
To start work on an independent branch in a parallel folder, run:
```bash
git worktree add ../<repo-slug>-<branch-name> -b <branch-name>
```
*Note: Paths are usually created as sibling folders to the repository root.*

## 2. Initialize the Worktree Environment
Navigate to the new directory (`../<repo-slug>-<branch-name>`) and prepare the environment:
1. Copy target `memory/local_env.md` if necessary to skip re-probing tools.
2. Bootstrap dependencies if needed (e.g. `npm install` or setup venv).
3. **Establish a clean test baseline before writing any code.** Run the test suite now and record the result.
   - Green baseline → any failure you see later is yours.
   - Already-red baseline → **write down exactly which tests were already failing.** Without this you cannot distinguish your breakage from pre-existing breakage, and you will either chase someone else's bug or ship yours believing it was already there.
   - Do not start work on a red baseline without telling the user which tests were red.

## 3. Execute Work & Test
Perform the task entirely in the worktree directory:
*   Make surgical code edits.
*   Run tests and verify.
*   Commit modifications locally in the worktree branch.
*   **Swarm Isolation & Parallel Reviews (Ruflo Inspiration)**: If performing a large-scale refactor or multi-agent migration, partition modules and assign them to separate subagents. Instruct each subagent to spin up its own isolated Git worktree, execute its task concurrently, and push the branch for validation. Combine branches back into the main line via git merges/rebases once reviews are green.

## 4. Finish the Branch — Decide Before Cleaning Up
Work is done when tests are green, not when the code is written. Before removing anything:

1. **Verify**: run the full suite and compare against the step 2 baseline. Any test red that was green at baseline is yours to fix. Apply `/ak-verify` — no "done" without fresh output.
2. **Present the options and let the user choose.** Do not pick for them; merging and discarding are both hard to reverse (Philosophy VIII):
   - **Merge** into the parent branch
   - **Open a PR** — use `/ak-prreview` for the gated review flow
   - **Keep** the worktree and branch as-is for later
   - **Discard** the branch and its work
3. Only after an explicit choice, proceed to cleanup.

> [!WARNING]
> **Discard is destructive.** Deleting a worktree with uncommitted changes, or deleting an unmerged branch, loses work permanently. Before discarding: run `git status` in the worktree to show what would be lost, confirm the branch is merged (`git branch --merged`) or that the user explicitly accepts losing it, and quote what is being deleted back to them. Never infer discard from silence or from "clean this up".

## 5. Clean Up and Remove
Once the branch is pushed, merged, or the user has explicitly chosen to discard it:
1. Return to your main repository directory.
2. Remove the worktree folder and its Git metadata:
   ```bash
   git worktree remove ../<repo-slug>-<branch-name>
   ```
   If Git refuses because the worktree is dirty, that refusal is a safety feature — surface it to the user rather than reaching for `--force`.
3. Run pruning if any stale references remain:
   ```bash
   git worktree prune
   ```
