# Antariksh Unified Agent Skills Framework

A universal master agent instructions, ruleset, and memory scaffolding framework designed to run seamlessly on **any LLM** (Gemini, OpenAI, Ollama, DeepSeek, Minimax, Claude) and **any assistant interface** (Claude Code, Antigravity CLI, Codex, OpenCode, VS Code Cursor/Cline, or standard Web UIs).

It integrates the best paradigms in agentic development:
- 🌲 **The Ponytail Lazy Developer Ladder**: Native platform features, standard library first, minimal viable code, and YAGNI.
- ⚡ **Karpathy Simplicity & Surgical Changes**: Touch only what is requested, clean up your own orphans, and avoid overengineering.
- 🪨 **Caveman Communication**: Terse, direct, pleasantry-free responses that cut token consumption by 65%+.
- 🧠 **4-File Second Brain (Claude-mem)**: Continuous context, index routing, and logs across session boundaries (`memory/`).
- 🔬 **Matt Pocock TDD & Debug Loops**: Strict Red-Green-Refactor and Reproduce-Minimize-Hypothesize-Fix protocols.
- ⚔️ **Adversarial Duel & Critic Pattern**: Self-criticism proposer-attacker loops and post-execution checks.
- 🛡️ **Interface Contracts**: Boundary validation mapping via `INTERFACES.md` to prevent multi-agent logical collisions.
- 📉 **Jcode Cache Optimization**: Lean rulesets and batched reads to prevent expensive cold-cache misses.
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
  - `MEMORY.md`: Root-level Second Brain index of status, projects, focus, and open loops.
  - `inbox.md`: Staging note inbox.
  - `memory/daily/template.md`: Daily append-only logs.
  - `memory/projects/template.md`: Project-specific facts and context cards.
  - `INTERFACES.md`: Shared contracts.

---

## How to Install in a Project

Running the installer creates the `memory/` structure, scaffolds Second Brain templates, creates today's daily log (`memory/daily/YYYY-MM-DD.md`), and copies rulesets to the root of the target directory.

### On Windows (PowerShell)
```powershell
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

### `/grill` — Brutally Honest Mentor Interrogation
The agent acts as a strict evaluator with 20+ years of experience. It interrogates your task scope, constraints, and traps in blocks before coding, and outputs a blunt, structured assessment and a 30-60-90 day action plan.

### `/tdd` — Test-Driven Development Loop (Matt Pocock TDD)
Pivots to TDD mode:
1. **RED**: Write a failing test for the requested feature. Run the test and verify it fails.
2. **GREEN**: Write the minimal code required to pass the test.
3. **REFACTOR**: Clean and optimize implementation without breaking tests.

### `/diagnose` — Structured Debugging (Matt Pocock Diagnose)
Follows a rigorous debugging sequence:
1. **REPRODUCE**: Write a minimal script/test reproducing the bug.
2. **MINIMIZE**: Isolate the exact file and lines responsible.
3. **HYPOTHESIZE**: List 1-2 probable causes.
4. **FIX**: Apply a surgical fix and remove the reproduction script.

### `/code` — Surgical Implementation
Instructs the agent to evaluate the task using the Ponytail ladder (Native first, standard library, YAGNI), inspect contract boundaries in `INTERFACES.md`, and write minimal, clean changes.

### `/review` — Adversarial Duel Review & Critic Widget
Runs a proposer-attacker duel. The Attacker personality tests the code against edge cases, race conditions, silent failures, assumption violations, security boundaries, and off-by-ones, outputting a clear critic verdict (`PASS/FAIL` and reason).

### `/doc` — Direct Documentation
Generates clear, direct documentation using markdown, tables, alert blocks, and mermaid diagrams with zero filler or redundant introductions.

### `/grok` — Repository Comprehension
Inspects the local Second Brain and code structure, outputting a concise map of directory contents and logic boundaries.

### `/scratch` — Scaffold New Project
Initializes a repository from zero, creating standard files, the Second Brain system (`MEMORY.md`, `inbox.md`, `memory/`), and the module boundary tracker (`INTERFACES.md`).

### `/compact` — Memory Consolidation (Second Brain Sync)
Consolidates current session learnings. It writes a daily log summary, updates project cards in `memory/projects/`, refines `MEMORY.md` open loops, and clears `inbox.md`. If toolless, it outputs updated files in markdown blocks for you to paste.

---

## Portability: Cross-LLM Fallback Protocol
If you are running the agent in a web browser interface (e.g., Gemini, ChatGPT, DeepSeek, or Minimax Web UI) or toolless API:
1. **Interactive Commands**: The model will parse typed slash commands in your messages (e.g. `/grill`) and run the corresponding behaviors.
2. **Dialogue Fallback**: The model will ask you to paste directory structures or file contents, output code updates with exact target file paths, and output full memory updates for you to manually paste into `MEMORY.md` and `memory/daily/` logs.
