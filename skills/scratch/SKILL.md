---
name: ak-scratch
description: Fresh Project Scaffolder — initializes Git, memory/ subfolders, and base template rulesets in an empty or fresh directory
trigger: /ak-scratch
---

# /ak-scratch — Project Scaffolding

Use this skill to bootstrap a new codebase from scratch.

## Step 1 — Verify Environment
Determine the repository state to choose the execution branch:
- **Branch A: Brand New Empty Directory**:
  1. Initialize Git by running `git init` (with standard branch name, e.g. `-b main`).
  2. Create a base `.gitignore` using the framework template.
- **Branch B: Existing Repository (With Code & History)**:
  1. Skip Git initialization entirely to preserve existing branch configs and commits.
  2. Locate the existing `.gitignore` and append the Antariksh unified framework ignore block (rather than overwriting the file).

## Step 2 — Create Directories
Initialize the systematic Cognitive Memory architecture subdirectories in the target workspace path:
- `memory/`
- `memory/daily/`
- `memory/projects/`
- `memory/adr/`
- `memory/prds/`

## Step 3 — Copy Core Rules & Configurations
Install the Antariksh core rule files. Copy files from `templates/` using the local installer script (`install.ps1` or `install.sh`) if available, or write them directly:
- `MEMORY.md`
- `GLOSSARY.md`
- `INTERFACES.md`
- `AGENTS.md`
- `CLAUDE.md`
- `GEMINI.md`
- `.cursorrules`
- `.clinerules`
- `inbox.md`
- `task.md`

> [!WARNING]
> Do NOT create `memory/handoff.md` during initialization. Real handoffs must only be created when explicitly compiled via `/ak-handoff`.

## Step 4 — Initialize Local Env
- Create a localized `memory/local_env.md` file checking for the presence of local tools (`git`, `jq`, `repomix`, `codegraph`, `sentry`).
- Instruct the user that credentials (like Sentry auth tokens) must be stored in environment variables, not in `memory/local_env.md`.

## Step 5 — Boot Today's Log
- Generate an empty daily log `memory/daily/YYYY-MM-DD.md` for today's session.
- Advise the user to run `/ak-grok` to build the codebase layout once they have added initial source code files.
