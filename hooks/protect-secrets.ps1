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
    $toolName = [string]$payload.tool_name

    # Path-based regex patterns. Use forward-or-backslash agnostic checks against normalized strings.
    $pathPatterns = @(
        @{ pattern = '(^|[\\/])\.env($|\.|[\\/])';            reason = '.env file' },
        @{ pattern = '\.(pem|key|pfx|p12)($|[\\/"''])';       reason = 'private key/certificate file' },
        @{ pattern = '(^|[\\/])id_(rsa|ed25519|ecdsa|dsa)($|[\\/"''\.])'; reason = 'SSH private key' },
        @{ pattern = '[\\/]\.aws[\\/](credentials|config)\b'; reason = 'AWS credentials/config' },
        @{ pattern = '[\\/]\.ssh[\\/]id_';                    reason = 'SSH identity file' },
        @{ pattern = '[\\/]\.ssh[\\/]config\b';               reason = 'SSH config' },
        @{ pattern = '[\\/]\.kube[\\/]config\b';              reason = 'Kubernetes config' },
        @{ pattern = '[\\/]\.docker[\\/]config\.json\b';      reason = 'Docker config (registry auth)' },
        @{ pattern = '[\\/]\.gnupg[\\/]';                     reason = 'GnuPG directory' },
        @{ pattern = '[\\/]\.netrc\b';                        reason = '.netrc credentials' }
    )

    function Test-SecretPath {
        param([string]$Path, [array]$Patterns)
        if ([string]::IsNullOrWhiteSpace($Path)) { return $null }
        $norm = $Path -replace '\\', '/'
        foreach ($p in $Patterns) {
            if ($Path -match $p.pattern -or $norm -match $p.pattern) {
                return $p.reason
            }
        }
        return $null
    }

    if ($toolName -in @('Read', 'Edit', 'Write')) {
        $fp = $null
        if ($payload.tool_input -and $payload.tool_input.file_path) {
            $fp = [string]$payload.tool_input.file_path
        }
        $reason = Test-SecretPath -Path $fp -Patterns $pathPatterns
        if ($reason) {
            [Console]::Error.WriteLine("[protect-secrets] Refused: $fp. Reason: secret-like file ($reason). Override only by user.")
            exit 2
        }
    } elseif ($toolName -in @('Bash', 'PowerShell')) {
        $cmd = $null
        if ($payload.tool_input -and $payload.tool_input.command) {
            $cmd = [string]$payload.tool_input.command
        }
        if ([string]::IsNullOrWhiteSpace($cmd)) { exit 0 }

        # Detect whether the command references a secret-like path with a read/write verb.
        $verbPattern = '(cat|type|less|more|head|tail|Get-Content|gc|Set-Content|sc|Add-Content|ac|Out-File|Copy-Item|cp|Move-Item|mv|echo\s+[^|]*>|>{1,2}\s*[^&|]+)'
        $reason = Test-SecretPath -Path $cmd -Patterns $pathPatterns
        if ($reason) {
            if ($cmd -match $verbPattern -or $cmd -match 'id_rsa' -or $cmd -match 'id_ed25519' -or $cmd -match '[\\/]\.aws[\\/]credentials') {
                $snippet = $cmd
                if ($snippet.Length -gt 200) { $snippet = $snippet.Substring(0, 200) + '...' }
                [Console]::Error.WriteLine("[protect-secrets] Refused: $snippet. Reason: secret-like file ($reason). Override only by user.")
                exit 2
            }
        }
    }

    exit 0
} catch {
    exit 0
}
