---
name: ak-tdd
description: Matt Pocock Test-Driven Development Loop — RED, GREEN, REFACTOR
trigger: /ak-tdd
---

# /ak-tdd — Test-Driven Development Loop

## Context Prerequisite
**Context Validation**: Refer to RULESET.md for project context validation before executing.

## The Iron Law

```
NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST
```

Violating the letter of this rule violates the spirit of it. If implementation code already exists for the behavior you are about to test, you are not doing TDD — see **Code Written Before Tests** below.

**Applies to**: new features, bug fixes, behavior changes, refactors that alter behavior.
**Ask the user first before skipping**: throwaway prototypes, generated code, pure config files.

## Bootstrap (if no test framework exists)
Run the Ponytail ladder: stdlib or already-installed dependency first. Do NOT add new dependencies just for testing.

## The Loop

### 1. RED — write a failing test, and watch it fail correctly
Write a failing test for the requested behavior. Run the test command. Verify it fails.

**The failure must be the right failure.** A test that fails on an import error, a typo, a missing fixture, or a syntax error is a *broken test*, not a RED test — it proves nothing about the behavior. Read the failure output and confirm it fails on the **assertion**, for the reason you intended. If the failure is wrong, fix the test and re-run before continuing.

If you cannot state what the test proves in one sentence, the test is wrong.

### 2. GREEN — minimal code
Write the minimal implementation to make the test pass. Run the test command. Verify it passes, and that no previously-passing test broke.

### 3. REFACTOR
Refactor for:
- Clean styling
- Karpathy simplicity (write code that's easy to read, not clever)
- Ponytail optimization (stop at the first rung that works)

Keep all tests green throughout. Re-run after each refactor step.

## Code Written Before Tests
If implementation was written before its test — by you, in this session — **delete it and start from the test.**

- Do not keep it "as reference"
- Do not adapt it while writing the test
- Do not look at it while writing the test

Reason: a test written against existing code tests what the code *does*, not what it *should do*. It locks in bugs instead of catching them. Re-implement fresh from the test.

**This applies only to code you just wrote out of order — never to pre-existing codebase code.** Adding tests to untested legacy code is characterization testing, a different and legitimate task; do not delete it.

## Rationalization Check
If you catch yourself thinking any of these, stop — the answer is always the right-hand column:

| Excuse | Reality |
|---|---|
| "Skip TDD just this once" | That's rationalization. Write the test. |
| "The change is too small to test" | Small changes break things. Write the test. |
| "I'll add tests after" | After never comes, and the test will be shaped by the bug. |
| "I already know it works" | Then the test costs 30 seconds and proves it. |
| "The test is hard to write" | Hard-to-test is a design signal. Fix the design, or ask. |
| "It failed, close enough" | Wrong-reason failure is not RED. Read the output. |

## Evidence Over Claims
Never claim TDD is done based on code inspection. Run the tests. Show the pass output as proof.
