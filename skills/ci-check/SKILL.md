---
name: ak-ci-check
description: Run local pre-PR validation checks (CRLF check, ShellCheck, ruleset sync verification, Trivy) to ensure remote CI passes.
trigger: /ak-ci-check
---

# /ak-ci-check — Local CI pre-check

This skill allows you to run all validation, linting, ruleset synchronization, and security checks locally on your machine before pushing changes to GitHub. Ensuring these check pass locally keeps the Git history clean and prevents failing remote CI runs.

---

## Graceful Tool Detection & Portability
Before running external CLI tools (`shellcheck`, `trivy`, `checkov`, `repomix` or `npx`), check if the command exists on the local PATH:
- **On macOS / Linux (Bash)**: `command -v <tool-name> >/dev/null 2>&1`
- **On Windows (PowerShell)**: `Get-Command <tool-name> -ErrorAction SilentlyContinue`

If a tool is missing, output a clean warning suggesting how to install it (e.g. using Scoop, Homebrew, Apt, or NPM) instead of failing with a command execution error.

---

## 1. Line Endings Normalization (CRLF to LF)
Before committing, check that no text, script, or config files contain CRLF line endings.
- **On macOS / Linux / Git Bash**:
  ```bash
  grep -rlI $'\r' --include=\*.sh --include=\*.md --include=\*.json --include=\*.yml --include=\*.yaml --include=\*.ps1 .
  ```
- **On Windows (PowerShell)**:
  ```powershell
  Get-ChildItem -Recurse -Include *.sh, *.md, *.json, *.yml, *.yaml, *.ps1 | Where-Object { (Get-Content -Path $_.FullName -Raw) -match '\r\n' } | Select-Object -ExpandProperty FullName
  ```

**How to Fix**:
If CRLF endings are found, run Git renormalization to convert them based on `.gitattributes`:
```bash
git add --renormalize .
```

---

## 2. Script Linting (ShellCheck)
Ensure that all bash script modifications comply with ShellCheck rules:
- **On Linux (apt)**: `sudo apt install shellcheck`
- **On macOS (Homebrew)**: `brew install shellcheck`
- **On Windows (Scoop)**: `scoop install shellcheck`

**Command to run**:
```bash
sh_files=$(find . -name "*.sh" -not -path "*/.git/*" -not -path "*/.agents/*")
if [ -n "$sh_files" ]; then shellcheck $sh_files; fi
```
*Scale Tip (Large Repositories)*: To scan only modified/staged shell scripts and avoid legacy noise, run:
```bash
sh_files=$(git diff --name-only --diff-filter=d | grep '\.sh$' || true)
if [ -n "$sh_files" ]; then shellcheck $sh_files; fi
```

---

## 3. Ruleset Compilation Drift Check
If you modified `templates/RULESET.md` or any root guideline configuration files, you MUST compile the ruleset to generate the portable headers. Do not modify rule files like `CLAUDE.md`, `AGENTS.md`, or Cursor MDC files directly.

**Compile Commands**:
- **On Windows (PowerShell)**:
  ```powershell
  .\install.ps1 -RulesOnly -Force
  ```
- **On macOS / Linux (Bash)**:
  ```bash
  bash install.sh --rules-only --force
  ```

**Check Drift**:
Run `git diff --exit-code` to confirm that compiled files do not show unstaged diffs. If diffs appear, stage and commit the compiled updates.

---

## 4. Local Security & CVE Scanning
Run local security audits to ensure no secrets have been leaked and configurations are safe:
- **Git Secrets Check** (Lightweight & Offline):
  Check for tracked `.env` files and scan staged changes for potential hardcoded keys/secrets:
  ```bash
  # Verify no .env files are tracked by Git
  tracked_envs=$(git ls-files | grep -E '\.env$' || true)
  if [ -n "$tracked_envs" ]; then
    echo "ERROR: Tracked .env files found in Git index:"
    echo "$tracked_envs"
    exit 1
  fi

  # Scan staged diff for credentials assignments (e.g. key = "value")
  secrets_found=$(git diff --staged | grep -E -i 'password|secret|token|api_key|private_key' | grep -E '\s*=\s*["'\''].+["'\']' || true)
  if [ -n "$secrets_found" ]; then
    echo "WARNING: Potential hardcoded secret or API token detected in staged diff:"
    echo "$secrets_found"
  fi
  ```
- **Repomix Security Scan**:
  Verify credentials safety across the repository codebase:
  ```bash
  npx repomix --security-check
  ```
- **Trivy File Scan**:
  ```bash
  trivy config .
  trivy fs .
  ```
  *Scale Tip*: For large repositories with many legacy warnings, scan only modified files:
  ```bash
  git diff --name-only --diff-filter=d | xargs -I {} trivy fs {}
  ```
- **Checkov Scan**:
  ```bash
  checkov -d .
  ```
  *Scale Tip*: Target Checkov to specific modified files rather than the entire directory:
  ```bash
  git diff --name-only --diff-filter=d | grep -E '\.(yaml|yml|tf|json)$' | xargs -r checkov -f
  ```
Fix all warnings/violations flagged as `CRITICAL` or `HIGH` before staging.

---

## Evidence Over Claims
Before declaring a branch ready to be pushed or PR created, run `/ak-ci-check` and verify all outcomes are green.
