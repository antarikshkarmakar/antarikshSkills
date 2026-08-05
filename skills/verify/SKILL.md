---
name: ak-verify
description: Verification Before Completion — prove the claim with fresh command output before saying done, fixed, or passing
trigger: /ak-verify
---

# /ak-verify — Verification Before Completion

The single rule every other skill in this framework leans on (Philosophy X). Invoke it directly before declaring work finished, or apply it inline — every skill's **Evidence Over Claims** footer points here.

## The Iron Law

```
NO COMPLETION CLAIMS WITHOUT FRESH VERIFICATION EVIDENCE
```

If you have not run the verifying command **in this session, after the change**, you cannot claim it passes. Violating the letter of this rule violates the spirit of it.

## The Gate

Before stating any status — done, fixed, passing, working, clean, deployed:

1. **IDENTIFY** — which exact command proves this claim?
2. **RUN** — execute it fresh and in full. Not a subset, not from memory, not a previous run.
3. **READ** — the whole output: exit code, failure count, warnings. Not just the last line.
4. **JUDGE** — does the output actually confirm the claim?
   - No → state the real status, with the output
   - Yes → state the claim **together with** the output
5. **ONLY THEN** — make the claim.

Skipping a step is not a faster verification; it is an unverified claim.

## Prefer the Command Over the Opinion
When both exist, a programmatic check beats a judgement call: exit codes, test counts, diffs, `grep`, a build. Reserve your own judgement for what no command can assess — meaning, taste, whether the thing solves the user's actual problem. If a check exists and you reasoned instead of running it, you guessed.

## Judge the Output, Not Your Intent
When checking your own work, evaluate the **artifact alone** — the code, the output, the file as it now stands — without replaying what you were *trying* to do. You know what you meant, and that knowledge quietly fills gaps that are not actually there on disk. A reader arriving cold has only the artifact.

Practical form: state the criterion, look only at the output, decide. If you catch yourself thinking "well, it's obviously meant to…", stop — that sentence is author-intent bias, and the next reader will not have your intent to lean on.

## Claim → Required Evidence

| Claim | Requires | Not sufficient |
|---|---|---|
| Tests pass | Test-run output showing 0 failures | A previous run, "should pass", unchanged-looking code |
| Linter clean | Linter output, 0 errors | Checking only changed files, extrapolation |
| Build succeeds | Build command, exit 0 | Linter passing, "no obvious errors" |
| Bug fixed | The original failing symptom now passes | Code changed, root cause "looks addressed" |
| Regression test works | Verified red **and** green (fails before the fix, passes after) | Test passes once, against the fixed code |
| Nothing else broke | Full suite, not just the new test | The new test passing |
| Subagent completed | The VCS diff and its evidence | The child's report saying "success" |
| Requirements met | Line-by-line check against the stated criteria | Tests passing |
| Deployed / config applied | Queried the live target and read the result back | The apply command exiting 0 |

## Red Flags — Stop and Verify
- The words "should", "probably", "seems to", "looks right"
- Satisfaction expressed before evidence: "Great!", "Perfect!", "All set!"
- About to commit, push, open a PR, or hand off
- Trusting a subagent's self-report (see the table — a report is a claim, the diff is proof)
- Verifying a part and generalising to the whole
- Being tired, being late, or "just this once"

## Rationalization Check

| Excuse | Reality |
|---|---|
| "Should work now" | Then the command costs seconds and proves it. |
| "I'm confident" | Confidence is not evidence. |
| "The linter passed" | A linter is not a compiler, and a compiler is not a test. |
| "The agent said success" | Verify independently. Agents report intent, not outcome. |
| "I ran it a minute ago" | Before or after the change? Only after counts. |
| "It's a trivial change" | Trivial changes break builds constantly. |
| "Just this once" | There is no once. |

## When Verification Is Impossible
Some claims genuinely cannot be verified locally — no test harness, no access to the target environment, a race that will not reproduce on demand. That is not a licence to claim success. **Say what you did, say what remains unverified, and name the check the user must run.** An honest "implemented, not verified — run `X` to confirm" is useful; a false "done" is not.
