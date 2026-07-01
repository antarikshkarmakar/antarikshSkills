# scan-secrets.ps1 -- Scan repository for tracked .env files and hardcoded credentials in staged changes.
$ErrorActionPreference = "Stop"

Write-Host "=== Running Secrets Scan (PowerShell) ===" -ForegroundColor Cyan

# 1. Verify no .env files are tracked by Git
$trackedEnvs = git ls-files | Select-String -Pattern "\.env$"
if ($trackedEnvs) {
    Write-Error "ERROR: Tracked .env files found in Git index:"
    $trackedEnvs | Out-String | Write-Host -ForegroundColor Red
    exit 1
}

# 2. Scan staged added lines for credentials assignments (e.g. key = "value")
$stagedDiff = git diff --staged
if ($stagedDiff) {
    $keyAssignmentPattern = "(?i)(password|secret|token|api[_-]?key|private[_-]?key)[A-Za-z0-9_-]*\s*[=:]\s*('[^']+'|`"[^`"]+`"|[A-Za-z0-9_./+=-]{12,})"
    $ignorePattern = "(?i)(status|placeholder|example|pattern|regex|FILL_ME|_STATUS)"
    $addedLines = $stagedDiff -split "`r?`n" | Where-Object { $_ -match "^\+" -and $_ -notmatch "^\+\+\+" }
    $secretsFound = $addedLines | Where-Object { $_ -match $keyAssignmentPattern -and $_ -notmatch $ignorePattern }
    if ($secretsFound) {
        Write-Host "WARNING: Potential hardcoded secret or API token detected in staged changes:" -ForegroundColor Yellow
        $secretsFound | ForEach-Object { Write-Host $_ -ForegroundColor Yellow }
    } else {
        Write-Host "No secrets or tracked .env files found in staged changes." -ForegroundColor Green
    }
} else {
    Write-Host "No staged changes to scan." -ForegroundColor Green
}
