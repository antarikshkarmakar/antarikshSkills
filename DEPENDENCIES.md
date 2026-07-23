# Dependency Matrix: Antariksh Unified Developer Framework

This document outlines the software dependencies required or optionally used by the Antariksh modular skill ecosystem.

| Tool | Used By Skill | Required / Optional | Detection Command | Install Hint | Fallback Behavior |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`git`** | Almost all skills | **Required** (for memory logs, worktree, and PR checks) | `git --version` | Install Git CLI (Windows: Git for Windows, Unix: standard package manager) | Basic read-only operations succeed; branch creation, incremental scanning, and worktrees fail. |
| **`bash`** | Hooks, `ak-devops`, `ak-ci-check` | **Required** (on macOS/Linux) | `bash --version` | Install bash (Windows: Git Bash or WSL) | Shell hooks and some devops pipeline validators cannot be executed. |
| **`PowerShell`** | Hooks, installer | **Required** (on Windows) | `$PSVersionTable` | Pre-installed on Windows; install PowerShell Core (`pwsh`) on Unix | Execution falls back to Unix/WSL shell scripts. |
| **`jq`** | Shell hooks, JSON manipulation | Optional | `command -v jq` | `scoop install jq` / `brew install jq` | Falls back to manual text parsing (less robust). |
| **`npm`** | `ak-security` (dependency CVE audit via `npm audit`) | Optional | `npm --version` | Install Node.js (which bundles npm) | Skip Node dependency auditing. |
| **`repomix`** | `ak-grok`, `ak-security`, `ak-ci-check` | Optional | `repomix --version` | `npm install -g repomix` after reviewing the package — skills never fetch it at runtime | Falls back to sequential file reads (`ak-grok`) or the offline git secrets scan (`ak-security`/`ak-ci-check`). |
| **`shellcheck`** | `ak-ci-check` | Optional | `shellcheck --version` | `scoop install shellcheck` / `brew install shellcheck` | Skip ShellCheck validation of scripts. |
| **`trivy`** | `ak-ci-check`, `ak-security` | Optional | `trivy --version` | Install Aquasecurity Trivy CLI | Skip security vulnerability scans. |
| **`checkov`** | `ak-ci-check`, `ak-security` | Optional | `checkov --version` | `pip install checkov` | Skip static analysis of IaC templates. |
| **`terraform`** | `ak-devops` | Optional | `terraform --version` | Install HashiCorp Terraform CLI | Skip Terraform validation and plan validation. |
| **`kubectl`** | `ak-devops` | Optional | `kubectl version` | Install Kubernetes CLI tool | Skip validation of active Kubernetes configs. |
| **`helm`** | `ak-devops` | Optional | `helm version` | Install Helm CLI tool | Skip Helm chart structure and lint checks. |
| **`gh`** | `ak-prreview` | Optional | `gh --version` | Install GitHub CLI (`gh`) | Outputs text instructions for manual PR creation/browser review. |
| **`graphify`** | `ak-grok` | Optional | Check skill config directory or `graphify --help` | `uv tool install graphifyy` or `pipx install graphifyy`, then `graphify install` after reviewing the package; pip fallback omits `--user` inside active virtualenvs; project installer can prompt for this with `--install-optional` / `-InstallOptional` | Falls back to CodeGraph or manual parsing. |
| **`codegraph`** | `ak-grok`, `ak-audit-arch` | Optional | `codegraph --version` | `npm install -g @colbymchenry/codegraph` then `codegraph install` after reviewing the package; project installer can prompt for this with `--install-optional` / `-InstallOptional` | Falls back to manual text-based AST structure walk. |
| **`sentry` / `sentry-cli`** | `ak-diagnose` | Optional | `sentry --version` or `sentry-cli --version` | `npm install -g sentry`; project installer can prompt for this with `--install-optional` / `-InstallOptional`; authentication stays manual via `sentry auth login` | Falls back to manual error logs and reproduction scripts. |
| **`caveman`** | `ak-compact`, `RULESET.md` Philosophy V | Optional | Check Claude plugin registry | `claude plugin marketplace add JuliusBrussee/caveman` then `claude plugin install caveman@caveman`; project installer can prompt for this with `--install-optional` / `-InstallOptional` | Fall back to manual token compression and memory consolidation. |
| **`headroom`** | `ak-headroom`, `RULESET.md` Cache Optimization | Optional | `headroom --version` | `uv tool install "headroom-ai[all]"`, `pipx install "headroom-ai[all]"`, or `pip install "headroom-ai[all]"` for the CLI; npm package is SDK-only; pip fallback omits `--user` inside active virtualenvs; project installer can prompt for this with `--install-optional` / `-InstallOptional` | Skip reversible context compression; fall back to normal text processing. |
| **`specify`** (GitHub spec-kit) | `ak-spec` | Optional | `specify --version` | `uv tool install specify-cli --from git+https://github.com/github/spec-kit.git` (review before installing) | `/ak-spec` runs its own prompt-level specify → tasks → analyze → converge flow; no CLI needed. |
