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

    # Patterns: each entry is @{ pattern = regex; reason = "explanation" }
    $patterns = @(
        @{ pattern = 'rm\s+-rf\s+/(\s|$)';                              reason = 'rm -rf / (root deletion)' },
        @{ pattern = 'rm\s+-rf\s+~(\s|/|$)';                            reason = 'rm -rf ~ (home deletion)' },
        @{ pattern = 'rm\s+-rf\s+\$HOME';                               reason = 'rm -rf $HOME' },
        @{ pattern = 'rm\s+-rf\s+%USERPROFILE%';                        reason = 'rm -rf %USERPROFILE%' },
        @{ pattern = 'rm\s+-rf\s+[A-Za-z]:\\(\s|$)';                    reason = 'rm -rf drive root' },
        @{ pattern = 'rm\s+-rf\s+[A-Za-z]:/(\s|$)';                     reason = 'rm -rf drive root' },
        @{ pattern = 'Remove-Item\s+.*-Recurse.*-Force.*\s+[A-Za-z]:\\(\s|''|"|$)'; reason = 'Remove-Item -Recurse -Force on drive root' },
        @{ pattern = 'Remove-Item\s+.*-Recurse.*-Force.*\s+~(\s|/|''|"|$)';        reason = 'Remove-Item -Recurse -Force ~' },
        @{ pattern = 'Remove-Item\s+.*-Recurse.*-Force.*\$env:USERPROFILE';        reason = 'Remove-Item -Recurse -Force $env:USERPROFILE' },
        @{ pattern = 'Remove-Item\s+.*-Recurse.*-Force.*\s+\*(\s|$)';              reason = 'Remove-Item -Recurse -Force * (top-level wildcard)' },
        @{ pattern = 'Format-Volume\b';                                 reason = 'Format-Volume (drive format)' },
        @{ pattern = '\bFormat-[A-Z]\w*\s+-Drive';                      reason = 'Format- drive command' },
        @{ pattern = '\bdd\s+if=';                                      reason = 'dd if= (block device write)' },
        @{ pattern = 'git\s+push\s+(--force|-f)\b.*\b(main|master|production)\b'; reason = 'git push --force to protected branch' },
        @{ pattern = 'git\s+push\s+(--force|-f)\b.*\brelease/';         reason = 'git push --force to release/ branch' },
        @{ pattern = 'git\s+reset\s+--hard\s+origin/(main|master|production)\b'; reason = 'git reset --hard origin/protected' },
        @{ pattern = ':\(\)\s*\{\s*:\|:&\s*\};:';                       reason = 'fork bomb' },
        @{ pattern = '\bmkfs\.';                                        reason = 'mkfs. (filesystem creation)' },
        @{ pattern = '\bStop-Computer\b';                               reason = 'Stop-Computer (shutdown)' },
        @{ pattern = '\bRestart-Computer\b';                            reason = 'Restart-Computer (reboot)' },
        @{ pattern = '\bDisable-NetAdapter\b';                          reason = 'Disable-NetAdapter (network disable)' },
        @{ pattern = '\bClear-RecycleBin\b.*-Force';                    reason = 'Clear-RecycleBin -Force' },
        @{ pattern = '(Set-Content|Out-File|Add-Content|Write-Output|>)\s+[''"]?[A-Za-z]:\\Windows\\System32'; reason = 'write to C:\Windows\System32' },
        @{ pattern = '(Copy-Item|Move-Item|cp|mv).*\s+[''"]?[A-Za-z]:\\Windows\\System32'; reason = 'write to C:\Windows\System32' },
        @{ pattern = '\breg\s+delete\s+HKLM\b';                         reason = 'reg delete HKLM' },
        @{ pattern = 'Remove-Item.*HKLM:';                              reason = 'Remove-Item HKLM:' }
    )

    foreach ($p in $patterns) {
        if ($cmd -match $p.pattern) {
            $snippet = $cmd
            if ($snippet.Length -gt 200) { $snippet = $snippet.Substring(0, 200) + '...' }
            [Console]::Error.WriteLine("[block-dangerous] Refused: $snippet. Reason: $($p.reason). Override by asking user explicitly.")
            exit 2
        }
    }

    exit 0
} catch {
    exit 0
}
