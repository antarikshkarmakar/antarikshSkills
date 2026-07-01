# Antariksh Unified Agent Skills Framework

A universal master agent instructions, ruleset, and memory scaffolding framework designed to run seamlessly on **any LLM** (Gemini, OpenAI, Ollama, DeepSeek, Minimax, Claude) and **any assistant interface** (Claude Code, Codex, Cursor, VS Code + Copilot, Antigravity, Cline/Roo-Code, OpenCode, or standard Web UIs).

## Why This Exists

Most agent setups force a choice between two failure modes: a pile of slash commands you have to remember to reach for, or a single LLM/IDE pairing that loses all context the moment you switch tools. This framework is a single canonical ruleset (`templates/RULESET.md`) that compiles into whatever file each tool actually reads — `CLAUDE.md`, `AGENTS.md`, `.cursorrules`, `.clinerules`, `GEMINI.md`, `.github/copilot-instructions.md` — so the same philosophy, memory, and command set follow you across tools and sessions instead of resetting every time you switch one.

It integrates the best paradigms in agentic development, grouped by what problem each one solves:

**Code Quality & Process**
- 🌲 **The Ponytail Lazy Developer Ladder (Philosophy I)**: Standard library and native feature reuse over new dependencies, using **`/ak-code`** for surgical Ponytail implementations.
- ⚡ **Karpathy Simplicity & Surgical Changes (Philosophy II)**: Touch only the requested scope, clean up orphans, and enforce plan gates via **`/ak-align`** before execution.
- 🔬 **Matt Pocock TDD & Debug Loops (Philosophy X)**: Systematic loops: RED-GREEN-REFACTOR via **`/ak-tdd`**, and Reproduce-Minimize-Fix via **`/ak-diagnose`**.
- ⚔️ **Adversarial Duel & Critic Pattern (Philosophy III & X)**: Proposer-attacker reviews via **`/ak-review`** to verify edge cases and validate contract compliance.
- 🏗️ **Continuous Architecture Care (Philosophy XII)**: Deliberate periodic scans for code smells, circular dependencies, and technical debt via **`/ak-audit-arch`**.
- 🧩 **Think Before Coding & Interrogation (Philosophy IX)**: Socratic evaluation and scoping via the **`/ak-grill`** mentor query and **`/ak-to-prd`** requirements drafting.
- 🎯 **Goal-Driven Execution (Philosophy X)**: Goal-driven verification loops applying to **`/ak-tdd`**, **`/ak-diagnose`**, and **`/ak-devops`** deployments.

**Memory & Continuity**
- 🧠 **Second Brain (Philosophy IV)**: Scaffolding repository directories and config indexes via **`/ak-scratch`**, managing handoffs via **`/ak-handoff`**, and compiling log files via **`/ak-compact`** (grounded in **Cognitive Memory Architecture** organizing Sensory, Working, Procedural, Semantic, and Episodic memory layers).
- 📖 **Shared Language (Philosophy XI)**: Constructing domain terms and Architecture Decision Records (ADRs) via **`/ak-align-docs`** and generating direct technical docs via **`/ak-doc`**.
- 🛡️ **Interface Contracts (Philosophy III)**: Multi-agent boundary maps in `INTERFACES.md` and verification checks to prevent collision.
- 🔐 **Standards Harness (Philosophy III & VI - ECC)**: Ensuring strict validation of directory structure, repository convention files, and Git credentials safety checks via **`/ak-ci-check`** (powered by local checks and **`repomix`** security scanning).
- 🎛️ **Modular Capability Alignment & Skill Advisory (Philosophy XIII)**: Preemptively routing capability queries (scoping, testing, debugging, or CI/CD) and capability extensions/searches to modular skills or **`/ak-skillset`** rather than writing ad-hoc patterns.

**Safety**
- 🚦 **Visible & Hard-to-Reverse Action Gate (Philosophy VIII)**: Gated approval loops for PR comments and code reviews via **`/ak-prreview`**.

**Efficiency & Portability**
- 🪨 **Caveman Communication (Philosophy V)**: Compression of context memory via Caveman and `/ak-compact`.
- 📉 **Jcode Cache Optimization & Subagent Delegation (Philosophy IV)**: Delegating background scans for symbol maps (**`/ak-grok`** using **`repomix`** context packaging), Sentry bug-triggers (**`/ak-diagnose`**), and smell sweeps (**`/ak-audit-arch`**) to isolated processes.
- 🐝 **Swarm Orchestration (Philosophy IV - Ruflo)**: Coordinating concurrent multi-agent refactors across separate branches via **`/ak-worktree`** and the **`/ak-skillset`** authoring manager.
- 🔍 **Adaptive Memory & RAG Routing (Philosophy IV - Ruflo)**: Treating project files as local indices to load only target modules.
- 🌐 **Cross-LLM Portability**: Dialogue-driven fallbacks for toolless environments (Web UIs/API).

---

## Repository Structure

- `templates/RULESET.md`: **The single canonical source** for the shared rules body (philosophies, command protocol, Second Brain protocol). Slash commands are a lean lookup table pointing to `.agents/skills/` — detailed instructions live in modular skill files, not in RULESET.md itself. Edit this file, not the 6 generated rule files below — they drift out of sync if hand-edited directly.
- `skills/`: **Modular on-demand skill files.** Each slash command is a thin pointer in RULESET.md; the full workflow lives in its own `.agents/skills/<name>/SKILL.md`. This keeps RULESET.md lean (~150 lines) and context-cache-friendly. Currently includes: `align/`, `align-docs/`, `tdd/`, `diagnose/`, `devops/`, `ci-check/`, `security/`, `skillset/`, `code/`, `review/`, `prreview/`, `worktree/`, `doc/`, `grok/`, `audit-arch/`, `scratch/`, `compact/`, `handoff/`, `grill/`, `to-prd/`, `headroom/`.
- `AGENTS.md`, `CLAUDE.md`, `.cursorrules`, `.clinerules`, `GEMINI.md`, `.github/copilot-instructions.md`: **Generated** from `templates/RULESET.md` plus a tool-specific header, at install time. Also copies the root-level `skills/` recursively to the target directory as `.agents/skills/`. Used by Codex/OpenCode/CLI assistants, Claude Code, Cursor, Cline/Roo-Code, Gemini CLI, and GitHub Copilot Chat respectively. (`.cursorrules` is Cursor's legacy format — still read, but Cursor's current standard is `.cursor/rules/*.mdc`; Cursor users are covered either way since Cursor also reads `AGENTS.md` natively. Copilot's autonomous coding agent already reads `AGENTS.md`/`CLAUDE.md`/`GEMINI.md` directly — `.github/copilot-instructions.md` is what closes the gap for everyday Copilot Chat.)
- `SKILL.md`: **Generated** master skill definition for this framework (used by Claude Code's Skill system, Antigravity, OpenClaw, etc.). It compiles into a self-contained command index and session loop guide to support toolless/web-UI environments.
- `install.ps1`: Windows PowerShell deployer script.
- `install.sh`: macOS/Linux/WSL Bash deployer script.
- `templates/`: Base structures for initialization:
  - `MEMORY.md`: Root-level Second Brain index of status, projects, focus, open loops, and detected agent skills.
  - `GLOSSARY.md`: Domain term/definition table — built by `/ak-align-docs` (Philosophy XI).
  - `inbox.md`: Staging note inbox.
  - `memory/skill-observations.md`: Reusable skill/process improvement backlog captured during `/ak-compact` and consumed by `/ak-skillset`.
  - `memory/daily/template.md`: Daily append-only logs.
  - `memory/projects/template.md`: Project-specific facts and context cards.
  - `memory/adr/template.md`: Architecture Decision Record format (Context/Decision/Consequences) — written by `/ak-align-docs`.
  - `memory/prds/template.md`: Product Requirements Doc format — written by `/to-prd`.
  - `INTERFACES.md`: Shared contracts.
  - `.gitignore`: Baseline secrets/junk rules (`.env`, keys, `node_modules/`, etc.), enforcing Philosophy VI.
  - `.claude/settings.json`, `.claude/hooks/*.sh`: **Opt-in** (`-Hooks`/`--hooks`) Claude Code hooks that mechanically enforce the Second Brain loop — see [Optional: Claude Code Hooks](#optional-claude-code-hooks) below.

---

## How to Install in a Project

Running the installer detects locally installed agent skills (see below), generates the 6 rule files from `templates/RULESET.md`, copies the root-level `skills/` recursively to `.agents/skills/` of the target directory (so slash commands have their full workflow files), creates the `memory/` structure (including `adr/` and `prds/`), scaffolds Second Brain templates (including `GLOSSARY.md` and `memory/skill-observations.md`), creates today's daily log (`memory/daily/YYYY-MM-DD.md`), ensures a `.gitignore` covers secrets/junk (creating one if missing, or appending only the missing baseline entries if one already exists — never overwrites your own rules), and writes everything to the root of the target directory.

### Skill Evolution Loop

`/ak-compact` can append reusable process misses, dependency gaps, portability issues, and over-engineering signals to `memory/skill-observations.md`. `/ak-skillset` reads those `OPEN` observations before creating or updating skills, then classifies each as action-now, defer, or decline. Mark an observation `public-safe` only after removing client names, project names, proprietary URLs, internal terms, credentials, personal data, and traceable examples; otherwise mark it `internal`. To keep context lean, `/ak-compact` archives old `ACTIONED`/`DECLINED` entries to `memory/skill-observations.archive.md`; `/ak-skillset` reads that archive only when older history is requested.

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
| **Codex (CLI)** | Local or Global | `AGENTS.md` / `hooks.json` | Run project installer OR install from the Codex plugin browser |
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
   This registers the master `antariksh-unified-skill` and the 21 modular command skills globally inside your Claude Code binary.

#### Codex (CLI)
OpenAI's Codex CLI reads `AGENTS.md` as its primary instruction file. Run `codex` from inside the installed project directory — zero extra configuration.

##### Installing as a Global Plugin
This repository includes Codex-native plugin metadata in `.codex-plugin/plugin.json` and a repo marketplace catalog at `.agents/plugins/marketplace.json`. The plugin package exposes the 21 modular `ak-*` skills through `skills/`; the project installer remains the path for generating per-repo rule files, memory scaffolding, and opt-in hooks.

1. **Add the Marketplace**: Tap the repository inside Codex CLI:
   ```bash
   codex plugin marketplace add antarikshkarmakar/antarikshSkills
   ```
2. **Install the Plugin**: Open the plugin browser with `/plugins`, choose the **Antariksh Skills** marketplace source, and install `antariksh-skills`.

Hooks are still opt-in project scaffolding, not automatic plugin side effects. Run `install.ps1 -Hooks` or `install.sh --hooks` in a target repository when you want mechanical SessionStart/Stop enforcement.


#### OpenClaw
*   **Identity & Guidelines**: Append the philosophies to your agent's workspace configuration manual (`AGENT.md` or `SOUL.md` in `~/.openclaw/agents/<name>/`).
*   **On-Demand Skills**: Projects created with our installer already have `.agents/skills/` copied recursively; OpenClaw will automatically discover and parse these skills on workspace load.

#### Everything else (also covered, not asked for above but worth knowing)
- **Cline / Roo-Code**: reads `.clinerules`.
- **Gemini CLI**: reads `GEMINI.md` as its own native convention.
- **No fixed convention** (raw Ollama, DeepSeek, Minimax, or a plain web-UI chat): falls back to the Cross-LLM Tool-Fallback Protocol below — paste file contents in, the agent works from what's pasted.

> [!NOTE]
> **Enforcement Parity**: Startup and termination log gates (SessionStart/Stop-Check) are enforced mechanically by custom hooks only in Claude Code and Codex CLI. In other IDEs and assistants (Cursor, Copilot, Gemini CLI, Web UIs), the session protocol relies on the model self-enforcing the guidelines in the ruleset files.

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
This registers the master `antariksh-unified-skill` and the modular commands (`/ak-grill`, `/ak-align`, `/ak-align-docs`, `/ak-to-prd`, `/ak-tdd`, `/ak-diagnose`, `/ak-devops`, `/ak-ci-check`, `/ak-security`, `/ak-skillset`, `/ak-code`, `/ak-review`, `/ak-prreview`, `/ak-worktree`, `/ak-doc`, `/ak-grok`, `/ak-audit-arch`, `/ak-scratch`, `/ak-compact`, `/ak-handoff`, `/ak-headroom`) in your active agent environments.

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

<a id="optional-claude-code-hooks"></a>
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

| Command | Purpose / Action Description | Target Skill Guide |
| :--- | :--- | :--- |
| **`/ak-grill`** | Acts as a strict evaluator with 20+ years of experience to interrogate task scope, constraints, and pitfalls, outputting a 30-60-90 day action plan. | [skills/grill/SKILL.md](file:///c:/GitHub/antarikshSkills/skills/grill/SKILL.md) |
| **`/ak-align`** | Pre-coding Socratic scope alignment to confirm goals, constraints, non-goals, and establish a strict implementation plan gate. | [skills/align/SKILL.md](file:///c:/GitHub/antarikshSkills/skills/align/SKILL.md) |
| **`/ak-align-docs`** | Pre-coding alignment + building the project's shared language glossary and writing Architecture Decision Records (ADRs). | [skills/align-docs/SKILL.md](file:///c:/GitHub/antarikshSkills/skills/align-docs/SKILL.md) |
| **`/ak-to-prd`** | Runs a modules-touched scoping quiz and drafts a Product Requirements Document (PRD) to `memory/prds/`. | [skills/to-prd/SKILL.md](file:///c:/GitHub/antarikshSkills/skills/to-prd/SKILL.md) |
| **`/ak-tdd`** | MATT POCOCK Test-Driven Development (RED-GREEN-REFACTOR) cycle, bootstrapping minimal test setups if needed. | [skills/tdd/SKILL.md](file:///c:/GitHub/antarikshSkills/skills/tdd/SKILL.md) |
| **`/ak-diagnose`** | Structured debugging loop (REPRODUCE via Sentry/logs → MINIMIZE via bisection → 5-WHYS root cause → FIX & PREVENT). | [skills/diagnose/SKILL.md](file:///c:/GitHub/antarikshSkills/skills/diagnose/SKILL.md) |
| **`/ak-devops`** | End-to-end DevOps automation (scaffold container/IaC/pipeline files, run linters/scanners, validate dry-runs, debug environments). | [skills/devops/SKILL.md](file:///c:/GitHub/antarikshSkills/skills/devops/SKILL.md) |
| **`/ak-ci-check`** | Runs local validation checks (line endings, ShellCheck lint, ruleset sync, Trivy, and git secrets check) to verify PR compliance locally. | [skills/ci-check/SKILL.md](file:///c:/GitHub/antarikshSkills/skills/ci-check/SKILL.md) |
| **`/ak-security`** | Runs static threat modeling checks, local secrets scanning, SAST checks, and dependency CVE scans. | [skills/security/SKILL.md](file:///c:/GitHub/antarikshSkills/skills/security/SKILL.md) |
| **`/ak-skillset`** | Skill authoring with observation intake, triage classes, 11 thinking lenses analysis, XML specs, public/internal safety sweep, and multi-agent synthesis loop. | [skills/skillset/SKILL.md](file:///c:/GitHub/antarikshSkills/skills/skillset/SKILL.md) |
| **`/ak-code`** | Surgical code implementation using the Ponytail ladder (Native first, standard library, YAGNI). | [skills/code/SKILL.md](file:///c:/GitHub/antarikshSkills/skills/code/SKILL.md) |
| **`/ak-review`** | Adversarial proposer-attacker duel verification testing against edge cases, race conditions, and security surfaces. | [skills/review/SKILL.md](file:///c:/GitHub/antarikshSkills/skills/review/SKILL.md) |
| **`/ak-prreview`** | Gated GitHub PR Review loop creating draft comments and reviews for explicit user approval before posting. | [skills/prreview/SKILL.md](file:///c:/GitHub/antarikshSkills/skills/prreview/SKILL.md) |
| **`/ak-worktree`** | Manages Git Worktrees for concurrent, isolated concurrent task execution. | [skills/worktree/SKILL.md](file:///c:/GitHub/antarikshSkills/skills/worktree/SKILL.md) |
| **`/ak-doc`** | Generates direct technical documentation using clean tables, callout alerts, and mermaid diagrams. | [skills/doc/SKILL.md](file:///c:/GitHub/antarikshSkills/skills/doc/SKILL.md) |
| **`/ak-grok`** | Incremental repository scanning using AST analysis (graphify, CodeGraph) to map codebase structure. | [skills/grok/SKILL.md](file:///c:/GitHub/antarikshSkills/skills/grok/SKILL.md) |
| **`/ak-audit-arch`** | Architectural health checks auditing codebase smells (god objects, tangles, duplicate logic). | [skills/audit-arch/SKILL.md](file:///c:/GitHub/antarikshSkills/skills/audit-arch/SKILL.md) |
| **`/ak-scratch`** | Scaffolds new projects from scratch, initializing second brain directories and `.gitignore` rules. | [skills/scratch/SKILL.md](file:///c:/GitHub/antarikshSkills/skills/scratch/SKILL.md) |
| **`/ak-compact`** | Memory consolidation compiling daily logs, updating project cards, capturing reusable skill observations, and clearing inbox note staging. | [skills/compact/SKILL.md](file:///c:/GitHub/antarikshSkills/skills/compact/SKILL.md) |
| **`/ak-handoff`** | Compiles state summary into a handoff note (`memory/handoff.md`) for incoming agents. | [skills/handoff/SKILL.md](file:///c:/GitHub/antarikshSkills/skills/handoff/SKILL.md) |
| **`/ak-headroom`** | Guides and checks configuration of Headroom for reversible token compression (MCP/proxy). | [skills/headroom/SKILL.md](file:///c:/GitHub/antarikshSkills/skills/headroom/SKILL.md) |

---

## Portability: Cross-LLM Fallback Protocol
If you are running the agent in a web browser interface (e.g., Gemini, ChatGPT, DeepSeek, or Minimax Web UI) or toolless API:
1. **Interactive Commands**: The model will parse typed slash commands in your messages (e.g. `/ak-grill`) and run the corresponding behaviors.
2. **Dialogue Fallback**: The model will ask you to paste directory structures or file contents, output code updates with exact target file paths, and output full memory updates for you to manually paste into `MEMORY.md` and `memory/daily/` logs.
