---
name: ak-align-docs
description: Scope alignment and design documentation - run scoping gate, update GLOSSARY.md, and generate ADRs
trigger: /ak-align-docs
---

# /ak-align-docs - Scope Alignment & Architecture Documentation

Use this skill when introducing complex components, changing interfaces, or making major architectural decisions to keep design specifications synchronized with code.

## Prerequisites
- Refer to RULESET.md for general repository alignment conventions.
- Build the project knowledge graph first using `/ak-grok` if a fresh repository context is needed.

## 1. Scoping Gate
First, initiate the Socratic scoping loop by running `/ak-align` to align with the user on:
1. **Goal**: The high-level intent.
2. **Success Criteria**: Clear validation steps.
3. **Implementation Plan**: Step-by-step checklist.

## 2. GLOSSARY.md Update
Identify any new abstractions, domain terms, or custom structures introduced in this scope.
1. Scan current proposed code files or design specs.
2. If new concepts are introduced, prompt the user for exact definitions and business meanings.
3. Format as standard definitions and append to `GLOSSARY.md`:
   ```markdown
   ### [Term Name]
   - **Definition**: [User provided explanation]
   - **Context**: [Where/how it is applied]
   ```

## 3. ADR (Architecture Decision Record) Generation
For architectural changes, design trade-offs, or database migration patterns, scaffold a formal ADR under `memory/adr/`:
1. Check existing ADRs in `memory/adr/` to determine the next sequential number (e.g. `memory/adr/003-use-mcp.md`).
2. Read the ADR template from `memory/adr/template.md` (or copy it to the destination file).
3. Populate the record sections:
   - **Title**: e.g., `ADR 003: [Short Title]`
   - **Status**: `Draft` (default, updates to `Approved` or `Rejected` based on user feedback).
   - **Context**: Explain the problem, drivers, and background.
   - **Decision**: The chosen solution.
   - **Consequences**: Trade-offs, risks, and follow-up tasks.
4. Prompt the user to review the generated ADR and update its status to `Approved` once confirmed.
