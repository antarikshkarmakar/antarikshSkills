# test_installer.ps1 -- Test PowerShell installer behavior.
$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$rootDir = Split-Path -Parent $scriptDir

Write-Host "=== Running Installer Tests (PowerShell) ===" -ForegroundColor Cyan

# Create temp directories
$tempDir = [System.IO.Path]::GetTempPath()
$tmpFresh = Join-Path $tempDir ("fresh_repo_" + [Guid]::NewGuid().ToString().Substring(0,8))
$tmpGit = Join-Path $tempDir ("git_repo_" + [Guid]::NewGuid().ToString().Substring(0,8))
$tmpHooks = Join-Path $tempDir ("hooks_repo_" + [Guid]::NewGuid().ToString().Substring(0,8))

if (!(Test-Path $tmpFresh)) { New-Item -ItemType Directory -Path $tmpFresh | Out-Null }
if (!(Test-Path $tmpGit)) { New-Item -ItemType Directory -Path $tmpGit | Out-Null }
if (!(Test-Path $tmpHooks)) { New-Item -ItemType Directory -Path $tmpHooks | Out-Null }

$psCmd = if (Get-Command pwsh -ErrorAction SilentlyContinue) { "pwsh" } else { "powershell.exe" }

function Cleanup {
    if (Test-Path $tmpFresh) { Remove-Item -Path $tmpFresh -Recurse -Force -ErrorAction SilentlyContinue }
    if (Test-Path $tmpGit) { Remove-Item -Path $tmpGit -Recurse -Force -ErrorAction SilentlyContinue }
    if (Test-Path $tmpHooks) { Remove-Item -Path $tmpHooks -Recurse -Force -ErrorAction SilentlyContinue }
    Write-Host "Temporary test directories cleaned up." -ForegroundColor Cyan
}

function Assert-HookCommandCount {
    param (
        [object]$Settings,
        [string]$EventName,
        [string]$CommandFragment,
        [string]$Label
    )

    $matches = @()
    foreach ($entry in @($Settings.hooks.$EventName)) {
        foreach ($hook in @($entry.hooks)) {
            if ($hook.command -like "*$CommandFragment*") {
                $matches += $hook
            }
        }
    }

    if ($matches.Count -ne 1) {
        throw "Scenario 4 FAIL: Expected exactly one $Label hook command, found $($matches.Count)"
    }
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
    $tmpNested = Join-Path $tmpFresh "nested/fresh/repo&ops"
    & $psCmd -ExecutionPolicy Bypass -File (Join-Path $rootDir "install.ps1") -TargetDir $tmpNested -Force

    if (!(Test-Path (Join-Path $tmpNested "memory")) -or !(Test-Path (Join-Path $tmpNested "memory/daily")) -or !(Test-Path (Join-Path $tmpNested "memory/projects"))) {
        throw "Scenario 2 FAIL: Memory subdirectories were not created"
    }

    # Verify memory/handoff.md is NOT created
    if (Test-Path (Join-Path $tmpNested "memory/handoff.md")) {
        throw "Scenario 2 FAIL: memory/handoff.md was created during installation"
    }

    # Verify today's daily log exists and does NOT contain examples or TEMPLATE_DO_NOT_USE warning
    $today = (Get-Date).ToString("yyyy-MM-dd")
    $dailyFile = Join-Path $tmpNested "memory/daily/$today.md"
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
    $projectName = Split-Path -Leaf $tmpNested
    $projectFile = Join-Path $tmpNested "memory/projects/$projectName.md"
    if (!(Test-Path $projectFile)) {
        throw "Scenario 2 FAIL: Project context file $projectFile was not created"
    }
    $projectContent = Get-Content -Path $projectFile -Raw
    if ($projectContent -match "TEMPLATE_DO_NOT_USE") {
        throw "Scenario 2 FAIL: Project context file contains TEMPLATE_DO_NOT_USE marker"
    }
    if ($projectContent -notmatch "# Project Context: $([regex]::Escape($projectName))") {
        throw "Scenario 2 FAIL: Project context file did not preserve escaped project name"
    }
    # Verify task.md exists and has NO TEMPLATE_DO_NOT_USE warning
    $taskFile = Join-Path $tmpNested "task.md"
    if (!(Test-Path $taskFile)) {
        throw "Scenario 2 FAIL: task.md was not created"
    }
    $taskContent = Get-Content -Path $taskFile -Raw
    if ($taskContent -match "TEMPLATE_DO_NOT_USE") {
        throw "Scenario 2 FAIL: task.md contains TEMPLATE_DO_NOT_USE marker"
    }

    # Verify skill observation backlog exists with the public/internal safety fields
    $skillObservations = Join-Path $tmpNested "memory/skill-observations.md"
    if (!(Test-Path $skillObservations)) {
        throw "Scenario 2 FAIL: memory/skill-observations.md was not created"
    }
    $skillObservationContent = Get-Content -Path $skillObservations -Raw
    if ($skillObservationContent -notmatch "Suggested improvement" -or $skillObservationContent -notmatch "public-safe" -or $skillObservationContent -notmatch "internal" -or $skillObservationContent -notmatch "memory/skill-observations.archive.md") {
        throw "Scenario 2 FAIL: skill-observations.md is missing observation safety/archive fields"
    }

    # Verify Sentry Org/Token statuses are Configured/Not Configured in memory/local_env.md
    $localEnv = Join-Path $tmpNested "memory/local_env.md"
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
    if ($localEnvContent -match "\[GRAPHIFY_STATUS\]" -or $localEnvContent -match "\[CODEGRAPH_STATUS\]" -or $localEnvContent -match "\[CAVEMAN_STATUS\]" -or $localEnvContent -match "\[SENTRY_STATUS\]" -or $localEnvContent -match "\[DETECTED_SKILLS\]") {
        throw "Scenario 2 FAIL: local_env.md contains unresolved status placeholders"
    }
    if (!(Test-Path (Join-Path $tmpNested ".agents/scripts/scan-secrets.sh")) -or !(Test-Path (Join-Path $tmpNested ".agents/scripts/scan-secrets.ps1"))) {
        throw "Scenario 2 FAIL: shared secrets scan scripts were not installed"
    }
    if ((Test-Path (Join-Path $tmpNested ".agents/scripts/test_installer.sh")) -or (Test-Path (Join-Path $tmpNested ".agents/scripts/validate_manifests.py"))) {
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

    # Scenario 4: Optional hooks install path
    Write-Host "Running Scenario 4: Optional hooks installation..." -ForegroundColor Yellow
    & $psCmd -ExecutionPolicy Bypass -File (Join-Path $rootDir "install.ps1") -TargetDir $tmpHooks -Force -Hooks

    foreach ($requiredFile in @(
        ".claude/hooks/session-start.ps1",
        ".claude/hooks/stop-check.ps1",
        ".codex/hooks/session-start.ps1",
        ".codex/hooks/stop-check.ps1",
        ".claude/settings.json",
        ".codex/hooks.json"
    )) {
        if (!(Test-Path (Join-Path $tmpHooks $requiredFile))) {
            throw "Scenario 4 FAIL: Missing hook artifact $requiredFile"
        }
    }

    $claudeSettings = Get-Content -Path (Join-Path $tmpHooks ".claude/settings.json") -Raw | ConvertFrom-Json
    $codexSettings = Get-Content -Path (Join-Path $tmpHooks ".codex/hooks.json") -Raw | ConvertFrom-Json

    Assert-HookCommandCount -Settings $claudeSettings -EventName "SessionStart" -CommandFragment ".claude/hooks/session-start.ps1" -Label "Claude SessionStart"
    Assert-HookCommandCount -Settings $claudeSettings -EventName "Stop" -CommandFragment ".claude/hooks/stop-check.ps1" -Label "Claude Stop"
    Assert-HookCommandCount -Settings $codexSettings -EventName "SessionStart" -CommandFragment ".codex/hooks/session-start.ps1" -Label "Codex SessionStart"
    Assert-HookCommandCount -Settings $codexSettings -EventName "Stop" -CommandFragment ".codex/hooks/stop-check.ps1" -Label "Codex Stop"

    & $psCmd -ExecutionPolicy Bypass -File (Join-Path $rootDir "install.ps1") -TargetDir $tmpHooks -Hooks

    $claudeSettings = Get-Content -Path (Join-Path $tmpHooks ".claude/settings.json") -Raw | ConvertFrom-Json
    $codexSettings = Get-Content -Path (Join-Path $tmpHooks ".codex/hooks.json") -Raw | ConvertFrom-Json

    Assert-HookCommandCount -Settings $claudeSettings -EventName "SessionStart" -CommandFragment ".claude/hooks/session-start.ps1" -Label "Claude SessionStart after rerun"
    Assert-HookCommandCount -Settings $claudeSettings -EventName "Stop" -CommandFragment ".claude/hooks/stop-check.ps1" -Label "Claude Stop after rerun"
    Assert-HookCommandCount -Settings $codexSettings -EventName "SessionStart" -CommandFragment ".codex/hooks/session-start.ps1" -Label "Codex SessionStart after rerun"
    Assert-HookCommandCount -Settings $codexSettings -EventName "Stop" -CommandFragment ".codex/hooks/stop-check.ps1" -Label "Codex Stop after rerun"

    Write-Host "Scenario 4 Passed." -ForegroundColor Green
    Write-Host "=== ALL POWERSHELL INSTALLER TESTS PASSED SUCCESSFULLY ===" -ForegroundColor Green

} finally {
    Cleanup
}
