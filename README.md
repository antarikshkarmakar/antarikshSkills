# Antariksh Unified Agent Skills Framework

A universal master agent instructions, ruleset, and memory scaffolding framework designed to run seamlessly on **any LLM** (Gemini, OpenAI, Ollama, DeepSeek, Minimax, Claude) and **any assistant interface** (Claude Code, Codex, Cursor, VS Code + Copilot, Antigravity, Cline/Roo-Code, OpenCode, or standard Web UIs).

## Why This Exists

Most agent setups force a choice between two failure modes: a pile of slash commands you have to remember to reach for, or a single LLM/IDE pairing that loses all context the moment you switch tools. This framework is a single canonical ruleset (`templates/RULESET.md`) that compiles into whatever file each tool actually reads — `CLAUDE.md`, `AGENTS.md`, `.cursorrules`, `.clinerules`, `GEMINI.md`, `.github/copilot-instructions.md` — so the same philosophy, memory, and command set follow you across tools and sessions instead of resetting every time you switch one.

It integrates the best paradigms in agentic development, grouped by what problem each one solves:

**Code Quality & Process**
- 🌲 **The Ponytail Lazy Developer Ladder**: Native platform features, standard library first, minimal viable code, and YAGNI.
- ⚡ **Karpathy Simplicity & Surgical Changes**: Touch only what is requested, clean up your own orphans, avoid overengineering, and enforce a strict design-and-plan gate (banish the "too simple to need a design" bypass).
- 🔬 **Matt Pocock TDD & Debug Loops**: Strict Red-Green-Refactor and Reproduce-Minimize-Hypothesize-Fix protocols.
- ⚔️ **Adversarial Duel & Critic Pattern**: Self-criticism proposer-attacker loops and post-execution checks.
- 🏗️ **Continuous Architecture Care**: Deep modules, simple interfaces, flagged (not silently fixed) ball-of-mud smells — `/ak-audit-arch` is its periodic, deliberate form.
- 🧩 **Think Before Coding**: State assumptions, surface tradeoffs, push back when a simpler approach exists, and stop to ask when genuinely confused — only when ambiguity would change the outcome.
- 🎯 **Goal-Driven Execution**: Turn imperative asks into verifiable success criteria and loop until they're actually checked, not just plausible — the default behind `/ak-tdd` and `/ak-diagnose`, applied everywhere.

**Memory & Continuity**
- 🧠 **Second Brain (Claude-mem)**: Continuous context, index routing, and logs across session boundaries (`memory/`, `GLOSSARY.md`, `memory/adr/`, `memory/prds/`).
- 📖 **Shared Language (Ubiquitous Language)**: A `GLOSSARY.md` of domain terms, built by `/align-docs`, used consistently in naming and communication to cut vocabulary-gap verbosity.
- 🛡️ **Interface Contracts**: Boundary validation mapping via `INTERFACES.md` to prevent multi-agent logical collisions.

**Safety**
- 🚦 **Visible & Hard-to-Reverse Action Gate**: Explicit yes/no approval before posting PR reviews, pushing, force-ops, or any other action that's visible to others or hard to undo. Production-sensitive work additionally gets an explicit edit-scope freeze — stated in-bounds files only, anything outside needs its own approval.

**Efficiency & Portability**
- 🪨 **Caveman Communication**: Terse, direct, pleasantry-free responses that cut token consumption by 65%+. Delegates to the [caveman](https://github.com/JuliusBrussee/caveman) plugin's real multi-level compression (`/caveman`, `/caveman-compress`) when it's installed.
- 📉 **Jcode Cache Optimization & Subagent Delegation**: Lean rulesets and batched reads to prevent expensive cold-cache misses. Compress before content enters context, and delegate heavy, token-intensive tasks (like `/ak-grok` scans, `/ak-diagnose` loops, or `/ak-audit-arch` sweeps) to background subagents when supported by the runner tool to keep the main session's token cache lean.
- 🌐 **Cross-LLM Portability**: Dialogue-driven fallbacks for toolless environments (Web UIs/API).

---

## Repository Structure

- `templates/RULESET.md`: **The single canonical source** for the shared rules body (philosophies, command protocol, Second Brain protocol). Slash commands are a lean lookup table pointing to `.agents/skills/` — detailed instructions live in modular skill files, not in RULESET.md itself. Edit this file, not the 6 generated rule files below — they drift out of sync if hand-edited directly.
- `skills/`: **Modular on-demand skill files.** Each slash command is a thin pointer in RULESET.md; the full workflow lives in its own `.agents/skills/<name>/SKILL.md`. This keeps RULESET.md lean (~150 lines) and context-cache-friendly. Currently includes: `align/`, `tdd/`, `diagnose/`, `review/`, `prreview/`, `worktree/`, `grok/`, `audit-arch/`, `compact/`, `handoff/`.
- `AGENTS.md`, `CLAUDE.md`, `.cursorrules`, `.clinerules`, `GEMINI.md`, `.github/copilot-instructions.md`: **Generated** from `templates/RULESET.md` plus a tool-specific header, at install time. Also copies the root-level `skills/` recursively to the target directory as `.agents/skills/`. Used by Codex/OpenCode/CLI assistants, Claude Code, Cursor, Cline/Roo-Code, Gemini CLI, and GitHub Copilot Chat respectively. (`.cursorrules` is Cursor's legacy format — still read, but Cursor's current standard is `.cursor/rules/*.mdc`; Cursor users are covered either way since Cursor also reads `AGENTS.md` natively. Copilot's autonomous coding agent already reads `AGENTS.md`/`CLAUDE.md`/`GEMINI.md` directly — `.github/copilot-instructions.md` is what closes the gap for everyday Copilot Chat.)
- `SKILL.md`: Hand-maintained master skill definition for this framework itself (used by Claude Code's Skill system, Antigravity, OpenClaw, etc.). Richer/more detailed than the 6 generated files and **not** regenerated from `RULESET.md` — only its `/ak-grok` section and Second Brain references are kept in sync by hand.
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

Running the installer detects locally installed agent skills (see below), generates the 6 rule files from `templates/RULESET.md`, copies the root-level `skills/` recursively to `.agents/skills/` of the target directory (so slash commands have their full workflow files), creates the `memory/` structure (including `adr/` and `prds/`), scaffolds Second Brain templates (including `GLOSSARY.md`), creates today's daily log (`memory/daily/YYYY-MM-DD.md`), ensures a `.gitignore` covers secrets/junk (creating one if missing, or appending only the missing baseline entries if one already exists — never overwrites your own rules), and writes everything to the root of the target directory.

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

## Tool Integration & Plugin Packaging

This section covers how to configure the framework for daily development in individual IDEs/CLIs (local setup), as well as how to package and distribute it as a custom plugin/extension.

### 1. Local Project Setup

The installer drops the right file for every tool in one pass (see Repository Structure above) — there's no separate per-tool configuration step. Open the installed project in whichever of these you use; each one picks its rules up automatically.

#### IDE & Tool Installation Reference Table

| Tool / IDE | Setup Type | Primary Configuration File(s) | Installation Command / Method |
| :--- | :--- | :--- | :--- |
| **Claude Code (CLI)** | Local or Global | `CLAUDE.md` / `settings.json` | Run project installer OR `/plugin install antariksh-skills` |
| **Codex (CLI)** | Local or Global | `AGENTS.md` / `hooks.json` | Run project installer OR `codex plugin install antariksh-skills` |
| **Cursor** | Project-Local | `AGENTS.md` / `.cursorrules` / `.cursor/rules/` | Run project installer, then open project folder |
| **VS Code (GitHub Copilot)** | Project-Local | `.github/copilot-instructions.md` / `AGENTS.md` | Run project installer, then open project folder |
| **OpenCode** | Project-Local | `AGENTS.md` | Run project installer, then open project folder |
| **Antigravity** | Local or Global | `AGENTS.md` / `GEMINI.md` | Run project installer OR symlink plugin to `~/.gemini/config/plugins/` |
| **Hermes Agent** | Global | `~/.hermes/SOUL.md` / `~/.hermes/skills/` | Copy philosophies to SOUL.md and skills to skills folder `cp -r skills/* ~/.hermes/skills/`|
| **OpenClaw** | Local | `AGENT.md` / `.agents/skills/` | Run project installer, then load workspace |


#### Claude Code (CLI)
Reads `CLAUDE.md` from the project root automatically. Run `claude` from inside the installed project directory. Add `-Hooks`/`--hooks` at install time for mechanical Second Brain enforcement (see [Optional: Claude Code Hooks](#optional-claude-code-hooks)).

##### Publishing & Installing as a Global Plugin
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

#### Codex (CLI)
OpenAI's Codex CLI reads `AGENTS.md` as its primary instruction file. Run `codex` from inside the installed project directory — zero extra configuration.

##### Installing as a Global Plugin
This repository is fully compatible with Codex's plugin marketplace configuration:

1. **Add the Marketplace**: Tap the repository inside Codex CLI:
   ```bash
   codex plugin marketplace add <github-username>/antarikshSkills
   ```
2. **Install the Plugin**:
   ```bash
   codex plugin install antariksh-skills
   ```
   *Make sure hooks are enabled in your global configuration `~/.codex/config.toml` (under `[features]` set `codex_hooks = true`) for stop-gate automation.*


#### OpenClaw
*   **Identity & Guidelines**: Append the philosophies to your agent's workspace configuration manual (`AGENT.md` or `SOUL.md` in `~/.openclaw/agents/<name>/`).
*   **On-Demand Skills**: Projects created with our installer already have `.agents/skills/` copied recursively; OpenClaw will automatically discover and parse these skills on workspace load.

#### Everything else (also covered, not asked for above but worth knowing)
- **Cline / Roo-Code**: reads `.clinerules`.
- **Gemini CLI**: reads `GEMINI.md` as its own native convention.
- **No fixed convention** (raw Ollama, DeepSeek, Minimax, or a plain web-UI chat): falls back to the Cross-LLM Tool-Fallback Protocol below — paste file contents in, the agent works from what's pasted.

---

### 2. Packaging & Marketplace Distribution

If you want to package and distribute this framework as a marketplace plugin, you can build wrappers around the installer:

#### VS Code, Cursor, and OpenCode (VS Code Extension)
Because Cursor and OpenCode are based on VS Code/VSCodium, a single VS Code extension will run in all three:
1. Create a standard VS Code extension using `yo code`.
2. Add a command contribution inside `package.json`:
   ```json
   "contributes": {
     "commands": [{
       "command": "antariksh.initialize",
       "title": "Antariksh: Initialize/Update Framework"
     }]
   }
   ```
3. Use the terminal/process Node APIs in `src/extension.ts` to run the installer:
   ```typescript
   import { exec } from 'child_process';
   import * as vscode from 'vscode';
   
   vscode.commands.registerCommand('antariksh.initialize', () => {
       const workspace = vscode.workspace.workspaceFolders?.[0].uri.fsPath;
       if (!workspace) return;
       const cmd = process.platform === 'win32'
           ? `powershell.exe -ExecutionPolicy Bypass -File "${installPs1Path}" -TargetDir "${workspace}" -Force`
           : `bash "${installShPath}" "${workspace}" --force`;
       exec(cmd, (err, stdout, stderr) => { ... });
   });
   ```

#### Antigravity (Native Agent Plugin)
Antigravity searches for custom plugins inside `~/.gemini/config/plugins/`. Because this repository already contains [.claude-plugin/plugin.json](file:///.claude-plugin/plugin.json) and [.claude-plugin/marketplace.json](file:///.claude-plugin/marketplace.json), you can install it globally by symlinking it:
* **Windows (PowerShell)**:
  ```powershell
  New-Item -ItemType SymbolicLink -Path "C:\Users\antar\.gemini\config\plugins\antarikshSkills" -Value "C:\GitHub\antarikshSkills"
  ```
* **macOS/Linux (Bash)**:
  ```bash
  ln -s /path/to/antarikshSkills ~/.gemini/config/plugins/antarikshSkills
  ```

#### SkillKit Integration (Universal Skills Manager)
Antariksh Unified Agent Skills are fully compatible with [SkillKit](https://github.com/rohitg00/skillkit). This repository contains a [package.json](file:///c:/GitHub/antarikshSkills/package.json) manifest mapping all custom agent skills, enabling packaging, conflict checking, and multi-agent translation.

##### Installation & Package Management
To install `antarikshSkills` globally or in your project using SkillKit:
```bash
skillkit add <github-username>/antarikshSkills
```
This registers the master `antariksh-unified-skill` and the modular commands (`/ak-align`, `/ak-tdd`, `/ak-diagnose`, `/ak-review`, `/ak-prreview`, `/ak-worktree`, `/ak-grok`, `/ak-audit-arch`, `/ak-compact`, `/ak-handoff`) in your active agent environments.

##### Format Translation Adapter
You can translate any modular skill in `skills/` to your favorite agent format using SkillKit's translation engine:
```bash
skillkit translate skills/diagnose --to cursor
```
This automatically converts the metadata frontmatter and instructions into the format expected by the target agent adapter.

##### Conflict Detection
Before initializing, run SkillKit's collision checking command to ensure that the custom slash commands do not conflict with existing global packages or tools:
```bash
skillkit conflicts
```
This analyzes the triggers (e.g., `/ak-align`, `/ak-tdd`, `/ak-diagnose`) defined in each modular `SKILL.md`'s frontmatter and reports any overlaps.

#### Factory Droid Integration
Factory Droid can pull and install custom plugins directly from your public repository.

##### Add the Marketplace
To register this repository as a plugin marketplace in Factory Droid:
```bash
droid plugin marketplace add https://github.com/<github-username>/antarikshSkills
```

##### Install the Plugin
```bash
droid plugin install antariksh-skills@antariksh-skills
```

#### VS Code, Cursor & GitHub Copilot Marketplace Registration Guidelines
Because of the architectural differences between IDEs and agents, publishing prompt-level rule files requires specific methods:

##### Cursor & VS Code Marketplace
Cursor and VS Code do not offer a native prompt marketplace. To distribute this framework to their users globally:
1. **VS Code Extension Wrapper**: Build a lightweight VS Code extension that places your `.cursorrules`, `.cursor/rules/*.mdc`, and `.clinerules` configurations into workspace folders programmatically.
2. **Publish**: Package the extension and publish it on the official [Visual Studio Marketplace](https://marketplace.visualstudio.com/) or the [Open VSX Registry](https://open-vsx.org/).
3. **Cursor Directory**: Submit your namespaced MDC rules to community directories like [cursor.directory](https://cursor.directory/) for easy copy-pasting.

##### GitHub Copilot CLI & Copilot Chat
GitHub Copilot does not support general prompt marketplaces.
1. **Repository Scope**: Commit `.github/copilot-instructions.md` directly to your repository's root directory. Copilot Chat will read and respect these rules automatically.
2. **Copilot Extensions**: To make this an official Copilot extension (integrated into the `@` agent dropdown):
   * Build a custom web service (e.g., in Node.js or Python) that acts as a chat agent and responds to user inputs.
   * Register it as a **GitHub App** and enable the **Copilot Agent** capability in settings.
   * Publish it to the official **GitHub Marketplace**.

---

## Agent Skill Detection (Read-Only)

The installer never installs or copies skills into your project — it only checks whether they're already available on the machine and records what it found in `MEMORY.md` under **Context Agent Needs**, so every agent reading the project's rules knows what's usable without re-probing the filesystem each session.

Specifically, it checks `~/.claude/skills/` (`%USERPROFILE%\.claude\skills\` on Windows) for:
- **graphify**: if found, `/ak-grok` uses it to build a real knowledge graph of the repo (`graphify-out/`). If not found, `/ak-grok` checks for Understand-Anything next, then falls back to a manual directory/stack scan. This makes graphify-backed repo comprehension work the same way in Claude Code, Cursor, Codex CLI, or Ollama CLI — any tool with terminal/file access can read graphify's `SKILL.md` directly from the detected path and follow its instructions; no Claude-specific "Skill tool" is required.
- Any other skill folders present, listed for visibility (e.g. `deep-research`, `claude-mem`, etc.).

It also checks `~/.claude/plugins/installed_plugins.json` (a different mechanism — [caveman](https://github.com/JuliusBrussee/caveman) is a Claude Code *plugin*, not a skills-folder entry) for:
- **caveman**: if installed, Philosophy V and `/ak-compact` delegate to its `/caveman` (output compression) and `/caveman-compress` (memory-file compression) commands. If not installed, the installer prints the one-line install command for the user to run themselves — **it never executes a third-party installer automatically**, consistent with Philosophy VIII.

And it checks for the [CodeGraph](https://github.com/colbymchenry/codegraph) CLI on PATH (a third option for `/grok`'s knowledge-graph step, alongside graphify and Understand-Anything):
- **CodeGraph**: if found, `/ak-grok` and `/ak-audit-arch` can delegate to it — beyond a structural map, it exposes real call-graph and blast-radius queries (`codegraph_explore`, `codegraph_impact`, `codegraph_callers`), useful for "what calls this" / "what breaks if I change this." If not found, both fall back the same way they already did (Understand-Anything → manual scan for `/ak-grok`; pathfinder → manual smell-scan for `/ak-audit-arch`).

---

## Optional: Claude Code & Codex CLI Session Hooks

Everything above is pure prompt text — it works, but it relies on the agent remembering to follow the Start-of-Session/End-of-Session Loop every time. `-Hooks`/`--hooks` (or `-k`/`--hooks`) adds actual mechanical enforcement, **opt-in only** since it's CLI-specific and alters local settings:

*   **Claude Code**: Deploys hooks to `.claude/hooks/` and registers them inside `.claude/settings.json`.
*   **Codex CLI**: Deploys hooks to `.codex/hooks/` and registers them inside `.codex/hooks.json`.

### Event Triggers (Shared Scripts)
- **`SessionStart`** (`session-start.sh` / `session-start.ps1`): automatically loads `memory/handoff.md`, `MEMORY.md`, and `GLOSSARY.md` into context — the agent doesn't have to be told to read them.
- **`Stop`** (`stop-check.sh` / `stop-check.ps1`): **blocks** ending the turn if source files were edited more recently than today's daily log (`memory/daily/YYYY-MM-DD.md`) — but only when real edits happened outside `memory/` itself, so read-only/Q&A sessions are never nagged. Requires a git repo to detect edits; no-ops otherwise.

If the settings file (`.claude/settings.json` or `.codex/hooks.json`) doesn't exist yet, it's created from scratch. If it already exists, the installer merges the two hooks in without touching any of your existing hooks or settings (PowerShell does this natively via JSON parsing; the bash installer uses `jq` if available, or prints the snippet to add by hand if not). Re-running is idempotent — it won't duplicate the hook entries.

Requires the CLI to run with a bash-capable shell to execute the hook scripts (Git Bash or WSL on Windows — consistent with everything else in this repo). Note that Codex CLI requires hooks to be enabled globally in your `~/.codex/config.toml` under `[features]` with `codex_hooks = true`.

---

## How to Use the Unified Agent

Once the rules are installed in your workspace root, any agent reading them will respond to the following slash subcommands:

### `/ak-grill` — Brutally Honest Mentor Interrogation
The agent acts as a strict evaluator with 20+ years of experience. It interrogates your task scope, constraints, and traps in blocks before coding, and outputs a blunt, structured assessment and a 30-60-90 day action plan.

### `/ak-align` — Pre-Coding Scope Alignment
Use before starting any non-trivial change. Interrogates the goal, constraints, "done" criteria, and explicit non-goals; confirms scope and checks the strict implementation plan gate (banishing the "too simple" bypass) before any code is written. The deliberate, structured form of Philosophy IX (Think Before Coding). If scope changes mid-task, classifies it first — **Expansion** (new `/align` pass), **Selective Expansion** (confirm and continue), **Hold Scope** (defer as an open loop), or **Reduction** (confirm the smaller scope) — instead of silently absorbing it. Full workflow in `.agents/skills/align/SKILL.md`.

### `/ak-align-docs` — Scope Alignment + Shared Language
Everything `/ak-align` does, plus building the project's shared language: adds undefined domain terms surfaced during the interrogation to `GLOSSARY.md`, and writes an ADR (`memory/adr/<NNN>-<slug>.md`) for any hard-to-explain decision (tradeoff, rejected alternative, constraint).

### `/ak-to-prd` — Product Requirements Doc with Module Quiz
Asks which modules/files a change will touch and why before drafting, then writes the PRD to `memory/prds/<feature-slug>.md` (problem statement, goals, non-goals, modules touched, acceptance criteria).

### `/ak-tdd` — Test-Driven Development Loop (Matt Pocock TDD)
Pivots to TDD mode. If no test framework exists yet, bootstraps the minimal one for the stack first — never skips RED-GREEN-REFACTOR just because nothing was there to begin with:
1. **RED**: Write a failing test for the requested feature. Run the test and verify it fails.
2. **GREEN**: Write the minimal code required to pass the test.
3. **REFACTOR**: Clean and optimize implementation without breaking tests.
Full workflow in `.agents/skills/tdd/SKILL.md`.

### `/ak-diagnose` — Structured Debugging (Matt Pocock Diagnose)
Follows a rigorous debugging sequence:
1. **REPRODUCE**: Smallest, simplest repro that fails consistently. **Sentry telemetry** integrates natively: if a Sentry Issue ID/URL is provided, the agent automatically queries Sentry via CLI or REST API to pull the exact stack traces, request payloads, and variables in scope. Otherwise, falls back to **log and trace** (verbose output/breakpoints).
2. **MINIMIZE**: **Divide and conquer** — bisect the system to isolate the exact file and lines responsible.
3. **ROOT CAUSE (5 Whys)**: Walk backward from the immediate defect/symptom 5 levels deep to uncover the true systemic cause (e.g., config error, upstream contract gap).
4. **FIX & PREVENT**: Apply a surgical fix to resolve the root cause. Change **one variable at a time** so you know what worked, write regression tests/validation to prevent recurrence, and remove the reproduction script.
For complex or multi-step debugging iterations, the REPRODUCE/MINIMIZE loops can be delegated to isolated subagents to preserve main session context. Full workflow in [skills/diagnose/SKILL.md](file:///c:/GitHub/antarikshSkills/skills/diagnose/SKILL.md) (deployed to `.agents/skills/diagnose/SKILL.md`).


### `/ak-code` — Surgical Implementation
Instructs the agent to evaluate the task using the Ponytail ladder (Native first, standard library, YAGNI), inspect contract boundaries in `INTERFACES.md`, and write minimal, clean changes.

### `/ak-review` — Adversarial Duel Review & Critic Widget
Runs a proposer-attacker duel. First routes the attack — skips axes the diff can't trigger (no Security Surfaces on a pure copy change, no UI axis on backend-only work) — then the Attacker personality tests the code against the axes that apply: edge cases, race conditions, silent failures, assumption violations, security boundaries, and off-by-ones, outputting a clear critic verdict (`PASS/FAIL` and reason). Full workflow in `.agents/skills/review/SKILL.md`.

### `/ak-prreview` — Gated GitHub PR Review (Draft → Approve → Post)
Checks whether `gh` is authenticated; if not, falls back to plain `git diff`/`git log` and a manually-pasted draft. Drafts inline PR comments (with `​```suggestion​` blocks where a fix applies) and an overall verdict, shows the *exact* comments and event type (`APPROVE`/`REQUEST_CHANGES`/`COMMENT`) for explicit yes/no approval, then posts via a batched `gh api` pending review. Never posts without approval — see Philosophy VIII (Visible & Hard-to-Reverse Action Gate). Full workflow in `.agents/skills/prreview/SKILL.md`.

### `/ak-worktree` — Isolated Concurrent Task Execution (Git Worktrees)
Instructs the agent to check out task branches into clean sibling directories to prevent active file collisions and database locks during concurrent tasks. Includes setup and teardown procedures. Full workflow in [skills/worktree/SKILL.md](file:///c:/GitHub/antarikshSkills/skills/worktree/SKILL.md) (deployed to `.agents/skills/worktree/SKILL.md`).

### `/ak-doc` — Direct Documentation
Generates clear, direct documentation using markdown, tables, alert blocks, and mermaid diagrams with zero filler or redundant introductions.

### `/ak-grok` — Repository Comprehension (Context Graph)
Checks `memory/projects/<name>.md` first — if a previous scan is recorded with a commit hash/date, diffs the repo against that point and only re-analyzes what changed, instead of rescanning from zero. Then checks whether graphify, Understand-Anything, or CodeGraph is available (see Agent Skill Detection above) and delegates to whichever is found — CodeGraph specifically also offers real call-graph/blast-radius queries beyond a structural map. If graphify is available, it runs a two-phase manifest-driven pipeline: Phase 1 (detect files, extract code AST, create job manifest for docs/images, exit); the agent then dispatches subagents for doc/image chunks and runs Phase 2 (`--resume`) to merge and finish. If no graph tool is available, falls back to a manual scan of manifest files, test framework, and entry points. Either way, persists the findings (stamped with the current commit hash/date) to `memory/projects/<name>.md` so the next run can do an incremental update. Full repository scans consume significant context tokens, so it is recommended to delegate `/ak-grok` to a background subagent when supported. Full workflow in `.agents/skills/grok/SKILL.md`.

### `/ak-audit-arch` — Architecture Health Check
Run periodically, not just when something's broken. Delegates to a codebase-mapping tool if available — `claude-mem:pathfinder` or CodeGraph (real blast-radius/dependency-tangle data via `codegraph impact`/`codegraph callers`); otherwise falls back to a manual smell-scan (god objects, shallow modules, duplicated logic, tangled dependencies). Outputs a prioritized refactor queue, not an unprompted rewrite — see Philosophy XII (Continuous Architecture Care). Audits are recommended to run in background subagents to keep the main chat session lean. Full workflow in `.agents/skills/audit-arch/SKILL.md`.

### `/ak-scratch` — Scaffold New Project
Initializes a repository from zero, creating standard files, the Second Brain system (`MEMORY.md`, `GLOSSARY.md`, `inbox.md`, `memory/`), and the module boundary tracker (`INTERFACES.md`). Per Philosophy VI, also ensures a `.gitignore` covers secrets and common build/dependency junk — created fresh if missing, or merged in if one exists without those entries.

### `/ak-compact` — Memory Consolidation (Second Brain Sync)
Consolidates current session learnings. It writes a daily log summary, updates project cards in `memory/projects/`, refines `MEMORY.md` open loops, and clears `inbox.md`. If the `caveman` plugin is installed, runs `/caveman-compress` on the updated memory files as the final step. If toolless, it outputs updated files in markdown blocks for you to paste. Full workflow in `.agents/skills/compact/SKILL.md`.

### `/ak-handoff` — Agent Handoff & State Compilation
Compiles a transition note summarizing accomplishments, active/in-progress files, open loops, blockers, and the next action for the incoming agent. It writes this to `memory/handoff.md` (or prints a markdown block for manual copy-pasting if toolless). Full workflow in `.agents/skills/handoff/SKILL.md`.

---

## Portability: Cross-LLM Fallback Protocol
If you are running the agent in a web browser interface (e.g., Gemini, ChatGPT, DeepSeek, or Minimax Web UI) or toolless API:
1. **Interactive Commands**: The model will parse typed slash commands in your messages (e.g. `/ak-grill`) and run the corresponding behaviors.
2. **Dialogue Fallback**: The model will ask you to paste directory structures or file contents, output code updates with exact target file paths, and output full memory updates for you to manually paste into `MEMORY.md` and `memory/daily/` logs.



