---
name: grok
description: Repository Comprehension — build/update knowledge graph of the codebase
trigger: /grok
---

# /grok — Repository Comprehension

## 1. Check Memory First
Read `memory/projects/<name>.md` if it exists. If a previous `/grok` run recorded the stack, conventions, and module boundaries (with commit hash or date), don't rescan from zero — diff the repo against that point:
```bash
git diff --name-only <hash>..HEAD
```
Only re-analyze changed files.

## 2. Check for Knowledge-Graph Tools
Priority order (pick first available):
1. **graphify** — `SKILL.md` at `<home>/.claude/skills/graphify/` (Windows: `%USERPROFILE%`, macOS/Linux: `~`)
2. **Understand-Anything** — `.claude-plugin/` or `.understand-anything/` marker, or `/understand` command
3. **CodeGraph** — `codegraph` CLI on PATH, or `.codegraph/codegraph.db` in repo

If any available: delegate to it. If graphify is chosen, invoke `/graphify` and follow its manifest-driven extraction loop, then compile the final project report into `memory/projects/<name>.md`. CodeGraph is preferred for "what calls this" or "what breaks if I change this" questions.

## 3. Manual Scan (if no tool available)
- Walk directory tree
- Identify stack from manifest files (`package.json`, `pyproject.toml`, `go.mod`, `*.csproj`)
- Locate test framework and entry points
- On previously-scanned repo: only re-walk files from step 1's diff

## 4. Persist Findings
Write to `memory/projects/<name>.md`:
- Stack and module boundaries
- Entry points
- Conventions observed
- Stamp with current commit hash and date

So next `/grok` run is incremental, not full scan.
