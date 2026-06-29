---
name: diagnose
description: Structured Debugging — REPRODUCE, MINIMIZE, HYPOTHESIZE, FIX
trigger: /diagnose
---

# /diagnose — Structured Debugging

## 1. REPRODUCE
*   **Minimal Repro**: Write a minimal script or test case that reliably reproduces the bug. Smallest, simplest version that fails consistently.
*   **Sentry Error Telemetry**: If the user provides a Sentry Issue ID, Event ID, or Trace URL, check `memory/local_env.md` for Sentry configuration (Org slug, auth token). Run:
    *   *Sentry CLI*: `sentry issue events <issue-id>` or `sentry issue view <issue-id>`
    *   *Sentry API*: `curl -s -H "Authorization: Bearer <auth-token>" "https://sentry.io/api/0/organizations/<org-slug>/issues/<issue-id>/events/?full=true"`
    Use the returned stack trace, request payloads, local variables, and breadcrumbs to directly pinpoint the error and construct the reproduction test.
*   **Fallback Log & Trace**: If a deterministic repro isn't feasible and Sentry isn't configured, add verbose output or breakpoints to watch data flow in real time.

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
