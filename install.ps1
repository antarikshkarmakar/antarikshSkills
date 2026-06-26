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

# Create Directories
$memDir = Join-Path $targetPath "memory"
if (!(Test-Path $memDir)) {
    New-Item -ItemType Directory -Path $memDir -Force | Out-Null
    Write-Host "Created folder: memory/" -ForegroundColor Green
}

# Copy Templates
$scriptDir = $PSScriptRoot
$templates = @(
    @{ Src = "templates/memory/IDENTITY.md"; Dest = "memory/IDENTITY.md" },
    @{ Src = "templates/memory/SEMANTIC.md"; Dest = "memory/SEMANTIC.md" },
    @{ Src = "templates/memory/EPISODIC.md"; Dest = "memory/EPISODIC.md" },
    @{ Src = "templates/memory/WORKING.md"; Dest = "memory/WORKING.md" },
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
