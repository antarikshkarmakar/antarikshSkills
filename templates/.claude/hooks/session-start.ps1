# session-start.ps1 -- Auto-loads the Second Brain into context on session start/resume
# (RULESET.md section 4, Start-of-Session Loop steps 1-6).
$projectDir = if ($env:CLAUDE_PROJECT_DIR) { $env:CLAUDE_PROJECT_DIR } else { $env:CODEX_PROJECT_DIR }
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

$taskFile = Join-Path $projectDir "task.md"
if (Test-Path $taskFile) {
    Write-Output ""
    Write-Output "### task.md (Active Checklist)"
    Get-Content -Path $taskFile -Raw
}

$localEnv = Join-Path $projectDir "memory/local_env.md"
if (Test-Path $localEnv) {
    Write-Output ""
    Write-Output "### memory/local_env.md"
    Get-Content -Path $localEnv -Raw
}

$agents = Join-Path $projectDir "AGENTS.md"
if (Test-Path $agents) {
    Write-Output ""
    Write-Output "### AGENTS.md"
    Get-Content -Path $agents -Raw
}

$glossary = Join-Path $projectDir "GLOSSARY.md"
if (Test-Path $glossary) {
    Write-Output ""
    Write-Output "### GLOSSARY.md"
    Get-Content -Path $glossary -Raw
}

# Project context validation check
$projectsDir = Join-Path $projectDir "memory/projects"
$projectContextFile = $null
if (Test-Path $projectsDir) {
    $files = Get-ChildItem -Path $projectsDir -Filter "*.md" | Where-Object { $_.Name -ne "template.md" }
    if ($files.Count -gt 0) {
        $targetProjectName = Split-Path -Leaf $projectDir
        $match = $files | Where-Object { $_.BaseName -eq $targetProjectName }
        $projectContextFile = if ($null -ne $match) { $match.FullName } else { $files[0].FullName }
    }
}

if ($null -ne $projectContextFile -and (Test-Path $projectContextFile)) {
    Write-Output ""
    Write-Output "### memory/projects/$($projectContextFile | Split-Path -Leaf)"
    Get-Content -Path $projectContextFile -Raw
} else {
    Write-Output ""
    Write-Output "### Context Validation Warning"
    Write-Output "WARNING: memory/projects/ context file not found! You must alert the user and run /ak-grok to build the repository context before coding."
}

# Load last 5 daily logs (sorted, last 5)
$dailyDir = Join-Path $projectDir "memory/daily"
if (Test-Path $dailyDir) {
    $logs = Get-ChildItem -Path $dailyDir -Filter "*.md" | Where-Object { $_.Name -ne "template.md" } | Sort-Object Name | Select-Object -Last 5
    if ($logs.Count -gt 0) {
        Write-Output ""
        Write-Output "### Recent Daily Logs (last 5 entries)"
        foreach ($log in $logs) {
            Write-Output ""
            Write-Output "#### memory/daily/$($log.Name)"
            Get-Content -Path $log.FullName -Raw
        }
    }
}

exit 0
