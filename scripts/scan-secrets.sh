#!/bin/bash
# scan-secrets.sh -- Scan repository for tracked .env files and hardcoded credentials in staged changes.
set -e

echo "=== Running Secrets Scan (Bash) ==="

# 1. Verify no .env files are tracked by Git
tracked_envs=$(git ls-files | grep -E '\.env$' || true)
if [ -n "$tracked_envs" ]; then
    echo "ERROR: Tracked .env files found in Git index:"
    echo "$tracked_envs"
    exit 1
fi

# 2. Scan staged added lines for credentials assignments (e.g. key = "value")
key_assignment_pattern='(password|secret|token|api[_-]?key|private[_-]?key)[A-Za-z0-9_-]*[[:space:]]*[:=][[:space:]]*("[^"]+"|[^[:space:]#]{12,})'
ignore_pattern='status|placeholder|example|pattern|regex|FILL_ME|_STATUS'
secrets_found=$(
    git diff --staged |
        grep -E '^\+' |
        grep -Ev '^\+\+\+' |
        grep -E -i "$key_assignment_pattern" |
        grep -Ev -i "$ignore_pattern" ||
        true
)
if [ -n "$secrets_found" ]; then
    echo "WARNING: Potential hardcoded secret or API token detected in staged changes:"
    echo "$secrets_found"
    exit 0
fi

echo "No secrets or tracked .env files found in staged changes."
