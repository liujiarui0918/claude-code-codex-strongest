#requires -version 5.1
$ErrorActionPreference = 'Stop'

function Get-FirstToken([string]$cmdline) {
    if ([string]::IsNullOrWhiteSpace($cmdline)) { return $null }
    $s = $cmdline.Trim()
    # Handle quoted path.
    if ($s.StartsWith('"')) {
        $end = $s.IndexOf('"', 1)
        if ($end -gt 0) { return $s.Substring(1, $end - 1) }
    }
    $sp = $s.IndexOf(' ')
    if ($sp -lt 0) { return $s }
    return $s.Substring(0, $sp)
}

function Test-StdioServer($server) {
    # Returns @{ ok = $bool; reason = $string }
    $command = [string]$server.command
    $argsArr = @()
    try { if ($server.args) { $argsArr = @($server.args) } } catch { }

    if ([string]::IsNullOrWhiteSpace($command)) {
        return @{ ok = $false; reason = 'no command field' }
    }

    # Check the command itself is resolvable.
    $cmdInfo = Get-Command $command -ErrorAction SilentlyContinue
    if (-not $cmdInfo) {
        return @{ ok = $false; reason = "command '$command' not on PATH" }
    }

    # Heuristic: if it's `cmd /c npx ...` (or similar wrapper), check the real tool.
    $lowerCmd = $command.ToLower()
    $wrapperHosts = @('cmd', 'cmd.exe', 'powershell', 'powershell.exe', 'pwsh', 'pwsh.exe', 'wsl', 'wsl.exe')
    if ($wrapperHosts -contains $lowerCmd) {
        # Skip flags like /c, /k, -c, -Command and find the first real exe/tool.
        $skipNext = $false
        $realTool = $null
        foreach ($a in $argsArr) {
            if ($skipNext) { $skipNext = $false; continue }
            $al = ([string]$a).Trim()
            if ([string]::IsNullOrWhiteSpace($al)) { continue }
            if ($al -match '^[-/](c|k|Command|File)$') { continue }
            # First token of the remainder.
            $realTool = Get-FirstToken $al
            break
        }
        if ($realTool) {
            $rt = Get-Command $realTool -ErrorAction SilentlyContinue
            if (-not $rt) {
                return @{ ok = $false; reason = "wrapper '$command' present but '$realTool' not on PATH" }
            }
            return @{ ok = $true; reason = "via $command -> $realTool (both on PATH)" }
        }
    }

    return @{ ok = $true; reason = "command '$command' resolvable" }
}

function Test-HttpServer($server) {
    $url = [string]$server.url
    if ([string]::IsNullOrWhiteSpace($url)) {
        return @{ ok = $false; reason = 'no url field' }
    }
    try {
        # OPTIONS is a probe; many servers reply 405/404 but the TCP/TLS handshake succeeding is what we want.
        $resp = Invoke-WebRequest -Uri $url -Method Options -TimeoutSec 5 -UseBasicParsing -ErrorAction Stop
        return @{ ok = $true; reason = "HTTP $($resp.StatusCode)" }
    } catch [System.Net.WebException] {
        # A WebException with a Response means we reached the server -- count as reachable.
        $we = $_.Exception
        if ($we.Response) {
            try {
                $code = [int]$we.Response.StatusCode
                return @{ ok = $true; reason = "HTTP $code" }
            } catch {
                return @{ ok = $true; reason = 'server responded (status unknown)' }
            }
        }
        return @{ ok = $false; reason = $we.Message }
    } catch {
        # Newer Invoke-WebRequest wraps 4xx/5xx as HttpResponseException with a Response.
        $resp = $null
        try { $resp = $_.Exception.Response } catch { }
        if ($resp) {
            try {
                $code = [int]$resp.StatusCode
                return @{ ok = $true; reason = "HTTP $code" }
            } catch {
                return @{ ok = $true; reason = 'server responded (status unknown)' }
            }
        }
        return @{ ok = $false; reason = $_.Exception.Message }
    }
}

try {
    $cfg = Join-Path $HOME '.claude.json'
    if (-not (Test-Path -LiteralPath $cfg)) {
        Write-Host "Config not found: $cfg"
        exit 1
    }

    $j = $null
    try {
        $j = Get-Content -LiteralPath $cfg -Raw -Encoding UTF8 | ConvertFrom-Json
    } catch {
        Write-Host "Failed to parse $cfg : $($_.Exception.Message)"
        exit 1
    }

    if (-not $j.mcpServers) {
        Write-Host 'No mcpServers configured.'
        exit 0
    }

    $names = @($j.mcpServers.PSObject.Properties.Name)
    if ($names.Count -eq 0) {
        Write-Host 'No mcpServers configured.'
        exit 0
    }

    $results = New-Object System.Collections.Generic.List[pscustomobject]
    $anyFail = $false

    foreach ($n in $names) {
        $srv = $j.mcpServers.$n
        $type = [string]$srv.type
        if ([string]::IsNullOrWhiteSpace($type)) {
            # Infer: url -> http, command -> stdio.
            if ($srv.url)     { $type = 'http' }
            elseif ($srv.command) { $type = 'stdio' }
            else                  { $type = '?' }
        }

        $r = $null
        switch ($type) {
            'http'  { $r = Test-HttpServer $srv }
            'sse'   { $r = Test-HttpServer $srv }
            'stdio' { $r = Test-StdioServer $srv }
            default { $r = @{ ok = $false; reason = "unknown type '$type'" } }
        }

        if (-not $r.ok) { $anyFail = $true }

        $mark = if ($r.ok) { 'OK ' } else { 'BAD' }
        $line = "[{0}] {1,-22} {2,-6} - {3}" -f $mark, $n, $type, $r.reason
        Write-Host $line
        $results.Add([pscustomobject]@{
            Name   = $n
            Type   = $type
            Status = $mark
            Reason = $r.reason
        }) | Out-Null
    }

    Write-Host ''
    Write-Host '+--------+------------------------+--------+'
    Write-Host '| Status | Name                   | Type   |'
    Write-Host '+--------+------------------------+--------+'
    foreach ($row in $results) {
        $line = "| {0,-6} | {1,-22} | {2,-6} |" -f $row.Status, $row.Name, $row.Type
        Write-Host $line
    }
    Write-Host '+--------+------------------------+--------+'

    if ($anyFail) { exit 1 } else { exit 0 }
} catch {
    Write-Host "mcp-doctor failed: $($_.Exception.Message)"
    exit 1
}
