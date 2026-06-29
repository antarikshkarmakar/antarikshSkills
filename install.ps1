# install.ps1 -- Antariksh Unified Skill Deployer for Windows
# Usage: .\install.ps1 [-TargetDir <path>] [-Force] [-RulesOnly] [-Hooks]

param (
    [string]$TargetDir = ".",
    [switch]$Force,
    [switch]$RulesOnly,
    [switch]$Hooks
)

$targetPath = Resolve-Path $TargetDir -ErrorAction SilentlyContinue
if ($null -eq $targetPath) {
    if ([System.IO.Path]::IsPathRooted($TargetDir)) {
        $targetPath = [System.IO.Path]::GetFullPath($TargetDir)
    } else {
        $targetPath = [System.IO.Path]::GetFullPath((Join-Path (Get-Location).Path $TargetDir))
    }
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

# Detect the caveman plugin (read-only -- never installs anything; caveman is a
# Claude Code plugin registered in plugins/installed_plugins.json, not a skills/ folder).
$pluginsRegistry = Join-Path $env:USERPROFILE ".claude\plugins\installed_plugins.json"
$cavemanInstallCmd = "Invoke-WebRequest -Uri https://github.com/JuliusBrussee/caveman/raw/main/install.ps1 -OutFile install_caveman.ps1; Get-Content install_caveman.ps1; .\install_caveman.ps1"
$cavemanStatus = "Caveman: not installed -- Philosophy V falls back to manual terse-style instructions. To install: $cavemanInstallCmd"
if ((Test-Path $pluginsRegistry) -and (Select-String -Path $pluginsRegistry -Pattern '"caveman@caveman"' -Quiet)) {
    $cavemanStatus = "Caveman: installed -- Philosophy V and /compact delegate to /caveman and /caveman-compress."
}
Write-Host $cavemanStatus -ForegroundColor Cyan

# Detect the CodeGraph CLI (read-only -- checks PATH only, never installs anything).
$codegraphStatus = "CodeGraph: not found on PATH -- /grok and /audit-arch fall back to graphify/Understand-Anything/manual scan."
if (Get-Command codegraph -ErrorAction SilentlyContinue) {
    $codegraphStatus = "CodeGraph: detected on PATH -- /grok and /audit-arch can delegate to it for call-graph/blast-radius queries."
}
Write-Host $codegraphStatus -ForegroundColor Cyan

# Generate the portable rule files from the single canonical templates/RULESET.md.
# Each tool gets its own header; the body is shared so it can never drift.
# This includes generating SKILL.md for the agent skill system.
$rulesetPath = Join-Path $scriptDir "templates\RULESET.md"
$rulesetBody = Get-Content -Path $rulesetPath -Raw

$ruleHeaders = @{
    "CLAUDE.md"    = "# Claude Code Guidelines (CLAUDE.md)`n`nThis project runs under the **Antariksh Unified Developer Framework**. Adhere to the following rules at all times.`n`n---`n`n"
    "AGENTS.md"    = "# Universal Agent Guidelines (AGENTS.md)`n`nThis repository follows the **Antariksh Unified Developer Framework**. All agents (Gemini, OpenAI, Ollama, DeepSeek, Minimax, Claude, Codex, OpenCode) must adhere to these rules.`n`n---`n`n"
    ".cursorrules" = "# Cursor System Rules (.cursorrules)`n`nYou are an expert developer assistant executing within Cursor. You follow the **Antariksh Unified Developer Framework**.`n`n---`n`n"
    ".clinerules"  = "# Cline/Roo-Code System Rules (.clinerules)`n`nYou are an expert developer assistant executing within Cline or Roo-Code. You follow the **Antariksh Unified Developer Framework**.`n`n---`n`n"
    "GEMINI.md"    = "# Gemini CLI Guidelines (GEMINI.md)`n`nThis project runs under the **Antariksh Unified Developer Framework**. Adhere to the following rules at all times.`n`n---`n`n"
    ".github/copilot-instructions.md" = "# GitHub Copilot Instructions (.github/copilot-instructions.md)`n`nThis project runs under the **Antariksh Unified Developer Framework**. Adhere to the following rules at all times.`n`n---`n`n"
    "SKILL.md"     = "---`nname: antariksh-unified-skill`ndescription: Master developer skill combining planning (grill, align), simplicity (ponytail/karpathy), TDD & diagnosis (mattpocock), token efficiency (caveman), continuous second brain (MEMORY/AGENTS/GLOSSARY/daily/projects/adr/prds), shared language and architecture care, gated PR review, and adversarial verification (duel).`n---`n`n# Antariksh Unified Agent Skill (Master Developer Framework)`n`nYou are a senior-level, pragmatic, and brutally honest developer agent who values simplicity, safety, and token-efficiency above all else. Your thinking and actions are governed by this framework across coding, code reviews, documentation, and repository discovery.`n`n---`n`n"
}

foreach ($ruleFile in $ruleHeaders.Keys) {
    $destPath = Join-Path $targetPath $ruleFile
    $destDir = Split-Path -Parent $destPath
    if (!(Test-Path $destDir)) {
        New-Item -ItemType Directory -Path $destDir -Force | Out-Null
    }
    if (!(Test-Path $destPath) -or $Force) {
        Set-Content -Path $destPath -Value ($ruleHeaders[$ruleFile] + $rulesetBody) -NoNewline
        Write-Host "Generated rules: $ruleFile" -ForegroundColor Green
    } else {
        Write-Host "Skipped rules: $ruleFile (already exists, use -Force to overwrite)" -ForegroundColor Yellow
    }
}

# Generate modular Cursor MDC rules under .cursor/rules/
$cursorRulesDir = Join-Path $targetPath ".cursor\rules"
if (!(Test-Path $cursorRulesDir)) {
    New-Item -ItemType Directory -Path $cursorRulesDir -Force | Out-Null
}

$sections = $rulesetBody -split "(?m)^---\r?$"
if ($sections.Count -ge 4) {
    $sec1 = $sections[0].Trim()
    $sec2 = $sections[1].Trim()
    $sec3 = $sections[2].Trim()
    $sec4 = $sections[3].Trim()

    $coreMdcPath = Join-Path $cursorRulesDir "core.mdc"
    $coreMdcHeader = "---`ndescription: Core developer philosophies, fallback protocols, and Second Brain standards`nglobs: *`n---`n`n"
    $coreMdcBody = "$sec1`n`n---`n`n$sec2`n`n---`n`n$sec4`n"
    if (!(Test-Path $coreMdcPath) -or $Force) {
        Set-Content -Path $coreMdcPath -Value ($coreMdcHeader + $coreMdcBody) -NoNewline
        Write-Host "Generated Cursor MDC: core.mdc" -ForegroundColor Green
    } else {
        Write-Host "Skipped Cursor MDC: core.mdc (already exists, use -Force to overwrite)" -ForegroundColor Yellow
    }

    $commandsMdcPath = Join-Path $cursorRulesDir "commands.mdc"
    $commandsMdcHeader = "---`ndescription: Interactive agent slash commands (/tdd, /diagnose, /align, etc.)`nglobs: *`n---`n`n"
    $commandsMdcBody = "$sec3`n"
    if (!(Test-Path $commandsMdcPath) -or $Force) {
        Set-Content -Path $commandsMdcPath -Value ($commandsMdcHeader + $commandsMdcBody) -NoNewline
        Write-Host "Generated Cursor MDC: commands.mdc" -ForegroundColor Green
    } else {
        Write-Host "Skipped Cursor MDC: commands.mdc (already exists, use -Force to overwrite)" -ForegroundColor Yellow
    }
}

if ($RulesOnly) {
    Write-Host "`nRules and Cursor MDC regenerated from templates/RULESET.md. Skipped memory scaffolding (-RulesOnly)." -ForegroundColor Cyan
    exit 0
}

# Copy the skills/ folder if it exists in the root
$skillsSrc = Join-Path $scriptDir "skills"
$skillsDest = Join-Path $targetPath ".agents\skills"
if (Test-Path $skillsSrc) {
    if (!(Test-Path $skillsDest) -or $Force) {
        if (!(Test-Path (Split-Path -Parent $skillsDest))) {
            New-Item -ItemType Directory -Path (Split-Path -Parent $skillsDest) -Force | Out-Null
        }
        Copy-Item -Path $skillsSrc -Destination $skillsDest -Recurse -Force
        Write-Host "Created folder: .agents/skills/ (modular agent skills)" -ForegroundColor Green
    } else {
        Write-Host "Skipped folder: .agents/skills/ (already exists, use -Force to overwrite)" -ForegroundColor Yellow
    }
}

# Create Folders
$folders = @("memory", "memory/daily", "memory/projects", "memory/adr", "memory/prds")
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
    @{ Src = "templates/GLOSSARY.md"; Dest = "GLOSSARY.md" },
    @{ Src = "templates/inbox.md"; Dest = "inbox.md" },
    @{ Src = "templates/memory/daily/template.md"; Dest = "memory/daily/template.md" },
    @{ Src = "templates/memory/projects/template.md"; Dest = "memory/projects/template.md" },
    @{ Src = "templates/memory/adr/template.md"; Dest = "memory/adr/template.md" },
    @{ Src = "templates/memory/prds/template.md"; Dest = "memory/prds/template.md" },
    @{ Src = "templates/memory/handoff.md"; Dest = "memory/handoff.md" },
    @{ Src = "templates/memory/local_env.md"; Dest = "memory/local_env.md" },
    @{ Src = "templates/INTERFACES.md"; Dest = "INTERFACES.md" }
)

foreach ($t in $templates) {
    $srcPath = Join-Path $scriptDir $t.Src
    $destPath = Join-Path $targetPath $t.Dest
    if (!(Test-Path $destPath) -or $Force) {
        Copy-Item -Path $srcPath -Destination $destPath -Force
        Write-Host "Created file: $($t.Dest)" -ForegroundColor Green

        if ($t.Dest -eq "memory/local_env.md") {
            $skillsLine = if ($detectedSkillNames.Count -gt 0) { "Detected agent skills on this machine: $($detectedSkillNames -join ', ')." } else { "No agent skills detected under $skillsDir." }
            $envContent = Get-Content -Path $destPath -Raw
            $envContent = $envContent -replace "\[GRAPHIFY_STATUS\]", $graphifyStatus
            $envContent = $envContent -replace "\[CODEGRAPH_STATUS\]", $codegraphStatus
            $envContent = $envContent -replace "\[CAVEMAN_STATUS\]", $cavemanStatus
            $envContent = $envContent -replace "\[DETECTED_SKILLS\]", $skillsLine
            Set-Content -Path $destPath -Value $envContent -NoNewline
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

# Optional: Claude Code hooks that mechanically enforce the Second Brain loop
# (SessionStart auto-loads memory, Stop blocks if real edits weren't logged).
# Opt-in only -- this is Claude-Code-specific and touches .claude/settings.json,
# unlike everything else this installer does.
if ($Hooks) {
    $claudeHooksDir = Join-Path $targetPath ".claude\hooks"
    if (!(Test-Path $claudeHooksDir)) {
        New-Item -ItemType Directory -Path $claudeHooksDir -Force | Out-Null
    }

    foreach ($hookScript in @("session-start.ps1", "stop-check.ps1")) {
        $hookSrc = Join-Path $scriptDir "templates\.claude\hooks\$hookScript"
        $hookDest = Join-Path $claudeHooksDir $hookScript
        if (!(Test-Path $hookDest) -or $Force) {
            Copy-Item -Path $hookSrc -Destination $hookDest -Force
            Write-Host "Created file: .claude/hooks/$hookScript" -ForegroundColor Green
        } else {
            Write-Host "Skipped file: .claude/hooks/$hookScript (already exists, use -Force to overwrite)" -ForegroundColor Yellow
        }
    }

    $settingsDest = Join-Path $targetPath ".claude\settings.json"
    $hookConfigs = @{
        "SessionStart" = "powershell.exe -ExecutionPolicy Bypass -File `${CLAUDE_PROJECT_DIR}/.claude/hooks/session-start.ps1"
        "Stop"         = "powershell.exe -ExecutionPolicy Bypass -File `${CLAUDE_PROJECT_DIR}/.claude/hooks/stop-check.ps1"
    }

    if (!(Test-Path $settingsDest)) {
        $settingsObject = [PSCustomObject]@{
            hooks = [PSCustomObject]@{
                SessionStart = @(
                    [PSCustomObject]@{
                        hooks = @(
                            [PSCustomObject]@{
                                type = "command"
                                command = $hookConfigs["SessionStart"]
                                timeout = 30
                            }
                        )
                    }
                )
                Stop = @(
                    [PSCustomObject]@{
                        hooks = @(
                            [PSCustomObject]@{
                                type = "command"
                                command = $hookConfigs["Stop"]
                                timeout = 10
                            }
                        )
                    }
                )
            }
        }
        $settingsObject | ConvertTo-Json -Depth 10 | Set-Content -Path $settingsDest -Force
        Write-Host "Created file: .claude/settings.json" -ForegroundColor Green
    } else {
        $existing = Get-Content -Path $settingsDest -Raw | ConvertFrom-Json

        if (-not ($existing.PSObject.Properties.Name -contains "hooks")) {
            $existing | Add-Member -MemberType NoteProperty -Name "hooks" -Value ([PSCustomObject]@{}) -Force
        }

        foreach ($eventName in @("SessionStart", "Stop")) {
            $cmdPath = $hookConfigs[$eventName]

            if (-not ($existing.hooks.PSObject.Properties.Name -contains $eventName)) {
                $existing.hooks | Add-Member -MemberType NoteProperty -Name $eventName -Value @() -Force
            }

            $alreadyPresent = $false
            foreach ($entry in @($existing.hooks.$eventName)) {
                foreach ($h in @($entry.hooks)) {
                    if ($h.command -eq $cmdPath) { $alreadyPresent = $true }
                }
            }

            if (-not $alreadyPresent) {
                $newEntry = [PSCustomObject]@{
                    hooks = @(
                        [PSCustomObject]@{
                            type = "command"
                            command = $cmdPath
                            timeout = if ($eventName -eq "SessionStart") { 30 } else { 10 }
                        }
                    )
                }
                $existing.hooks.$eventName = @(@($existing.hooks.$eventName) + @($newEntry))
            }
        }

        $existing | ConvertTo-Json -Depth 10 | Set-Content -Path $settingsDest -Force
        Write-Host "Merged PowerShell hooks into existing .claude/settings.json" -ForegroundColor Green
    }

    Write-Host "PowerShell hooks installed successfully." -ForegroundColor Cyan
}

Write-Host "`nAntariksh rules deployed. Memory folders initialized. Code safe." -ForegroundColor Cyan
