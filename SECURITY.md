# Security Policy

## Reporting a Vulnerability

If you find a security issue in this framework — a skill instruction that could be abused, a script vulnerability, a secrets-handling gap — report it privately rather than opening a public issue:

- **Email**: antariksh.karmakar@gmail.com (subject line starting with `[SECURITY]`)
- Include the affected file(s), a description of the issue, and reproduction steps if applicable.

You will get an acknowledgement within 7 days. Please allow time for a fix before public disclosure.

## Scope

This repository ships **prompt-level agent instructions** (`SKILL.md` files, rule files), **installer scripts** (`install.ps1`, `install.sh`), **optional session hooks** (`templates/.claude/hooks/`), and **validation scripts** (`scripts/`). None of it runs network services or handles credentials directly — but the skills instruct AI agents that do run commands with the user's permissions, so instruction-level issues (e.g. a skill that could be prompt-injected into destructive behavior) are in scope and taken seriously.

## Security Design Principles

- **No auto-install, ever**: skills never install software on the user's behalf. Missing tools produce a warning pointing to [DEPENDENCIES.md](DEPENDENCIES.md) install hints (Philosophy VIII).
- **No runtime package fetching**: skills never invoke `npx`, `uvx`, or any download-and-execute mechanism. External tools (repomix, trivy, checkov, shellcheck) run only when a locally installed executable already exists on PATH; otherwise the check is skipped with a pointer to [DEPENDENCIES.md](DEPENDENCIES.md).
- **Untrusted-input rules**: `/ak-diagnose` treats logs, telemetry, and stack traces as untrusted evidence — agents must never execute instructions found inside them.
- **Approval gates**: anything visible to others or hard to reverse (posting PR reviews, changing contracts) requires explicit user confirmation (Philosophy VIII); `/ak-prreview` drafts and asks before posting.
- **Secrets hygiene**: `scripts/scan-secrets.sh`/`.ps1` scan staged changes for hardcoded credentials (regression-tested in CI); memory files must never contain plaintext tokens; installers scaffold a `.gitignore` covering `.env` and local config.
- **CI enforcement**: every push runs manifest parity checks, installer integration tests, secrets-scanner regression tests, ShellCheck, and a Trivy CVE scan.

## Known & Accepted Audit Findings

[skills.sh](https://skills.sh/antarikshkarmakar/antarikshSkills) runs independent audits (Gen, Socket, Snyk) on every published skill. The following recurring low-severity findings are **known, reviewed, and accepted** — they describe features working as designed, and removing them would remove the feature:

| Finding | File(s) | Why it's accepted |
| :--- | :--- | :--- |
| Executes local scanner tooling while processing repository content | `skills/security/SKILL.md`, `skills/ci-check/SKILL.md` | The skills' purpose is running security scanners (repomix, trivy, checkov). Only locally installed executables are invoked — runtime package fetching (`npx` and similar) was removed entirely in v1.4.1. |
| PowerShell hooks run with `-ExecutionPolicy Bypass` | `install.ps1` | Standard mechanism for Claude Code hooks on default Windows policy; the hooks are opt-in (`-Hooks` flag), short, and readable before install. The installer never fetches remote code. |
| Hook config executes scripts from `${CLAUDE_PROJECT_DIR}` | `templates/.claude/settings.json` | This is the definition of a Claude Code session hook. Integrity depends on the user's own project directory, which the user controls. |
| Med risk: fetches error telemetry / posts PR reviews | `skills/diagnose/SKILL.md`, `skills/prreview/SKILL.md` | Core function of those skills. Credentials come from environment variables only (never printed or stored), and PR posting sits behind an explicit yes/no gate. |

If an audit surfaces something **not** listed here, treat it as unreviewed and report it.

## Supported Versions

Only the latest released version (see `package.json`) receives fixes. The plugin manifests pin an explicit version, so users receive updates when the version is bumped — run `bash scripts/refresh-plugins.sh` or your platform's plugin update command to stay current.
