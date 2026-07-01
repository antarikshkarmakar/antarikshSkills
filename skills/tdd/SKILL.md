---
name: ak-tdd
description: Matt Pocock Test-Driven Development Loop — RED, GREEN, REFACTOR
trigger: /ak-tdd
---

# /ak-tdd — Test-Driven Development Loop

## Context Prerequisite
Before executing `/ak-tdd`, verify that `memory/projects/<name>.md` exists (the repository context file). If it does not exist, alert the user and advise running `/ak-grok` first to build the codebase context.

## Bootstrap (if no test framework exists)
Run the Ponytail ladder: stdlib or already-installed dependency first. Do NOT add new dependencies just for testing.

## The Loop

### 1. RED
Write a failing test for the requested feature. Run the test command. Verify it fails.

### 2. GREEN
Write the minimal implementation code to make the test pass. Run the test command. Verify it passes.

### 3. REFACTOR
Refactor for:
- Clean styling
- Karpathy simplicity (write code that's easy to read, not clever)
- Ponytail optimization (stop at the first rung that works)

Keep all tests green throughout.

## Evidence Over Claims
Never claim TDD is done based on code inspection. Run the tests. Show the pass output as proof.
