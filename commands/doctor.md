---
description: "Diagnose Claude Code config health: hooks, MCPs, skills, agents"
argument-hint:
allowed-tools: PowerShell, Read
---

Run a full self-check on the local Claude Code configuration and report each result as a checkmark or cross with a one-line reason.

## Checks (run all, do not stop on first failure)

For each check, accumulate a result into a list of `[name, ok, detail]` and render a final table.

### 1. settings.json — JSON valid, hook paths exist

```powershell
$settingsPath = Join-Path $HOME '.claude/settings.json'
$settingsOK = $false
$settingsDetail = ''
$hooks = @()
if (-not (Test-Path $settingsPath)) {
    $settingsDetail = "settings.json not found"
} else {
    try {
        $s = Get-Content $settingsPath -Raw -Encoding UTF8 | ConvertFrom-Json
        $settingsOK = $true
        $settingsDetail = "parsed OK"
        # Walk hook configurations and collect command strings ending in .ps1
        if ($s.hooks) {
            $s.hooks.PSObject.Properties | ForEach-Object {
                $eventEntries = $_.Value
                foreach ($entry in $eventEntries) {
                    foreach ($h in $entry.hooks) {
                        if ($h.command) { $hooks += $h.command }
                    }
                }
            }
        }
    } catch {
        $settingsDetail = "JSON parse failed: $($_.Exception.Message)"
    }
}
```

For each hook command string, extract a `.ps1` path (look for `~/.claude/hooks/*.ps1` substrings or `&` invocations) and Test-Path it. Report the count of missing hook scripts.

### 2. ~/.claude.json mcpServers

```powershell
$claudeJsonPath = Join-Path $HOME '.claude.json'
$mcpOK = $false
$mcpDetail = ''
$mcpCount = 0
if (-not (Test-Path $claudeJsonPath)) {
    $mcpDetail = "~/.claude.json not found"
} else {
    try {
        $j = Get-Content $claudeJsonPath -Raw -Encoding UTF8 | ConvertFrom-Json
        if ($j.mcpServers) {
            $mcpCount = ($j.mcpServers.PSObject.Properties | Measure-Object).Count
        }
        $mcpOK = $mcpCount -gt 0
        $mcpDetail = "$mcpCount mcpServers configured"
    } catch {
        $mcpDetail = "JSON parse failed: $($_.Exception.Message)"
    }
}
```

### 3. Skills (>= 21 expected) with valid frontmatter

```powershell
$skillFiles = Get-ChildItem (Join-Path $HOME '.claude/skills') -Recurse -Filter SKILL.md -ErrorAction SilentlyContinue
$skillCount = $skillFiles.Count
$skillBad = @()
foreach ($f in $skillFiles) {
    $lines = Get-Content $f.FullName -Encoding UTF8 -ErrorAction SilentlyContinue
    if (-not $lines -or $lines[0] -ne '---') { $skillBad += $f.FullName; continue }
    $end = 1; while ($end -lt $lines.Count -and $lines[$end] -ne '---') { $end++ }
    $fm = $lines[1..($end-1)] -join "`n"
    if ($fm -notmatch '(?m)^\s*name:\s*\S' -or $fm -notmatch '(?m)^\s*description:\s*\S') {
        $skillBad += $f.FullName
    }
}
$skillOK = ($skillCount -ge 21) -and ($skillBad.Count -eq 0)
```

### 4. Agents (>= 12 expected) with valid frontmatter

```powershell
$agentFiles = Get-ChildItem (Join-Path $HOME '.claude/agents') -Filter *.md -ErrorAction SilentlyContinue
$agentCount = $agentFiles.Count
$agentBad = @()
foreach ($f in $agentFiles) {
    $lines = Get-Content $f.FullName -Encoding UTF8 -ErrorAction SilentlyContinue
    if (-not $lines -or $lines[0] -ne '---') { $agentBad += $f.FullName; continue }
    $end = 1; while ($end -lt $lines.Count -and $lines[$end] -ne '---') { $end++ }
    $fm = $lines[1..($end-1)] -join "`n"
    $missing = @()
    foreach ($k in 'name','description','tools','model') {
        if ($fm -notmatch "(?m)^\s*${k}:\s*\S") { $missing += $k }
    }
    if ($missing.Count) { $agentBad += "$($f.FullName) [missing: $($missing -join ',')]" }
}
$agentOK = ($agentCount -ge 12) -and ($agentBad.Count -eq 0)
```

### 5. Hooks (11 expected) parse cleanly

```powershell
$hookFiles = Get-ChildItem (Join-Path $HOME '.claude/hooks') -Filter *.ps1 -ErrorAction SilentlyContinue
$hookCount = $hookFiles.Count
$hookBad = @()
foreach ($f in $hookFiles) {
    $tokens = $null; $errors = $null
    [System.Management.Automation.Language.Parser]::ParseFile($f.FullName, [ref]$tokens, [ref]$errors) | Out-Null
    if ($errors -and $errors.Count -gt 0) {
        $hookBad += "$($f.Name): $($errors[0].Message)"
    }
}
$hookOK = ($hookCount -ge 11) -and ($hookBad.Count -eq 0)
```

### 6. External deps: BurntToast, git, uv

```powershell
$burntToast = [bool](Get-Module BurntToast -ListAvailable -ErrorAction SilentlyContinue)
$hasGit = [bool](Get-Command git -ErrorAction SilentlyContinue)
$hasUv  = [bool](Get-Command uv  -ErrorAction SilentlyContinue)
$hasNpx = [bool](Get-Command npx -ErrorAction SilentlyContinue)
```

## Output

Render a markdown table:

```
| check | status | detail |
| --- | --- | --- |
| settings.json valid | OK / FAIL | <reason> |
| hook paths in settings exist | OK / FAIL | <N missing> |
| ~/.claude.json mcpServers | OK / FAIL | <N configured> |
| skills (>=21 + frontmatter) | OK / FAIL | <count, bad list> |
| agents (>=12 + frontmatter) | OK / FAIL | <count, bad list> |
| hooks (>=11 + parse) | OK / FAIL | <count, bad list> |
| BurntToast installed | OK / FAIL | <yes/no> |
| git on PATH | OK / FAIL | <yes/no> |
| uv on PATH | OK / FAIL | <yes/no> |
| npx on PATH | OK / FAIL | <yes/no> |
```

Use `OK` for pass and `FAIL` for fail. Do not use emoji.

After the table, print a one-line summary: `N/M checks passing`. If any FAIL, list 1-3 concrete fix suggestions (e.g., "Install BurntToast: `Install-Module BurntToast -Scope CurrentUser`", "Run `uv` installer from https://docs.astral.sh/uv/", "Restore missing hook scripts from backup").
