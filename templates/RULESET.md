# RULESET.md — Antariksh Unified Developer Framework

This framework works on ANY LLM with ANY interface. See `.agents/skills/` for on-demand skill files.

---

## 1. Cross-LLM Tool-Fallback Protocol

### LLM has file/terminal tools?
Use them (`read_file`, `write_file`, `run_command`).

### LLM has NO tools (web UI, simple API)?
- **Reading**: ask user to paste file contents
- **Writing**: output code blocks with file path and save instructions
- **Memory updates** (`/ak-compact`, `/ak-align-docs`): print updated content in markdown blocks
- **Handoff** (`/ak-handoff`): print handoff notes in code block

---

## 2. Core Philosophies

### I. Ponytail Lazy Developer Ladder
Before writing code, stop at first rung that works:
1. Does it need to exist? → skip (YAGNI)
2. Already in codebase? → reuse
3. Stdlib does it? → use it
4. Native platform feature? → use it
5. Installed dependency? → use it
6. One line? → one line
7. Only then: minimum that works

### II. Simplicity First — Surgical Changes
- No speculative features
- Don't touch adjacent code/formatting/comments
- Remove unused code your changes introduced; don't touch pre-existing dead code
- **Strict Plan Gate**: Every change requires a goal, success criteria, and a plan. For low-risk changes (e.g. typos, single-line local fixes), you only need a goal and verification step without a full Socratic loop. Trigger a full `/ak-align` scoping gate for changes affecting shared contracts, architecture, security, DevOps, multi-file edits, or whenever ambiguity is present.

### III. Interface Contracts (Swarm Safety)
- Before modifying shared API/utility → check `INTERFACES.md`
- Changing a contract → stop, flag for human review
- Micro-agent delegation → define boundaries first, isolate by directory/branch
- **Standards Harness (ECC Inspiration)**: Before making any code changes, read the repository convention index (`memory/projects/<name>.md`) and interface bounds (`INTERFACES.md`) to prevent contract drift.

### IV. Cache Optimization
- Keep `AGENTS.md`, `MEMORY.md` under 300 lines
- Avoid constant tiny turns that waste context cache
- Compress before it enters context — quote excerpts, not raw files
- **Subagent Delegation**: Delegate heavy operations (like `/ak-grok` repository scans, `/ak-diagnose` loops, or `/ak-audit-arch` sweeps) to background subagents when supported by the runner tool. This keeps the main session's context cache clean, bringing back only the final verified results/patches. Assign one tack/hypothesis per subagent — a focused agent outperforms one juggling multiple angles.
- **Swarm Orchestration (Ruflo Inspiration)**: For complex multi-file refactors or migrations, partition the work into independent modules, spawn background subagents to work concurrently on separate directories or Git worktrees, and synthesize their results into a unified pull request.
- **Repomix Packaging**: Prefer a reviewed local `repomix` executable. If using `npx`, pin the package version, e.g. `npx --yes repomix@1.16.0`, to bundle codebase contents into a single structured, token-efficient XML file that respects `.gitignore` rules.
- **Headroom Compression (Optional)**: If Headroom is detected (run `/ak-headroom` to check), leverage its reversible compression to reduce the token footprint of large tool outputs or debugging logs while keeping them retrievable by hash.

### V. Terse Communication (Caveman Style)
- Strip filler, be direct
- If `caveman` plugin installed (check MEMORY.md "Context Agent Needs") → use `/caveman-compress`

### VI. Security & Credential Protection
- Never output/log/commit API keys, tokens, passwords
- `.env` must be in `.gitignore`
- **Repomix Security Scan**: Proactively run `repomix --security-check`, `npx --yes repomix@1.16.0 --security-check`, or local git pattern validation to scan the project files and staged diffs for active credentials or secrets.

### VII. Clean Git
- Format: `[verb]: [short explanation]` — e.g., `feat: add handoff command`

### VIII. Visible & Hard-to-Reverse Action Gate
Before any visible-to-others or hard-to-reverse action → show exactly what will happen, ask explicit yes/no. Approval for one action does not cover a different action.

### IX. Think Before Coding
- State assumptions explicitly when ambiguity changes approach
- Surface tradeoffs — name alternatives instead of silently picking
- Push back when simpler approach suffices
- Stop when confused — ask, don't guess
- **Re-plan on failure**: If the plan is going sideways or repeated attempts keep failing, stop and re-enter `/ak-align` with what you learned — do not brute-force forward on a broken plan

### X. Goal-Driven Execution (Evidence over Claims)
- Define success criteria before acting
- Never claim done based on code inspection — run verification, show proof
- State plan: `1. [Step] → verify: [check]`
- Loop until verified

### XI. Shared Language (Ubiquitous Language)
Use terms from `GLOSSARY.md` consistently. Propose names for new domain concepts.

### XII. Continuous Architecture Care
Don't silently fix smells — flag for `/ak-audit-arch`. Prefer deep modules with simple interfaces.

### XIII. Modular Capability Alignment & Skill Advisory
- **Trigger Routing**: If the user asks "how do I do X", "is there a skill for X", or "can you do X" where X maps to an existing command (such as scoping, testing, debugging, CI/CD, or refactoring), do not write ad-hoc recipes. Route the query to the correct slash command (`/ak-align`, `/ak-tdd`, `/ak-diagnose`, `/ak-devops`, `/ak-ci-check`, `/ak-grok`, etc.).
- **Capability Extension**: If the user expresses interest in extending agent capabilities, searches for templates/workflows, or requests domain help, run or recommend `/ak-skillset` to triage, design, and compile a new modular skill.

### XIV. Large-Repository Scaling
- In monorepos or repositories with vendored folders, symlinks, submodules, generated files, or binary assets, avoid scanning or indexing blindly.
- Exclude large/vendored directories (e.g., `node_modules`, `vendor/`, `build/`, `.git/`, `.terraform/`) and binary formats.
- If no Git repository is initialized, gracefully fall back to basic directory-tree mapping up to depth 3 and manual file queries.
- Use path-based targeting for commands; never load full directory content into context.

---

## 3. Slash Commands → Point to `.agents/skills/`

| Command | Triggers |
|---------|----------|
| `/ak-grill` | Brutally honest mentor interrogation → `.agents/skills/grill/SKILL.md` |
| `/ak-align` | Pre-coding scope alignment (Socratic) → `.agents/skills/align/SKILL.md` |
| `/ak-align-docs` | Scope alignment + shared language + ADR → `.agents/skills/align-docs/SKILL.md` |
| `/ak-to-prd` | Product requirements doc with module quiz → `.agents/skills/to-prd/SKILL.md` |
| `/ak-tdd` | Test-driven development loop → `.agents/skills/tdd/SKILL.md` |
| `/ak-diagnose` | Structured debugging → `.agents/skills/diagnose/SKILL.md` |
| `/ak-devops` | DevOps & CI/CD automation → `.agents/skills/devops/SKILL.md` |
| `/ak-ci-check` | Local CI validation pre-check → `.agents/skills/ci-check/SKILL.md` |
| `/ak-security` | Security audit (threat modeling, secrets, SAST, CVEs) → `.agents/skills/security/SKILL.md` |
| `/ak-skillset` | Skill authoring, observation intake, triage, synthesis, public/internal safety, and advisory loop → `.agents/skills/skillset/SKILL.md` |
| `/ak-code` | Ponytail surgical implementation → `.agents/skills/code/SKILL.md` |
| `/ak-review` | Adversarial duel review → `.agents/skills/review/SKILL.md` |
| `/ak-prreview` | Gated GitHub PR review → `.agents/skills/prreview/SKILL.md` |
| `/ak-worktree` | Git Worktrees parallel workflow → `.agents/skills/worktree/SKILL.md` |
| `/ak-doc` | Direct documentation → `.agents/skills/doc/SKILL.md` |
| `/ak-grok` | Repository comprehension → `.agents/skills/grok/SKILL.md` |
| `/ak-audit-arch` | Architecture health check → `.agents/skills/audit-arch/SKILL.md` |
| `/ak-scratch` | Scaffold new project + memory/ folders → `.agents/skills/scratch/SKILL.md` |
| `/ak-compact` | Memory consolidation and skill-observation capture → `.agents/skills/compact/SKILL.md` |
| `/ak-handoff` | Agent handoff → `.agents/skills/handoff/SKILL.md` |
| `/ak-headroom` | Headroom Integration → `.agents/skills/headroom/SKILL.md` |

---

## 4. Second Brain Protocol (Cognitive Memory Architecture)

Maintain second brain files categorized under the systematic Cognitive Memory framework (inspired by Awesome-Agent-Memory):
1. **Sensory Memory** (Environment state):
   - `memory/local_env.md` — localized skills, platform OS, and tool configurations
2. **Working Memory** (Session checklists):
   - `task.md` — active task steps list (temporary session checklist)
3. **Procedural Memory** (Action sequences):
   - `.agents/skills/` — slash command workflows
4. **Semantic Memory** (Domain knowledge):
   - `MEMORY.md` — root second brain status, projects, and active loops
   - `GLOSSARY.md` — shared terms
   - `INTERFACES.md` — api/contract boundaries
   - `memory/projects/<name>.md` — project facts. (Note: `<name>` resolves to the basename of the repository root directory. In monorepos, separate files may be created for each package as `memory/projects/<package-name>.md`).
   - `memory/skill-observations.md` -- active reusable skill/process improvement backlog captured during `/ak-compact`
   - `memory/skill-observations.archive.md` -- archived `ACTIONED`/`DECLINED` skill observations, read only when older history is requested
5. **Episodic Memory** (Execution history):
   - `inbox.md` — raw session notes staging area
   - `memory/daily/YYYY-MM-DD.md` — timestamped session logs
   - `memory/adr/<NNN>-<slug>.md` — Architecture Decision Records (ADRs)
   - `memory/prds/<feature-slug>.md` — Product Requirements Documents (PRDs)
   - `memory/handoff.md` — active handoff instructions

### Start-of-Session Loop:
1. Read `memory/handoff.md` if exists → then delete/clear it
2. Read `MEMORY.md`
3. Read `memory/local_env.md` if exists (local skills/tools)
4. Read `AGENTS.md` + `GLOSSARY.md`
5. **Context Validation Check**: Check if `memory/projects/<name>.md` exists. If not, alert the user and advise running `/ak-grok` first to build the project context card and knowledge graph.
6. Read last 5 daily log entries or relevant project file
7. Set up today's log in `memory/daily/YYYY-MM-DD.md`
8. Terse status + *"Is there anything new before we start?"*

### End-of-Session Loop:
1. Write session summary to daily log
2. Update project files with verified decisions/facts
3. Update `MEMORY.md`
4. Add corrections to `AGENTS.md` Learned section
5. Append reusable skill/process observations to `memory/skill-observations.md`
6. Clear `inbox.md`

### Memory Trust & Hygiene Rules
1. **Ignore Templates**: Never parse or copy template files under `templates/` or `.agents/skills/` (like `template.md` files) as real execution history.
2. **Verify and Stamp**: Verified facts in `memory/projects/<name>.md` or `MEMORY.md` must be stamped with the date and current Git commit hash.
3. **Stale Log Archiving**: Archive daily logs older than 30 days to a `.stale` sub-folder if they clutter directory listings, keeping only recent active history.
4. **Redact Secrets**: Never record plain-text tokens, API keys, Sentry tokens, or database passwords in any memory files. Always verify that `.gitignore` covers local environment configurations.
5. **Hook Enforcement Parity**: Automated startup and termination hooks (SessionStart/Stop-Check) are enforced mechanically in Claude Code and Codex CLI. For other clients (Cursor, Gemini CLI, VS Code Copilot, Web UI, etc.), this session protocol is self-enforced by the model parsing this ruleset.
6. **Public Skill Safety**: `memory/skill-observations.md` entries marked `public-safe` must not include client names, project names, proprietary URLs, internal terms, credentials, personal data, or traceable examples. If unsure, mark the observation `internal`.
7. **Skill Observation Archiving**: Keep all `OPEN` observations in `memory/skill-observations.md`. During `/ak-compact`, archive `ACTIONED`/`DECLINED` entries older than 30 days to `memory/skill-observations.archive.md` when the active file exceeds 150 lines or contains more than 20 closed entries.
