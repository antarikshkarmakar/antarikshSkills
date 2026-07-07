---
name: ak-bughunt
description: High-Severity Bug Hunt — sweep recent commits for critical defects, patch only with a concrete trigger scenario
trigger: /ak-bughunt
---

# /ak-bughunt — High-Severity Bug Hunt

Proactive sweep of recent commits for critical defects only. This is a hunting patrol, not a full review: most runs should end with a one-line "no critical bugs found" — that is the expected outcome, never manufacture findings to look productive.

## Context Prerequisite
**Context Validation**: Refer to RULESET.md for project context validation before executing.

## 0. SCOPE
- **Default hunting ground**: the last 10 non-merge commits (`git log --oneline --no-merges -10`), or the range the user names (branch, tag range, or paths).
- **Continuity**: check the recent daily logs for the last swept range and resume after it — do not re-sweep commits already cleared unless the user asks.
- **Exclusions**: committed history only — uncommitted working-tree changes belong to `/ak-review`. Skip generated files, lockfiles, and vendored directories per RULESET Large-Repository Scaling.
- **Shallow clone or short history**: sweep what exists and state the actual range covered.

**Surface ONLY bugs that cause:**
- Data loss or corruption
- Crashes
- Auth or permission bypass
- Race conditions that lose writes
- Null dereference in critical paths
- Infinite loops
- Resource leaks
- Silent truncation

**Ignore:** style, minor edge cases, theoretical concerns, UX-only issues. Architectural smells go to `/ak-audit-arch` as flags, not findings here.

## 1. HUNT
- **Follow existing signals first**: failing or red CI on a swept commit, fresh error telemetry (e.g. Sentry), or user-reported symptoms are leads — start there before cold-reading diffs.
- Read each commit's diff, then **trace the caller chain and downstream effects — do not pattern-match diffs**. A suspicious-looking line is not a finding until you know who calls it and with what state.
- Check `INTERFACES.md`: a commit that changed a shared contract multiplies its blast radius — trace consumers first.
- **Dependency bumps count as commits**: a version bump that pulls in a known CVE or a breaking behavioral change is in scope — route CVE analysis through `/ak-security` and check `DEPENDENCIES.md`.
- **Oversized commits**: prioritize auth, persistence, concurrency, and money/data-mutation paths; explicitly log which areas were skipped — never imply full coverage that didn't happen.
- For deep sweeps, delegate one commit or one hypothesis per subagent (RULESET Subagent Delegation); each returns only a verified finding or "clean".

## 2. CONFIDENCE GATE
- **A finding requires a concrete trigger scenario**: the inputs, state, and sequence that make it fail. No trigger scenario → no patch.
- **Classify origin**: *regression* (introduced inside the swept range) vs *latent* (pre-existing, merely revealed — confirm with `git log -S` / blame). Both are reportable if critical; the classification changes the fix conversation (revert is only on the table for regressions).
- **Race conditions**: the trigger scenario is the exact interleaving (thread/request A does X between B's Y and Z). A deterministic test may be impossible — a stress test or a documented interleaving analysis passes the gate; say which one you used.
- Uncertain but worried? Report it to the user as a **suspicion** with your reasoning — do not patch speculation.
- A reproducible trigger that needs deeper investigation → hand off to `/ak-diagnose` (REPRODUCE → MINIMIZE → 5-WHYS).
- Security-class findings (injection, credential exposure) → also run `/ak-security` on the affected surface.

## ⚠ INCIDENT INTERRUPT
If a confirmed finding is plausibly causing **active damage right now** (corrupting production data, leaking credentials, bypassing auth on a live system): stop the sweep, alert the user immediately with the evidence and trigger scenario, and let them choose hotfix/rollback/incident response. Do not quietly keep hunting past an active fire.

## 3. FIX (only through the gate)
- **Consider revert first** (Lazy Ladder): for a regression in a recent unreleased commit, `git revert` of the offending commit is often safer than a forward patch — name the tradeoff before writing new code.
- Minimal, high-confidence patch. No drive-by refactors (RULESET Simplicity First).
- **One bug at a time**: multiple findings → order by severity and exploitability, fix sequentially, one commit per bug — never batch unrelated fixes.
- Add or update tests that lock the behavior — the trigger scenario from step 2 becomes the regression test. If no test harness exists for that path, fall back to a minimal repro script per `/ak-diagnose`, keep its output as proof, and record the test gap as a skill observation.
- Verify per Evidence Over Claims: run the failing test, apply the patch, show it passing — **then run the existing test suite** to prove the patch didn't become the next hunt's finding.
- Committing, pushing, or opening a PR is a visible action — show the diff and get explicit confirmation first (RULESET Action Gate). For PR flows, use `/ak-prreview`.

## 4. REPORT
**If fixed (per bug):**
- Bug + impact (which critical category) + origin (regression or latent)
- Root cause
- Trigger scenario
- Fix + validation performed (test output as proof, full-suite result)

**Suspicions** (failed the confidence gate but worth eyes): one line each — location, worry, what evidence is missing.

**If nothing critical found:** one line — `No critical bugs found in <range>.` (plus suspicions, if any).

**Always**: log the swept range and one-liners for refuted hypotheses in the daily log, so the next hunt resumes cleanly and doesn't re-chase dead leads.

## Evidence Over Claims
Never report a bug as fixed based on code inspection. Run the regression test and show it passing.
