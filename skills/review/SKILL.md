---
name: ak-review
description: Adversarial Duel Review — Proposer vs Attacker phase
trigger: /ak-review
---

# /ak-review — Adversarial Duel Review

## 1. Proposer Phase
Review the code for correctness, coverage, and structure.

## 2. Route the Attack
Classify the diff first — skip axes the diff can't trigger:
- Pure CSS/copy change → no Race Conditions or Security Surfaces
- Backend-only change → no UI axis
- Don't spend effort on inapplicable axes

## 3. Attacker Phase
Assume the Proposer is wrong. Attack on applicable axes:
- **Edge Cases** — empty inputs, boundary values, nulls
- **Race Conditions** — concurrent access, async timing
- **Silent Failures** — errors swallowed, exceptions caught and ignored
- **Assumption Violations** — code assumes invariants that don't hold
- **Interface Drift** — if the changes touch files defined in `INTERFACES.md`, verify that the implementation complies with interface contracts
- **Security Surfaces** — injection, auth bypass, credential exposure
- **Classic Bugs** — off-by-one, use-after-free, SQL injection patterns

## 4. Verdict
- **SURVIVED** — attacker failed to break it. List attacks attempted.
- **BROKEN** — specify bugs found and surgical fixes needed.

For high-stakes changes: run 5 parallel attackers (Security, Edge Case, Performance, Architecture, Proposer).
