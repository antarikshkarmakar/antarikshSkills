# Antariksh Unified Agent Skills Framework

A universal master agent instructions, ruleset, and memory scaffolding framework designed to run seamlessly on **any LLM** (Gemini, OpenAI, Ollama, DeepSeek, Minimax, Claude) and **any assistant interface** (Claude Code, Codex, Cursor, VS Code + Copilot, Antigravity, Cline/Roo-Code, OpenCode, or standard Web UIs).

## Why This Exists

Most agent setups force a choice between two failure modes: a pile of slash commands you have to remember to reach for, or a single LLM/IDE pairing that loses all context the moment you switch tools. This framework is a single canonical ruleset (`templates/RULESET.md`) that compiles into whatever file each tool actually reads — `CLAUDE.md`, `AGENTS.md`, `.cursorrules`, `.clinerules`, `GEMINI.md`, `.github/copilot-instructions.md` — so the same philosophy, memory, and command set follow you across tools and sessions instead of resetting every time you switch one.

It integrates the best paradigms in agentic development, grouped by what problem each one solves:

**Code Quality & Process**
- 🌲 **The Ponytail Lazy Developer Ladder**: Native platform features, standard library first, minimal viable code, and YAGNI.
- ⚡ **Karpathy Simplicity & Surgical Changes**: Touch only what is requested, clean up your own orphans, and avoid overengineering.
- 🔬 **Matt Pocock TDD & Debug Loops**: Strict Red-Green-Refactor and Reproduce-Minimize-Hypothesize-Fix protocols.
- ⚔️ **Adversarial Duel & Critic Pattern**: Self-criticism proposer-attacker loops and post-execution checks.
- 🏗️ **Continuous Architecture Care**: Deep modules, simple interfaces, flagged (not silently fixed) ball-of-mud smells — `/audit-arch` is its periodic, deliberate form.
- 🧩 **Think Before Coding**: State assumptions, surface tradeoffs, push back when a simpler approach exists, and stop to ask when genuinely confused — only when ambiguity would change the outcome.
- 🎯 **Goal-Driven Execution**: Turn imperative asks into verifiable success criteria and loop until they're actually checked, not just plausible — the default behind `/tdd` and `/diagnose`, applied everywhere.

**Memory & Continuity**
- 🧠 **Second Brain (Claude-mem)**: Continuous context, index routing, and logs across session boundaries (`memory/`, `GLOSSARY.md`, `memory/adr/`, `memory/prds/`).
- 📖 **Shared Language (Ubiquitous Language)**: A `GLOSSARY.md` of domain terms, built by `/align-docs`, used consistently in naming and communication to cut vocabulary-gap verbosity.
- 🛡️ **Interface Contracts**: Boundary validation mapping via `INTERFACES.md` to prevent multi-agent logical collisions.

**Safety**
- 🚦 **Visible & Hard-to-Reverse Action Gate**: Explicit yes/no approval before posting PR reviews, pushing, force-ops, or any other action that's visible to others or hard to undo. Production-sensitive work additionally gets an explicit edit-scope freeze — stated in-bounds files only, anything outside needs its own approval.

**Efficiency & Portability**
- 🪨 **Caveman Communication**: Terse, direct, pleasantry-free responses that cut token consumption by 65%+. Delegates to the [caveman](https://github.com/JuliusBrussee/caveman) plugin's real multi-level compression (`/caveman`, `/caveman-compress`) when it's installed.
- 📉 **Jcode Cache Optimization**: Lean rulesets and batched reads to prevent expensive cold-cache misses. Compress before content enters context, not just what leaves it — read excerpts/summaries instead of pasting raw tool output/logs (the lightweight, no-infra version of what [Headroom](https://github.com/headroomlabs-ai/headroom) does as a proxy).
- 🌐 **Cross-LLM Portability**: Dialogue-driven fallbacks for toolless environments (Web UIs/API).

---

## Repository Structure

- `templates/RULESET.md`: **The single canonical source** for the shared rules body (philosophies, command protocol, Second Brain protocol). Slash commands are a lean lookup table pointing to `.agents/skills/` — detailed instructions live in modular skill files, not in RULESET.md itself. Edit this file, not the 6 generated rule files below — they drift out of sync if hand-edited directly.
- `templates/.agents/skills/`: **Modular on-demand skill files.** Each slash command is a thin pointer in RULESET.md; the full workflow lives in its own `.agents/skills/<name>/SKILL.md`. This keeps RULESET.md lean (~150 lines) and context-cache-friendly. Currently includes: `align/`, `tdd/`, `diagnose/`, `review/`, `prreview/`, `grok/`, `audit-arch/`, `compact/`, `handoff/`.
- `AGENTS.md`, `CLAUDE.md`, `.cursorrules`, `.clinerules`, `GEMINI.md`, `.github/copilot-instructions.md`: **Generated** from `templates/RULESET.md` plus a tool-specific header, at install time. Also copies `.agents/skills/` recursively to the target directory. Used by Codex/OpenCode/CLI assistants, Claude Code, Cursor, Cline/Roo-Code, Gemini CLI, and GitHub Copilot Chat respectively. (`.cursorrules` is Cursor's legacy format — still read, but Cursor's current standard is `.cursor/rules/*.mdc`; Cursor users are covered either way since Cursor also reads `AGENTS.md` natively. Copilot's autonomous coding agent already reads `AGENTS.md`/`CLAUDE.md`/`GEMINI.md` directly — `.github/copilot-instructions.md` is what closes the gap for everyday Copilot Chat.)
- `SKILL.md`: Hand-maintained master skill definition for this framework itself (used by Claude Code's Skill system, Antigravity, OpenClaw, etc.). Richer/more detailed than the 6 generated files and **not** regenerated from `RULESET.md` — only its `/grok` section and Second Brain references are kept in sync by hand.
- `install.ps1`: Windows PowerShell deployer script.
- `install.sh`: macOS/Linux/WSL Bash deployer script.
- `templates/`: Base structures for initialization:
  - `MEMORY.md`: Root-level Second Brain index of status, projects, focus, open loops, and detected agent skills.
  - `GLOSSARY.md`: Domain term/definition table — built by `/align-docs` (Philosophy XI).
  - `inbox.md`: Staging note inbox.
  - `memory/daily/template.md`: Daily append-only logs.
  - `memory/projects/template.md`: Project-specific facts and context cards.
  - `memory/adr/template.md`: Architecture Decision Record format (Context/Decision/Consequences) — written by `/align-docs`.
  - `memory/prds/template.md`: Product Requirements Doc format — written by `/to-prd`.
  - `INTERFACES.md`: Shared contracts.
  - `.gitignore`: Baseline secrets/junk rules (`.env`, keys, `node_modules/`, etc.), enforcing Philosophy VI.
  - `.claude/settings.json`, `.claude/hooks/*.sh`: **Opt-in** (`-Hooks`/`--hooks`) Claude Code hooks that mechanically enforce the Second Brain loop — see [Optional: Claude Code Hooks](#optional-claude-code-hooks) below.

---

## How to Install in a Project

Running the installer detects locally installed agent skills (see below), generates the 6 rule files from `templates/RULESET.md`, copies `.agents/skills/` recursively to the target directory (so slash commands have their full workflow files), creates the `memory/` structure (including `adr/` and `prds/`), scaffolds Second Brain templates (including `GLOSSARY.md`), creates today's daily log (`memory/daily/YYYY-MM-DD.md`), ensures a `.gitignore` covers secrets/junk (creating one if missing, or appending only the missing baseline entries if one already exists — never overwrites your own rules), and writes everything to the root of the target directory.

### On Windows (PowerShell)
```powershell
cd c:\GitHub\antarikshSkills
.\install.ps1 -TargetDir C:\path\to\your\project
```
*Add `-Force` to overwrite existing configuration files. Add `-RulesOnly` to only (re)generate the 6 rule files, skipping memory scaffolding — use this to refresh an existing project's rules after `templates/RULESET.md` changes, or to regenerate this repo's own root rule files after editing the template. Add `-Hooks` to also install the opt-in Claude Code hooks (see below).*

### On macOS / Linux / WSL (Bash)
```bash
cd /path/to/antarikshSkills
./install.sh /path/to/your/project
```
*Add `--force` or `-f` to overwrite. Add `--rules-only` or `-r` for the rules-only refresh described above. Add `--hooks` or `-k` for the opt-in Claude Code hooks (see below).*

---

## Setup Per Tool

The installer drops the right file for every tool in one pass (see Repository Structure above) — there's no separate per-tool configuration step. Open the installed project in whichever of these you use; each one picks its rules up automatically:

### Claude Code (CLI)
Reads `CLAUDE.md` from the project root automatically. Run `claude` from inside the installed project directory. Add `-Hooks`/`--hooks` at install time for mechanical Second Brain enforcement (see [Optional: Claude Code Hooks](#optional-claude-code-hooks)).

#### Publishing & Installing as a Global Plugin
This repository is pre-configured as a **Claude Code Plugin Marketplace**. You can register and install it globally so that the modular slash commands are always available on your system, even outside initialized target projects:

1. **Add the Marketplace**: Tap this repository to register it in your local Claude Code configuration:
   ```bash
   /plugin marketplace add <github-username>/antarikshSkills
   ```
   *(For local testing, run `/plugin marketplace add /path/to/local/antarikshSkills`)*
2. **Install the Plugin**:
   ```bash
   /plugin install antariksh-skills
   ```
   This registers the master `antariksh-unified-skill` and the 9 modular command skills globally inside your Claude Code binary.

### Codex (CLI)
OpenAI's Codex CLI reads `AGENTS.md` as its primary instruction file. Run `codex` from inside the installed project directory — zero extra configuration.

### Cursor
Reads `AGENTS.md` natively (Cursor's current standard) and also honors the legacy `.cursorrules` if present for older setups. Just open the installed project folder in Cursor.

### VS Code (GitHub Copilot)
Copilot Chat/agent mode in VS Code auto-detects `.github/copilot-instructions.md` and applies it to all chat requests in the workspace; Copilot's autonomous coding agent additionally reads `AGENTS.md`/`CLAUDE.md`/`GEMINI.md` directly. Open the installed project folder — both are already in place.

### Antigravity
Google's agentic IDE reads both `AGENTS.md` and `GEMINI.md` natively (requires Antigravity v1.20.3+; per its own rule hierarchy, `GEMINI.md` takes precedence over `AGENTS.md` when both exist — that's fine, they're generated from the same `RULESET.md` body so there's nothing to conflict on in practice). Open the installed project folder.

### Hermes Agent
*   **Global Identity**: Append the Core Philosophies of `templates/RULESET.md` directly to your global identity file at `~/.hermes/SOUL.md`.
*   **Modular Skills**: Copy the templates' modular skills into Hermes' custom skills folder:
    ```bash
    cp -r skills/* ~/.hermes/skills/
    ```

### OpenClaw
*   **Identity & Guidelines**: Append the philosophies to your agent's workspace configuration manual (`AGENT.md` or `SOUL.md` in `~/.openclaw/agents/<name>/`).
*   **On-Demand Skills**: Projects created with our installer already have `.agents/skills/` copied recursively; OpenClaw will automatically discover and parse these skills on workspace load.

### Everything else (also covered, not asked for above but worth knowing)
- **Cline / Roo-Code**: reads `.clinerules`.
- **Gemini CLI**: reads `GEMINI.md` as its own native convention.
- **No fixed convention** (raw Ollama, DeepSeek, Minimax, or a plain web-UI chat): falls back to the Cross-LLM Tool-Fallback Protocol below — paste file contents in, the agent works from what's pasted.

---

## Agent Skill Detection (Read-Only)

The installer never installs or copies skills into your project — it only checks whether they're already available on the machine and records what it found in `MEMORY.md` under **Context Agent Needs**, so every agent reading the project's rules knows what's usable without re-probing the filesystem each session.

Specifically, it checks `~/.claude/skills/` (`%USERPROFILE%\.claude\skills\` on Windows) for:
- **graphify**: if found, `/grok` uses it to build a real knowledge graph of the repo (`graphify-out/`). If not found, `/grok` checks for Understand-Anything next, then falls back to a manual directory/stack scan. This makes graphify-backed repo comprehension work the same way in Claude Code, Cursor, Codex CLI, or Ollama CLI — any tool with terminal/file access can read graphify's `SKILL.md` directly from the detected path and follow its instructions; no Claude-specific "Skill tool" is required.
- Any other skill folders present, listed for visibility (e.g. `deep-research`, `claude-mem`, etc.).

It also checks `~/.claude/plugins/installed_plugins.json` (a different mechanism — [caveman](https://github.com/JuliusBrussee/caveman) is a Claude Code *plugin*, not a skills-folder entry) for:
- **caveman**: if installed, Philosophy V and `/compact` delegate to its `/caveman` (output compression) and `/caveman-compress` (memory-file compression) commands. If not installed, the installer prints the one-line install command for the user to run themselves — **it never executes a third-party installer automatically**, consistent with Philosophy VIII.

And it checks for the [CodeGraph](https://github.com/colbymchenry/codegraph) CLI on PATH (a third option for `/grok`'s knowledge-graph step, alongside graphify and Understand-Anything):
- **CodeGraph**: if found, `/grok` and `/audit-arch` can delegate to it — beyond a structural map, it exposes real call-graph and blast-radius queries (`codegraph_explore`, `codegraph_impact`, `codegraph_callers`), useful for "what calls this" / "what breaks if I change this." If not found, both fall back the same way they already did (Understand-Anything → manual scan for `/grok`; pathfinder → manual smell-scan for `/audit-arch`).

---

## Optional: Claude Code Hooks

Everything above is pure prompt text — it works, but it relies on the agent remembering to follow the Start-of-Session/End-of-Session Loop every time. `-Hooks`/`--hooks` adds actual mechanical enforcement, **opt-in only** since it's Claude-Code-specific (no equivalent standard across Cursor/Cline/Codex) and touches `.claude/settings.json` rather than just dropping a template:

- **`SessionStart`** (`.claude/hooks/session-start.sh`): automatically loads `memory/handoff.md`, `MEMORY.md`, and `GLOSSARY.md` into context — the agent doesn't have to be told to read them.
- **`Stop`** (`.claude/hooks/stop-check.sh`): **blocks** ending the turn if source files were edited more recently than today's daily log (`memory/daily/YYYY-MM-DD.md`) — but only when real edits happened outside `memory/` itself, so read-only/Q&A sessions are never nagged. Requires a git repo to detect edits; no-ops otherwise.

If `.claude/settings.json` doesn't exist yet, it's created from scratch. If it already exists, the installer merges the two hooks in without touching any of your existing hooks or settings (PowerShell does this natively via JSON parsing; the bash installer uses `jq` if available, or prints the snippet to add by hand if not — it will never attempt a risky text-based merge). Re-running is idempotent — it won't duplicate the hook entries.

Requires Claude Code to run with a bash-capable shell to execute the hook scripts (Git Bash or WSL on Windows — consistent with everything else in this repo).

---

## How to Use the Unified Agent

Once the rules are installed in your workspace root, any agent reading them will respond to the following slash subcommands:

### `/grill` — Brutally Honest Mentor Interrogation
The agent acts as a strict evaluator with 20+ years of experience. It interrogates your task scope, constraints, and traps in blocks before coding, and outputs a blunt, structured assessment and a 30-60-90 day action plan.

### `/align` — Pre-Coding Scope Alignment
Use before starting any non-trivial change. Interrogates the goal, constraints, "done" criteria, and explicit non-goals; if the request is ambiguous, lists the plausible interpretations instead of silently picking one; confirms scope back before any code is written. The deliberate, structured form of Philosophy IX (Think Before Coding). If scope changes mid-task, classifies it first — **Expansion** (new `/align` pass), **Selective Expansion** (confirm and continue), **Hold Scope** (defer as an open loop), or **Reduction** (confirm the smaller scope) — instead of silently absorbing it. Full workflow in `.agents/skills/align/SKILL.md`.

### `/align-docs` — Scope Alignment + Shared Language
Everything `/align` does, plus building the project's shared language: adds undefined domain terms surfaced during the interrogation to `GLOSSARY.md`, and writes an ADR (`memory/adr/<NNN>-<slug>.md`) for any hard-to-explain decision (tradeoff, rejected alternative, constraint).

### `/to-prd` — Product Requirements Doc with Module Quiz
Asks which modules/files a change will touch and why before drafting, then writes the PRD to `memory/prds/<feature-slug>.md` (problem statement, goals, non-goals, modules touched, acceptance criteria).

### `/tdd` — Test-Driven Development Loop (Matt Pocock TDD)
Pivots to TDD mode. If no test framework exists yet, bootstraps the minimal one for the stack first — never skips RED-GREEN-REFACTOR just because nothing was there to begin with:
1. **RED**: Write a failing test for the requested feature. Run the test and verify it fails.
2. **GREEN**: Write the minimal code required to pass the test.
3. **REFACTOR**: Clean and optimize implementation without breaking tests.
Full workflow in `.agents/skills/tdd/SKILL.md`.

### `/diagnose` — Structured Debugging (Matt Pocock Diagnose)
Follows a rigorous debugging sequence:
1. **REPRODUCE**: Smallest, simplest repro that fails consistently — or **log and trace** (verbose output/breakpoints) when a deterministic repro isn't feasible.
2. **MINIMIZE**: **Divide and conquer** — bisect the system to isolate the exact file and lines responsible.
3. **HYPOTHESIZE**: List 1-2 probable causes.
4. **FIX**: Apply a surgical fix, changing **one variable at a time** so you know exactly what worked, then remove the reproduction script.
Full workflow in `.agents/skills/diagnose/SKILL.md`.

### `/code` — Surgical Implementation
Instructs the agent to evaluate the task using the Ponytail ladder (Native first, standard library, YAGNI), inspect contract boundaries in `INTERFACES.md`, and write minimal, clean changes.

### `/review` — Adversarial Duel Review & Critic Widget
Runs a proposer-attacker duel. First routes the attack — skips axes the diff can't trigger (no Security Surfaces on a pure copy change, no UI axis on backend-only work) — then the Attacker personality tests the code against the axes that apply: edge cases, race conditions, silent failures, assumption violations, security boundaries, and off-by-ones, outputting a clear critic verdict (`PASS/FAIL` and reason). Full workflow in `.agents/skills/review/SKILL.md`.

### `/prreview` — Gated GitHub PR Review (Draft → Approve → Post)
Checks whether `gh` is authenticated; if not, falls back to plain `git diff`/`git log` and a manually-pasted draft. Drafts inline PR comments (with `​```suggestion​` blocks where a fix applies) and an overall verdict, shows the *exact* comments and event type (`APPROVE`/`REQUEST_CHANGES`/`COMMENT`) for explicit yes/no approval, then posts via a batched `gh api` pending review. Never posts without approval — see Philosophy VIII (Visible & Hard-to-Reverse Action Gate). Full workflow in `.agents/skills/prreview/SKILL.md`.

### `/doc` — Direct Documentation
Generates clear, direct documentation using markdown, tables, alert blocks, and mermaid diagrams with zero filler or redundant introductions.

### `/grok` — Repository Comprehension (Context Graph)
Checks `memory/projects/<name>.md` first — if a previous scan is recorded with a commit hash/date, diffs the repo against that point and only re-analyzes what changed, instead of rescanning from zero. Then checks whether graphify, Understand-Anything, or CodeGraph is available (see Agent Skill Detection above) and delegates to whichever is found — CodeGraph specifically also offers real call-graph/blast-radius queries beyond a structural map. If graphify is available, it runs a two-phase manifest-driven pipeline: Phase 1 (detect files, extract code AST, create job manifest for docs/images, exit); the agent then dispatches subagents for doc/image chunks and runs Phase 2 (`--resume`) to merge and finish. If no graph tool is available, falls back to a manual scan of manifest files, test framework, and entry points. Either way, persists the findings (stamped with the current commit hash/date) to `memory/projects/<name>.md` so the next run can do an incremental update. Full workflow in `.agents/skills/grok/SKILL.md`.

### `/audit-arch` — Architecture Health Check
Run periodically, not just when something's broken. Delegates to a codebase-mapping tool if available — `claude-mem:pathfinder` or CodeGraph (real blast-radius/dependency-tangle data via `codegraph impact`/`codegraph callers`); otherwise falls back to a manual smell-scan (god objects, shallow modules, duplicated logic, tangled dependencies). Outputs a prioritized refactor queue, not an unprompted rewrite — see Philosophy XII (Continuous Architecture Care). Full workflow in `.agents/skills/audit-arch/SKILL.md`.

### `/scratch` — Scaffold New Project
Initializes a repository from zero, creating standard files, the Second Brain system (`MEMORY.md`, `GLOSSARY.md`, `inbox.md`, `memory/`), and the module boundary tracker (`INTERFACES.md`). Per Philosophy VI, also ensures a `.gitignore` covers secrets and common build/dependency junk — created fresh if missing, or merged in if one exists without those entries.

### `/compact` — Memory Consolidation (Second Brain Sync)
Consolidates current session learnings. It writes a daily log summary, updates project cards in `memory/projects/`, refines `MEMORY.md` open loops, and clears `inbox.md`. If the `caveman` plugin is installed, runs `/caveman-compress` on the updated memory files as the final step. If toolless, it outputs updated files in markdown blocks for you to paste. Full workflow in `.agents/skills/compact/SKILL.md`.

### `/handoff` — Agent Handoff & State Compilation
Compiles a transition note summarizing accomplishments, active/in-progress files, open loops, blockers, and the next action for the incoming agent. It writes this to `memory/handoff.md` (or prints a markdown block for manual copy-pasting if toolless). Full workflow in `.agents/skills/handoff/SKILL.md`.

---

## Portability: Cross-LLM Fallback Protocol
If you are running the agent in a web browser interface (e.g., Gemini, ChatGPT, DeepSeek, or Minimax Web UI) or toolless API:
1. **Interactive Commands**: The model will parse typed slash commands in your messages (e.g. `/grill`) and run the corresponding behaviors.
2. **Dialogue Fallback**: The model will ask you to paste directory structures or file contents, output code updates with exact target file paths, and output full memory updates for you to manually paste into `MEMORY.md` and `memory/daily/` logs.
