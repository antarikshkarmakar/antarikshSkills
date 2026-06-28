# session-start.ps1 -- Auto-loads the Second Brain into context on session start/resume
# (RULESET.md section 4, Start-of-Session Loop steps 1-3).
$projectDir = $env:CLAUDE_PROJECT_DIR
if ($null -eq $projectDir) { $projectDir = "." }

Write-Output "## Second Brain (auto-loaded by SessionStart hook)"

$handoff = Join-Path $projectDir "memory/handoff.md"
if (Test-Path $handoff) {
    Write-Output ""
    Write-Output "### memory/handoff.md (previous session's handoff -- read, then clear it once acted on)"
    Get-Content -Path $handoff -Raw
}

$memoryFile = Join-Path $projectDir "MEMORY.md"
if (Test-Path $memoryFile) {
    Write-Output ""
    Write-Output "### MEMORY.md"
    Get-Content -Path $memoryFile -Raw
}

$glossary = Join-Path $projectDir "GLOSSARY.md"
if (Test-Path $glossary) {
    Write-Output ""
    Write-Output "### GLOSSARY.md"
    Get-Content -Path $glossary -Raw
}

exit 0
