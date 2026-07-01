---
name: ak-diagnose
description: Structured Debugging — REPRODUCE, MINIMIZE, 5-WHYS ROOT CAUSE, FIX & PREVENT
trigger: /ak-diagnose
---

# /ak-diagnose — Structured Debugging

## Context Prerequisite
Before executing `/ak-diagnose`, verify that `memory/projects/<name>.md` exists (the repository context file). If it does not exist, alert the user and advise running `/ak-grok` first to build the codebase context.

## 1. REPRODUCE
*   **Minimal Repro**: Write a minimal script or test case that reliably reproduces the bug. Smallest, simplest version that fails consistently.
*   **Sentry Error Telemetry**: If the user provides a Sentry Issue ID, Event ID, or Trace URL, check `memory/local_env.md` for Sentry configuration (Org slug, auth token). Run:
    *   *Sentry CLI*: `sentry issue events <issue-id>` or `sentry issue view <issue-id>`
    *   *Sentry API*: `curl -s -H "Authorization: Bearer <auth-token>" "https://sentry.io/api/0/organizations/<org-slug>/issues/<issue-id>/events/?full=true"`
    Use the returned stack trace, request payloads, local variables, and breadcrumbs to directly pinpoint the error and construct the reproduction test.
*   **Fallback Log & Trace**: If a deterministic repro isn't feasible and Sentry isn't configured, add verbose output or breakpoints to watch data flow in real time.
*   **PII & Secrets Scrubbing**: Before printing, saving, or writing stack traces, logs, or error telemetry to disk (daily logs, scratch files, or chat), strip all authentication headers, bearer tokens, API keys, passwords, and sensitive PII (e.g. emails, phone numbers) to prevent leakages.

## 2. MINIMIZE
Isolate the code surface area using divide and conquer:
- Split system in half
- Check which half still fails
- Repeat until exact file and lines responsible are found

## 3. ROOT CAUSE (5 Whys Analysis)
Trace the failure backward to its source by asking "Why" 5 times iteratively:
1. **Why** did the immediate failure occur? (e.g., database constraint error)
2. **Why** was that constraint violated? (e.g., foreign key value was null)
3. **Why** was it null? (e.g., API payload didn't map the parameter)
4. **Why** did the mapper fail? (e.g., upstream validator was bypassed)
5. **Why** was the validator bypassed? (e.g., no regression test for the interface contract in `INTERFACES.md`)

This identifies the systemic root cause, rather than just patching the immediate symptom.

## 4. FIX & PREVENT
Apply a surgical fix to resolve the root cause. If testing candidate fixes, **change one variable at a time** so you can identify exactly what works.
*   **Prevent Recurrence**: Add regression tests, update API validations, or adjust `INTERFACES.md` contracts as indicated by the 5 Whys.
*   Verify the repro script passes. Then clean up/remove the repro script.

## Evidence Over Claims
Never claim the bug is fixed based on code inspection. Run the repro. Show it passing as proof.

> [!TIP]
> **Subagent Debugging Delegation**: For complex, multi-step debugging sessions (e.g. running multiple test iterations), delegate the REPRODUCE/MINIMIZE loops to an isolated subagent. The subagent should return only a verified diagnostic report and a surgical fix, keeping the main session's context clean.

