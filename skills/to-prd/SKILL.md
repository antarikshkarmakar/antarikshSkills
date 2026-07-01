---
name: ak-to-prd
description: Product Requirements Scoping Quiz — asks a targeted modules-touched quiz and drafts a Product Requirements Document (PRD) to memory/prds/
trigger: /ak-to-prd
---

# /ak-to-prd — Product Requirements Document (PRD) Generation

Use this skill to convert a high-level feature request into a well-defined Product Requirements Document (PRD).

## Context Prerequisite
**Context Validation**: Refer to RULESET.md for project context validation before executing.

## Step 1 — Scoping & Modules Quiz
Ask the user a quick modules-touched quiz to locate code boundaries:
1. **Directories & Modules**: Which high-level directories, packages, or assemblies will this new feature touch? (e.g. `src/components`, `api/controllers`).
2. **Interfaces & Contracts**: Does it introduce new endpoints, CLI commands, database schemas, or public APIs? Check `INTERFACES.md` if existing ones are affected.
3. **Data/State**: Does it introduce new persistent storage fields, database tables, or environment variables?
4. **Third-Party Integrations**: Does it add any new dependencies or call external service integrations?

## Step 2 — Draft the PRD
Create a new file under `memory/prds/<feature-name>.md` (use a lowercase, URL-friendly kebab-case name) using the project's PRD template (`templates/memory/prds/template.md`). Make sure to:
- Strip the `TEMPLATE_DO_NOT_USE` marker from the output file.
- Populate the problem statement, goals, non-goals, and acceptance criteria based on user inputs.
- Map the answers of the Scoping Quiz to the **Modules Touched** section.
- Summarize testing strategy and validation guidelines for the developer.

Once drafted, present a markdown link to the newly created file.
