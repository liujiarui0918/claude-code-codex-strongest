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
    $fp = $null
    if ($payload.tool_input -and $payload.tool_input.file_path) {
        $fp = [string]$payload.tool_input.file_path
    }
    if ([string]::IsNullOrWhiteSpace($fp) -or -not (Test-Path -LiteralPath $fp)) { exit 0 }

    $ext = [System.IO.Path]::GetExtension($fp).ToLowerInvariant()

    # Map extension -> @{ tool = exe-name; args = @(...args...) }
    $jobs = @()
    switch -Regex ($ext) {
        '^\.(js|ts|jsx|tsx|json|css|scss|html|md|markdown|yaml|yml)$' {
            $jobs += ,@{ tool = 'prettier'; args = @('--write', $fp) }
            break
        }
        '^\.py$' {
            if (Get-Command 'ruff' -ErrorAction SilentlyContinue) {
                $jobs += ,@{ tool = 'ruff'; args = @('format', $fp) }
            } elseif (Get-Command 'black' -ErrorAction SilentlyContinue) {
                $jobs += ,@{ tool = 'black'; args = @('--quiet', $fp) }
            }
            break
        }
        '^\.go$' {
            $jobs += ,@{ tool = 'gofmt'; args = @('-w', $fp) }
            break
        }
        '^\.rs$' {
            $jobs += ,@{ tool = 'rustfmt'; args = @($fp) }
            break
        }
    }

    foreach ($j in $jobs) {
        $tool = $j.tool
        $args = $j.args
        $cmd = Get-Command $tool -ErrorAction SilentlyContinue
        if (-not $cmd) { continue }

        # Run with 2-second timeout via background job; suppress all output.
        $job = Start-Job -ScriptBlock {
            param($exe, $a)
            try { & $exe @a 2>&1 | Out-Null } catch { }
        } -ArgumentList $cmd.Source, $args

        $finished = Wait-Job -Job $job -Timeout 2
        if (-not $finished) {
            try { Stop-Job -Job $job -ErrorAction SilentlyContinue } catch { }
        }
        try { Remove-Job -Job $job -Force -ErrorAction SilentlyContinue } catch { }
    }

    exit 0
} catch {
    exit 0
}
