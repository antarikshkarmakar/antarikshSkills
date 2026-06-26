Parallel Agents
8 coding agents. One repo. Zero conflicts.
Claude Code + git worktrees + Daytona + Hatchet


Two script corrections. (1) 'A twenty year old Git feature': git worktree was added in Git 2.5, released July 2015 -- 11 years old, not 20. Git itself is 20 years old. (2) Claude Code stars: 115K confirmed April 16 2026 (Augment Code). Script says 131K -- plausible by June given its growth from 81.6K in March to 115K in April. (3) Daytona's sub-90ms is warm start from a pre-warmed pool, not cold start. Cold starts when the image is not cached can take longer.




The Four Tools

Tool
Package
Stars
Role in the swarm
Claude Code
claude CLI
115K+ (Apr 26)
Supervisor + 8 coding subagents
git worktree
built into git
git 2.5+
Isolates each agent to its own branch+folder
Daytona
@daytona/sdk
72K+ (May 26)
Boots a sandbox per worktree in sub-90ms
Hatchet
@hatchet-dev/typescript-sdk
~7K
Dispatches jobs, tracks status, retries failures




Why Agents Collide Without This
Eight agents writing to the same working directory overwrite each other. Agent 3 reads a file that Agent 7 is mid-edit. Merging becomes impossible. The fix has nothing to do with the AI -- it is file system isolation.

git worktree: one shared repo, multiple checked-out branches in different directories simultaneously. Each agent gets its own folder and its own branch. They never touch each other's files.
Daytona sandbox: each worktree runs inside its own isolated container. Agents cannot interfere at the process or filesystem level either.




The Architecture
repo/
  main/                    # your main branch
  .git/                    # shared git objects
  worktrees/
    agent-1/               # branch: agent/task-auth-module
    agent-2/               # branch: agent/task-db-layer
    agent-3/               # branch: agent/task-api-routes
    agent-4/               # branch: agent/task-tests
    agent-5/               # branch: agent/task-cache
    agent-6/               # branch: agent/task-logging
    agent-7/               # branch: agent/task-migrations
    agent-8/               # branch: agent/task-docs
 
Each worktree is a separate directory, separate branch,
inside the same .git -- so push/PR/merge all work normally.




Step 1 -- git worktrees
git worktree lets you check out multiple branches simultaneously in different directories from the same repo. No cloning. One .git, many working trees.

# Create a worktree for each task
git worktree add worktrees/agent-1 -b agent/task-auth-module
git worktree add worktrees/agent-2 -b agent/task-db-layer
git worktree add worktrees/agent-3 -b agent/task-api-routes
# ...repeat for each task
 
# Each worktree has its own working directory
ls worktrees/agent-1/  # full codebase, on branch agent/task-auth-module
ls worktrees/agent-2/  # full codebase, on branch agent/task-db-layer
 
# After agents finish, clean up worktrees
git worktree remove worktrees/agent-1
git git worktree prune  # remove stale worktree metadata




Step 2 -- Daytona Sandbox Per Worktree
Each worktree gets its own Daytona sandbox. The sandbox boots sub-90ms from a warm pool. The agent runs inside it -- isolated at the container level.

Daytona uses Docker containers, not full VMs. Containers share the host kernel. This is sufficient for most agent workloads, but if your agents run untrusted external code, consider E2B (Firecracker microVM isolation) instead.


import { Daytona } from '@daytona/sdk';
 
const daytona = new Daytona();
 
async function spawnAgentSandbox(worktreePath: string, branch: string) {
  const sandbox = await daytona.create({
    language: 'typescript',
    envVars: { WORKTREE: worktreePath, BRANCH: branch },
  });
 
  // Mount the worktree into the sandbox
  await sandbox.fs.uploadFolder(worktreePath, '/workspace');
 
  return sandbox;
}
 
// Spawn 8 sandboxes in parallel -- one per worktree
const sandboxes = await Promise.all(
  tasks.map((task, i) =>
    spawnAgentSandbox(`worktrees/agent-${i+1}`, task.branch)
  )
);
// All 8 boot in ~1 second total (sub-90ms each from warm pool)




Step 3 -- Hatchet Dispatches the Jobs
Hatchet is the job queue and supervisor. It dispatches a Claude Code task per agent, retries failures, and exposes a dashboard to watch the swarm in real time.

import Hatchet from '@hatchet-dev/typescript-sdk';
 
const hatchet = await Hatchet.init();
 
// Define the agent worker
const agentWorker = hatchet.worker('coding-agent');
 
agentWorker.on('run-agent', async (ctx) => {
  const { task, worktreePath, branch } = ctx.workflowInput();
 
  // Claude Code runs inside the Daytona sandbox on this worktree
  const result = await runClaudeInWorktree(worktreePath, task);
 
  if (result.testsPass) {
    await gitPushAndOpenPR(branch, task);
    return { status: 'green', pr: result.prUrl };
  } else {
    return { status: 'red', errors: result.testOutput };
  }
});
 
// Dispatch all 8 jobs at once
const jobs = await Promise.all(tasks.map(task =>
  hatchet.admin.runWorkflow('run-agent', {
    task: task.description,
    worktreePath: task.worktreePath,
    branch: task.branch,
  })
));




Step 4 -- Tests as the Judge
The supervisor runs your test suite against each worktree. Only branches that pass get merged. The rest get logged and queued for a second pass.

async function runClaudeInWorktree(worktreePath: string, task: string) {
  // Claude Code runs the task in the worktree directory
  const claude = spawn('claude', [
    '--bare',                    // no interactive prompts
    '--max-turns', '20',
    '--allowedTools', 'Read,Write,Bash',
    '-p', task,
  ], { cwd: worktreePath });
 
  await waitForExit(claude);
 
  // Run tests inside the worktree -- tests are the judge
  const testResult = await runCommand('npm test', { cwd: worktreePath });
  return {
    testsPass: testResult.exitCode === 0,
    testOutput: testResult.stdout,
  };
}




The Gotcha -- Logic Conflicts
Worktrees stop FILE conflicts. They do not stop logic conflicts.
Two agents can change the same function's behavior in incompatible ways. Agent 1 changes how auth tokens are validated. Agent 3 changes an API route that calls that auth function. Both pass their own tests. When merged, they break.


Two solutions:

Scope each task to a different module. Agent 1 owns auth/. Agent 2 owns db/. Agent 3 owns api/. No agent touches another's module.
Shared interface file: create an INTERFACES.md at the root that defines the contract between modules. Each agent reads it first. Changes to the interface require human sign-off before any agent proceeds.

# INTERFACES.md -- agents read this before starting
## Auth module contract
verifyToken(token: string): Promise<{userId: string} | null>
-- Returns null on invalid token, never throws
 
## DB layer contract
getUser(userId: string): Promise<User | null>
-- userId is always a UUID string
 
## Rule: if your task requires changing an interface above,
## stop and flag for human review before proceeding.




TUI Setup -- Single Paste
Paste this into Claude Code to scaffold the full parallel agent system.

Build my parallel coding agent swarm. Ask me for the task list first.
 
Step 1 -- Ask me for:
  - My task list (each task scoped to a different module)
  - DAYTONA_API_KEY (from app.daytona.io)
  - HATCHET_CLIENT_TOKEN (from app.hatchet.run)
  - ANTHROPIC_API_KEY
 
Step 2 -- Create worktrees:
  For each task, run:
    git worktree add worktrees/agent-N -b agent/task-[name]
  Confirm all worktrees with: git worktree list
 
Step 3 -- Create INTERFACES.md:
  Ask me to describe the module boundaries.
  Write the interface contracts for each module.
  Add the rule: flag before changing any interface.
 
Step 4 -- Create swarm.ts with:
  - spawnAgentSandbox() using @daytona/sdk
  - Hatchet worker using @hatchet-dev/typescript-sdk
  - runClaudeInWorktree() using claude --bare --max-turns 20
  - Tests as judge: only push PR if npm test passes
  - Promise.all() to run all agents simultaneously
 
Step 5 -- Install dependencies:
  npm install @daytona/sdk @hatchet-dev/typescript-sdk
 
Step 6 -- Smoke test on 2 tasks first:
  Run swarm.ts with just 2 tasks before all 8.
  Confirm both worktrees get their own sandbox.
  Confirm results reported back to Hatchet dashboard.
  Ask me: 'Ready to run all 8?'




One worktree and one sandbox per agent. Tests as the judge. Merge the winners. Eight agents on the same repo, zero file conflicts -- and the gotcha is logic conflicts, not file conflicts. Scope by module. Define the interfaces first.
