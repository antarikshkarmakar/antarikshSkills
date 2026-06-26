# Antariksh Unified Agent Skills Framework

A universal master agent instructions, ruleset, and memory scaffolding framework designed to run seamlessly on **any LLM** (Gemini, OpenAI, Ollama, DeepSeek, Minimax, Claude) and **any assistant interface** (Claude Code, Antigravity CLI, Codex, OpenCode, VS Code Cursor/Cline, or standard Web UIs).

It combines the best paradigms in agentic development:
- 🌲 **The Ponytail Lazy Developer Ladder**: Native platform features, stdlib first, minimal viable code, and YAGNI.
- ⚡ **Karpathy Simplicity & Surgical Changes**: Touch only what is requested, clean up your own orphans, no overengineering.
- 🪨 **Caveman Communication**: Terse, direct, pleasantry-free responses that cut token consumption by 65%+.
- 🧠 **4-Layer Memory system (Claude-mem)**: Persistent context across session boundaries (`memory/`).
- ⚔️ **Adversarial Duel Reviews**: Self-criticism through proposer-attacker verification loops.
- 🛡️ **Interface Contracts**: Boundary validation mapping via `INTERFACES.md` to prevent multi-agent logical collisions.
- 🌐 **Cross-LLM Portability**: Dialogue-driven fallbacks for toolless environments (Web UIs/API).

---

## Repository Structure

- `SKILL.md`: Master skill configuration file (used by Antigravity, OpenClaw, Codex, etc.).
- `AGENTS.md`: Universal rules file (used by Codex, OpenCode, CLI assistants).
- `CLAUDE.md`: Claude Code guidelines.
- `.cursorrules`: VS Code Cursor system rules.
- `.clinerules`: VS Code Cline/Roo-Code system rules.
- `install.ps1`: Windows PowerShell deployer script.
- `install.sh`: macOS/Linux/WSL Bash deployer script.
- `templates/`: Base structures for initialization:
  - `memory/IDENTITY.md`: Who the agent is and non-negotiables.
  - `memory/SEMANTIC.md`: Durable project facts, tech stack, and constraints.
  - `memory/EPISODIC.md`: Append-only session event timeline.
  - `memory/WORKING.md`: Current session task scratchpad.
  - `INTERFACES.md`: Shared contracts.

---

## How to Install in a Project

Running the installer creates the `memory/` structure, scaffolds templates, and copies rulesets to the root of the target directory.

### On Windows (PowerShell)
```powershell
# Open PowerShell and run:
cd c:\GitHub\antarikshSkills
.\install.ps1 -TargetDir C:\path\to\your\project
```
*Add `-Force` to overwrite existing configuration files.*

### On macOS / Linux / WSL (Bash)
```bash
cd /path/to/antarikshSkills
./install.sh /path/to/your/project
```
*Add `--force` or `-f` to overwrite.*

---

## How to Use the Unified Agent

Once the rules are installed in your workspace root, any agent reading them will respond to the following slash subcommands:

### `/grill` — The Brutally Honest Mentor Interrogation
Act as a brutally honest evaluator with 20+ years of experience. The agent will interrogate your task scope, timeline, consistency, and assumptions in blocks before writing code, and output a strict, no-fluff assessment and a 30-60-90 day action plan.

### `/code` — Surgical Implementation
Instructs the agent to evaluate the task using the Ponytail ladder (Native first, standard library, YAGNI) and write minimal, clean, surgical changes.

### `/review` — Adversarial Duel Review
The agent will perform a code review by acting as a Proposer (validating correctness) and then switching context to an Attacker (ruthlessly targeting edge cases, concurrency/race conditions, silent failures, security boundaries, and off-by-ones) to verify if the changes survive.

### `/doc` — Direct Documentation
Generates clear, direct documentation using markdown, tables, alert blocks, and mermaid diagrams with zero filler or redundant introductions.

### `/grok` — Repository Comprehension
Inspects the local memory files and code structure, outputting a concise map of directory contents and logic boundaries.

### `/scratch` — Scaffold New Project
Initializes a repository from zero, creating standard files, the 4-layer memory system (`memory/`), and the module boundary tracker (`INTERFACES.md`).

### `/compact` — Memory Consolidation
Consolidates current session learnings. If the assistant has workspace file tools, it updates the files directly. If running toolless (e.g., standard Web UIs), it prints copy-pasteable blocks of the updated memory files for you to save.

---

## Portability: Cross-LLM Fallback Protocol
If you are running the agent in a web browser interface (e.g., Gemini, ChatGPT, DeepSeek, or Minimax Web UI) or toolless API:
1. **Interactive Commands**: The model will parse typed slash commands in your messages (e.g. `/grill`) and run the corresponding behaviors.
2. **Dialogue Fallback**: The model will ask you to paste directory structures or file contents, output code updates with exact target file paths, and output full memory updates for you to manually paste into `memory/SEMANTIC.md` and `memory/EPISODIC.md` at session end.
