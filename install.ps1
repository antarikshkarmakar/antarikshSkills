# install.ps1 -- Antariksh Unified Skill Deployer for Windows
# Usage: .\install.ps1 [-TargetDir <path>] [-Force] [-RulesOnly] [-Hooks] [-InstallOptional]

param (
    [string]$TargetDir = ".",
    [switch]$Force,
    [switch]$RulesOnly,
    [switch]$Hooks,
    [switch]$InstallOptional
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

# Detect installed agent skills and optional accelerators. By default this is
# read-only. -InstallOptional can install the small set with known safe commands.
$skillsDir = Join-Path $env:USERPROFILE ".claude/skills"
$pluginsRegistry = Join-Path $env:USERPROFILE ".claude/plugins/installed_plugins.json"
$detectedSkillNames = @()
$graphifyInstalled = $false
$cavemanInstalled = $false
$codegraphInstalled = $false
$sentryInstalled = $false
$headroomInstalled = $false
$pythonCmd = $null
$optionalInstallDryRun = $env:ANTARIKSH_INSTALL_OPTIONAL_DRY_RUN -in @("1", "true", "TRUE")

function Get-PythonCommand {
    foreach ($cmd in @("python", "python3")) {
        if (Get-Command $cmd -ErrorAction SilentlyContinue) {
            return $cmd
        }
    }
    return $null
}

function Test-CommandRuns {
    param(
        [string]$Command,
        [string[]]$Arguments
    )

    $cmd = Get-Command $Command -ErrorAction SilentlyContinue
    if (-not $cmd) { return $false }
    & $cmd.Source @Arguments *> $null
    return $LASTEXITCODE -eq 0
}

function Test-PythonVirtualEnv {
    if ($env:VIRTUAL_ENV) {
        return $true
    }
    if (-not $script:pythonCmd) {
        return $false
    }
    & $script:pythonCmd -c "import sys; raise SystemExit(0 if sys.prefix != getattr(sys, 'base_prefix', sys.prefix) else 1)" *> $null
    return $LASTEXITCODE -eq 0
}

function Get-PythonScriptsPath {
    if (-not $script:pythonCmd) {
        return $null
    }
    $scriptsPath = (& $script:pythonCmd -c "import sysconfig; print(sysconfig.get_path('scripts') or '')" 2>$null | Select-Object -First 1)
    if ($scriptsPath) {
        return $scriptsPath
    }
    return $null
}

function Get-GraphifyCommand {
    $cmd = Get-Command graphify -ErrorAction SilentlyContinue
    if ($cmd) {
        & $cmd.Source --help *> $null
        if ($LASTEXITCODE -eq 0) {
            return $cmd.Source
        }
    }

    $candidateRoots = @((Join-Path $HOME ".local/bin"))
    if ($script:pythonCmd) {
        $scriptsPath = Get-PythonScriptsPath
        if ($scriptsPath) {
            $candidateRoots += $scriptsPath
        }
        $userBase = (& $script:pythonCmd -m site --user-base 2>$null | Select-Object -First 1)
        if ($userBase) {
            $candidateRoots += (Join-Path $userBase "Scripts")
            $candidateRoots += (Join-Path $userBase "bin")
        }
    }

    foreach ($root in ($candidateRoots | Where-Object { $_ } | Select-Object -Unique)) {
        foreach ($candidate in @(
            (Join-Path $root "graphify.exe"),
            (Join-Path $root "graphify.cmd"),
            (Join-Path $root "graphify")
        )) {
            if (Test-Path $candidate) {
                & $candidate --help *> $null
                if ($LASTEXITCODE -eq 0) {
                    return $candidate
                }
            }
        }
    }

    return $null
}

function Update-OptionalAcceleratorStatus {
    $script:detectedSkillNames = @()
    $script:graphifyInstalled = $false
    $script:cavemanInstalled = $false
    $script:codegraphInstalled = $false
    $script:sentryInstalled = $false
    $script:headroomInstalled = $false
    $script:graphifyStatus = "Graphify: not found under $skillsDir and no graphify CLI detected -- /grok will fall back to a manual directory/stack scan."

    if (Test-Path $skillsDir) {
        $script:detectedSkillNames = Get-ChildItem -Path $skillsDir -Directory -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name
    }

    $graphifySkillFile = Join-Path $skillsDir "graphify/SKILL.md"
    if (Test-Path $graphifySkillFile) {
        $versionFile = Join-Path $skillsDir "graphify/.graphify_version"
        $version = if (Test-Path $versionFile) { (Get-Content $versionFile -Raw).Trim() } else { "unknown version" }
        $script:graphifyStatus = "Graphify: detected ($version) at $graphifySkillFile -- /grok will use it to build the repo's knowledge graph."
        $script:graphifyInstalled = $true
    } else {
        $graphifyCommand = Get-GraphifyCommand
        if ($graphifyCommand) {
            $script:graphifyStatus = "Graphify: detected at $graphifyCommand -- /grok can use it even without a Claude skill folder."
            $script:graphifyInstalled = $true
        }
    }

    $script:cavemanStatus = "Caveman: not installed -- Philosophy V falls back to manual terse-style instructions. Run with -InstallOptional to install supported optional accelerators after confirmation."
    if ((Test-Path $pluginsRegistry) -and (Select-String -Path $pluginsRegistry -Pattern '"caveman@caveman"' -Quiet)) {
        $script:cavemanStatus = "Caveman: installed -- Philosophy V and /compact delegate to /caveman and /caveman-compress."
        $script:cavemanInstalled = $true
    }

    $script:codegraphStatus = "CodeGraph: not found on PATH -- /grok and /audit-arch fall back to graphify/Understand-Anything/manual scan."
    if (Test-CommandRuns "codegraph" @("--version")) {
        $script:codegraphStatus = "CodeGraph: detected on PATH -- /grok and /audit-arch can delegate to it for call-graph/blast-radius queries."
        $script:codegraphInstalled = $true
    }

    $script:sentryStatus = "Sentry: not found -- /diagnose falls back to manual reproduction script or log-tracing."
    if ((Test-CommandRuns "sentry" @("--version")) -or (Test-CommandRuns "sentry-cli" @("--version"))) {
        $script:sentryStatus = "Sentry: detected on PATH -- /diagnose can pull telemetry and crash traces directly using the CLI or REST API."
        $script:sentryInstalled = $true
    }

    $script:headroomStatus = "Headroom: not found on PATH -- /ak-headroom and Cache Optimization fall back to uncompressed context."
    if (Test-CommandRuns "headroom" @("--version")) {
        $script:headroomStatus = "Headroom: detected on PATH -- /ak-headroom and Cache Optimization can delegate to it for reversible compression."
        $script:headroomInstalled = $true
    }
}

function Confirm-OptionalInstall {
    param([string]$Name)

    if ($optionalInstallDryRun) {
        return $true
    }

    $answer = Read-Host "Install optional accelerator $Name now? This downloads third-party code. Review DEPENDENCIES.md first. [y/N]"
    return $answer -match "^(y|yes)$"
}

function Install-GraphifyOptional {
    if ($script:graphifyInstalled) { return }

    if (Test-CommandRuns "uv" @("--version")) {
        if (-not (Confirm-OptionalInstall "Graphify (uv tool package graphifyy + graphify install)")) {
            Write-Host "Skipped optional accelerator: Graphify" -ForegroundColor Yellow
            return
        }
        if ($optionalInstallDryRun) {
            Write-Host "DRY RUN: would run 'uv tool install graphifyy' then 'graphify install'" -ForegroundColor Cyan
            return
        }
        & uv tool install graphifyy
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Graphify optional install failed. Continue with manual /ak-grok fallback." -ForegroundColor Yellow
            return
        }
    } elseif (Test-CommandRuns "pipx" @("--version")) {
        if (-not (Confirm-OptionalInstall "Graphify (pipx package graphifyy + graphify install)")) {
            Write-Host "Skipped optional accelerator: Graphify" -ForegroundColor Yellow
            return
        }
        if ($optionalInstallDryRun) {
            Write-Host "DRY RUN: would run 'pipx install graphifyy' then 'graphify install'" -ForegroundColor Cyan
            return
        }
        & pipx install graphifyy
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Graphify optional install failed. Continue with manual /ak-grok fallback." -ForegroundColor Yellow
            return
        }
    } else {
        $script:pythonCmd = Get-PythonCommand
        if (-not $script:pythonCmd) {
            Write-Host "Graphify optional install skipped: uv, pipx, and python/python3 not found. See DEPENDENCIES.md." -ForegroundColor Yellow
            return
        }

        & $script:pythonCmd -m pip --version *> $null
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Graphify optional install skipped: pip is not available for $script:pythonCmd. See DEPENDENCIES.md." -ForegroundColor Yellow
            return
        }

        if (-not (Confirm-OptionalInstall "Graphify (python package graphifyy)")) {
            Write-Host "Skipped optional accelerator: Graphify" -ForegroundColor Yellow
            return
        }

        if (Test-PythonVirtualEnv) {
            if ($optionalInstallDryRun) {
                Write-Host "DRY RUN: would run '$script:pythonCmd -m pip install graphifyy' then 'graphify install'" -ForegroundColor Cyan
                return
            }
            & $script:pythonCmd -m pip install graphifyy
        } else {
            if ($optionalInstallDryRun) {
                Write-Host "DRY RUN: would run '$script:pythonCmd -m pip install --user graphifyy' then 'graphify install'" -ForegroundColor Cyan
                return
            }
            & $script:pythonCmd -m pip install --user graphifyy
        }
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Graphify optional install failed. Continue with manual /ak-grok fallback." -ForegroundColor Yellow
            return
        }
    }

    $graphifyCommand = Get-GraphifyCommand
    if ($graphifyCommand) {
        & $graphifyCommand install
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Graphify package installed, but skill registration failed. Run 'graphify install' after review." -ForegroundColor Yellow
        }
    } else {
        Write-Host "Graphify package installed, but the graphify CLI is not on PATH. Run 'uv tool update-shell' or 'pipx ensurepath' if applicable, then run 'graphify install'." -ForegroundColor Yellow
    }
}

function Install-CavemanOptional {
    if ($script:cavemanInstalled) { return }

    if (-not (Get-Command claude -ErrorAction SilentlyContinue)) {
        Write-Host "Caveman optional install skipped: claude CLI not found. See DEPENDENCIES.md." -ForegroundColor Yellow
        return
    }

    if (-not (Confirm-OptionalInstall "Caveman Claude Code plugin")) {
        Write-Host "Skipped optional accelerator: Caveman" -ForegroundColor Yellow
        return
    }

    if ($optionalInstallDryRun) {
        Write-Host "DRY RUN: would run 'claude plugin marketplace add JuliusBrussee/caveman' and 'claude plugin install caveman@caveman'" -ForegroundColor Cyan
        return
    }

    & claude plugin marketplace add JuliusBrussee/caveman 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Caveman marketplace may already be registered; continuing." -ForegroundColor Yellow
    }
    & claude plugin install caveman@caveman
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Caveman optional install failed. Continue with manual terse-style fallback." -ForegroundColor Yellow
    }
}

function Install-CodeGraphOptional {
    if ($script:codegraphInstalled) { return }

    if (-not (Test-CommandRuns "npm" @("--version"))) {
        Write-Host "CodeGraph optional install skipped: npm not found. See DEPENDENCIES.md." -ForegroundColor Yellow
        return
    }

    if (-not (Confirm-OptionalInstall "CodeGraph (npm package @colbymchenry/codegraph + codegraph install)")) {
        Write-Host "Skipped optional accelerator: CodeGraph" -ForegroundColor Yellow
        return
    }

    if ($optionalInstallDryRun) {
        Write-Host "DRY RUN: would run 'npm install -g @colbymchenry/codegraph' then 'codegraph install'" -ForegroundColor Cyan
        return
    }

    & npm install -g "@colbymchenry/codegraph"
    if ($LASTEXITCODE -ne 0) {
        Write-Host "CodeGraph optional install failed. Continue with manual /ak-grok fallback." -ForegroundColor Yellow
        return
    }

    if (Test-CommandRuns "codegraph" @("--version")) {
        & codegraph install
        if ($LASTEXITCODE -ne 0) {
            Write-Host "CodeGraph CLI installed, but agent registration failed. Run 'codegraph install' after review." -ForegroundColor Yellow
        }
    } else {
        Write-Host "CodeGraph package installed, but codegraph is not on PATH. Add the npm global bin directory to PATH, then run 'codegraph install'." -ForegroundColor Yellow
    }
}

function Install-SentryOptional {
    if ($script:sentryInstalled) { return }

    if (-not (Test-CommandRuns "npm" @("--version"))) {
        Write-Host "Sentry CLI optional install skipped: npm not found. See DEPENDENCIES.md." -ForegroundColor Yellow
        return
    }

    if (-not (Confirm-OptionalInstall "Sentry CLI (npm package sentry; auth remains manual)")) {
        Write-Host "Skipped optional accelerator: Sentry CLI" -ForegroundColor Yellow
        return
    }

    if ($optionalInstallDryRun) {
        Write-Host "DRY RUN: would run 'npm install -g sentry'" -ForegroundColor Cyan
        return
    }

    & npm install -g sentry
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Sentry CLI optional install failed. Continue with manual /ak-diagnose fallback." -ForegroundColor Yellow
        return
    }
    Write-Host "Sentry CLI installed. Run 'sentry auth login' when you want telemetry-backed diagnosis." -ForegroundColor Cyan
}

function Install-HeadroomOptional {
    if ($script:headroomInstalled) { return }

    if (Test-CommandRuns "uv" @("--version")) {
        if (-not (Confirm-OptionalInstall "Headroom CLI (uv tool package headroom-ai[all])")) {
            Write-Host "Skipped optional accelerator: Headroom" -ForegroundColor Yellow
            return
        }

        if ($optionalInstallDryRun) {
            Write-Host "DRY RUN: would run 'uv tool install `"headroom-ai[all]`"'" -ForegroundColor Cyan
            return
        }

        & uv tool install "headroom-ai[all]"
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Headroom optional install failed. Continue with uncompressed context fallback." -ForegroundColor Yellow
            return
        }
        Write-Host "Headroom CLI installed. Run 'uv tool update-shell' if headroom is not on PATH, then /ak-headroom for MCP/proxy setup." -ForegroundColor Cyan
        return
    }

    if (Test-CommandRuns "pipx" @("--version")) {
        if (-not (Confirm-OptionalInstall "Headroom CLI (pipx package headroom-ai[all])")) {
            Write-Host "Skipped optional accelerator: Headroom" -ForegroundColor Yellow
            return
        }

        if ($optionalInstallDryRun) {
            Write-Host "DRY RUN: would run 'pipx install `"headroom-ai[all]`"'" -ForegroundColor Cyan
            return
        }

        & pipx install "headroom-ai[all]"
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Headroom optional install failed. Continue with uncompressed context fallback." -ForegroundColor Yellow
            return
        }
        Write-Host "Headroom CLI installed. Run 'pipx ensurepath' if headroom is not on PATH, then /ak-headroom for MCP/proxy setup." -ForegroundColor Cyan
        return
    }

    $script:pythonCmd = Get-PythonCommand
    if (-not $script:pythonCmd) {
        Write-Host "Headroom optional install skipped: uv, pipx, and python/python3 not found. See DEPENDENCIES.md." -ForegroundColor Yellow
        return
    }

    & $script:pythonCmd -m pip --version *> $null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Headroom optional install skipped: pip is not available for $script:pythonCmd. See DEPENDENCIES.md." -ForegroundColor Yellow
        return
    }

    if (-not (Confirm-OptionalInstall "Headroom CLI (python package headroom-ai[all])")) {
        Write-Host "Skipped optional accelerator: Headroom" -ForegroundColor Yellow
        return
    }

    if ($optionalInstallDryRun) {
        if (Test-PythonVirtualEnv) {
            Write-Host "DRY RUN: would run '$script:pythonCmd -m pip install `"headroom-ai[all]`"'" -ForegroundColor Cyan
        } else {
            Write-Host "DRY RUN: would run '$script:pythonCmd -m pip install --user `"headroom-ai[all]`"'" -ForegroundColor Cyan
        }
        return
    }

    if (Test-PythonVirtualEnv) {
        & $script:pythonCmd -m pip install "headroom-ai[all]"
    } else {
        & $script:pythonCmd -m pip install --user "headroom-ai[all]"
    }
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Headroom optional install failed. Continue with uncompressed context fallback." -ForegroundColor Yellow
        return
    }
    Write-Host "Headroom CLI installed. Add the Python user scripts directory to PATH if needed, then run /ak-headroom for MCP/proxy setup." -ForegroundColor Cyan
}

Update-OptionalAcceleratorStatus
if ($InstallOptional) {
    Write-Host "Optional accelerator install requested. Supported: Graphify, Caveman, CodeGraph, Sentry CLI, and Headroom." -ForegroundColor Cyan
    Install-GraphifyOptional
    Install-CavemanOptional
    Install-CodeGraphOptional
    Install-SentryOptional
    Install-HeadroomOptional
    Update-OptionalAcceleratorStatus
}

Write-Host $graphifyStatus -ForegroundColor Cyan
if ($detectedSkillNames.Count -gt 0) {
    Write-Host "Detected agent skills: $($detectedSkillNames -join ', ')" -ForegroundColor Cyan
}
Write-Host $cavemanStatus -ForegroundColor Cyan
Write-Host $codegraphStatus -ForegroundColor Cyan
Write-Host $sentryStatus -ForegroundColor Cyan
Write-Host $headroomStatus -ForegroundColor Cyan

# Generate the portable rule files from the single canonical templates/RULESET.md.
# Each tool gets its own header; the body is shared so it can never drift.
# This includes generating SKILL.md for the agent skill system.
$rulesetPath = Join-Path $scriptDir "templates/RULESET.md"
$rulesetBody = Get-Content -Path $rulesetPath -Raw

$ruleHeaders = @{
    "CLAUDE.md"    = "# Claude Code Guidelines (CLAUDE.md)`n`nThis project runs under the **Antariksh Unified Developer Framework**. Adhere to the following rules at all times.`n`n---`n`n"
    "AGENTS.md"    = "# Universal Agent Guidelines (AGENTS.md)`n`nThis repository follows the **Antariksh Unified Developer Framework**. All agents (Gemini, OpenAI, Ollama, DeepSeek, Minimax, Claude, Codex, OpenCode) must adhere to these rules.`n`n---`n`n"
    ".cursorrules" = "# Cursor System Rules (.cursorrules)`n`nYou are an expert developer assistant executing within Cursor. You follow the **Antariksh Unified Developer Framework**.`n`n---`n`n"
    ".clinerules"  = "# Cline/Roo-Code System Rules (.clinerules)`n`nYou are an expert developer assistant executing within Cline or Roo-Code. You follow the **Antariksh Unified Developer Framework**.`n`n---`n`n"
    "GEMINI.md"    = "# Gemini CLI Guidelines (GEMINI.md)`n`nThis project runs under the **Antariksh Unified Developer Framework**. Adhere to the following rules at all times.`n`n---`n`n"
    ".github/copilot-instructions.md" = "# GitHub Copilot Instructions (.github/copilot-instructions.md)`n`nThis project runs under the **Antariksh Unified Developer Framework**. Adhere to the following rules at all times.`n`n---`n`n"
    "SKILL.md"     = "---`nname: antariksh-unified-skill`ndescription: Master developer skill combining planning, simplicity, TDD, diagnosis, devops, QA, security, and skill evolution`n---`n`n# Antariksh Unified Agent Skill (Master Developer Framework)`n`nThis is a master-skill for developer agents. When running in a toolless or web-UI interface, follow the inline loops and command workflows below.`n`n## 1. Core Sessions Loop`n- **Session Start**:`n  1. Read ``memory/handoff.md`` if exists → then delete/clear it.`n  2. Read ``MEMORY.md``.`n  3. Read ``memory/local_env.md`` if exists (local skills/tools).`n  4. Read ``AGENTS.md`` + ``GLOSSARY.md``.`n  5. **Context Validation Check**: Check if ``memory/projects/<name>.md`` exists. If not, alert the user and advise running ``/ak-grok`` first to build the project context card and knowledge graph.`n  6. **Episodic Review**: Read the last 5 daily logs (``memory/daily/*.md``) to gain historic execution context.`n  7. **Session Boot**: Set up today's daily log and ask the user `"Is there anything new or changed before we begin?`"`n- **Session End**: Run ``/ak-compact`` to summarize logs, update project lists, update MEMORY.md, record learned corrections, and append reusable skill observations to ``memory/skill-observations.md``.`n`n## 2. Slash Commands Index & Workflows`n- **``/ak-grill``**: Interrogate scope, check edge cases, and output action plan → ``.agents/skills/grill/SKILL.md``.`n- **``/ak-align``**: Pre-coding Socratic scope alignment to agree on plans and success criteria.`n- **``/ak-align-docs``**: Scope alignment + Shared Language glossary update + ADR generation → ``.agents/skills/align-docs/SKILL.md``.`n- **``/ak-to-prd``**: Scopes features with module quizzes and drafts PRD to ``memory/prds/`` → ``.agents/skills/to-prd/SKILL.md``.`n- **``/ak-spec``**: Spec-driven loop (specify -> clarify -> plan -> tasks -> analyze -> implement -> converge) → ``.agents/skills/spec/SKILL.md``.`n- **``/ak-tdd``**: Test-driven development (write tests -> run fail -> implement -> run pass).`n- **``/ak-diagnose``**: Reproduce bug -> bisect scope -> find root cause -> surgical fix -> prevent.`n- **``/ak-bughunt``**: Sweep recent commits for critical defects (trace callers -> concrete trigger scenario -> minimal gated fix or one-line all-clear) → ``.agents/skills/bughunt/SKILL.md``.`n- **``/ak-devops``**: Scaffold container/IaC files, run linters, validate dry-run setups.`n- **``/ak-ci-check``**: Run local line ending, shellcheck, Trivy scan, secrets scan, and indentation diff checks.`n- **``/ak-security``**: OWASP threat audit, local credentials scan, dependency CVE audit, and security report.`n- **``/ak-skillset``**: Observation intake -> skill triage (USE_EXISTING, etc.) -> 11 lenses analysis -> XML spec -> public/internal safety sweep -> critique duel.`n- **``/ak-code``**: Surgical minimal implementation (contracts check -> lazy ladder -> tests -> diff check).`n- **``/ak-review``**: Adversarial attacker duel verification against edge cases and interface drift.`n- **``/ak-prreview``**: Gated PR review creating draft reviews for explicit user approval.`n- **``/ak-worktree``**: Worktree-isolated parallel subagent sweep orchestration.`n- **``/ak-orchestrate``**: Fleet orchestration (plan -> decompose -> brief -> delegate -> synthesize) → ``.agents/skills/orchestrate/SKILL.md``.`n- **``/ak-doc``**: Direct module and interface documentation via tables and diagrams → ``.agents/skills/doc/SKILL.md``.`n- **``/ak-grok``**: Incremental repository scans (RAG index building/AST parsing) to map structure.`n- **``/ak-audit-arch``**: Sweep codebase for architectural smells (god files, duplicate logic, tangles).`n- **``/ak-scratch``**: Scaffold new projects with standard folder layouts and template configs → ``.agents/skills/scratch/SKILL.md``.`n- **``/ak-compact``**: Log consolidation, project facts compilation, skill-observation capture, inbox clearing, and corrections capture.`n- **``/ak-handoff``**: Compile handoff notes to ``memory/handoff.md`` for incoming agents.`n"
}

foreach ($ruleFile in $ruleHeaders.Keys) {
    $destPath = Join-Path $targetPath $ruleFile
    $destDir = Split-Path -Parent $destPath
    if (!(Test-Path $destDir)) {
        New-Item -ItemType Directory -Path $destDir -Force | Out-Null
    }
    if (!(Test-Path $destPath) -or $Force) {
        $content = if ($ruleFile -eq "SKILL.md") { $ruleHeaders[$ruleFile] } else { $ruleHeaders[$ruleFile] + $rulesetBody }
        Set-Content -Path $destPath -Value $content -NoNewline
        Write-Host "Generated rules: $ruleFile" -ForegroundColor Green
    } else {
        Write-Host "Skipped rules: $ruleFile (already exists, use -Force to overwrite)" -ForegroundColor Yellow
    }
}

# Generate modular Cursor MDC rules under .cursor/rules/
$cursorRulesDir = Join-Path $targetPath ".cursor/rules"
if (!(Test-Path $cursorRulesDir)) {
    New-Item -ItemType Directory -Path $cursorRulesDir -Force | Out-Null
}

$sections = $rulesetBody -split "(?m)^---\r?$"
if ($sections.Count -ge 5) {
    $sec1 = $sections[0].Trim()
    $sec2 = $sections[1].Trim()
    $sec3 = $sections[2].Trim()
    $sec4 = $sections[3].Trim()
    $sec5 = $sections[4].Trim()

    $coreMdcPath = Join-Path $cursorRulesDir "core.mdc"
    $coreMdcHeader = "---`ndescription: Core developer philosophies, fallback protocols, and Second Brain standards`nglobs: *`n---`n`n"
    $coreMdcBody = "$sec1`n`n---`n`n$sec2`n`n---`n`n$sec3`n`n---`n`n$sec5`n"
    if (!(Test-Path $coreMdcPath) -or $Force) {
        Set-Content -Path $coreMdcPath -Value ($coreMdcHeader + $coreMdcBody) -NoNewline
        Write-Host "Generated Cursor MDC: core.mdc" -ForegroundColor Green
    } else {
        Write-Host "Skipped Cursor MDC: core.mdc (already exists, use -Force to overwrite)" -ForegroundColor Yellow
    }

    $commandsMdcPath = Join-Path $cursorRulesDir "commands.mdc"
    $commandsMdcHeader = "---`ndescription: Interactive agent slash commands (/ak-tdd, /ak-diagnose, /ak-align, etc.)`nglobs: *`n---`n`n"
    $commandsMdcBody = "$sec4`n"
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
$skillsDest = Join-Path $targetPath ".agents/skills"
if (Test-Path $skillsSrc) {
    if (!(Test-Path $skillsDest) -or $Force) {
        if (!(Test-Path $skillsDest)) {
            New-Item -ItemType Directory -Path $skillsDest -Force | Out-Null
        }
        Copy-Item -Path "$skillsSrc/*" -Destination $skillsDest -Recurse -Force
        Write-Host "Created folder: .agents/skills/ (modular agent skills)" -ForegroundColor Green
    } else {
        Write-Host "Skipped folder: .agents/skills/ (already exists, use -Force to overwrite)" -ForegroundColor Yellow
    }
}

# Copy shared framework scripts needed by installed skills.
$scriptsSrc = Join-Path $scriptDir "scripts"
$scriptsDest = Join-Path $targetPath ".agents/scripts"
if (Test-Path $scriptsSrc) {
    if (!(Test-Path $scriptsDest) -or $Force) {
        if (!(Test-Path $scriptsDest)) {
            New-Item -ItemType Directory -Path $scriptsDest -Force | Out-Null
        }
        foreach ($scriptFile in @("scan-secrets.ps1", "scan-secrets.sh")) {
            $scriptPath = Join-Path $scriptsSrc $scriptFile
            if (Test-Path $scriptPath) {
                Copy-Item -Path $scriptPath -Destination (Join-Path $scriptsDest $scriptFile) -Force
            }
        }
        Write-Host "Created folder: .agents/scripts/ (shared framework scripts)" -ForegroundColor Green
    } else {
        Write-Host "Skipped folder: .agents/scripts/ (already exists, use -Force to overwrite)" -ForegroundColor Yellow
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
    @{ Src = "templates/skill-observations.md"; Dest = "memory/skill-observations.md" },
    @{ Src = "templates/task.md"; Dest = "task.md" },
    @{ Src = "templates/memory/daily/template.md"; Dest = "memory/daily/template.md" },
    @{ Src = "templates/memory/projects/template.md"; Dest = "memory/projects/template.md" },
    @{ Src = "templates/memory/adr/template.md"; Dest = "memory/adr/template.md" },
    @{ Src = "templates/memory/prds/template.md"; Dest = "memory/prds/template.md" },
    @{ Src = "templates/memory/local_env.md"; Dest = "memory/local_env.md" },
    @{ Src = "templates/INTERFACES.md"; Dest = "INTERFACES.md" }
)

foreach ($t in $templates) {
    $srcPath = Join-Path $scriptDir $t.Src
    $destPath = Join-Path $targetPath $t.Dest
    if (!(Test-Path $destPath) -or $Force) {
        Copy-Item -Path $srcPath -Destination $destPath -Force
        Write-Host "Created file: $($t.Dest)" -ForegroundColor Green

        if ($t.Dest -eq "task.md") {
            $taskContent = Get-Content -Path $destPath -Raw
            $taskContent = $taskContent -replace "<!-- TEMPLATE_DO_NOT_USE -->`r?`n", ""
            Set-Content -Path $destPath -Value $taskContent -NoNewline
        }

        if ($t.Dest -eq "memory/local_env.md") {
            $skillsLine = if ($detectedSkillNames.Count -gt 0) { "Detected agent skills on this machine: $($detectedSkillNames -join ', ')." } else { "No agent skills detected under $skillsDir." }
            $sentryOrgStatus = if ($env:SENTRY_ORG_SLUG) { "Configured (from env)" } else { "Not configured" }
            $sentryTokenStatus = if ($env:SENTRY_AUTH_TOKEN) { "Configured (from env)" } else { "Not configured" }
            $envContent = Get-Content -Path $destPath -Raw
            $envContent = $envContent -replace "<!-- TEMPLATE_DO_NOT_USE -->`r?`n", ""
            $envContent = $envContent -replace "\[GRAPHIFY_STATUS\]", $graphifyStatus
            $envContent = $envContent -replace "\[CODEGRAPH_STATUS\]", $codegraphStatus
            $envContent = $envContent -replace "\[CAVEMAN_STATUS\]", $cavemanStatus
            $envContent = $envContent -replace "\[SENTRY_STATUS\]", $sentryStatus
            $envContent = $envContent -replace "\[SENTRY_ORG_SLUG_STATUS\]", $sentryOrgStatus
            $envContent = $envContent -replace "\[SENTRY_AUTH_TOKEN_STATUS\]", $sentryTokenStatus
            $envContent = $envContent -replace "\[HEADROOM_STATUS\]", $headroomStatus
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
    $content = @"
# Daily Log -- $today

## Start of Day
- [ ]

## Log Entries
-

## End of Day Summary
- **Accomplishments**:
- **Key Decisions**:
- **Open Loops**:
- **Tomorrow's First Task**:
"@
    Set-Content -Path $dailyLogDest -Value $content -Force
    Write-Host "Created today's daily log: memory/daily/$today.md" -ForegroundColor Green
}

# Create repository-specific project context file if it doesn't exist
$projectName = Split-Path -Leaf $targetPath
$projectFileDest = Join-Path $targetPath "memory/projects/$projectName.md"
if (!(Test-Path $projectFileDest) -or $Force) {
    $srcTemplate = Join-Path $scriptDir "templates/memory/projects/template.md"
    Copy-Item -Path $srcTemplate -Destination $projectFileDest -Force
    $content = Get-Content -Path $projectFileDest -Raw
    $content = $content -replace "<!-- TEMPLATE_DO_NOT_USE -->`r?`n", ""
    $content = $content -replace "\[Project Name\]", $projectName
    Set-Content -Path $projectFileDest -Value $content -Force
    Write-Host "Created project memory file: memory/projects/$projectName.md" -ForegroundColor Green
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
    $claudeHooksDir = Join-Path $targetPath ".claude/hooks"
    if (!(Test-Path $claudeHooksDir)) {
        New-Item -ItemType Directory -Path $claudeHooksDir -Force | Out-Null
    }

    foreach ($hookScript in @("session-start.ps1", "stop-check.ps1")) {
        $hookSrc = Join-Path $scriptDir "templates/.claude/hooks/$hookScript"
        $hookDest = Join-Path $claudeHooksDir $hookScript
        if (!(Test-Path $hookDest) -or $Force) {
            Copy-Item -Path $hookSrc -Destination $hookDest -Force
            Write-Host "Created file: .claude/hooks/$hookScript" -ForegroundColor Green
        } else {
            Write-Host "Skipped file: .claude/hooks/$hookScript (already exists, use -Force to overwrite)" -ForegroundColor Yellow
        }
    }

    $settingsDest = Join-Path $targetPath ".claude/settings.json"
    $hookConfigs = @{
        "SessionStart" = 'powershell.exe -ExecutionPolicy Bypass -File ${CLAUDE_PROJECT_DIR}/.claude/hooks/session-start.ps1'
        "Stop"         = 'powershell.exe -ExecutionPolicy Bypass -File ${CLAUDE_PROJECT_DIR}/.claude/hooks/stop-check.ps1'
    }

    if (!(Test-Path $settingsDest)) {
        $settingsObject = @{
            hooks = @{
                "SessionStart" = @()
                "Stop"         = @()
            }
        }
        $startHook = @{
            type    = "command"
            command = $hookConfigs["SessionStart"]
            timeout = 30
        }
        $settingsObject.hooks["SessionStart"] += @{ hooks = @($startHook) }

        $stopHook = @{
            type    = "command"
            command = $hookConfigs["Stop"]
            timeout = 10
        }
        $settingsObject.hooks["Stop"] += @{ hooks = @($stopHook) }
        $settingsObject | ConvertTo-Json -Depth 10 | Set-Content -Path $settingsDest -Force
        Write-Host "Created file: .claude/settings.json" -ForegroundColor Green
    } else {
        $existing = Get-Content -Path $settingsDest -Raw | ConvertFrom-Json

        if (-not ($existing.PSObject.Properties.Name -contains "hooks")) {
            $existing | Add-Member -MemberType NoteProperty -Name "hooks" -Value (@{}) -Force
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
                if ($eventName -eq "SessionStart") {
                    $timeoutVal = 30
                } else {
                    $timeoutVal = 10
                }
                $newEntry = @{
                    hooks = @(
                        @{
                            type = "command"
                            command = $cmdPath
                            timeout = $timeoutVal
                        }
                    )
                }
                $existing.hooks.$eventName = @(@($existing.hooks.$eventName) + @($newEntry))
            }
        }

        $existing | ConvertTo-Json -Depth 10 | Set-Content -Path $settingsDest -Force
        Write-Host "Merged PowerShell hooks into existing .claude/settings.json" -ForegroundColor Green
    }

    # Codex CLI Hooks
    $codexHooksDir = Join-Path $targetPath ".codex/hooks"
    if (!(Test-Path $codexHooksDir)) {
        New-Item -ItemType Directory -Path $codexHooksDir -Force | Out-Null
    }

    foreach ($hookScript in @("session-start.ps1", "stop-check.ps1")) {
        $hookSrc = Join-Path $scriptDir "templates/.claude/hooks/$hookScript"
        $hookDest = Join-Path $codexHooksDir $hookScript
        if (!(Test-Path $hookDest) -or $Force) {
            Copy-Item -Path $hookSrc -Destination $hookDest -Force
            Write-Host "Created file: .codex/hooks/$hookScript" -ForegroundColor Green
        } else {
            Write-Host "Skipped file: .codex/hooks/$hookScript (already exists, use -Force to overwrite)" -ForegroundColor Yellow
        }
    }

    $codexSettingsDest = Join-Path $targetPath ".codex/hooks.json"
    $codexHookConfigs = @{
        "SessionStart" = 'powershell.exe -ExecutionPolicy Bypass -File ${CODEX_PROJECT_DIR}/.codex/hooks/session-start.ps1'
        "Stop"         = 'powershell.exe -ExecutionPolicy Bypass -File ${CODEX_PROJECT_DIR}/.codex/hooks/stop-check.ps1'
    }

    if (!(Test-Path $codexSettingsDest)) {
        $codexSettingsObject = @{
            hooks = @{
                "SessionStart" = @()
                "Stop"         = @()
            }
        }
        $codexStartHook = @{
            type    = "command"
            command = $codexHookConfigs["SessionStart"]
            timeout = 30
        }
        $codexSettingsObject.hooks["SessionStart"] += @{ hooks = @($codexStartHook) }

        $codexStopHook = @{
            type    = "command"
            command = $codexHookConfigs["Stop"]
            timeout = 10
        }
        $codexSettingsObject.hooks["Stop"] += @{ hooks = @($codexStopHook) }
        $codexSettingsObject | ConvertTo-Json -Depth 10 | Set-Content -Path $codexSettingsDest -Force
        Write-Host "Created file: .codex/hooks.json" -ForegroundColor Green
    } else {
        $existingCodex = Get-Content -Path $codexSettingsDest -Raw | ConvertFrom-Json

        if (-not ($existingCodex.PSObject.Properties.Name -contains "hooks")) {
            $existingCodex | Add-Member -MemberType NoteProperty -Name "hooks" -Value (@{}) -Force
        }

        foreach ($eventName in @("SessionStart", "Stop")) {
            $cmdPath = $codexHookConfigs[$eventName]

            if (-not ($existingCodex.hooks.PSObject.Properties.Name -contains $eventName)) {
                $existingCodex.hooks | Add-Member -MemberType NoteProperty -Name $eventName -Value @() -Force
            }

            $alreadyPresent = $false
            foreach ($entry in @($existingCodex.hooks.$eventName)) {
                foreach ($h in @($entry.hooks)) {
                    if ($h.command -eq $cmdPath) { $alreadyPresent = $true }
                }
            }

            if (-not $alreadyPresent) {
                if ($eventName -eq "SessionStart") {
                    $timeoutVal = 30
                } else {
                    $timeoutVal = 10
                }
                $newEntry = @{
                    hooks = @(
                        @{
                            type = "command"
                            command = $cmdPath
                            timeout = $timeoutVal
                        }
                    )
                }
                $existingCodex.hooks.$eventName = @(@($existingCodex.hooks.$eventName) + @($newEntry))
            }
        }

        $existingCodex | ConvertTo-Json -Depth 10 | Set-Content -Path $codexSettingsDest -Force
        Write-Host "Merged PowerShell hooks into existing .codex/hooks.json" -ForegroundColor Green
    }

    Write-Host "PowerShell hooks installed successfully (Claude Code + Codex CLI)." -ForegroundColor Cyan
}

Write-Host "`nAntariksh rules deployed. Memory folders initialized. Code safe." -ForegroundColor Cyan
