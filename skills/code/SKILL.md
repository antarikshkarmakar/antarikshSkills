---
name: ak-code
description: Ponytail Surgical Coding — implement surgical changes using the lazy developer ladder
trigger: /ak-code
---

# /ak-code — Ponytail Surgical Coding

## Prerequisites
**Context Validation Check**: Verify if the project convention file `memory/projects/<name>.md` is present. If it does not exist, alert the user and advise running `/ak-grok` first to comprehend the codebase architecture and compile conventions before modifying any code.

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
Run localized tests and builds to verify changes:
- Run language/framework specific tests:
  - Node: `npm test` or `npm run test`
  - Python: `pytest` or `python -m unittest`
  - Go: `go test ./...`
  - Rust: `cargo test`
- Compile the codebase locally to ensure zero compiler warnings or linting errors.

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

---

## Evidence Over Claims
Do not declare the task finished based on visual code inspection. Run all tests and validation scripts, and present the final terminal pass output to the user as direct proof of correctness.
