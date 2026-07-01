---
name: antariksh-unified-skill
description: Master developer skill combining planning, simplicity, TDD, diagnosis, devops, QA, and security
---

# Antariksh Unified Agent Skill (Master Developer Framework)

This is a master-skill for developer agents. When running in a toolless or web-UI interface, follow the inline loops and command workflows below.

## 1. Core Sessions Loop
- **Session Start**:
  1. Read `memory/handoff.md` (if exists) -> clear/delete it.
  2. Read `MEMORY.md`.
  3. Read `memory/local_env.md` (if exists).
  4. Read `AGENTS.md` + `GLOSSARY.md`.
- **Session End**: Run `/ak-compact` to summarize logs, update project lists, update MEMORY.md, and record learned corrections.

## 2. Slash Commands Index & Workflows
- **`/ak-grill`**: Interrogate scope, check edge cases and push back, output action plan.
- **`/ak-align`**: Pre-coding Socratic scope alignment to agree on plans and success criteria.
- **`/ak-align-docs`**: Scope alignment + Shared Language glossary update + ADR generation.
- **`/ak-to-prd`**: Scopes features with module quizzes and drafts PRD to `memory/prds/`.
- **`/ak-tdd`**: Test-driven development (write tests -> run fail -> implement -> run pass).
- **`/ak-diagnose`**: Reproduce bug -> bisect scope -> find root cause -> surgical fix -> prevent.
- **`/ak-devops`**: Scaffold container/IaC files, run linters, validate dry-run setups.
- **`/ak-ci-check`**: Run local line ending, shellcheck, Trivy scan, secrets scan, and indentation diff checks.
- **`/ak-security`**: OWASP threat audit, local credentials scan, dependency CVE audit, and security report.
- **`/ak-skillset`**: Skill triage (USE_EXISTING, etc.) -> 11 lenses analysis -> XML spec -> critique duel.
- **`/ak-code`**: Surgical minimal implementation (contracts check -> lazy ladder -> tests -> diff check).
- **`/ak-review`**: Adversarial attacker duel verification against edge cases and interface drift.
- **`/ak-prreview`**: Gated PR review creating draft reviews for explicit user approval.
- **`/ak-worktree`**: Worktree-isolated parallel subagent sweep orchestration.
- **`/ak-doc`**: Direct module and interface documentation via tables and diagrams.
- **`/ak-grok`**: Incremental repository scans (RAG index building/AST parsing) to map structure.
- **`/ak-audit-arch`**: Sweep codebase for architectural smells (god files, duplicate logic, tangles).
- **`/ak-scratch`**: Scaffold new projects with standard folder layouts and template configs.
- **`/ak-compact`**: Log consolidation, project facts compilation, inbox clearing, and corrections capture.
- **`/ak-handoff`**: Compile handoff notes to `memory/handoff.md` for incoming agents.
