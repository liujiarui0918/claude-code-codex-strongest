---
description: List all available agents with description, tools, model
argument-hint: [filter pattern, optional]
allowed-tools: PowerShell, Read, Glob
---

List every installed subagent on this machine, optionally filtered by `$ARGUMENTS`.

## Steps

1. Find all agent files:

   ```powershell
   Get-ChildItem (Join-Path $HOME '.claude/agents') -Filter *.md -ErrorAction SilentlyContinue
   ```

2. For each file, parse YAML frontmatter and extract `name`, `description`, `tools`, `model`:

   ```powershell
   $agents = @()
   Get-ChildItem (Join-Path $HOME '.claude/agents') -Filter *.md -ErrorAction SilentlyContinue | ForEach-Object {
       $lines = Get-Content $_.FullName -Encoding UTF8
       if ($lines[0] -ne '---') { return }
       $end = 1
       while ($end -lt $lines.Count -and $lines[$end] -ne '---') { $end++ }
       $fm = $lines[1..($end-1)]
       function Get-FmValue($key) {
           ($fm | Where-Object { $_ -match "^\s*${key}:\s*(.+?)\s*$" } | ForEach-Object { $Matches[1].Trim('"',"'") }) | Select-Object -First 1
       }
       $name  = Get-FmValue 'name'
       $desc  = Get-FmValue 'description'
       $tools = Get-FmValue 'tools'
       $model = Get-FmValue 'model'
       if (-not $name) { $name = [IO.Path]::GetFileNameWithoutExtension($_.Name) }
       $agents += [pscustomobject]@{ agent = $name; description = $desc; tools = $tools; model = $model }
   }
   $agents | Sort-Object agent
   ```

3. If `$ARGUMENTS` is non-empty, case-insensitive substring filter on `agent` or `description`.

4. Render as markdown table:

   ```
   | agent | description | tools | model |
   | --- | --- | --- | --- |
   ```

   Truncate description to ~100 chars and tools to ~60 chars with ellipsis so the row stays readable. If `model` is empty, render as `(inherit)`.

5. After the table, print `Found N agents` (or `Found N agents matching "<filter>"`).

6. If any well-known agents are present (`planner`, `code-reviewer`, `security-reviewer`, `debugger`, `research-agent`, `explore`), call them out in one short line: "Common workflows: dispatch `planner` for design, `debugger` for bugs, `code-reviewer` before commit."

Filter argument (may be empty): `$ARGUMENTS`
