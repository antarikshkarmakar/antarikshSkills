---
name: ak-ci-check
description: Run local pre-PR validation checks (CRLF check, ShellCheck, ruleset sync verification, Trivy) to ensure remote CI passes.
trigger: /ak-ci-check
---

# /ak-ci-check — Local CI pre-check

This skill allows you to run all validation, linting, ruleset synchronization, and security checks locally on your machine before pushing changes to GitHub. Ensuring these check pass locally keeps the Git history clean and prevents failing remote CI runs.

---

## Graceful Tool Detection & Portability
Before running external CLI tools (`shellcheck`, `trivy`, `checkov`, or `repomix`), check if the command exists on the local PATH:
- **On macOS / Linux (Bash)**: `command -v <tool-name> >/dev/null 2>&1`
- **On Windows (PowerShell)**: `Get-Command <tool-name> -ErrorAction SilentlyContinue`

If a tool is missing, output a clean warning pointing the user to the install hint in `DEPENDENCIES.md`, then skip that check. Never install, download, or execute software on the user's behalf — all install decisions belong to the user (Philosophy VIII).

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
Ensure that all bash script modifications comply with ShellCheck rules. If `shellcheck` is not on PATH, skip this check with a warning and point the user to the install hint in `DEPENDENCIES.md` — never install software yourself.

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
  Verify no `.env` files are tracked by Git, and scan staged changes for credentials (runs the shared secrets scan script):
  - **On Windows (PowerShell)** (the script is a local file installed into your repo — review `.agents/scripts/scan-secrets.ps1` before first use):
    ```powershell
    powershell -ExecutionPolicy RemoteSigned -File .agents/scripts/scan-secrets.ps1
    ```
  - **On macOS / Linux (Bash)**:
    ```bash
    bash .agents/scripts/scan-secrets.sh
    ```
- **Repomix Security Scan** (only if a reviewed local `repomix` executable is already installed):
  ```bash
  repomix --security-check
  ```
  If `repomix` is not on PATH, skip this scan with a warning pointing to `DEPENDENCIES.md` — do not fetch it at runtime. The git secrets check above already covers staged credentials offline.
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

## 5. Indentation & Whitespace Check
Ensure that code formatting is clean, consistent, and free of trailing spaces or mixed indentation:
- **Git-Aware Whitespace Scan**:
  Scan both active working changes and staged files for spacing errors:
  ```bash
  # Check active working tree changes for formatting anomalies
  git diff --check

  # Check staged changes for mixed indentation or trailing space
  git diff --staged --check
  ```
  If any whitespace or mixed tabs/spaces issues are flagged, correct them before committing.

---

## Evidence Over Claims
Before declaring a branch ready to be pushed or PR created, run `/ak-ci-check` and verify all outcomes are green.
