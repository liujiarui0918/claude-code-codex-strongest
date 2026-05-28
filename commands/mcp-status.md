---
description: Check status of configured MCP servers
argument-hint:
allowed-tools: PowerShell, Read
---

Inspect the MCP server configuration in `~/.claude.json` and report on each entry.

## Steps

1. Read and parse the global config:

   ```powershell
   $cfgPath = Join-Path $HOME '.claude.json'
   if (-not (Test-Path $cfgPath)) {
       Write-Output "No ~/.claude.json found at $cfgPath"
       return
   }
   $cfg = Get-Content $cfgPath -Raw -Encoding UTF8 | ConvertFrom-Json
   $servers = $cfg.mcpServers
   if (-not $servers) {
       Write-Output "No mcpServers configured."
       return
   }
   ```

2. For each property on `$servers`, determine the transport type and key fields:
   - If the entry has a `url` -> transport is `http` (or `sse` if `type: "sse"`), record `url`.
   - If the entry has `command` -> transport is `stdio`, record `command` + `args` (joined by space).

   ```powershell
   $rows = @()
   $servers.PSObject.Properties | ForEach-Object {
       $name = $_.Name
       $s = $_.Value
       if ($s.url) {
           $type = if ($s.type) { $s.type } else { 'http' }
           $endpoint = $s.url
       } elseif ($s.command) {
           $type = 'stdio'
           $endpoint = (@($s.command) + @($s.args)) -join ' '
       } else {
           $type = 'unknown'
           $endpoint = ''
       }
       $rows += [pscustomobject]@{ name = $name; type = $type; endpoint = $endpoint; command = $s.command }
   }
   $rows | Sort-Object name | Format-Table -AutoSize | Out-String
   ```

3. Render the list as a markdown table:

   ```
   | server | type | endpoint |
   | --- | --- | --- |
   ```

4. Sanity check stdio entries: if any `command` is `npx` or `npm`, confirm npx is on PATH; if `command` is `uvx` / `uv`, confirm uv is installed:

   ```powershell
   $needsNpx = $rows | Where-Object { $_.command -in @('npx','npm') }
   $needsUv  = $rows | Where-Object { $_.command -in @('uvx','uv') }
   if ($needsNpx -and -not (Get-Command npx -ErrorAction SilentlyContinue)) {
       Write-Output "WARNING: stdio MCP needs npx but npx is not on PATH: $($needsNpx.name -join ', ')"
   }
   if ($needsUv -and -not (Get-Command uv -ErrorAction SilentlyContinue)) {
       Write-Output "WARNING: stdio MCP needs uv but uv is not on PATH: $($needsUv.name -join ', ')"
   }
   ```

5. After the table, remind the user: "This shows configuration only. Run the built-in `/mcp` command to see live connection status."
