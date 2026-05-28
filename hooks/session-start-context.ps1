#requires -version 5.1
$ErrorActionPreference = 'Stop'

# Read stdin payload (empty allowed — SessionStart often has no payload).
try {
    $stdinReader = [System.IO.StreamReader]::new([Console]::OpenStandardInput(), [System.Text.Encoding]::UTF8)
    $jsonText = $stdinReader.ReadToEnd()
    if ([string]::IsNullOrWhiteSpace($jsonText)) {
        $payload = [pscustomobject]@{}
    } else {
        try {
            $payload = $jsonText | ConvertFrom-Json
        } catch {
            # Bad JSON — still emit context, just without cwd from payload.
            $payload = [pscustomobject]@{}
        }
    }
} catch {
    $payload = [pscustomobject]@{}
}

try {
    $claudeHome = if ($env:CLAUDE_HOME) { $env:CLAUDE_HOME } else { Join-Path $HOME '.claude' }

    $cwd = $null
    try { if ($payload.cwd) { $cwd = [string]$payload.cwd } } catch { }
    if ([string]::IsNullOrWhiteSpace($cwd)) { $cwd = (Get-Location).Path }

    $sb = New-Object System.Text.StringBuilder

    # --- Git Context (only if inside a git repo) -----------------------------
    $inGit = $false
    if (Test-Path -LiteralPath $cwd) {
        if (Test-Path -LiteralPath (Join-Path $cwd '.git')) { $inGit = $true }
    }

    if ($inGit) {
        $git = Get-Command git -ErrorAction SilentlyContinue
        if ($git) {
            $branch = ''
            $statusLines = @()
            $logLines = @()
            try {
                $b = (& git -C $cwd rev-parse --abbrev-ref HEAD 2>$null) -join ''
                $branch = $b.Trim()
            } catch { }
            try {
                $statusRaw = & git -C $cwd status --short 2>$null
                if ($statusRaw) { $statusLines = @($statusRaw) | Where-Object { $_ -ne $null -and $_ -ne '' } }
            } catch { }
            try {
                $logRaw = & git -C $cwd log --oneline -n 5 2>$null
                if ($logRaw) { $logLines = @($logRaw) | Where-Object { $_ -ne $null -and $_ -ne '' } }
            } catch { }

            [void]$sb.AppendLine('## Git Context')
            if ($branch) { [void]$sb.AppendLine("Branch: $branch") }
            [void]$sb.AppendLine("Modified: $($statusLines.Count) files")
            foreach ($l in ($statusLines | Select-Object -First 8)) {
                [void]$sb.AppendLine("  $l")
            }
            if ($logLines.Count -gt 0) {
                [void]$sb.AppendLine('Recent commits:')
                foreach ($l in $logLines) { [void]$sb.AppendLine("- $l") }
            }
            [void]$sb.AppendLine('')
        }
    }

    # --- Available Locally ---------------------------------------------------
    $skillCount  = 0
    $agentCount  = 0
    $cmdCount    = 0
    $mcpNames    = @()

    try {
        $skillsDir = Join-Path $claudeHome 'skills'
        if (Test-Path -LiteralPath $skillsDir) {
            $skillCount = @(Get-ChildItem -LiteralPath $skillsDir -Directory -ErrorAction SilentlyContinue |
                Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName 'SKILL.md') }).Count
        }
    } catch { }

    try {
        $agentsDir = Join-Path $claudeHome 'agents'
        if (Test-Path -LiteralPath $agentsDir) {
            $agentCount = @(Get-ChildItem -LiteralPath $agentsDir -Filter *.md -File -ErrorAction SilentlyContinue).Count
        }
    } catch { }

    try {
        $cmdsDir = Join-Path $claudeHome 'commands'
        if (Test-Path -LiteralPath $cmdsDir) {
            $cmdCount = @(Get-ChildItem -LiteralPath $cmdsDir -Filter *.md -File -ErrorAction SilentlyContinue).Count
        }
    } catch { }

    try {
        $cfg = Join-Path (Split-Path $claudeHome -Parent) '.claude.json'
        if (Test-Path -LiteralPath $cfg) {
            $j = Get-Content -LiteralPath $cfg -Raw -Encoding UTF8 | ConvertFrom-Json
            if ($j.mcpServers) {
                $mcpNames = @($j.mcpServers.PSObject.Properties.Name)
            }
        }
    } catch { }

    [void]$sb.AppendLine('## Available Locally')
    [void]$sb.AppendLine("Skills: $skillCount  |  Agents: $agentCount  |  Commands: $cmdCount  |  MCPs: $($mcpNames.Count)")
    if ($mcpNames.Count -gt 0) {
        [void]$sb.AppendLine("MCP servers: $($mcpNames -join ', ')")
    }
    [void]$sb.AppendLine('')

    # --- Skill Auto-Triggers -------------------------------------------------
    [void]$sb.AppendLine('## Skill Auto-Triggers')
    [void]$sb.AppendLine('When the user mentions / asks for, invoke the corresponding Skill:')
    [void]$sb.AppendLine('- "design / brainstorm / what should we do" -> brainstorming')
    [void]$sb.AppendLine('- "plan / break down / decompose this work" -> writing-plans')
    [void]$sb.AppendLine('- "execute the plan / let''s go / start working" -> executing-plans')
    [void]$sb.AppendLine('- "test / TDD / write a test" -> test-driven-development')
    [void]$sb.AppendLine('- "debug / why is this broken / trace this bug" -> systematic-debugging + root-cause-tracing')
    [void]$sb.AppendLine('- "verify / does it work / prove the fix" -> verification-before-completion')
    [void]$sb.AppendLine('- "review / look over my code / self-check" -> requesting-code-review')
    [void]$sb.AppendLine('- "library docs / how to use X package / API of X" -> using-context7')
    [void]$sb.AppendLine('- "GitHub repo / how does X repo work / explain Y/Z repo" -> using-deepwiki')
    [void]$sb.AppendLine('- "think through / hard decision / architecture choice" -> using-sequential-thinking')
    [void]$sb.AppendLine('- "screenshot of UI / browser test / verify UI" -> using-playwright')
    [void]$sb.AppendLine('- "remind me / every N min / daily" -> using-cron')
    [void]$sb.AppendLine('- "complex multi-step task" -> using-task-list + subagent-driven-development')
    [void]$sb.AppendLine('- "image attached / look at this screenshot" -> extracting-from-images')
    [void]$sb.AppendLine('- "write a prompt / improve this prompt" -> prompt-engineering')
    [void]$sb.AppendLine('- "new codebase / first time seeing this project" -> incremental-context-building')
    [void]$sb.AppendLine('')

    # --- Quick reminders -----------------------------------------------------
    [void]$sb.AppendLine('## Quick reminders')
    [void]$sb.AppendLine('- /plan: brainstorm + write a plan before non-trivial work')
    [void]$sb.AppendLine('- /tdd: strict RED -> GREEN -> REFACTOR')
    [void]$sb.AppendLine('- /review: code review on current diff')
    [void]$sb.AppendLine('- /debug: reproduce -> isolate -> fix -> verify')
    [void]$sb.AppendLine('- /verify: run real commands, observe behavior')
    [void]$sb.AppendLine('')

    # --- Disabled hooks ------------------------------------------------------
    if (-not [string]::IsNullOrWhiteSpace($env:CLAUDE_DISABLED_HOOKS)) {
        [void]$sb.AppendLine('## Disabled hooks')
        [void]$sb.AppendLine($env:CLAUDE_DISABLED_HOOKS)
        [void]$sb.AppendLine('')
    }

    $out = $sb.ToString()
    # Keep output < 3KB (was 2KB; new auto-trigger block needs more room).
    $maxBytes = 3072
    if ($out.Length -gt $maxBytes) {
        $out = $out.Substring(0, $maxBytes - 16) + "`r`n...[truncated]"
    }

    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    [Console]::Out.Write($out)
    exit 0
} catch {
    exit 0
}
