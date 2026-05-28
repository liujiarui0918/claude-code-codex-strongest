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
    $transcript = $null
    if ($payload.transcript_path) { $transcript = [string]$payload.transcript_path }
    if ([string]::IsNullOrWhiteSpace($transcript) -or -not (Test-Path -LiteralPath $transcript)) { exit 0 }

    $sid = 'unknown'
    if ($payload.session_id) {
        $sid = [string]$payload.session_id
        # sanitize for filename
        $sid = ($sid -replace '[^A-Za-z0-9_\-]', '')
        if ([string]::IsNullOrWhiteSpace($sid)) { $sid = 'unknown' }
    }

    $backupDir = Join-Path $HOME '.claude/logs/transcript-backup'
    if (-not (Test-Path -LiteralPath $backupDir)) {
        try { New-Item -ItemType Directory -Path $backupDir -Force | Out-Null } catch { exit 0 }
    }

    $ts = (Get-Date).ToString('yyyyMMdd-HHmmss')
    $dest = Join-Path $backupDir "$sid-$ts.jsonl"

    try {
        Copy-Item -LiteralPath $transcript -Destination $dest -Force
    } catch {
        # ignore copy failures
    }

    exit 0
} catch {
    exit 0
}
