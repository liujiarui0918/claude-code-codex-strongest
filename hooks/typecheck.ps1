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

    function Find-TsconfigDir {
        param([string]$startFile)
        $dir = Split-Path -Path $startFile -Parent
        for ($i = 0; $i -lt 8 -and -not [string]::IsNullOrWhiteSpace($dir); $i++) {
            if (Test-Path -LiteralPath (Join-Path $dir 'tsconfig.json')) {
                return $dir
            }
            $parent = Split-Path -Path $dir -Parent
            if ($parent -eq $dir) { break }
            $dir = $parent
        }
        return $null
    }

    function Invoke-WithTimeout {
        param([string]$Exe, [string[]]$Args, [string]$WorkDir, [int]$TimeoutSec = 5)
        $job = Start-Job -ScriptBlock {
            param($exe, $a, $wd)
            try {
                if ($wd) { Set-Location -LiteralPath $wd }
                $output = & $exe @a 2>&1
                [pscustomobject]@{ ExitCode = $LASTEXITCODE; Output = ($output | Out-String) }
            } catch {
                [pscustomobject]@{ ExitCode = 1; Output = $_.Exception.Message }
            }
        } -ArgumentList $Exe, $Args, $WorkDir

        $finished = Wait-Job -Job $job -Timeout $TimeoutSec
        if (-not $finished) {
            try { Stop-Job -Job $job -ErrorAction SilentlyContinue } catch { }
            try { Remove-Job -Job $job -Force -ErrorAction SilentlyContinue } catch { }
            return $null
        }
        $r = Receive-Job -Job $job -ErrorAction SilentlyContinue
        try { Remove-Job -Job $job -Force -ErrorAction SilentlyContinue } catch { }
        return $r
    }

    $result = $null

    switch -Regex ($ext) {
        '^\.(ts|tsx)$' {
            $tsc = Get-Command tsc -ErrorAction SilentlyContinue
            if ($tsc) {
                $cfgDir = Find-TsconfigDir -startFile $fp
                if ($cfgDir) {
                    $result = Invoke-WithTimeout -Exe $tsc.Source -Args @('--noEmit', '-p', $cfgDir) -WorkDir $cfgDir -TimeoutSec 5
                } else {
                    $result = Invoke-WithTimeout -Exe $tsc.Source -Args @('--noEmit', $fp) -WorkDir (Split-Path $fp -Parent) -TimeoutSec 5
                }
            }
            break
        }
        '^\.py$' {
            $pyright = Get-Command pyright -ErrorAction SilentlyContinue
            if ($pyright) {
                $result = Invoke-WithTimeout -Exe $pyright.Source -Args @($fp) -WorkDir (Split-Path $fp -Parent) -TimeoutSec 5
            } else {
                $mypy = Get-Command mypy -ErrorAction SilentlyContinue
                if ($mypy) {
                    $result = Invoke-WithTimeout -Exe $mypy.Source -Args @($fp) -WorkDir (Split-Path $fp -Parent) -TimeoutSec 5
                }
            }
            break
        }
    }

    if ($null -ne $result -and $result.ExitCode -ne 0 -and -not [string]::IsNullOrWhiteSpace($result.Output)) {
        $msg = $result.Output.Trim()
        if ($msg.Length -gt 2000) { $msg = $msg.Substring(0, 2000) + '...' }
        [Console]::Error.WriteLine("[typecheck] Issues in $fp`n$msg")
    }

    exit 0
} catch {
    exit 0
}
