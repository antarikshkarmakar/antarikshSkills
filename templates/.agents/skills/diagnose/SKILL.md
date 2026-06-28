---
name: diagnose
description: Structured Debugging — REPRODUCE, MINIMIZE, HYPOTHESIZE, FIX
trigger: /diagnose
---

# /diagnose — Structured Debugging

## 1. REPRODUCE
Write a minimal script or test case that reliably reproduces the bug. Smallest, simplest version that fails consistently.

If deterministic repro isn't feasible → **log and trace**: add verbose output or breakpoints to watch data flow in real time.

## 2. MINIMIZE
Isolate the code surface area using divide and conquer:
- Split system in half
- Check which half still fails
- Repeat until exact file and lines responsible are found

## 3. HYPOTHESIZE
State 1-2 hypotheses explaining the cause of the failure.

## 4. FIX
Apply the surgical fix. If testing multiple candidate fixes, **change one variable at a time** — so if it doesn't work, you know exactly which change caused it.

Verify the repro script passes. Then remove the repro script.

## Evidence Over Claims
Never claim the bug is fixed based on code inspection. Run the repro. Show it passing as proof.
