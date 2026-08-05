---
name: ak-code
description: Ponytail Surgical Coding — implement surgical changes using the lazy developer ladder
trigger: /ak-code
---

# /ak-code — Ponytail Surgical Coding

## Prerequisites
**Context Validation**: Refer to RULESET.md for project context validation before executing.

## 1. Check Interface Contracts
Before writing a single line of code, locate and inspect:
- **`INTERFACES.md`**: Verify API/module boundaries.
- **`memory/projects/<name>.md`**: Confirm repository conventions and patterns.
- If you are altering a shared module or contract, stop and align with the user first.

## 1a. Right-Size the Work
Before implementing, cut the change into units. **A unit is the smallest piece that carries its own test cycle and is worth a reviewer's separate verdict.**

- Fold setup, config, scaffolding, and doc updates into the unit whose deliverable needs them — they are not separate units.
- Split only where a reviewer could sensibly reject one unit while approving its neighbour.
- Each unit ends with something independently testable. If a unit cannot be tested on its own, it is half a unit — merge it with its other half.
- Units that must land together to keep the tree green are one unit, not two.

Too-large units hide defects in a wall of diff; too-small units cost more in ceremony than they return. If the work exceeds 3 independent units, consider `/ak-orchestrate`.

## 2. Surgical Minimal Implementation
Follow the **Ponytail Lazy Developer Ladder**:
- Reuse existing code/dependencies.
- Implement the absolute minimum logic required to satisfy the goal.
- Avoid speculative features, unused parameters, or redundant utility functions.
- Do not modify adjacent whitespace, formatting, or comments.
- **Ship no placeholders.** No stubs, empty blocks, `// TODO`, or "handle this later" comments left behind as if the work were finished. Anything you deliberately left undone belongs in your report to the user, not buried in a comment they have to discover.

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

Full gate, claim→evidence table, and rationalization checks: **`/ak-verify`**.
