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
- 🚦 **Visible & Hard-to-Reverse Action Gate**: Explicit yes/no approval before posting PR reviews, pushing, force-ops, or any other action that's visible to others or hard to undo.

---

## Repository Structure

- `templates/RULESET.md`: **The single canonical source** for the shared rules body (philosophies, command protocol, Second Brain protocol). Edit this file, not the 4 generated rule files below — they drift out of sync if hand-edited directly.
- `AGENTS.md`, `CLAUDE.md`, `.cursorrules`, `.clinerules`: **Generated** from `templates/RULESET.md` plus a small tool-specific header, at install time. Used by Codex/OpenCode/CLI assistants, Claude Code, Cursor, and Cline/Roo-Code respectively.
- `SKILL.md`: Hand-maintained master skill definition for this framework itself (used by Claude Code's Skill system, Antigravity, OpenClaw, etc.). Richer/more detailed than the 4 generated files and **not** regenerated from `RULESET.md` — only its `/grok` section and Second Brain references are kept in sync by hand.
- `install.ps1`: Windows PowerShell deployer script.
- `install.sh`: macOS/Linux/WSL Bash deployer script.
- `templates/`: Base structures for initialization:
  - `MEMORY.md`: Root-level Second Brain index of status, projects, focus, open loops, and detected agent skills.
  - `inbox.md`: Staging note inbox.
  - `memory/daily/template.md`: Daily append-only logs.
  - `memory/projects/template.md`: Project-specific facts and context cards.
  - `INTERFACES.md`: Shared contracts.
  - `.gitignore`: Baseline secrets/junk rules (`.env`, keys, `node_modules/`, etc.), enforcing Philosophy VI.

---

## How to Install in a Project

Running the installer detects locally installed agent skills (see below), generates the 4 rule files from `templates/RULESET.md`, creates the `memory/` structure, scaffolds Second Brain templates, creates today's daily log (`memory/daily/YYYY-MM-DD.md`), ensures a `.gitignore` covers secrets/junk (creating one if missing, or appending only the missing baseline entries if one already exists — never overwrites your own rules), and writes everything to the root of the target directory.

### On Windows (PowerShell)
```powershell
cd c:\GitHub\antarikshSkills
.\install.ps1 -TargetDir C:\path\to\your\project
```
*Add `-Force` to overwrite existing configuration files. Add `-RulesOnly` to only (re)generate the 4 rule files, skipping memory scaffolding — use this to refresh an existing project's rules after `templates/RULESET.md` changes, or to regenerate this repo's own root rule files after editing the template.*

### On macOS / Linux / WSL (Bash)
```bash
cd /path/to/antarikshSkills
./install.sh /path/to/your/project
```
*Add `--force` or `-f` to overwrite. Add `--rules-only` or `-r` for the rules-only refresh described above.*

---

## Agent Skill Detection (Read-Only)

The installer never installs or copies skills into your project — it only checks whether they're already available on the machine and records what it found in `MEMORY.md` under **Context Agent Needs**, so every agent reading the project's rules knows what's usable without re-probing the filesystem each session.

Specifically, it checks `~/.claude/skills/` (`%USERPROFILE%\.claude\skills\` on Windows) for:
- **graphify**: if found, `/grok` uses it to build a real knowledge graph of the repo (`graphify-out/`). If not found, `/grok` falls back to a manual directory/stack scan.
- Any other skill folders present, listed for visibility (e.g. `deep-research`, `claude-mem`, etc.).

This makes graphify-backed repo comprehension work the same way in Claude Code, Cursor, Codex CLI, or Ollama CLI — any tool with terminal/file access can read graphify's `SKILL.md` directly from the detected path and follow its instructions; no Claude-specific "Skill tool" is required.

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

### `/prreview` — Gated GitHub PR Review (Draft → Approve → Post)
Checks whether `gh` is authenticated; if not, falls back to plain `git diff`/`git log` and a manually-pasted draft. Drafts inline PR comments (with `​```suggestion​` blocks where a fix applies) and an overall verdict, shows the *exact* comments and event type (`APPROVE`/`REQUEST_CHANGES`/`COMMENT`) for explicit yes/no approval, then posts via a batched `gh api` pending review. Never posts without approval — see Philosophy VIII (Visible & Hard-to-Reverse Action Gate).

### `/doc` — Direct Documentation
Generates clear, direct documentation using markdown, tables, alert blocks, and mermaid diagrams with zero filler or redundant introductions.

### `/grok` — Repository Comprehension (Context Graph)
Checks `memory/projects/<name>.md` first, then checks whether graphify is available (see Agent Skill Detection above). If graphify is available, builds/updates a real knowledge graph of the repo and summarizes it as the map. If not, falls back to a manual scan of manifest files, test framework, and entry points. Either way, persists the findings to `memory/projects/<name>.md` so it isn't rediscovered every session.

### `/scratch` — Scaffold New Project
Initializes a repository from zero, creating standard files, the Second Brain system (`MEMORY.md`, `inbox.md`, `memory/`), and the module boundary tracker (`INTERFACES.md`). Per Philosophy VI, also ensures a `.gitignore` covers secrets and common build/dependency junk — created fresh if missing, or merged in if one exists without those entries.

### `/compact` — Memory Consolidation (Second Brain Sync)
Consolidates current session learnings. It writes a daily log summary, updates project cards in `memory/projects/`, refines `MEMORY.md` open loops, and clears `inbox.md`. If toolless, it outputs updated files in markdown blocks for you to paste.

### `/handoff` — Agent Handoff & State Compilation
Compiles a transition note summarizing accomplishments, active/in-progress files, open loops, blockers, and the next action for the incoming agent. It writes this to `memory/handoff.md` (or prints a markdown block for manual copy-pasting if toolless).

---

## Portability: Cross-LLM Fallback Protocol
If you are running the agent in a web browser interface (e.g., Gemini, ChatGPT, DeepSeek, or Minimax Web UI) or toolless API:
1. **Interactive Commands**: The model will parse typed slash commands in your messages (e.g. `/grill`) and run the corresponding behaviors.
2. **Dialogue Fallback**: The model will ask you to paste directory structures or file contents, output code updates with exact target file paths, and output full memory updates for you to manually paste into `MEMORY.md` and `memory/daily/` logs.
