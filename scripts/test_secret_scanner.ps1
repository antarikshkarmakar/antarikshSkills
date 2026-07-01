# test_secret_scanner.ps1 -- Regression tests for shared PowerShell secrets scanner.
$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$tempDir = [System.IO.Path]::GetTempPath()
$tmpRepo = Join-Path $tempDir ("secret_scan_repo_" + [Guid]::NewGuid().ToString().Substring(0,8))

Write-Host "=== Running Secrets Scanner Tests (PowerShell) ===" -ForegroundColor Cyan

function Cleanup {
    if (Test-Path $tmpRepo) {
        Remove-Item -Path $tmpRepo -Recurse -Force -ErrorAction SilentlyContinue
    }
    Write-Host "Temporary secret scanner test repo cleaned up." -ForegroundColor Cyan
}

try {
    New-Item -ItemType Directory -Path $tmpRepo | Out-Null
    Push-Location $tmpRepo
    git init -b main | Out-Null
    git config user.name "Test"
    git config user.email "test@example.com"

    $credentialName = "api_" + "key"
    $fixtureValue = "sk-live-51H8xJ2KpQr9t" + "ZvNmYcAbCdEfGh"
    Set-Content -Path "app.py" -Value "$credentialName = `"$fixtureValue`"  # example for staging"
    git add app.py

    $scannerOutput = & powershell -ExecutionPolicy Bypass -File (Join-Path $scriptDir "scan-secrets.ps1") | Out-String
    if ($scannerOutput -notmatch "WARNING: Potential hardcoded secret") {
        throw "FAIL: PowerShell scanner missed a live-looking key because the surrounding line contained an ignore word.`n$scannerOutput"
    }

    git reset --hard | Out-Null

    Set-Content -Path "app.py" -Value "$credentialName = `"FILL_ME_IF_USING_SENTRY`""
    git add app.py

    $scannerOutput = & powershell -ExecutionPolicy Bypass -File (Join-Path $scriptDir "scan-secrets.ps1") | Out-String
    if ($scannerOutput -match "WARNING: Potential hardcoded secret") {
        throw "FAIL: PowerShell scanner warned on an explicit placeholder value.`n$scannerOutput"
    }

    git reset --hard | Out-Null

    $statusName = "sentry_" + "token"
    Set-Content -Path "status.sh" -Value ($statusName + '=$(escape_sed "$SENTRY_TOKEN_STATUS")')
    git add status.sh

    $scannerOutput = & powershell -ExecutionPolicy Bypass -File (Join-Path $scriptDir "scan-secrets.ps1") | Out-String
    if ($scannerOutput -match "WARNING: Potential hardcoded secret") {
        throw "FAIL: PowerShell scanner warned on a dynamic variable/command-substitution value.`n$scannerOutput"
    }

    git reset --hard | Out-Null

    $prefixBypassName = "to" + "ken"
    $prefixBypassValue = '$FAKEVARLOOKSLIKESECRETsk_live_abcdef123456'
    Set-Content -Path "app.py" -Value "$prefixBypassName = `"$prefixBypassValue`""
    git add app.py

    $scannerOutput = & powershell -ExecutionPolicy Bypass -File (Join-Path $scriptDir "scan-secrets.ps1") | Out-String
    if ($scannerOutput -notmatch "WARNING: Potential hardcoded secret") {
        throw "FAIL: PowerShell scanner missed a quoted hardcoded value merely because it started with a dollar sign.`n$scannerOutput"
    }

    Write-Host "=== ALL POWERSHELL SECRETS SCANNER TESTS PASSED SUCCESSFULLY ===" -ForegroundColor Green
} finally {
    Pop-Location
    Cleanup
}
