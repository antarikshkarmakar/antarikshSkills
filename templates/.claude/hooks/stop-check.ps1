# stop-check.ps1 -- Blocks ending the turn if source files were edited but daily log wasn't updated
# (RULESET.md section 4, End-of-Session Loop).
$projectDir = if ($env:CLAUDE_PROJECT_DIR) { $env:CLAUDE_PROJECT_DIR } else { $env:CODEX_PROJECT_DIR }
if ($null -eq $projectDir) { $projectDir = "." }

# Verify if it is a git repo
$gitCheck = git -C $projectDir rev-parse --is-inside-work-tree 2>$null
if ($gitCheck -ne "true") { exit 0 }

$today = (Get-Date).ToString("yyyy-MM-dd")
$dailyLog = Join-Path $projectDir "memory/daily/$today.md"

# Get changed files outside memory/
$gitStatus = git -C $projectDir status --porcelain 2>$null
if ($null -eq $gitStatus) { exit 0 }

$changedFiles = @()
foreach ($line in $gitStatus) {
    $parts = $line.Trim() -split "\s+"
    if ($parts.Length -ge 2) {
        $file = $parts[1]
        # Ignore memory/ files
        if ($file -notmatch "^(memory/|MEMORY\.md$|GLOSSARY\.md$|inbox\.md$)") {
            $changedFiles += Join-Path $projectDir $file
        }
    }
}

if ($changedFiles.Count -eq 0) { exit 0 }

if (!(Test-Path $dailyLog)) {
    $reason = "Source files changed this session but memory/daily/$today.md doesn't exist yet. Per the End-of-Session Loop, create it and summarize what got done before stopping."
    $json = @{
        decision = "block"
        reason = $reason
        hookSpecificOutput = @{
            hookEventName = "Stop"
            additionalContext = $reason
        }
    } | ConvertTo-Json -Compress
    Write-Output $json
    exit 2
}

# Check if any changed file is newer than the daily log
$stale = $false
$dailyLogTime = (Get-Item $dailyLog).LastWriteTime

foreach ($f in $changedFiles) {
    if (Test-Path $f) {
        $fTime = (Get-Item $f).LastWriteTime
        if ($fTime -gt $dailyLogTime) {
            $stale = $true
            break
        }
    }
}

if ($stale) {
    $reason = "Source files were edited more recently than memory/daily/$today.md. Per the End-of-Session Loop, update the daily log (and MEMORY.md if relevant) before stopping."
    $json = @{
        decision = "block"
        reason = $reason
        hookSpecificOutput = @{
            hookEventName = "Stop"
            additionalContext = $reason
        }
    } | ConvertTo-Json -Compress
    Write-Output $json
    exit 2
}

exit 0
