---
description: List all available skills with one-line descriptions
argument-hint: [filter pattern, optional]
allowed-tools: PowerShell, Read, Glob
---

List every installed skill on this machine, optionally filtered by `$ARGUMENTS`.

## Steps

1. Find all `SKILL.md` files:

   ```powershell
   Get-ChildItem (Join-Path $HOME '.claude/skills') -Recurse -Filter SKILL.md -ErrorAction SilentlyContinue
   ```

2. For each file, parse the YAML frontmatter and extract `name` and `description`. The frontmatter is delimited by `---` lines at the top. A robust extraction approach in PowerShell:

   ```powershell
   $skills = @()
   Get-ChildItem (Join-Path $HOME '.claude/skills') -Recurse -Filter SKILL.md -ErrorAction SilentlyContinue | ForEach-Object {
       $lines = Get-Content $_.FullName -Encoding UTF8
       if ($lines[0] -ne '---') { return }
       $end = 1
       while ($end -lt $lines.Count -and $lines[$end] -ne '---') { $end++ }
       $fm = $lines[1..($end-1)]
       $name = ($fm | Where-Object { $_ -match '^\s*name:\s*(.+?)\s*$' } | ForEach-Object { $Matches[1].Trim('"',"'") }) | Select-Object -First 1
       $desc = ($fm | Where-Object { $_ -match '^\s*description:\s*(.+?)\s*$' } | ForEach-Object { $Matches[1].Trim('"',"'") }) | Select-Object -First 1
       if (-not $name) { $name = $_.Directory.Name }
       $skills += [pscustomobject]@{ name = $name; description = $desc }
   }
   $skills | Sort-Object name
   ```

3. If `$ARGUMENTS` is non-empty, filter the resulting list (case-insensitive substring match on either `name` or `description`).

4. Render as a markdown table:

   ```
   | skill | description |
   | --- | --- |
   | <name> | <description> |
   ```

   Sort rows alphabetically by skill name. Truncate any description longer than ~120 chars with a trailing ellipsis so the table stays readable.

5. After the table, print a one-line count: `Found N skills` (or `Found N skills matching "<filter>"`).

6. Suggest 2-3 high-value skills the user likely wants to invoke next, based on what's installed (e.g., `brainstorming` for design work, `systematic-debugging` for bugs, `verification-before-completion` before claiming done). Keep this to 3 lines max.

Filter argument (may be empty): `$ARGUMENTS`
