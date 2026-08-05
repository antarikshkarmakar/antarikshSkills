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

> [!IMPORTANT]
> **Attack the diff, not the intention.** Drop everything you know about what the change was *supposed* to do and read only what is actually there. Reviewing your own work is the hard case: you supply the missing context from memory and score the code for what you meant rather than what you wrote. The next reader gets the diff and nothing else — review as that reader. "It's obviously meant to handle X" is not a defence; if X isn't handled in the code, the attack lands.
- **Edge Cases** — empty inputs, boundary values, nulls
- **Race Conditions** — concurrent access, async timing
- **Silent Failures** — errors swallowed, exceptions caught and ignored
- **Assumption Violations** — code assumes invariants that don't hold
- **Interface Drift** — if the changes touch files defined in `INTERFACES.md`, verify that the implementation complies with interface contracts
- **Behavioral Diff** — when relevant, run the same scenario against the base branch (`main`) and the change branch and compare outputs; any unexplained behavioral difference is a finding
- **Security Surfaces** — injection, auth bypass, credential exposure
- **Classic Bugs** — off-by-one, use-after-free, SQL injection patterns

## 4. Verdict
- **SURVIVED** — attacker failed to break it. List attacks attempted.
- **BROKEN** — specify bugs found and surgical fixes needed.

For high-stakes changes: run 5 parallel attackers (Security, Edge Case, Performance, Architecture, Proposer).
