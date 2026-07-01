---
name: ak-devops
description: End-to-end DevOps & CI/CD pipeline automation — configuration generation, linting, security audits, dry-run deployment, and debugging.
trigger: /ak-devops
---

# /ak-devops — DevOps & CI/CD Automation

This skill covers the end-to-end DevOps lifecycle from development/generation, linting, testing, and dry-run validation, to cluster and pipeline debugging.

## Context Prerequisite
Before executing `/ak-devops`, verify that `memory/projects/<name>.md` exists (the repository context file). If it does not exist, alert the user and advise running `/ak-grok` first to build the codebase context.

---

## 1. SCAFFOLD / GENERATE
When generating infrastructure-as-code (IaC), containerization configs, or pipeline definitions, adhere to these production-grade requirements:

### I. General Best Practices
- **Least Privilege**: Always restrict permissions, port bindings, and user scopes to the minimum necessary.
- **Pin Versions**: Never use `latest` or unversioned references. Pin exact container digests/tags, action versions (e.g. `@v4`), and provider/module constraints.
- **Secrets Management**: NEVER hardcode API keys, passwords, or tokens. Use environment variables, workspace secrets, or vault references.

### II. Terraform & Terragrunt
- **Dynamic Context**: Do NOT hardcode cloud provider region/account/subnet/AMI IDs. Use dynamic data sources (e.g., `aws_caller_identity`, `aws_region`, `azurerm_client_config`, `google_client_config`).
- **Deletion Safeguards**: Stateful resources (databases, S3 buckets, KMS keys, storage) MUST have `lifecycle { prevent_destroy = true }` and provider-native deletion protection flags where supported.
- **S3 Multipart Uploads**: Always configure lifecycle rules to abort incomplete multipart uploads after a maximum of 7 days to prevent runaway billing.

### III. Containers & Docker
- **Non-Root Execution**: Container processes must run as a non-root user (`USER node` or `USER 10001`).
- **Multi-Stage Builds**: Build in one stage, copy only artifacts to the runner stage to keep images lean and secure.
- **Cache Cleanups**: Clean package manager caches in the same `RUN` command (e.g., `apt-get clean && rm -rf /var/lib/apt/lists/*`) to reduce layer size.

### IV. Kubernetes & Helm
- **Resource Limits**: Always declare `resources.requests` and `resources.limits` for CPU and Memory.
- **Security Contexts**: Force `runAsNonRoot: true`, `readOnlyRootFilesystem: true`, and drop all capabilities unless explicitly required.
- **Dynamic Ports & Values**: Parameterize image tags, replica counts, ingress hosts, and environment settings.

### V. CI/CD Pipelines (GitHub Actions / GitLab CI)
- **Token Permissions**: Limit default `GITHUB_TOKEN` permissions to read-only (`permissions: contents: read`). Elevate permissions selectively per-job if writing back to repo or deploying.
- **Runner Environments**: Ensure workflows clean up sensitive workspace variables upon completion and handle caching keys deterministically.

---

## 2. VALIDATE / LINT / AUDIT
Before submitting any configurations, run automated linting and security scans to guarantee syntax accuracy and vulnerability compliance.

### I. Tool Matrix
If the environment provides the following tools, execute validation immediately:
- **Terraform / HCL**: Run `terraform fmt -check`, `terraform validate`, and `tflint`.
- **Dockerfiles**: Run `hadolint <Dockerfile>`.
- **Kubernetes / Helm**: Run `kubeval` or `pluto` (for deprecated APIs).
- **Bash Scripts**: Run `shellcheck <script.sh>` (ensure `set -euo pipefail` is present at the start).
- **CI/CD Actions**: Run `actionlint` for GitHub Actions.
- **YAML Configs**: Run `yamllint`.

### II. Security & Vulnerability Audits
- **Checkov / Trivy**: Run scans on IaC and Docker configs to catch open ports, root execution, missing lifecycles, and package vulnerabilities:
  - Checkov: `checkov -d .`
  - Trivy: `trivy config .`
- **Audit Logging**: Report all validation warnings, classify by severity (`CRITICAL`, `HIGH`, `MEDIUM`, `LOW`), and offer/execute code repairs to resolve violations.

---

## 3. DRY-RUN / PLAN
Confirm that configurations deploy correctly without applying state changes:
- **Terraform**: Execute `terraform plan` to verify exact additions, destructions, and modifications.
- **Kubernetes**: Run `kubectl apply --dry-run=client -f <file>` to validate API payload compliance.
- **Helm**: Execute `helm template <chart-path>` or run `helm install --dry-run --generate-name <chart-path>` to verify chart rendering.
- **Docker Compose**: Execute `docker-compose config` to validate composed services.
- **GitHub Actions**: Suggest testing workflows locally using `act` (if installed) to simulate step executions.

---

## 4. DEBUG / TROUBLESHOOT
Follow a structured, investigative debugging checklist when deployments, pods, or pipelines fail:

### I. Kubernetes Cluster Diagnostic Loop
1. **List Resources**: Identify abnormal states: `kubectl get pods -A | grep -v Running`.
2. **Describe Resource**: Check events and status: `kubectl describe pod <pod-name> -n <namespace>`.
3. **Extract Logs**: Inspect container logs, including crashed restarts:
   - Current logs: `kubectl logs <pod-name> -n <namespace>`
   - Previous crashed run logs: `kubectl logs <pod-name> -n <namespace> --previous`
4. **Interactive Shell**: Spawn an ephemeral debug pod or shell into the container:
   - `kubectl exec -it <pod-name> -n <namespace> -- /bin/sh`
5. **Connectivity Check**: Port-forward local traffic to inspect internal ports:
   - `kubectl port-forward pod/<pod-name> 8080:<target-port> -n <namespace>`

### II. CI/CD Runner Troubleshooting
- Inspect runner logs for specific setup phases (caching, checkout, credentials).
- Verify environment variable interpolation and scope access boundaries.
- Trace step failures back to OS-specific differences (Windows PowerShell vs. Linux Bash pathing).

---

## Evidence Over Claims
Do not declare deployment readiness or bug resolution based on inspection. Prove correctness by showing:
- Success outputs of linters/validation runs.
- Green test logs.
- Executed `terraform plan` summaries showing `0 errors`.
