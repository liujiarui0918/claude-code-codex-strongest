#requires -version 5.1
$ErrorActionPreference = 'Stop'

try {
    $stdinReader = [System.IO.StreamReader]::new([Console]::OpenStandardInput(), [System.Text.Encoding]::UTF8)
    $jsonText = $stdinReader.ReadToEnd()
    if (-not [string]::IsNullOrWhiteSpace($jsonText)) {
        $null = $jsonText | ConvertFrom-Json
    }
} catch {
    # ignore — Stop hooks don't need payload
}

try {
    # Throttle: don't replay within 2 seconds.
    $throttleFile = Join-Path $env:TEMP '.claude_last_stop'
    $nowTicks = [DateTime]::UtcNow.Ticks
    $twoSec = [TimeSpan]::FromSeconds(2).Ticks

    if (Test-Path -LiteralPath $throttleFile) {
        try {
            $lastRaw = Get-Content -LiteralPath $throttleFile -Raw -ErrorAction Stop
            $last = [int64]($lastRaw.Trim())
            if (($nowTicks - $last) -lt $twoSec) {
                exit 0
            }
        } catch {
            # bad content — treat as no throttle
        }
    }

    try {
        Set-Content -LiteralPath $throttleFile -Value $nowTicks -Encoding utf8 -Force
    } catch { }

    try {
        [System.Media.SystemSounds]::Asterisk.Play()
    } catch { }

    exit 0
} catch {
    exit 0
}
