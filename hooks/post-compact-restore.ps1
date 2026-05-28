#requires -version 5.1
$ErrorActionPreference = 'Stop'

# Utility script — list recent transcript backups saved by precompact-backup.ps1.
# Claude Code emits PreCompact only (no PostCompact event), so this is meant to
# be invoked manually by the user when they want to find a prior transcript.

# This is a utility script (manual invocation). No stdin read — that would
# either hang interactively or do nothing useful here.

try {
    $backupDir = Join-Path $HOME '.claude/logs/transcript-backup'

    if (-not (Test-Path -LiteralPath $backupDir)) {
        Write-Output "No transcript backups found (directory does not exist):"
        Write-Output "  $backupDir"
        exit 0
    }

    $files = @(Get-ChildItem -LiteralPath $backupDir -File -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 5)

    if ($files.Count -eq 0) {
        Write-Output "Recent transcript backups (PreCompact saved):"
        Write-Output "  (none)"
        Write-Output "Backup directory: $backupDir"
        exit 0
    }

    Write-Output "Recent transcript backups (PreCompact saved):"
    $i = 1
    foreach ($f in $files) {
        $sizeKb = [math]::Round($f.Length / 1KB, 1)
        $ts = $f.LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss')
        Write-Output ("{0}. {1}  ({2} KB)  {3}" -f $i, $f.Name, $sizeKb, $ts)
        $i++
    }
    Write-Output ""
    Write-Output "Location: $backupDir"

    exit 0
} catch {
    exit 0
}
