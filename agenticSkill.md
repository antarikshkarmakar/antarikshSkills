agentic-stack
One brain. Every coding agent. Nothing resets.
 github.com/codejunkie99/agentic-stack

What It Is
A portable .agent/ folder -- memory, skills, and protocols -- that drops into any project and plugs into any coding
agent you use. Switch from Claude Code to Cursor to Codex and nothing resets. The same brain carries forward.

No subscription. No cloud. No telemetry. Local only. MIT license. Created by @AV1DLIVE.

Install
Mac / Linux -- Homebrew (recommended):
# One-time setup -- both lines required
brew tap codejunkie99/agentic-stack https://github.com/codejunkie99/agentic-stack
brew install agentic-stack

Mac / Linux -- no Homebrew:
git clone https://github.com/codejunkie99/agentic-stack.git
cd agentic-stack &amp;&amp; ./install.sh claude-code
# replace claude-code with your harness

Windows -- PowerShell (native installer):
git clone https://github.com/codejunkie99/agentic-stack.git
cd agentic-stack
.\install.ps1 claude-code C:\path\to\your-project
# replace claude-code with your harness and path with your project path

install.ps1 runs natively in PowerShell. install.sh works under Git Bash or WSL.

Drop It Into a Project
cd into any project directory, then run agentic-stack with your harness name. The onboarding wizard runs
automatically.

cd your-project
agentic-stack claude-code
# Onboarding wizard runs automatically.
# It scaffolds .agent/ and configures the adapter for your tool.

All supported harness names as of the latest release -- check the README for additions:
Adapter name Tool
claude-code Claude Code (Anthropic)
cursor Cursor
windsurf Windsurf
opencode OpenCode
openclaw OpenClaw
hermes Hermes
codex OpenAI Codex CLI
pi Pi Coding Agent
antigravity Antigravity
standalone-python DIY Python agent loop

This repo ships frequently. New adapters are added in minor releases. Always check the current README at
github.com/codejunkie99/agentic-stack for the full up-to-date list before deploying.

What Is Inside .agent/
One folder that every adapter reads. Switch the tool, the folder stays.

.agent/
AGENTS.md # the map -- every adapter reads this first
memory/ # working, episodic, semantic, personal layers
skills/ # reusable task definitions (_index.md + SKILL.md files)
protocols/ # permissions, tool schemas, delegation rules
tools/ # host-agent CLI (graduate.py, reject.py, reopen.py)
harness/ # conductor + hooks for standalone path
adapters/ # one small shim per harness, outside .agent/
claude-code/ # CLAUDE.md + settings.json hooks
cursor/ # .cursor/rules/*.mdc
windsurf/ # .windsurfrules
opencode/ # AGENTS.md + opencode.json

• Memory has four layers: working/, episodic/, semantic/, personal/ -- each with its own retention policy

• Nightly staging cycle: auto_dream.py stages candidate lessons. You review them with list_candidates.py,
graduate.py, reject.py, and reopen.py
• Search falls back to ripgrep if installed, then grep -- restricted to .md and .jsonl so source files are never
polluted

Switch Tools Without Losing Anything
Same .agent/ folder. Different adapter. Everything carries forward.

agentic-stack cursor # switch to Cursor
agentic-stack hermes # switch to Hermes
agentic-stack codex # switch to Codex
agentic-stack openclaw # switch to OpenClaw

The .agent/ folder is tool-agnostic. The adapter is just a shim that bridges it to the harness&#39;s config format.
Switching harnesses never touches your memory, skills, or protocols.

Data Layer -- Local Dashboard
Run this to get a unified dashboard across all your harnesses:

agentic-stack data-layer

• Harness activity and cron timelines
• Token and cost estimates
• KPI summaries
• Screenshot-ready daily reports
All local. No telemetry. No external API calls. Nothing leaves your machine.

Data Flywheel -- Training-Ready Exports
Turn approved, redacted agent runs into local artifacts for eval and fine-tuning:
• Trace records
• Context cards
• Eval cases
• Training-ready JSONL
Model-agnostic. Does not call external APIs. Does not train a model. Produces local files you control.

Update
brew update &amp;&amp; brew upgrade agentic-stack

Repo and release notes: github.com/codejunkie99/agentic-stack