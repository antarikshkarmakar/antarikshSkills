---
name: ak-headroom
description: Headroom Integration — detect, check status, and configure Headroom's reversible context compression (MCP or proxy)
trigger: /ak-headroom
---

# /ak-headroom — Headroom Integration & Compression

Use this skill to detect, verify, and guide the use of Headroom's context compression capabilities.

## 1. Detection Loop
Check the status of required environment binaries:
1. **Headroom CLI**: Run `headroom --version` to verify if Headroom is installed on the local PATH.
2. **Python**: Run `python --version` (requires Python 3.10+).
3. **Environment/Managers**: Check for the presence of `pipx`, `uv`, or npm to understand package management capabilities.
4. **MCP Availability**: Check if the agent interface supports MCP configurations.

## 2. Safety Guidelines
Before configuring or recommending actions, ensure compliance with these rules:
- **No Auto-Install**: Never run installer scripts for Headroom without explicit yes/no user approval (Philosophy VIII).
- **No Auto-Wrap**: Never configure automatic agent wrapping without explicit approval.
- **Never Modify Rule Files**: Under no circumstances should Headroom be allowed to write directly to `CLAUDE.md`, `AGENTS.md`, `GEMINI.md`, or `.cursorrules`. All rule modifications must flow from `templates/RULESET.md`.
- **Telemetry Redaction**: Advise the user to disable telemetry via setting the environment variable `HEADROOM_TELEMETRY=off`.
- **Localhost Proxy Binding**: If configuring Headroom as a proxy, ensure it is bound strictly to `localhost` (`127.0.0.1`) to prevent external exposure of telemetry and logs (Security warning).

## 3. Recommended Integration Modes
Present the best integration mode to the user depending on their environment:
1. **MCP Integration (Preferred)**: Recommend configuring the Headroom MCP server for on-demand context compression and retrieval using `headroom_compress` and `headroom_retrieve` tools.
2. **Local Proxy**: Recommend running the Headroom local proxy for full traffic compression (useful for heavy JSON APIs and debugging logs).
3. **Simulation/Audit Mode**: Always advise running optimization and cleanups in `audit` or `simulate` mode first to preview what will be modified.

## 4. Verification Commands
Guide the user to verify their Headroom setup using documented status checks and an MCP smoke test:
- **Doctor Check**: `headroom doctor` (runs sanity checks on environment and credentials)
- **MCP Status**: `headroom mcp status`
- **Proxy Metrics**: `headroom perf` or `headroom dashboard` when the proxy is running
- **MCP Smoke Test**: If MCP tools are available, call `headroom_compress` on synthetic log content, record the returned hash, then call `headroom_retrieve` with that hash to prove reversible retrieval.
- **Fallback SDK Smoke Test**: If MCP is not available but the Python package is installed, run a tiny local script that imports Headroom and compresses synthetic content. Do not claim retrieval is verified unless a returned hash has been retrieved through MCP or proxy-backed retrieval.
