---
description: Backup all Claude Code config (skills/agents/commands/hooks/settings) to a zip
argument-hint: [destination dir, default: ~/.claude/backups]
allowed-tools: PowerShell
---

Run the backup script and report on the resulting archive.

## Steps

1. Resolve the destination:

   ```powershell
   $dest = if ([string]::IsNullOrWhiteSpace($args)) { (Join-Path $HOME '.claude/backups') } else { $args }
   ```

   (where `$args` is `$ARGUMENTS` from the slash command)

2. Locate the backup script:

   ```powershell
   $script = Join-Path $HOME '.claude/hooks/backup-config.ps1'
   if (-not (Test-Path $script)) {
       Write-Output "Backup script not found at $script."
       Write-Output "Install it first (ask the maintainer or run the install task that places hooks/backup-config.ps1)."
       return
   }
   ```

3. Invoke the script with the destination:

   ```powershell
   & $script -Destination $dest
   if (-not $?) {
       Write-Output "Backup script exited with an error."
       return
   }
   ```

4. Find the most recent zip in `$dest` and report path, size, and file count inside:

   ```powershell
   $zip = Get-ChildItem $dest -Filter *.zip -ErrorAction SilentlyContinue |
          Sort-Object LastWriteTime -Descending | Select-Object -First 1
   if (-not $zip) {
       Write-Output "Script ran but no .zip was produced in $dest."
       return
   }
   Add-Type -AssemblyName System.IO.Compression.FileSystem
   $archive = [System.IO.Compression.ZipFile]::OpenRead($zip.FullName)
   $count = $archive.Entries.Count
   $archive.Dispose()
   $sizeMB = [math]::Round($zip.Length / 1MB, 2)
   Write-Output "Backup OK"
   Write-Output "  path:  $($zip.FullName)"
   Write-Output "  size:  ${sizeMB} MB"
   Write-Output "  files: $count"
   ```

5. Report back the three lines (path / size / files) plus the timestamp on the archive. If anything failed, report which step and the error.

Destination argument (may be empty -> default used): `$ARGUMENTS`
