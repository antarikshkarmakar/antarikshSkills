# install.ps1 -- Antariksh Unified Skill Deployer for Windows
# Usage: .\install.ps1 [-TargetDir <path>] [-Force] [-RulesOnly]

param (
    [string]$TargetDir = ".",
    [switch]$Force,
    [switch]$RulesOnly
)

$targetPath = Resolve-Path $TargetDir -ErrorAction SilentlyContinue
if ($null -eq $targetPath) {
    $targetPath = [System.IO.Path]::GetFullPath((Join-Path (Get-Location) $TargetDir))
} else {
    $targetPath = $targetPath.Path
}

Write-Host "Target: $targetPath" -ForegroundColor Cyan

# Create target directory if it doesn't exist
if (!(Test-Path $targetPath)) {
    New-Item -ItemType Directory -Path $targetPath -Force | Out-Null
    Write-Host "Created target directory: $targetPath" -ForegroundColor Green
}

$scriptDir = $PSScriptRoot

# Detect installed agent skills (read-only -- never copies or installs anything)
$skillsDir = Join-Path $env:USERPROFILE ".claude\skills"
$detectedSkillNames = @()
$graphifyStatus = "Graphify: not found under $skillsDir -- /grok will fall back to a manual directory/stack scan."
if (Test-Path $skillsDir) {
    $detectedSkillNames = Get-ChildItem -Path $skillsDir -Directory -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name
    $graphifySkillFile = Join-Path $skillsDir "graphify\SKILL.md"
    if (Test-Path $graphifySkillFile) {
        $versionFile = Join-Path $skillsDir "graphify\.graphify_version"
        $version = if (Test-Path $versionFile) { (Get-Content $versionFile -Raw).Trim() } else { "unknown version" }
        $graphifyStatus = "Graphify: detected ($version) at $graphifySkillFile -- /grok will use it to build the repo's knowledge graph."
    }
}
Write-Host $graphifyStatus -ForegroundColor Cyan
if ($detectedSkillNames.Count -gt 0) {
    Write-Host "Detected agent skills: $($detectedSkillNames -join ', ')" -ForegroundColor Cyan
}

# Generate the 4 portable rule files from the single canonical templates/RULESET.md.
# Each tool gets its own header; the body is shared so it can never drift.
# SKILL.md is NOT generated here -- it's the hand-maintained, richer master skill
# definition for this framework itself, not a per-project file the installer deploys.
$rulesetPath = Join-Path $scriptDir "templates\RULESET.md"
$rulesetBody = Get-Content -Path $rulesetPath -Raw

$ruleHeaders = @{
    "CLAUDE.md"    = "# Claude Code Guidelines (CLAUDE.md)`n`nThis project runs under the **Antariksh Unified Developer Framework**. Adhere to the following rules at all times.`n`n---`n`n"
    "AGENTS.md"    = "# Universal Agent Guidelines (AGENTS.md)`n`nThis repository follows the **Antariksh Unified Developer Framework**. All agents (Gemini, OpenAI, Ollama, DeepSeek, Minimax, Claude, Codex, OpenCode) must adhere to these rules.`n`n---`n`n"
    ".cursorrules" = "# Cursor System Rules (.cursorrules)`n`nYou are an expert developer assistant executing within Cursor. You follow the **Antariksh Unified Developer Framework**.`n`n---`n`n"
    ".clinerules"  = "# Cline/Roo-Code System Rules (.clinerules)`n`nYou are an expert developer assistant executing within Cline or Roo-Code. You follow the **Antariksh Unified Developer Framework**.`n`n---`n`n"
}

foreach ($ruleFile in $ruleHeaders.Keys) {
    $destPath = Join-Path $targetPath $ruleFile
    if (!(Test-Path $destPath) -or $Force) {
        Set-Content -Path $destPath -Value ($ruleHeaders[$ruleFile] + $rulesetBody) -NoNewline
        Write-Host "Generated rules: $ruleFile" -ForegroundColor Green
    } else {
        Write-Host "Skipped rules: $ruleFile (already exists, use -Force to overwrite)" -ForegroundColor Yellow
    }
}

if ($RulesOnly) {
    Write-Host "`nRules regenerated from templates/RULESET.md. Skipped memory scaffolding (-RulesOnly)." -ForegroundColor Cyan
    exit 0
}

# Create Folders
$folders = @("memory", "memory/daily", "memory/projects")
foreach ($f in $folders) {
    $dirPath = Join-Path $targetPath $f
    if (!(Test-Path $dirPath)) {
        New-Item -ItemType Directory -Path $dirPath -Force | Out-Null
        Write-Host "Created folder: $f/" -ForegroundColor Green
    }
}

# Copy Templates
$templates = @(
    @{ Src = "templates/MEMORY.md"; Dest = "MEMORY.md" },
    @{ Src = "templates/inbox.md"; Dest = "inbox.md" },
    @{ Src = "templates/memory/daily/template.md"; Dest = "memory/daily/template.md" },
    @{ Src = "templates/memory/projects/template.md"; Dest = "memory/projects/template.md" },
    @{ Src = "templates/memory/handoff.md"; Dest = "memory/handoff.md" },
    @{ Src = "templates/INTERFACES.md"; Dest = "INTERFACES.md" }
)

foreach ($t in $templates) {
    $srcPath = Join-Path $scriptDir $t.Src
    $destPath = Join-Path $targetPath $t.Dest
    if (!(Test-Path $destPath) -or $Force) {
        Copy-Item -Path $srcPath -Destination $destPath -Force
        Write-Host "Created file: $($t.Dest)" -ForegroundColor Green

        if ($t.Dest -eq "MEMORY.md") {
            $skillsLine = if ($detectedSkillNames.Count -gt 0) { "Detected agent skills on this machine: $($detectedSkillNames -join ', ')." } else { "No agent skills detected under $skillsDir." }
            $memContent = Get-Content -Path $destPath -Raw
            $memContent = $memContent -replace "\[GRAPHIFY_STATUS\]", $graphifyStatus
            $memContent = $memContent -replace "\[DETECTED_SKILLS\]", $skillsLine
            Set-Content -Path $destPath -Value $memContent -NoNewline
        }
    } else {
        Write-Host "Skipped file: $($t.Dest) (already exists, use -Force to overwrite)" -ForegroundColor Yellow
    }
}

# Create Today's Daily Log if it doesn't exist
$today = (Get-Date).ToString("yyyy-MM-dd")
$dailyLogDest = Join-Path $targetPath "memory/daily/$today.md"
if (!(Test-Path $dailyLogDest)) {
    $srcDailyTemplate = Join-Path $scriptDir "templates/memory/daily/template.md"
    $content = Get-Content -Path $srcDailyTemplate -Raw
    $content = $content -replace "\[YYYY-MM-DD\]", $today
    Set-Content -Path $dailyLogDest -Value $content -Force
    Write-Host "Created today's daily log: memory/daily/$today.md" -ForegroundColor Green
}

# Ensure .gitignore covers secrets/junk (Philosophy VI) -- never overwrites, only
# creates if missing or appends the baseline block if an existing file lacks it.
$gitignoreTemplate = Join-Path $scriptDir "templates/.gitignore"
$gitignoreDest = Join-Path $targetPath ".gitignore"
$gitignoreMarker = "# Antariksh Unified Framework"
if (!(Test-Path $gitignoreDest)) {
    Copy-Item -Path $gitignoreTemplate -Destination $gitignoreDest -Force
    Write-Host "Created file: .gitignore" -ForegroundColor Green
} elseif ((Get-Content -Path $gitignoreDest -Raw) -notmatch [regex]::Escape($gitignoreMarker)) {
    Add-Content -Path $gitignoreDest -Value ("`n" + (Get-Content -Path $gitignoreTemplate -Raw))
    Write-Host "Appended baseline secrets/junk rules to existing .gitignore" -ForegroundColor Green
} else {
    Write-Host "Skipped .gitignore (baseline rules already present)" -ForegroundColor Yellow
}

Write-Host "`nAntariksh rules deployed. Memory folders initialized. Code safe." -ForegroundColor Cyan
