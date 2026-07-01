# test_installer.ps1 -- Test PowerShell installer behavior.
$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$rootDir = Split-Path -Parent $scriptDir

Write-Host "=== Running Installer Tests (PowerShell) ===" -ForegroundColor Cyan

# Create temp directories
$tempDir = [System.IO.Path]::GetTempPath()
$tmpFresh = Join-Path $tempDir ("fresh_repo_" + [Guid]::NewGuid().ToString().Substring(0,8))
$tmpGit = Join-Path $tempDir ("git_repo_" + [Guid]::NewGuid().ToString().Substring(0,8))

if (!(Test-Path $tmpFresh)) { New-Item -ItemType Directory -Path $tmpFresh | Out-Null }
if (!(Test-Path $tmpGit)) { New-Item -ItemType Directory -Path $tmpGit | Out-Null }

$psCmd = if (Get-Command pwsh -ErrorAction SilentlyContinue) { "pwsh" } else { "powershell.exe" }

function Cleanup {
    if (Test-Path $tmpFresh) { Remove-Item -Path $tmpFresh -Recurse -Force -ErrorAction SilentlyContinue }
    if (Test-Path $tmpGit) { Remove-Item -Path $tmpGit -Recurse -Force -ErrorAction SilentlyContinue }
    Write-Host "Temporary test directories cleaned up." -ForegroundColor Cyan
}

try {
    # Scenario 1: Rules-Only Install on Fresh Dir
    Write-Host "Running Scenario 1: -RulesOnly on fresh directory..." -ForegroundColor Yellow
    & $psCmd -ExecutionPolicy Bypass -File (Join-Path $rootDir "install.ps1") -Target $tmpFresh -RulesOnly -Force

    # Verify only rule files and cursor rules are generated
    if (!(Test-Path (Join-Path $tmpFresh "CLAUDE.md")) -or !(Test-Path (Join-Path $tmpFresh "AGENTS.md"))) {
        throw "Scenario 1 FAIL: Missing CLAUDE.md or AGENTS.md"
    }
    if (Test-Path (Join-Path $tmpFresh "memory")) {
        throw "Scenario 1 FAIL: Scaffolding memory directory created despite -RulesOnly flag"
    }
    if (!(Test-Path (Join-Path $tmpFresh ".cursor/rules/core.mdc")) -or !(Test-Path (Join-Path $tmpFresh ".cursor/rules/commands.mdc"))) {
        throw "Scenario 1 FAIL: Missing .cursor/rules/core.mdc or commands.mdc"
    }

    # Verify core.mdc contents
    $coreMdcContent = Get-Content -Path (Join-Path $tmpFresh ".cursor/rules/core.mdc") -Raw
    if ($coreMdcContent -match "\| /ak-align") {
        throw "Scenario 1 FAIL: core.mdc contains slash commands table instead of being in commands.mdc"
    }
    if ($coreMdcContent -notmatch "Ponytail Lazy Developer Ladder") {
        throw "Scenario 1 FAIL: core.mdc is missing philosophies"
    }
    if ($coreMdcContent -notmatch "Second Brain Protocol") {
        throw "Scenario 1 FAIL: core.mdc is missing Second Brain section"
    }

    # Verify commands.mdc contents
    $commandsMdcContent = Get-Content -Path (Join-Path $tmpFresh ".cursor/rules/commands.mdc") -Raw
    if ($commandsMdcContent -notmatch "/ak-align") {
        throw "Scenario 1 FAIL: commands.mdc is missing slash commands"
    }
    if ($commandsMdcContent -match "Ponytail Lazy Developer Ladder") {
        throw "Scenario 1 FAIL: commands.mdc contains philosophies"
    }

    Write-Host "Scenario 1 Passed." -ForegroundColor Green

    # Scenario 2: Full Scaffolding on Fresh/Non-Git Dir
    Write-Host "Running Scenario 2: Full scaffolding on non-Git directory..." -ForegroundColor Yellow
    & $psCmd -ExecutionPolicy Bypass -File (Join-Path $rootDir "install.ps1") -Target $tmpFresh -Force

    if (!(Test-Path (Join-Path $tmpFresh "memory")) -or !(Test-Path (Join-Path $tmpFresh "memory/daily")) -or !(Test-Path (Join-Path $tmpFresh "memory/projects"))) {
        throw "Scenario 2 FAIL: Memory subdirectories were not created"
    }

    # Verify memory/handoff.md is NOT created
    if (Test-Path (Join-Path $tmpFresh "memory/handoff.md")) {
        throw "Scenario 2 FAIL: memory/handoff.md was created during installation"
    }

    # Verify today's daily log exists and does NOT contain examples or TEMPLATE_DO_NOT_USE warning
    $today = (Get-Date).ToString("yyyy-MM-dd")
    $dailyFile = Join-Path $tmpFresh "memory/daily/$today.md"
    if (!(Test-Path $dailyFile)) {
        throw "Scenario 2 FAIL: Today's daily log $dailyFile was not created"
    }
    $dailyContent = Get-Content -Path $dailyFile -Raw
    if ($dailyContent -match "Initialized session and loaded memory") {
        throw "Scenario 2 FAIL: Today's daily log contains template example log entries!"
    }
    if ($dailyContent -match "TEMPLATE_DO_NOT_USE") {
        throw "Scenario 2 FAIL: Today's daily log contains TEMPLATE_DO_NOT_USE marker"
    }

    # Verify project memory file is created and has NO TEMPLATE_DO_NOT_USE warning
    $projectName = Split-Path -Leaf $tmpFresh
    $projectFile = Join-Path $tmpFresh "memory/projects/$projectName.md"
    if (!(Test-Path $projectFile)) {
        throw "Scenario 2 FAIL: Project context file $projectFile was not created"
    }
    $projectContent = Get-Content -Path $projectFile -Raw
    if ($projectContent -match "TEMPLATE_DO_NOT_USE") {
        throw "Scenario 2 FAIL: Project context file contains TEMPLATE_DO_NOT_USE marker"
    }
    # Verify task.md exists and has NO TEMPLATE_DO_NOT_USE warning
    $taskFile = Join-Path $tmpFresh "task.md"
    if (!(Test-Path $taskFile)) {
        throw "Scenario 2 FAIL: task.md was not created"
    }
    $taskContent = Get-Content -Path $taskFile -Raw
    if ($taskContent -match "TEMPLATE_DO_NOT_USE") {
        throw "Scenario 2 FAIL: task.md contains TEMPLATE_DO_NOT_USE marker"
    }

    # Verify Sentry Org/Token statuses are Configured/Not Configured in memory/local_env.md
    $localEnv = Join-Path $tmpFresh "memory/local_env.md"
    if (!(Test-Path $localEnv)) {
        throw "Scenario 2 FAIL: memory/local_env.md was not created"
    }
    $localEnvContent = Get-Content -Path $localEnv -Raw
    if ($localEnvContent -match "TEMPLATE_DO_NOT_USE") {
        throw "Scenario 2 FAIL: local_env.md contains TEMPLATE_DO_NOT_USE marker"
    }
    if ($localEnvContent -match "FILL_ME_IF_USING_SENTRY" -or $localEnvContent -match "\[SENTRY_AUTH_TOKEN\]") {
        throw "Scenario 2 FAIL: local_env.md still contains raw Sentry secrets placeholders"
    }
    if ($localEnvContent -notmatch "Headroom:" -or $localEnvContent -match "\[HEADROOM_STATUS\]") {
        throw "Scenario 2 FAIL: local_env.md is missing resolved Headroom status"
    }
    if (!(Test-Path (Join-Path $tmpFresh ".agents/scripts/scan-secrets.sh")) -or !(Test-Path (Join-Path $tmpFresh ".agents/scripts/scan-secrets.ps1"))) {
        throw "Scenario 2 FAIL: shared secrets scan scripts were not installed"
    }
    if ((Test-Path (Join-Path $tmpFresh ".agents/scripts/test_installer.sh")) -or (Test-Path (Join-Path $tmpFresh ".agents/scripts/validate_manifests.py"))) {
        throw "Scenario 2 FAIL: repository maintenance scripts leaked into target .agents/scripts"
    }

    Write-Host "Scenario 2 Passed." -ForegroundColor Green

    # Scenario 3: Installer on Existing Git repository
    Write-Host "Running Scenario 3: Full scaffolding on existing Git directory..." -ForegroundColor Yellow

    # Initialize Git
    Push-Location $tmpGit
    git init -b main
    git config user.name "Test"
    git config user.email "test@example.com"
    Pop-Location

    & $psCmd -ExecutionPolicy Bypass -File (Join-Path $rootDir "install.ps1") -Target $tmpGit -Force

    if (!(Test-Path (Join-Path $tmpGit ".gitignore"))) {
        throw "Scenario 3 FAIL: .gitignore was not created in Git repository"
    }

    # Check that the baseline block is appended
    $gitignoreContent = Get-Content -Path (Join-Path $tmpGit ".gitignore") -Raw
    if ($gitignoreContent -notmatch "# Antariksh Unified Framework") {
        throw "Scenario 3 FAIL: .gitignore is missing the Antariksh baseline block"
    }
    if ($gitignoreContent -notmatch "(?m)^task\.md$") {
        throw "Scenario 3 FAIL: .gitignore is missing task.md working-memory rule"
    }

    Write-Host "Scenario 3 Passed." -ForegroundColor Green
    Write-Host "=== ALL POWERSHELL INSTALLER TESTS PASSED SUCCESSFULLY ===" -ForegroundColor Green

} finally {
    Cleanup
}
