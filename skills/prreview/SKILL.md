---
name: ak-prreview
description: Gated GitHub PR Review — Draft → Approve → Post (Philosophy VIII gate)
trigger: /ak-prreview
---

# /ak-prreview — Gated GitHub PR Review

Posting a PR review is **visible to others** — never post without explicit approval (Philosophy VIII).

## 1. Check Tooling
Run `gh auth status`:
- **Authenticated** → use the GitHub CLI/API workflow below
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

1. Create a pending review for the target PR using the authenticated GitHub CLI or API client.
2. Attach only the approved comments, each scoped to the approved file, line, side, and body.
3. Submit the review with the approved event (`APPROVE`, `REQUEST_CHANGES`, or `COMMENT`) and body.
4. Report the posted review URL or ID.

Never paste raw API tokens into commands. If the CLI is unavailable or authentication is unclear, stop and provide the approved review text for the user to post manually.
