#!/bin/bash
# test_secret_scanner.sh -- Regression tests for shared Bash secrets scanner.
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== Running Secrets Scanner Tests (Bash) ==="

TMP_REPO=$(mktemp -d -t secret_scan_repo_XXXXXX)

cleanup() {
    rm -rf "$TMP_REPO"
    echo "Temporary secret scanner test repo cleaned up."
}
trap cleanup EXIT

cd "$TMP_REPO"
git init -b main >/dev/null
git config user.name "Test"
git config user.email "test@example.com"

credential_name="api_"
credential_name="${credential_name}key"
fixture_value="sk-live-51H8xJ2KpQr9t"
fixture_value="${fixture_value}ZvNmYcAbCdEfGh"
printf '%s = "%s"  # example for staging\n' "$credential_name" "$fixture_value" > app.py
git add app.py

scanner_output=$(bash "$SCRIPT_DIR/scan-secrets.sh")
if ! printf '%s\n' "$scanner_output" | grep -q "WARNING: Potential hardcoded secret"; then
    echo "FAIL: Bash scanner missed a live-looking key because the surrounding line contained an ignore word."
    printf '%s\n' "$scanner_output"
    exit 1
fi

git reset --hard >/dev/null

printf '%s = "FILL_ME_IF_USING_SENTRY"\n' "$credential_name" > app.py
git add app.py

scanner_output=$(bash "$SCRIPT_DIR/scan-secrets.sh")
if printf '%s\n' "$scanner_output" | grep -q "WARNING: Potential hardcoded secret"; then
    echo "FAIL: Bash scanner warned on an explicit placeholder value."
    printf '%s\n' "$scanner_output"
    exit 1
fi

git reset --hard >/dev/null

status_name="sentry_"
status_name="${status_name}token"
printf '%s=$(escape_sed "$SENTRY_TOKEN_STATUS")\n' "$status_name" > status.sh
git add status.sh

scanner_output=$(bash "$SCRIPT_DIR/scan-secrets.sh")
if printf '%s\n' "$scanner_output" | grep -q "WARNING: Potential hardcoded secret"; then
    echo "FAIL: Bash scanner warned on a dynamic variable/command-substitution value."
    printf '%s\n' "$scanner_output"
    exit 1
fi

git reset --hard >/dev/null

prefix_bypass_name="to"
prefix_bypass_name="${prefix_bypass_name}ken"
prefix_bypass_value='$FAKEVARLOOKSLIKESECRETsk_live_abcdef123456'
printf '%s = "%s"\n' "$prefix_bypass_name" "$prefix_bypass_value" > app.py
git add app.py

scanner_output=$(bash "$SCRIPT_DIR/scan-secrets.sh")
if ! printf '%s\n' "$scanner_output" | grep -q "WARNING: Potential hardcoded secret"; then
    echo "FAIL: Bash scanner missed a quoted hardcoded value merely because it started with a dollar sign."
    printf '%s\n' "$scanner_output"
    exit 1
fi

echo "=== ALL BASH SECRETS SCANNER TESTS PASSED SUCCESSFULLY ==="
