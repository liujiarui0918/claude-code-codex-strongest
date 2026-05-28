#requires -version 5.1
$ErrorActionPreference = 'Stop'

# Read stdin payload (empty allowed, silent exit on parse failure).
try {
    $stdinReader = [System.IO.StreamReader]::new([Console]::OpenStandardInput(), [System.Text.Encoding]::UTF8)
    $jsonText = $stdinReader.ReadToEnd()
    if ([string]::IsNullOrWhiteSpace($jsonText)) { exit 0 }
    $payload = $jsonText | ConvertFrom-Json
} catch {
    exit 0
}

try {
    # Extract fields defensively — different harness versions use different shapes.
    $sessionId = ''
    try { if ($payload.session_id) { $sessionId = [string]$payload.session_id } } catch { }
    if ([string]::IsNullOrWhiteSpace($sessionId)) {
        try { if ($payload.sessionId) { $sessionId = [string]$payload.sessionId } } catch { }
    }
    $sidShort = if ($sessionId.Length -ge 8) { $sessionId.Substring(0, 8) } elseif ($sessionId) { $sessionId } else { 'nosid' }

    $subagentType = ''
    foreach ($field in 'subagent_type','subagentType','agent_type','agentType','agent','name') {
        try {
            $v = $payload.$field
            if ($v -and -not [string]::IsNullOrWhiteSpace([string]$v)) { $subagentType = [string]$v; break }
        } catch { }
    }
    if ([string]::IsNullOrWhiteSpace($subagentType)) { $subagentType = 'unknown' }

    $transcriptPath = ''
    foreach ($field in 'transcript_path','transcriptPath','transcript') {
        try {
            $v = $payload.$field
            if ($v -and -not [string]::IsNullOrWhiteSpace([string]$v)) { $transcriptPath = [string]$v; break }
        } catch { }
    }

    # Resolve log dir.
    $logDir = $env:CLAUDE_HOOKS_LOG_DIR
    if ([string]::IsNullOrWhiteSpace($logDir)) { $logDir = Join-Path $HOME '.claude/logs' }
    if (-not (Test-Path -LiteralPath $logDir)) {
        try { New-Item -ItemType Directory -Path $logDir -Force | Out-Null } catch { exit 0 }
    }

    $logFile = Join-Path $logDir 'subagents.log'
    $ts = (Get-Date).ToString('o')
    $line = "$ts $sidShort $subagentType"
    if ($transcriptPath) { $line += " $transcriptPath" }

    # UTF-8 append, no BOM concern for log files but keep it consistent.
    Add-Content -LiteralPath $logFile -Value $line -Encoding UTF8

    exit 0
} catch {
    exit 0
}
