#requires -version 5.1
$ErrorActionPreference = 'Stop'

try {
    $stdinReader = [System.IO.StreamReader]::new([Console]::OpenStandardInput(), [System.Text.Encoding]::UTF8)
    $jsonText = $stdinReader.ReadToEnd()
    if ([string]::IsNullOrWhiteSpace($jsonText)) {
        [Console]::Out.Write('[Claude Code]')
        exit 0
    }
    $payload = $jsonText | ConvertFrom-Json
} catch {
    [Console]::Out.Write('[Claude Code]')
    exit 0
}

try {
    # --- Model short name ----------------------------------------------------
    $modelShort = '?'
    try {
        $disp = $null
        if ($payload.model -and $payload.model.display_name) {
            $disp = [string]$payload.model.display_name
        }
        if (-not [string]::IsNullOrWhiteSpace($disp)) {
            # e.g. "Opus 4.7" -> "O4.7", "Sonnet 4.6" -> "S4.6", "Haiku 4.5" -> "H4.5"
            $m = [regex]::Match($disp, '^\s*([A-Za-z])[A-Za-z]*\s+([0-9]+(?:\.[0-9]+)?)')
            if ($m.Success) {
                $modelShort = $m.Groups[1].Value.ToUpper() + $m.Groups[2].Value
            } else {
                $modelShort = ($disp -replace '\s+', '').Substring(0, [Math]::Min(6, ($disp -replace '\s+', '').Length))
            }
        }
    } catch { $modelShort = '?' }

    # --- Project name --------------------------------------------------------
    $projectName = '?'
    $curDir = $null
    try {
        if ($payload.workspace -and $payload.workspace.current_dir) {
            $curDir = [string]$payload.workspace.current_dir
        }
        if ([string]::IsNullOrWhiteSpace($curDir) -and $payload.cwd) {
            $curDir = [string]$payload.cwd
        }
        if (-not [string]::IsNullOrWhiteSpace($curDir)) {
            $leaf = Split-Path -Path $curDir -Leaf
            if (-not [string]::IsNullOrWhiteSpace($leaf)) { $projectName = $leaf }
        }
    } catch { $projectName = '?' }

    # --- Git branch (optional block) -----------------------------------------
    $branch = ''
    try {
        if (-not [string]::IsNullOrWhiteSpace($curDir) -and (Test-Path -LiteralPath (Join-Path $curDir '.git'))) {
            $git = Get-Command git -ErrorAction SilentlyContinue
            if ($git) {
                $b = (& git -C $curDir rev-parse --abbrev-ref HEAD 2>$null) -join ''
                if ($b) { $branch = $b.Trim() }
            }
        }
    } catch { $branch = '' }

    # --- MCP count -----------------------------------------------------------
    $mcpCount = 0
    try {
        $cfg = Join-Path $HOME '.claude.json'
        if (Test-Path -LiteralPath $cfg) {
            $j = Get-Content -LiteralPath $cfg -Raw -Encoding UTF8 | ConvertFrom-Json
            if ($j.mcpServers) {
                $mcpCount = @($j.mcpServers.PSObject.Properties.Name).Count
            }
        }
    } catch { $mcpCount = 0 }

    # --- Session id ----------------------------------------------------------
    $sid4 = '?'
    try {
        if ($payload.session_id) {
            $s = [string]$payload.session_id
            if ($s.Length -ge 4) { $sid4 = $s.Substring(0, 4) } else { $sid4 = $s }
        }
    } catch { $sid4 = '?' }

    # --- Assemble ASCII line -------------------------------------------------
    $parts = @("[$modelShort]", $projectName)
    if (-not [string]::IsNullOrWhiteSpace($branch)) {
        $parts += '|'
        $parts += $branch
    }
    if ($mcpCount -gt 0) {
        $parts += '|'
        $parts += "${mcpCount}MCP"
    }
    $parts += '|'
    $parts += $sid4

    $line = ($parts -join ' ')
    $line = ($line -replace "`r?`n", ' ').Trim()
    if ($line.Length -gt 100) { $line = $line.Substring(0, 100) }

    [Console]::Out.Write($line)
    exit 0
} catch {
    [Console]::Out.Write('[Claude Code]')
    exit 0
}
