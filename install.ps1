# install.ps1 -- Antariksh Unified Skill Deployer for Windows
# Usage: .\install.ps1 [-TargetDir <path>] [-Force]

param (
    [string]$TargetDir = ".",
    [switch]$Force
)

$targetPath = Resolve-Path $TargetDir -ErrorAction SilentlyContinue
if ($null -eq $targetPath) {
    $targetPath = [System.IO.Path]::GetFullPath((Join-Path (Get-Location) $TargetDir))
} else {
    $targetPath = $targetPath.Path
}

Write-Host "Target: $targetPath" -ForegroundColor Cyan

# Create Folders
$folders = @("memory", "memory/daily", "memory/projects")
foreach ($f in $folders) {
    $dirPath = Join-Path $targetPath $f
    if (!(Test-Path $dirPath)) {
        New-Item -ItemType Directory -Path $dirPath -Force | Out-Null
        Write-Host "Created folder: $f/" -ForegroundColor Green
    }
}

$scriptDir = $PSScriptRoot

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

# Deploy Rules
$rules = @("AGENTS.md", "CLAUDE.md", ".cursorrules", ".clinerules")
foreach ($r in $rules) {
    $srcPath = Join-Path $scriptDir $r
    $destPath = Join-Path $targetPath $r
    if (!(Test-Path $destPath) -or $Force) {
        Copy-Item -Path $srcPath -Destination $destPath -Force
        Write-Host "Deployed rules: $r" -ForegroundColor Green
    } else {
        Write-Host "Skipped rules: $r (already exists, use -Force to overwrite)" -ForegroundColor Yellow
    }
}

Write-Host "`nAntariksh rules deployed. Memory folders initialized. Code safe." -ForegroundColor Cyan
