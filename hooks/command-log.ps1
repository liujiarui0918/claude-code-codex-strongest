#requires -version 5.1
$ErrorActionPreference = 'Stop'

try {
    $stdinReader = [System.IO.StreamReader]::new([Console]::OpenStandardInput(), [System.Text.Encoding]::UTF8)
    $jsonText = $stdinReader.ReadToEnd()
    if ([string]::IsNullOrWhiteSpace($jsonText)) { exit 0 }
    $payload = $jsonText | ConvertFrom-Json
} catch {
    exit 0
}

try {
    $cmd = $null
    if ($payload.tool_input -and $payload.tool_input.command) {
        $cmd = [string]$payload.tool_input.command
    }
    if ([string]::IsNullOrWhiteSpace($cmd)) { exit 0 }

    $logDir = $env:CLAUDE_HOOKS_LOG_DIR
    if ([string]::IsNullOrWhiteSpace($logDir)) {
        $logDir = Join-Path $HOME '.claude/logs'
    }
    if (-not (Test-Path -LiteralPath $logDir)) {
        try { New-Item -ItemType Directory -Path $logDir -Force | Out-Null } catch { exit 0 }
    }
    $logPath = Join-Path $logDir 'commands.log'

    $ts = (Get-Date).ToString('o')
    $sid = ''
    if ($payload.session_id) {
        $sid = [string]$payload.session_id
        if ($sid.Length -ge 8) { $sid = $sid.Substring(0, 8) } else { $sid = $sid.PadRight(8, ' ') }
    } else {
        $sid = '--------'
    }

    # Flatten newlines so each command is one log line.
    $oneLine = ($cmd -replace "`r?`n", ' \n ').Trim()

    $line = "$ts $sid $oneLine"
    Add-Content -Path $logPath -Value $line -Encoding utf8
    exit 0
} catch {
    exit 0
}
