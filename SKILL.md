---
name: antariksh-unified-skill
description: Master developer skill combining planning, simplicity, TDD, diagnosis, devops, QA, security, and skill evolution
---

# Antariksh Unified Agent Skill (Master Developer Framework)

This is a master-skill for developer agents. When running in a toolless or web-UI interface, follow the inline loops and command workflows below.

## 1. Core Sessions Loop
- **Session Start**:
  1. Read `memory/handoff.md` if exists → then delete/clear it.
  2. Read `MEMORY.md`.
  3. Read `memory/local_env.md` if exists (local skills/tools).
  4. Read `AGENTS.md` + `GLOSSARY.md`.
  5. **Context Validation Check**: Check if `memory/projects/<name>.md` exists. If not, alert the user and advise running `/ak-grok` first to build the project context card and knowledge graph.
  6. **Episodic Review**: Read the last 5 daily logs (`memory/daily/*.md`) to gain historic execution context.
  7. **Session Boot**: Set up today's daily log and ask the user "Is there anything new or changed before we begin?"
- **Session End**: Run `/ak-compact` to summarize logs, update project lists, update MEMORY.md, record learned corrections, and append reusable skill observations to `memory/skill-observations.md`.

## 2. Slash Commands Index & Workflows
- **`/ak-grill`**: Interrogate scope, check edge cases, and output action plan → `.agents/skills/grill/SKILL.md`.
- **`/ak-align`**: Pre-coding Socratic scope alignment to agree on plans and success criteria; push each criterion until it is binary and observable.
- **`/ak-align-docs`**: Scope alignment + Shared Language glossary update + ADR generation → `.agents/skills/align-docs/SKILL.md`.
- **`/ak-to-prd`**: Scopes features with module quizzes and drafts PRD to `memory/prds/` → `.agents/skills/to-prd/SKILL.md`.
- **`/ak-spec`**: Spec-driven loop (specify -> clarify -> plan -> tasks -> analyze -> implement -> converge) → `.agents/skills/spec/SKILL.md`.
- **`/ak-tdd`**: Test-driven development. Iron Law: no production code without a failing test first; RED must fail for the right reason; delete code written before its test.
- **`/ak-verify`**: Verification before completion. Iron Law: no completion claims without fresh verification evidence; identify the proving command, run it in full, read the output, then claim → `.agents/skills/verify/SKILL.md`.
- **`/ak-diagnose`**: Read error text and recent diff first -> reproduce -> bisect scope -> 5-whys root cause -> surgical fix -> prevent. Iron Law: no fixes without root cause investigation first.
- **`/ak-bughunt`**: Sweep recent commits for critical defects (trace callers -> concrete trigger scenario -> minimal gated fix or one-line all-clear) → `.agents/skills/bughunt/SKILL.md`.
- **`/ak-devops`**: Scaffold container/IaC files, run linters, validate dry-run setups.
- **`/ak-ci-check`**: Run local line ending, shellcheck, Trivy scan, secrets scan, and indentation diff checks.
- **`/ak-security`**: OWASP threat audit, local credentials scan, dependency CVE audit, and security report.
- **`/ak-skillset`**: RED baseline (no failure without the skill = no skill) -> observation intake -> skill triage (USE_EXISTING, etc.) -> 11 lenses analysis -> XML spec, no ungrounded sections -> GREEN check on behaviour -> safety sweep -> critique duel.
- **`/ak-code`**: Surgical minimal implementation (contracts check -> right-size units -> lazy ladder -> tests -> diff check). Ship no placeholders or TODO stubs as finished work.
- **`/ak-review`**: Adversarial attacker duel against edge cases and interface drift. Attack the diff, not the intention behind it.
- **`/ak-prreview`**: Gated PR review creating draft reviews for explicit user approval.
- **`/ak-worktree`**: Worktree-isolated parallel subagent sweep orchestration. Record a clean test baseline at creation; finish with an explicit merge/PR/keep/discard choice before destructive cleanup.
- **`/ak-orchestrate`**: Fleet orchestration (gate on verifiable success -> plan + budget -> decompose -> ledger -> pre-flight baseline -> brief -> delegate -> two-stage review by differing reviewers -> synthesize). Do not delegate what you cannot verify; do not split work whose hard part is coherence; report budget exhaustion honestly → `.agents/skills/orchestrate/SKILL.md`.
- **`/ak-doc`**: Direct module and interface documentation via tables and diagrams → `.agents/skills/doc/SKILL.md`.
- **`/ak-grok`**: Incremental repository scans (RAG index building/AST parsing) to map structure.
- **`/ak-audit-arch`**: Sweep codebase for architectural smells (god files, duplicate logic, tangles).
- **`/ak-scratch`**: Scaffold new projects with standard folder layouts and template configs → `.agents/skills/scratch/SKILL.md`.
- **`/ak-compact`**: Log consolidation, project facts compilation, skill-observation capture, inbox clearing, and corrections capture.
- **`/ak-handoff`**: Compile handoff notes to `memory/handoff.md` for incoming agents.
- **`/ak-headroom`**: Detect and configure Headroom for reversible token compression (MCP/proxy); skip cleanly when it is not installed → `.agents/skills/headroom/SKILL.md`.
