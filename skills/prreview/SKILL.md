---
name: ak-prreview
description: Gated GitHub PR Review — Draft → Approve → Post (Philosophy VIII gate)
trigger: /ak-prreview
---

# /ak-prreview — Gated GitHub PR Review

Posting a PR review is **visible to others** — never post without explicit approval (Philosophy VIII).

## 1. Check Tooling
Run `gh auth status`:
- **Authenticated** → use GitHub API workflow below
- **Not authenticated** → fall back to `git diff`/`git log`, output draft as markdown blocks for user to paste manually

## 2. Draft
Analyze the PR diff. Optionally run `/review` (Proposer-Attacker duel) first.

Prepare each comment as `{file, line, side, suggestion}` using:
```
 ```suggestion
 // the fix
 ```
```

Decide overall event:
- **APPROVE** — minor/non-blocking issues only
- **REQUEST_CHANGES** — blocking issues
- **COMMENT** — no verdict, informational

## 3. Show & Approve
Show every comment with file/line/suggestion, the event type, and the review body.

Ask one explicit yes/no: *"Post this review?"*

Do NOT proceed without explicit yes.

## 4. Post (gh authenticated workflow only)
After explicit yes:

**Step A — Create pending review:**
```bash
gh api repos/:owner/:repo/pulls/<PR>/reviews -X POST \
  -f commit_id="<SHA>" \
  -f 'comments[][path]=file.ts' -F 'comments[][line]=42' -f 'comments[][side]=RIGHT' \
  -f 'comments[][body]=...' --jq '{id, state}'
```

**Step B — Submit with event:**
```bash
gh api repos/:owner/:repo/pulls/<PR>/reviews/<REVIEW_ID>/events -X POST \
  -f event="APPROVE" -f body="..."
```
