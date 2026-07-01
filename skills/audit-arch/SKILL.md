---
name: audit-arch
description: Architecture Health Check — periodic smell scan, output queue not rewrite
trigger: /audit-arch
---

# /audit-arch — Architecture Health Check

Run periodically (every few days) or when smells accumulate per Philosophy XII — not just when something is broken.

## 1. Check for Mapping Tool
Priority:
1. **claude-mem:pathfinder** — feature-grouped flowcharts, duplicated concerns, unified architecture
2. **CodeGraph** — `codegraph impact`/`codegraph callers` for real blast-radius and dependency-tangle data

If available: delegate to it. This is Ponytail rung 2 — reuse before building.

## 2. Manual Smell-Scan (if no tool)
Look for:
- **God objects** — classes/modules doing too much
- **Shallow modules** with leaky interfaces
- **Duplicated logic** across files
- **Circular/tangled dependencies**
- **Ball-of-mud** patterns

## 3. Output a Queue, Not a Rewrite
List findings as discrete, surgical refactor candidates. The user acts on them later.

Do NOT refactor unprompted (Philosophy II — Surgical Changes).

> [!TIP]
> **Subagent Delegation**: Running codebase audits consumes large amounts of file context. If supported, run the `/audit-arch` sweep in an isolated subagent and paste only the final prioritized refactor queue into the main chat session.

