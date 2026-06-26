OpenHands 1.7 vs Claude Code
4 features audited. 3 already existed. 1 worth copying.
OpenHands v1.7.0 -- May 1, 2026


The script calls OpenHands 'the free version of Claude Code.' More precisely: OpenHands is the leading open-source coding agent -- it predates Claude Code and runs any model. It is not a fork of Claude Code. Also: the script calls Feature 3 'Tavily MCP proxy.' Tavily is a search tool -- the actual feature is enterprise MCP proxy routing through the app server. Corrected throughout.




What OpenHands Is
Open-source autonomous coding agent. Formerly OpenDevin. Built by All-Hands-AI. Runs any model -- Claude, GPT, Gemini, DeepSeek, local models via Ollama. Sandboxed Docker runtime. Free to self-host. 40,000+ GitHub stars.

# Install (Docker)
docker pull docker.all-hands.dev/all-hands-ai/runtime:0.43-nikolaos
docker run -it --rm --pull=always -e SANDBOX_RUNTIME_CONTAINER_IMAGE=... \
  -e LOG_ALL_EVENTS=true -v /var/run/docker.sock:/var/run/docker.sock \
  -p 3000:3000 --add-host host.docker.internal:host-gateway \
  ghcr.io/all-hands-ai/openhands:0.43
 
# Or via pip (SDK)
pip install openhands




The 4-Feature Audit

Feature
OpenHands 1.7
Claude Code
Verdict
LLM profile management
Shipped May 2026
Available since launch
Catch-up
Sub-agent delegation
Shipped May 2026
Available since launch
Catch-up
Enterprise MCP proxy
Shipped May 2026
Covered by hooks
Catch-up
Critic result display
Shipped May 2026
Not yet
New. Copy this.




1.  LLM Profile Management + /model  [Catch-up]
Save multiple model configurations as named profiles. Switch between them with /model in chat without leaving the interface. Tests confirmed against Claude Sonnet, GPT-5.5, DeepSeek V4 Pro, and local Ollama models.

Saved LLM Profiles: store model ID, API key reference, temperature, context settings as a reusable profile
/model slash command: list all saved profiles, select one, continue the conversation with that model active
Claude Code has had model switching via settings since launch. OpenHands now has the same feature in the chat UI.

If you are already on Claude Code, nothing changes. If you build on OpenHands and need to route different tasks to different models mid-session, this is the feature that makes it possible without restarting.


2.  Sub-Agent Delegation via Task Tool  [Catch-up]
Spawn specialized agents for sub-tasks within a larger workflow. The orchestrator breaks a task down, delegates steps to sub-agents, and reassembles the output. OpenHands calls this micro-agents with task decomposition.

Claude Code has had subagents via the /agents menu and worktree isolation since launch
OpenHands' implementation is now formally shipped as a first-class feature with dependency graph support
The open-source version of the pattern. Functionally equivalent to what Claude Code does with --worktree and parallel agents.

3.  Enterprise MCP Proxy Routing  [Catch-up]
Route MCP server calls through the OpenHands app server for centralized monitoring, secrets management, and audit logging. Shipped in 1.7 with secrets support for MCP config variable expansion.

Secrets support for MCP config variable expansion (confirmed from SDK release notes: feat: Add secrets support for MCP config variable expansion)
Claude Code covers the equivalent through hooks -- PostToolUse hooks can log every MCP call, PreToolUse hooks can block or audit them
The difference: OpenHands routes at the proxy layer. Claude Code routes at the hook layer. Same audit outcome, different implementation.

4.  Critic Result Display  [New -- Copy This.]
Every time the agent completes a step, an inline critic widget renders the validation result right inside the chat. Pass or fail. Why. What to fix. The second judgment loop built into the interface.

This is the one Claude Code does not have yet.
Right now Claude tells you what it did. The critic tells you whether what it did is good -- inline, automatically, without you having to ask. That second judgment loop is the difference between an agent that ships code and an agent that ships shippable code.


Backed by a published rubric paper: 'A Rubric-Supervised Critic from Sparse Real-World Outcomes' -- the OpenHands org has a dedicated critic-rubrics repo
UI component: renders pass/fail plus explanation directly in the conversation stream after each agent step
Model-agnostic: the critic runs as a separate LLM call with a structured rubric, then the result is displayed inline
Claude Code does not have this. You can build it manually this quarter. See the implementation pattern below.



The Critic Pattern -- Build It in Claude Code Today
You do not need to wait for Anthropic to ship this. The critic pattern is a PostToolUse hook plus a structured review prompt. Here is the pattern:

# Step 1: Add a PostToolUse hook that triggers after Edit or Write
# In ~/.claude/settings.json:
{ "hooks": { "PostToolUse": [{ "matcher": "Edit|Write",
    "hooks": [{"type": "command",
      "command": "bash ~/.claude/scripts/critic.sh"}]
}}
 
# Step 2: critic.sh reads the file and runs a structured review
#!/bin/bash
mkdir -p ~/.claude   # ensure log directory exists
FILE=$(cat /dev/stdin | python3 -c "import sys,json; print(json.load(sys.stdin).get('tool_input',{}).get('file_path',''))" 2>/dev/null)
[ -z "$FILE" ] && exit 0
claude --bare -p "Review $FILE against these criteria:
  1. Does it match the stated task?
  2. Are there any obvious bugs or edge cases missed?
  3. Pass or fail, and why in one sentence.
Output: PASS or FAIL, then one sentence reason." \
  --allowedTools Read --max-turns 3 >> ~/.claude/critic-log.md


This is the manual version. It runs after every file edit, logs the critic result to critic-log.md, and you can review it after the session. The full inline display (like OpenHands) requires UI work -- but the judgment loop is the valuable part, not the display.




Three Takeaways

1.  The open-source race is closing on table stakes
Profile management. Sub-agents. Enterprise plumbing. These used to be moats. They are commodities now. Pick your tool based on the next moat, not the last one.

2.  Inline critic widgets are the next interface upgrade
The agency that ships the critic pattern manually wins the next six months. Build it in Claude Code now. OpenHands will ship the polished version. You want to have already been running it in production.

3.  The harness is the part OpenHands cannot copy by shipping a release
Skills. Hooks. CLAUDE.md layers. The install layer you built on top of your tool. OpenHands can ship /model. It cannot ship your six months of AGENTS.md tuning, your eight hooks, and your four custom skills built for a specific client stack.

The answer is still Claude Code for client installs. But ship the critic pattern manually this quarter. That gap closes in three months.


