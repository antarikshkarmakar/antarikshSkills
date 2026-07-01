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

## 3. Execute Work & Test
Perform the task entirely in the worktree directory:
*   Make surgical code edits.
*   Run tests and verify.
*   Commit modifications locally in the worktree branch.

## 4. Clean Up and Remove
Once the branch is pushed or merged:
1. Return to your main repository directory.
2. Remove the worktree folder and its Git metadata:
   ```bash
   git worktree remove ../<repo-slug>-<branch-name>
   ```
3. Run pruning if any stale references remain:
   ```bash
   git worktree prune
   ```
