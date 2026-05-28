#requires -version 5.1
param(
    [string]$Destination = ''
)
$ErrorActionPreference = 'Stop'

function Write-Info($msg)  { Write-Host $msg }
function Write-Bad($msg)   { Write-Host $msg -ForegroundColor Red }

try {
    $claudeHome = if ($env:CLAUDE_HOME) { $env:CLAUDE_HOME } else { Join-Path $HOME '.claude' }

    if ([string]::IsNullOrWhiteSpace($Destination)) {
        $Destination = Join-Path $claudeHome 'backups'
    }

    if (-not (Test-Path -LiteralPath $Destination)) {
        try {
            New-Item -ItemType Directory -Path $Destination -Force | Out-Null
        } catch {
            Write-Bad "Failed to create destination: $Destination"
            Write-Bad $_.Exception.Message
            exit 1
        }
    }

    $stamp   = (Get-Date).ToString('yyyyMMdd-HHmmss')
    $zipName = "claude-config-$stamp.zip"
    $zipPath = Join-Path $Destination $zipName

    # Candidate items to back up. Skip those that don't exist on disk.
    $candidates = @(
        (Join-Path $claudeHome 'CLAUDE.md'),
        (Join-Path $claudeHome 'settings.json'),
        (Join-Path $claudeHome 'SETUP_PLAN.md'),
        (Join-Path $claudeHome 'skills'),
        (Join-Path $claudeHome 'agents'),
        (Join-Path $claudeHome 'commands'),
        (Join-Path $claudeHome 'output-styles')
    )

    $paths = New-Object System.Collections.Generic.List[string]
    foreach ($c in $candidates) {
        if (Test-Path -LiteralPath $c) { $paths.Add($c) | Out-Null }
    }

    # hooks: only *.ps1 (skip logs/cache that may live alongside).
    $hooksDir = Join-Path $claudeHome 'hooks'
    if (Test-Path -LiteralPath $hooksDir) {
        $ps1s = Get-ChildItem -LiteralPath $hooksDir -Filter *.ps1 -File -ErrorAction SilentlyContinue
        foreach ($f in $ps1s) { $paths.Add($f.FullName) | Out-Null }
    }

    if ($paths.Count -eq 0) {
        Write-Bad "Nothing to back up: no candidate files exist under $claudeHome."
        exit 1
    }

    try {
        Compress-Archive -Path $paths -DestinationPath $zipPath -CompressionLevel Optimal -Force
    } catch {
        Write-Bad "Failed to create archive: $zipPath"
        Write-Bad $_.Exception.Message
        exit 1
    }

    # Report.
    $zipItem = Get-Item -LiteralPath $zipPath -ErrorAction SilentlyContinue
    $sizeKB  = if ($zipItem) { [math]::Round($zipItem.Length / 1KB, 1) } else { 0 }

    # Count files actually in the archive.
    $fileCount = 0
    try {
        Add-Type -AssemblyName 'System.IO.Compression.FileSystem' -ErrorAction SilentlyContinue | Out-Null
        $zip = [System.IO.Compression.ZipFile]::OpenRead($zipPath)
        try {
            $fileCount = @($zip.Entries | Where-Object { -not $_.FullName.EndsWith('/') }).Count
        } finally {
            $zip.Dispose()
        }
    } catch {
        $fileCount = -1
    }

    Write-Info "Backup written: $zipPath"
    Write-Info "Files:          $fileCount"
    Write-Info "Size:           ${sizeKB} KB"
    Write-Info "Excluded:       logs/, cache/, telemetry/, backups/, ~/.claude.json"

    # Rotation: drop backups older than 7 days. Non-blocking on errors.
    try {
        $cutoff = (Get-Date).AddDays(-7)
        $old = Get-ChildItem -LiteralPath $Destination -Filter 'claude-config-*.zip' -File -ErrorAction SilentlyContinue |
            Where-Object { $_.LastWriteTime -lt $cutoff }
        foreach ($o in $old) {
            try {
                Remove-Item -LiteralPath $o.FullName -Force -ErrorAction Stop
                Write-Info "Rotated old:    $($o.Name)"
            } catch {
                Write-Info "Could not delete old backup: $($o.Name) - $($_.Exception.Message)"
            }
        }
    } catch {
        # Rotation must never fail the script.
    }

    exit 0
} catch {
    Write-Bad "backup-config failed: $($_.Exception.Message)"
    exit 1
}
