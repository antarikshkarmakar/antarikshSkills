---
name: ak-grok
description: Repository Comprehension — build/update knowledge graph of the codebase
trigger: /ak-grok
---

# /ak-grok — Repository Comprehension

## 1. Check Codebase Scale & Empty State
*   **Empty Repository Check**: Check if the codebase has 0 source files or is in an un-initialized Git state. If empty, stop execution, notify the user, and advise them to run `/ak-scratch` first to bootstrap folder directories, `.gitignore`, and second brain configs.
*   **Large Repository Scaling**: If the repository is large (over 200 source files or 50 directories), do not perform a full upfront AST parse. Instead, map the high-level folder structure first (up to depth 3) to build a structural layout, then scan specific subfolders/modules on-demand (lazy grokking) as they are visited by active tasks.
*   **Adaptive Memory & RAG Routing (Ruflo Inspiration)**: Use `memory/projects/<name>.md` as a localized RAG index. Dynamically query and read only the subset of files, module boundaries, and API interfaces that map directly to the user's task instead of loading the entire directory list into the session context.

## 2. Check Memory First
Read `memory/projects/<name>.md` if it exists. If a previous `/ak-grok` run recorded the stack, conventions, and module boundaries (with commit hash or date), don't rescan from zero — diff the repo against that point:
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
- **Repomix Context Packager**: If executing a deep manual codebase analysis, check if `npx` or `repomix` is available on the local PATH. If yes, run:
  ```bash
  npx repomix --output repomix-output.xml
  ```
  to bundle codebase contexts into a structured XML representation, avoiding sequential file reads. Remember to delete `repomix-output.xml` when done to avoid git tracking. If unavailable, fall back to manual directory traversing.

## 4. Persist Findings
Write to `memory/projects/<name>.md`:
- Stack and module boundaries
- Entry points
- Conventions observed
- Stamp with current commit hash and date

So next `/ak-grok` run is incremental, not full scan.

> [!TIP]
> **Subagent Cache Hygiene**: Full repository scans consume significant context tokens. If supported by your runner (e.g. Antigravity subagents or CLI parallel runs), delegate `/ak-grok` to a background subagent, persisting findings to `memory/projects/<name>.md` outside the main session to keep the token cache lean.
