---
name: ak-code
description: Ponytail Surgical Coding — implement surgical changes using the lazy developer ladder
trigger: /ak-code
---

# /ak-code — Ponytail Surgical Coding

## 1. Check Interface Contracts
Before writing a single line of code, locate and inspect:
- **`INTERFACES.md`**: Verify API/module boundaries.
- **`memory/projects/<name>.md`**: Confirm repository conventions and patterns.
- If you are altering a shared module or contract, stop and align with the user first.

## 2. Surgical Minimal Implementation
Follow the **Ponytail Lazy Developer Ladder**:
- Reuse existing code/dependencies.
- Implement the absolute minimum logic required to satisfy the goal.
- Avoid speculative features, unused parameters, or redundant utility functions.
- Do not modify adjacent whitespace, formatting, or comments.

## 3. Local Verification
Run localized tests and builds to ensure correctness:
- Execute target unit tests.
- Compile codebase and check for errors.

## 4. Spacing & Whitespace Check
Before committing, check the working tree for formatting anomalies:
```bash
git diff --check
```
Correct any mixed tabs/spaces or trailing whitespaces flagged by the check.

## 5. Pre-PR Scans
Proactively run pre-PR checks to ensure credentials security and codebase integrity:
- Run `/ak-ci-check` (verify offline secrets scan, shellcheck linting, and Trivy filesystem sweeps).
- Fix any `CRITICAL` or `HIGH` violations.

## 6. Clean Commit
Stage, commit, and explain changes concisely:
- Commit format: `[verb]: [short explanation]` (e.g., `fix(auth): resolve token refresh loop`).
