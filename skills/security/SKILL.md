---
name: ak-security
description: Security Audit — run local secrets scanning, threat modeling, dependency scans, and OWASP audits
trigger: /ak-security
---

# /ak-security — Security Audit

## 1. Threat Modeling (OWASP Top 10)
Inspect the codebase or active PR diffs targeting key threat categories:
- **Injection**: Ensure SQL, OS commands, or LDAP inputs are parameterized.
- **Authentication & Authorization**: Verify authentication tokens/cookies and role checks are enforced on endpoints.
- **Sensitive Data Exposure**: Check that passwords, hashes, keys, or PII are encrypted in transit and at rest.
- **Security Misconfigurations**: Review server headers, default users/passwords, or debug features left enabled.

## 2. Secrets Scan
Proactively check that no credentials or tokens are committed or staged:
- Check staged differences for credential patterns:
  ```bash
  git diff --staged --check
  ```
- If `repomix` is installed, run packaging with security checks:
  ```bash
  npx repomix --security-check
  ```

## 3. Dependency Audit (CVE Scan)
Scan external packages and packages locks for known CVE vulnerabilities:
- For Node.js: `npm audit` / `yarn audit`
- For Python: `pip-audit`
- For general filesystems:
  ```bash
  trivy fs .
  ```

## 4. IaC Security (If Applicable)
If the project uses Kubernetes, Terraform, or Docker configurations:
- Run Checkov to inspect configurations:
  ```bash
  checkov -d .
  ```
- Or run Trivy config scans:
  ```bash
  trivy config .
  ```

## 5. Security Checklist Report
Output a brief Markdown summary of the audit findings:
1. **Threats Inspected**: List components/files reviewed and threat models applied.
2. **Secrets Found**: (None or list of paths).
3. **CVEs Flagged**: List packages and CVSS severity.
4. **Remediation Plan**: Actionable steps to fix highlighted security gaps.
