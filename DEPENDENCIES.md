# Dependency Matrix: Antariksh Unified Developer Framework

This document outlines the software dependencies required or optionally used by the Antariksh modular skill ecosystem.

| Tool | Used By Skill | Required / Optional | Detection Command | Install Hint | Fallback Behavior |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`git`** | Almost all skills | **Required** (for memory logs, worktree, and PR checks) | `git --version` | Install Git CLI (Windows: Git for Windows, Unix: standard package manager) | Basic read-only operations succeed; branch creation, incremental scanning, and worktrees fail. |
| **`bash`** | Hooks, `ak-devops`, `ak-ci-check` | **Required** (on macOS/Linux) | `bash --version` | Install bash (Windows: Git Bash or WSL) | Shell hooks and some devops pipeline validators cannot be executed. |
| **`PowerShell`** | Hooks, installer | **Required** (on Windows) | `$PSVersionTable` | Pre-installed on Windows; install PowerShell Core (`pwsh`) on Unix | Execution falls back to Unix/WSL shell scripts. |
| **`jq`** | Shell hooks, JSON manipulation | Optional | `command -v jq` | `scoop install jq` / `brew install jq` | Falls back to manual text parsing (less robust). |
| **`npx`** / **`npm`** | `ak-grok`, `ak-devops`, `ak-security` | Optional | `npx --version` | Install Node.js (which bundles npm/npx) | Skip Repomix packaging or IaC vulnerability scanning. |
| **`repomix`** | `ak-grok` (deep manual code packager) | Optional | `npx repomix --version` | `npm install -g repomix` | Falls back to sequential file-by-file traversing and reading. |
| **`shellcheck`** | `ak-ci-check` | Optional | `shellcheck --version` | `scoop install shellcheck` / `brew install shellcheck` | Skip ShellCheck validation of scripts. |
| **`trivy`** | `ak-ci-check`, `ak-security` | Optional | `trivy --version` | Install Aquasecurity Trivy CLI | Skip security vulnerability scans. |
| **`checkov`** | `ak-ci-check`, `ak-security` | Optional | `checkov --version` | `pip install checkov` | Skip static analysis of IaC templates. |
| **`terraform`** | `ak-devops` | Optional | `terraform --version` | Install HashiCorp Terraform CLI | Skip Terraform validation and plan validation. |
| **`kubectl`** | `ak-devops` | Optional | `kubectl version` | Install Kubernetes CLI tool | Skip validation of active Kubernetes configs. |
| **`helm`** | `ak-devops` | Optional | `helm version` | Install Helm CLI tool | Skip Helm chart structure and lint checks. |
| **`gh`** | `ak-prreview` | Optional | `gh --version` | Install GitHub CLI (`gh`) | Outputs text instructions for manual PR creation/browser review. |
| **`graphify`** | `ak-grok` | Optional | Check skill config directory | Locally installed skill config | Falls back to CodeGraph or manual parsing. |
| **`codegraph`** | `ak-grok`, `ak-audit-arch` | Optional | `codegraph --version` | Install CodeGraph CLI tool | Falls back to manual text-based AST structure walk. |
| **`sentry-cli`** | `ak-diagnose` | Optional | `sentry-cli --version` | Install Sentry CLI tool | Falls back to manual error logs and reproduction scripts. |
| **`caveman`** | `ak-compact`, `RULESET.md` Philosophy V | Optional | Check Claude plugin registry | Install JuliusBrussee/caveman plugin | Fall back to manual token compression and memory consolidation. |
| **`headroom`** | `ak-headroom`, `RULESET.md` Cache Optimization | Optional | `headroom --version` | `pip install "headroom-ai[mcp]"` or `pipx install headroom-ai` for the CLI; npm package is SDK-only | Skip reversible context compression; fall back to normal text processing. |
