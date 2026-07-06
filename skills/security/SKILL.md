---
name: ak-security
description: Security Audit — run local secrets scanning, threat modeling, dependency scans, and OWASP audits
trigger: /ak-security
---

# /ak-security — Security Audit

## Prerequisites
**Context Validation**: Refer to RULESET.md for project context validation before executing.

## 1. Threat Modeling (OWASP Top 10)
Evaluate target files and PR diffs against all 10 core threat categories:
- **A01:2021-Broken Access Control**: Ensure endpoints check user roles and ownership bounds.
- **A02:2021-Cryptographic Failures**: Check that keys/salts are secure, HTTPS is enforced, and cryptography algorithms are modern.
- **A03:2021-Injection**: Verify all database queries, OS exec inputs, and LDAP fetches are parameterized.
- **A04:2021-Insecure Design**: Audit workflow logic for potential bypasses or lack of threat profiling.
- **A05:2021-Security Misconfiguration**: Inspect configurations for default ports, open CORS, and enabled debug features.
- **A06:2021-Vulnerable and Outdated Components**: Audit package dependencies for active CVE warnings.
- **A07:2021-Identification and Authentication Failures**: Validate secure session creation, token timeouts, and MFA/login limits.
- **A08:2021-Software and Data Integrity Failures**: Guard against untrusted CDN endpoints and raw script runs.
- **A09:2021-Security Logging and Monitoring Failures**: Confirm critical login/auth failures are logged without storing PII/credentials.
- **A10:2021-Server-Side Request Forgery (SSRF)**: Validate user-supplied fetch URLs against strict domain white-lists.

## 2. Secrets Scan
Proactively check that no credentials or private tokens are committed or staged:
- **Git staged secrets search** (runs the shared secrets scan script):
  - **On Windows (PowerShell)**:
    ```powershell
    powershell -ExecutionPolicy Bypass -File .agents/scripts/scan-secrets.ps1
    ```
  - **On macOS / Linux (Bash)**:
    ```bash
    bash .agents/scripts/scan-secrets.sh
    ```
- **Repomix security scanner** (only if a reviewed local `repomix` executable is already installed):
  ```bash
  command -v repomix >/dev/null 2>&1 && repomix --security-check
  ```
  If `repomix` is not on PATH, skip it with a warning pointing to `DEPENDENCIES.md` — never fetch packages at runtime. The staged-secrets scan above covers credentials offline.

## 3. Dependency Audit (CVE Scan)
Audit package managers and filesystems for known CVE exposures (Graceful Check: verify CLI tools exist before running):
- **Node.js**: Check if `npm` or `yarn` is available → `npm audit` / `yarn audit`
- **Python**: Check if `pip-audit` is available → `pip-audit`
- **System Sweep**: Check if `trivy` is on PATH (`command -v trivy` or `Get-Command trivy`):
  ```bash
  trivy fs .
  ```

## 4. IaC Security (If Applicable)
If container configs or infrastructure files (Terraform/Kubernetes) are detected:
- **Checkov**: Verify if `checkov` is on PATH (`command -v checkov` or `Get-Command checkov`):
  ```bash
  checkov -d .
  ```
- **Trivy Config**: Verify `trivy` is on PATH:
  ```bash
  trivy config .
  ```

## 5. Security Checklist Report
Output a brief Markdown summary of the audit findings:
1. **Threats Inspected**: List components/files reviewed and threat models applied.
2. **Secrets Found**: (None or list of paths).
3. **CVEs Flagged**: List packages and CVSS severity.
4. **Remediation Plan**: Actionable steps to fix highlighted security gaps.

---

## Evidence Over Claims
Do not declare an audit complete based on raw assumptions. List every tool run, provide command outputs/reports, and explain the exact threat modeling vectors tested.
