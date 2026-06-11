#requires -version 5.1
<#
.SYNOPSIS
    One-click installer for claude-code-codex-strongest on Windows.

.DESCRIPTION
    Installs VS Code, Claude Code CLI, Codex CLI, official VS Code extensions, and deploys
    the full ~/.claude/ configuration (skills, agents, commands, hooks) plus Claude Code Codex Strongest
    templates to ~/.codex/ and the 8 MCP servers into ~/.claude.json. Also installs
    cc-switch (a multi-provider /
    multi-model GUI) and opens it at the end so you enter your API key / provider
    there -- there is NO credential popup. Use -NoCcSwitch to skip cc-switch.

.PARAMETER ClaudeHome
    Override the default ~/.claude install location.

.PARAMETER ApiToken
    Optional Anthropic API key / relay token for scripted installs. If omitted, no
    credentials are written to settings.json -- configure your provider in cc-switch
    (which this installer opens at the end) instead.

.PARAMETER BaseUrl
    Optional Anthropic API base URL for scripted installs (paired with -ApiToken).

.PARAMETER Model
    Optional model name. If set, both ANTHROPIC_MODEL and ANTHROPIC_DEFAULT_HAIKU_MODEL
    are pinned to it -- so a single-model relay (e.g. deepseek-chat, gpt-4o) works for
    both foreground and background calls. Empty = use Claude Code defaults. For per-tier
    (Opus/Sonnet/Haiku) routing or juggling multiple providers, use cc-switch instead.

.PARAMETER NoCcSwitch
    Skip installing cc-switch. By default the installer also installs cc-switch
    (a GUI to switch Claude Code between multiple API providers and models, with a
    built-in OpenAI<->Anthropic proxy so OpenAI-format relays work). Installed via
    winget id farion1231.CC-Switch. Pass -NoCcSwitch to skip it.

.PARAMETER Reset
    Clean reinstall: back up and remove the existing ~/.claude and ~/.claude.json,
    log out of Claude Code, and uninstall+reinstall the VS Code extension. Use this
    when a machine already has VS Code / Claude Code with old or broken config.

.PARAMETER Timezone
    IANA timezone for the 'time' MCP server. Default: Asia/Shanghai.

.PARAMETER Force
    Overwrite existing ~/.claude without prompting (backs up first).

.PARAMETER NonInteractive
    Do not auto-open cc-switch when the install finishes (for CI/scripted installs).

.PARAMETER SkipPrereqs
    Skip installing VS Code / Git / Node.js / uv / Claude Code CLI.

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File install-windows.ps1

.EXAMPLE
    .\install-windows.ps1 -Reset

.EXAMPLE
    .\install-windows.ps1 -ApiToken 'sk-ant-xxx' -NonInteractive -Force
#>
[CmdletBinding()]
param(
    [string]$ClaudeHome   = '',
    [string]$CodexHome    = '',
    [string]$ApiToken     = '',
    [string]$BaseUrl      = '',
    [string]$Model        = '',
    [switch]$Reset,
    [string]$Timezone     = 'Asia/Shanghai',
    [switch]$NoCcSwitch,
    [switch]$Force,
    [switch]$NonInteractive,
    [switch]$SkipPrereqs,
    [string]$LogFile      = ''
)

$ErrorActionPreference = 'Stop'
$ProgressPreference    = 'SilentlyContinue'

# ============================================================================
# Logging
# ============================================================================
function Write-Step  { param($msg) Write-Host ">>> $msg" -ForegroundColor Cyan }
function Write-Ok    { param($msg) Write-Host "    [OK]   $msg" -ForegroundColor Green }
function Write-Warn  { param($msg) Write-Host "    [WARN] $msg" -ForegroundColor Yellow }
function Write-Err   { param($msg) Write-Host "    [ERR]  $msg" -ForegroundColor Red }
function Write-Info  { param($msg) Write-Host "    $msg" -ForegroundColor Gray }

# ============================================================================
# Utilities
# ============================================================================
function Test-Command {
    param([string]$Name)
    return [bool](Get-Command $Name -ErrorAction SilentlyContinue)
}

function Refresh-Path {
    $machine = [System.Environment]::GetEnvironmentVariable('Path', 'Machine')
    $user    = [System.Environment]::GetEnvironmentVariable('Path', 'User')
    if ($user) { $env:Path = "$machine;$user" } else { $env:Path = $machine }
}

# Create (or refresh) a Desktop .lnk via WScript.Shell. Idempotent: re-running overwrites
# the same .lnk instead of duplicating it. We create shortcuts ourselves because winget's
# VS Code (Inno Setup) only drops a desktop icon when the 'desktopicon' task is selected --
# and it skips that task entirely when VS Code is already installed. cc-switch gets one for
# free (its NSIS installer always makes one); this brings VS Code to parity.
function New-DesktopShortcut {
    param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][string]$TargetPath,
        [string]$Arguments  = '',
        [string]$WorkingDir = ''
    )
    if (-not (Test-Path $TargetPath)) {
        Write-Warn "Skipping '$Name' shortcut: target not found ($TargetPath)"
        return $false
    }
    try {
        $desktop = [Environment]::GetFolderPath('DesktopDirectory')
        if (-not $desktop) { $desktop = Join-Path $env:USERPROFILE 'Desktop' }
        $lnk   = Join-Path $desktop "$Name.lnk"
        $shell = New-Object -ComObject WScript.Shell
        $sc    = $shell.CreateShortcut($lnk)
        $sc.TargetPath       = $TargetPath
        $sc.WorkingDirectory = if ($WorkingDir) { $WorkingDir } else { Split-Path -Parent $TargetPath }
        if ($Arguments) { $sc.Arguments = $Arguments }
        $sc.IconLocation = "$TargetPath,0"
        $sc.Save()
        [System.Runtime.InteropServices.Marshal]::ReleaseComObject($shell) | Out-Null
        Write-Ok "Desktop shortcut: $lnk"
        return $true
    } catch {
        Write-Warn "Could not create '$Name' desktop shortcut: $($_.Exception.Message)"
        return $false
    }
}

# Locate Code.exe across system-wide and user-scope installs (winget may produce either),
# falling back to resolving the `code` CLI shim (<install>\bin\code.cmd -> ..\Code.exe).
function Find-VSCodeExe {
    $bases = @($env:ProgramFiles, ${env:ProgramFiles(x86)}) | Where-Object { $_ }
    $candidates = @()
    foreach ($b in $bases) { $candidates += (Join-Path $b 'Microsoft VS Code\Code.exe') }
    $candidates += (Join-Path $env:LOCALAPPDATA 'Programs\Microsoft VS Code\Code.exe')
    foreach ($c in $candidates) { if (Test-Path $c) { return $c } }

    $cmd = Get-Command code -ErrorAction SilentlyContinue
    if ($cmd -and $cmd.Source) {
        $exe = Join-Path (Split-Path -Parent (Split-Path -Parent $cmd.Source)) 'Code.exe'
        if (Test-Path $exe) { return $exe }
    }
    return $null
}

# Write UTF-8 WITHOUT BOM. Claude Code parses ~/.claude.json and settings.json with
# Node's JSON.parse, which throws on a leading BOM. PS 5.1's Set-Content -Encoding UTF8
# emits a BOM, so we must use the .NET writer with UTF8Encoding($false).
function Write-Utf8NoBom {
    param([string]$Path, [string]$Content)
    $enc = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($Path, $Content, $enc)
}

function Get-RepoRoot {
    # install-windows.ps1 lives in <repo>/install/, so go up one level.
    # Inside a function, $MyInvocation.MyCommand.Path describes the function call and is
    # $null -- with ErrorActionPreference=Stop that makes Split-Path throw before any
    # fallback runs. $PSScriptRoot is the dir of THIS .ps1 file (reliable in PS 3+).
    $here = $PSScriptRoot
    if (-not $here) { $here = Split-Path -Parent $PSCommandPath }
    if (-not $here) {
        throw 'Cannot determine script directory. Run install-windows.ps1 as a file, not via piped stdin.'
    }
    return (Resolve-Path (Join-Path $here '..')).Path
}

function Show-Welcome {
    $line = '+' + ('-' * 60) + '+'
    Write-Host ''
    Write-Host $line -ForegroundColor Magenta
    Write-Host '|  Claude Code Codex Strongest - One-Click Setup (Windows)  |' -ForegroundColor Magenta
    Write-Host '|                                                            |' -ForegroundColor Magenta
    Write-Host '|   Installs: Claude Code CLI + anthropic.claude-code        |' -ForegroundColor Magenta
    Write-Host '|             Codex CLI + openai.chatgpt + cc-switch         |' -ForegroundColor Magenta
    Write-Host '|   Deploys:  33 skills / 22 agents / 25 commands / 8 MCPs  |' -ForegroundColor Magenta
    Write-Host $line -ForegroundColor Magenta
    Write-Host ''
}

# ============================================================================
# Reset (clean reinstall)
# ============================================================================
function Reset-Environment {
    param([string]$ClaudeHome)
    Write-Step 'RESET MODE: backing up and clearing existing Claude Code state'
    $ts = Get-Date -Format 'yyyyMMdd-HHmmss'

    foreach ($target in @($ClaudeHome, (Join-Path $env:USERPROFILE '.claude.json'))) {
        if (Test-Path $target) {
            $bak = "$target.reset-bak.$ts"
            try {
                Move-Item -LiteralPath $target -Destination $bak -Force
                Write-Ok "Backed up + removed: $target"
            } catch {
                Write-Warn "Could not move $target : $($_.Exception.Message)"
            }
        }
    }

    # Log out (clears any OAuth/keyring login) if the CLI is present.
    if (Test-Command 'claude') {
        try { & claude logout 2>&1 | Out-Null; Write-Ok 'Logged out of Claude Code (claude logout)' } catch {}
    }

    # Uninstall the VS Code extension so prereqs reinstalls it clean.
    if (Test-Command 'code') {
        try { & code --uninstall-extension anthropic.claude-code 2>&1 | Out-Null; Write-Ok 'Removed VS Code extension (will reinstall)' } catch {}
    }

    # Clear the extension's globalStorage (settings/cache), backed up.
    $gs = Join-Path $env:APPDATA 'Code\User\globalStorage\anthropic.claude-code'
    if (Test-Path $gs) {
        try { Move-Item -LiteralPath $gs -Destination "$gs.reset-bak.$ts" -Force; Write-Ok 'Cleared VS Code extension globalStorage' } catch {}
    }

    Write-Host ''
}

# ============================================================================
# Prerequisites
# ============================================================================
function Test-Winget {
    if (-not (Test-Command 'winget')) {
        Write-Err 'winget not found.'
        Write-Info 'Install "App Installer" from the Microsoft Store, then re-run.'
        Write-Info 'Or download from: https://aka.ms/getwinget'
        return $false
    }
    return $true
}

function Invoke-Winget {
    param(
        [string]$Id,
        [string]$Friendly,
        [string]$Override = ''
    )
    Write-Step "Installing $Friendly (winget id: $Id)"
    $argList = @('install', '--id', $Id, '--source', 'winget',
                 '--silent', '--accept-package-agreements', '--accept-source-agreements')
    if ($Override) { $argList += @('--override', $Override) }
    try {
        & winget @argList | Out-Null
        $code = $LASTEXITCODE
        if ($code -eq 0) {
            Write-Ok "$Friendly installed"
            return $true
        } elseif ($code -eq -1978335189 -or $code -eq -1978335135) {
            Write-Ok "$Friendly already installed"
            return $true
        } else {
            Write-Warn "$Friendly winget exit code $code"
            return $false
        }
    } catch {
        Write-Warn "$Friendly install threw: $($_.Exception.Message)"
        return $false
    }
}

function Install-Prerequisites {
    Write-Step 'Phase 1/5: Installing prerequisites via winget'
    if (-not (Test-Winget)) {
        throw 'winget unavailable; cannot proceed in unattended mode.'
    }

    # VS Code with full Inno Setup options
    $vscodeOverride = '/VERYSILENT /SP- /MERGETASKS=!runcode,desktopicon,addcontextmenufiles,addcontextmenufolders,associatewithfiles,addtopath'
    Invoke-Winget -Id 'Microsoft.VisualStudioCode' -Friendly 'VS Code' -Override $vscodeOverride | Out-Null

    Invoke-Winget -Id 'Git.Git'         -Friendly 'Git'         | Out-Null
    Invoke-Winget -Id 'OpenJS.NodeJS'   -Friendly 'Node.js LTS' | Out-Null
    Invoke-Winget -Id 'astral-sh.uv'    -Friendly 'uv (Python)' | Out-Null

    Refresh-Path

    # npm-based: Claude Code CLI
    Write-Step 'Installing Claude Code CLI (npm)'
    if (Test-Command 'npm') {
        try {
            & npm install -g '@anthropic-ai/claude-code' 2>&1 | Out-Null
            if (Test-Command 'claude') {
                Write-Ok 'Claude Code CLI installed'
            } else {
                Refresh-Path
                if (Test-Command 'claude') {
                    Write-Ok 'Claude Code CLI installed (after PATH refresh)'
                } else {
                    Write-Warn 'npm reported success but `claude` not on PATH. Open a NEW terminal after install.'
                }
            }
        } catch {
            Write-Warn "npm install failed: $($_.Exception.Message)"
            Write-Info 'You can install manually later: npm install -g @anthropic-ai/claude-code'
        }
    } else {
        Write-Warn 'npm not on PATH; skipping Claude Code CLI. Re-run after Node installs.'
    }

    # npm-based: Codex CLI (authentication stays user-owned; run `codex login` after install).
    Write-Step 'Installing Codex CLI (npm)'
    if (Test-Command 'npm') {
        try {
            & npm install -g '@openai/codex' 2>&1 | Out-Null
            if (Test-Command 'codex') {
                Write-Ok 'Codex CLI installed'
            } else {
                Refresh-Path
                if (Test-Command 'codex') {
                    Write-Ok 'Codex CLI installed (after PATH refresh)'
                } else {
                    Write-Warn 'npm reported success but `codex` not on PATH. Open a NEW terminal after install.'
                }
            }
        } catch {
            Write-Warn "Codex npm install failed: $($_.Exception.Message)"
            Write-Info 'You can install manually later: npm install -g @openai/codex'
        }
    } else {
        Write-Warn 'npm not on PATH; skipping Codex CLI. Re-run after Node installs.'
    }

    # VS Code extensions
    $vscodeExtensions = @(
        'anthropic.claude-code',
        'openai.chatgpt',
        'MS-CEINTL.vscode-language-pack-zh-hans',
        'cweijan.vscode-office'
    )
    Write-Step 'Installing VS Code extensions'
    if (Test-Command 'code') {
        foreach ($ext in $vscodeExtensions) {
            try {
                & code --install-extension $ext --force | Out-Null
                $codeExit = $LASTEXITCODE
                if ($codeExit -eq 0) {
                    Write-Ok "VS Code extension installed: $ext"
                } else {
                    Write-Warn "code --install-extension $ext exited with code $codeExit"
                    Write-Info "Install manually in VS Code: code --install-extension $ext"
                }
            } catch {
                Write-Warn "code --install-extension $ext failed: $($_.Exception.Message)"
                Write-Info "Install manually in VS Code: code --install-extension $ext"
            }
        }
    } else {
        Write-Warn '`code` CLI not on PATH; VS Code extensions skipped.'
        foreach ($ext in $vscodeExtensions) {
            Write-Info "After installing VS Code, run: code --install-extension $ext"
        }
    }

    # Desktop shortcut for VS Code (parity with cc-switch, whose installer makes one).
    Write-Step 'Creating VS Code desktop shortcut'
    $codeExe = Find-VSCodeExe
    if ($codeExe) {
        New-DesktopShortcut -Name 'Visual Studio Code' -TargetPath $codeExe | Out-Null
    } else {
        Write-Warn 'Code.exe not found; skipping VS Code desktop shortcut.'
    }

    Write-Host ''
}

# ============================================================================
# cc-switch (optional multi-provider switcher)
# ============================================================================
function Install-CcSwitch {
    Write-Step 'Installing cc-switch (multi-provider / multi-model switcher GUI)'
    if (-not (Test-Command 'winget')) {
        Write-Warn 'winget unavailable; skipping cc-switch. Download: https://github.com/farion1231/cc-switch/releases'
        return
    }
    Invoke-Winget -Id 'farion1231.CC-Switch' -Friendly 'cc-switch' | Out-Null
}

# ============================================================================
# Credentials (no popup -- cc-switch is the entry point)
# ============================================================================
# We do NOT prompt for an API key. Any values passed via -ApiToken/-BaseUrl/-Model are
# written to settings.json (handy for scripted installs); otherwise those env vars are
# omitted and the user enters their provider in cc-switch, which we open at the end.
function Get-Creds {
    param([string]$ExistingToken, [string]$ExistingUrl, [string]$ExistingModel)
    return @{
        Token = $ExistingToken.Trim()
        Url   = $ExistingUrl.Trim()
        Model = $ExistingModel.Trim()
    }
}

# Best-effort: open cc-switch so the user can add their provider (API key + URL).
# Tries Start Menu shortcuts (most reliable across winget installs), then known exe paths.
function Open-CcSwitch {
    try {
        $menus = @(
            (Join-Path $env:APPDATA   'Microsoft\Windows\Start Menu\Programs'),
            (Join-Path $env:ProgramData 'Microsoft\Windows\Start Menu\Programs')
        )
        foreach ($m in $menus) {
            if (-not (Test-Path $m)) { continue }
            $lnk = Get-ChildItem -Path $m -Recurse -Filter '*.lnk' -ErrorAction SilentlyContinue |
                   Where-Object { $_.BaseName -match 'cc.?switch' } | Select-Object -First 1
            if ($lnk) {
                Start-Process $lnk.FullName
                Write-Ok 'Opened cc-switch -- add your provider (API key + URL) there.'
                return $true
            }
        }
        $exe = @(
            (Join-Path $env:LOCALAPPDATA 'Programs\cc-switch\cc-switch.exe'),
            (Join-Path $env:ProgramFiles 'cc-switch\cc-switch.exe')
        ) | Where-Object { Test-Path $_ } | Select-Object -First 1
        if ($exe) {
            Start-Process $exe
            Write-Ok 'Opened cc-switch -- add your provider (API key + URL) there.'
            return $true
        }
    } catch {}
    Write-Info 'Open cc-switch from the Start Menu to add your API key / provider.'
    return $false
}

# ============================================================================
# Deploy
# ============================================================================
function Backup-Existing {
    param([string]$Path)
    if (-not (Test-Path $Path)) { return }
    $ts = Get-Date -Format 'yyyyMMdd-HHmmss'
    $backup = "$Path.bak.$ts"
    Write-Step "Backing up existing $Path -> $backup"
    try {
        Move-Item -Path $Path -Destination $backup -Force
        Write-Ok "Backup at $backup"
        return
    } catch {
        Write-Warn "Original directory is in use and was copied instead of moved: $($_.Exception.Message)"
    }

    New-Item -ItemType Directory -Path $backup -Force | Out-Null
    $rcArgs = @($Path, $backup, '/E', '/XJ', '/NFL', '/NDL', '/NJH', '/NJS', '/NC', '/NS', '/NP')
    & robocopy @rcArgs | Out-Null
    if ($LASTEXITCODE -gt 7) {
        throw "backup robocopy failed with exit code $LASTEXITCODE"
    }
    Write-Ok "Backup copy at $backup"
}

function Deploy-Repo {
    param([string]$RepoRoot, [string]$ClaudeHome)
    Write-Step "Phase 2/5: Deploying files to $ClaudeHome"

    if (Test-Path $ClaudeHome) {
        if (-not $Force -and -not $NonInteractive) {
            $answer = Read-Host "$ClaudeHome exists. Backup and overwrite? [Y/n]"
            if ($answer -and $answer.ToLower() -ne 'y' -and $answer -ne '') {
                throw 'Install aborted by user.'
            }
        }
        Backup-Existing -Path $ClaudeHome
    }

    New-Item -ItemType Directory -Path $ClaudeHome -Force | Out-Null

    # robocopy: copy everything except install/ and the repo-only files (templates rendered separately).
    $excludeDirs  = @('install')
    $excludeFiles = @('settings.template.json', 'mcp-servers.windows.json', 'mcp-servers.macos.json',
                      'LICENSE', 'README.md', '.gitignore', '.gitattributes', '.git')
    $rcArgs = @($RepoRoot, $ClaudeHome, '/E', '/XJ',
                '/XD', $excludeDirs[0],
                '/XF') + $excludeFiles + @('/NFL', '/NDL', '/NJH', '/NJS', '/NC', '/NS', '/NP')
    & robocopy @rcArgs | Out-Null
    if ($LASTEXITCODE -gt 7) {
        throw "robocopy failed with exit code $LASTEXITCODE"
    }
    Write-Ok 'Files copied'
}

function Render-Settings {
    param(
        [string]$TemplatePath,
        [string]$OutPath,
        [hashtable]$Values,
        [bool]$TokenEmpty,
        [bool]$UrlEmpty,
        [bool]$ModelEmpty
    )
    Write-Step 'Phase 3/5: Rendering settings.json from template'
    if (-not (Test-Path $TemplatePath)) {
        throw "Template not found: $TemplatePath"
    }
    $content = Get-Content -LiteralPath $TemplatePath -Raw -Encoding UTF8

    if ($TokenEmpty) {
        # No API key passed -> drop the line; the user configures the provider in cc-switch.
        $content = $content -replace '(?m)^\s*"ANTHROPIC_AUTH_TOKEN":\s*"\{\{ANTHROPIC_AUTH_TOKEN\}\}",?\r?\n', ''
    }

    if ($UrlEmpty) {
        # Strip the ANTHROPIC_BASE_URL line entirely so Claude Code uses the default.
        $content = $content -replace '(?m)^\s*"ANTHROPIC_BASE_URL":\s*"\{\{ANTHROPIC_BASE_URL\}\}",?\r?\n', ''
    }

    if ($ModelEmpty) {
        # No model override -> drop both model lines so Claude Code uses its defaults.
        $content = $content -replace '(?m)^\s*"ANTHROPIC_MODEL":\s*"\{\{ANTHROPIC_MODEL\}\}",?\r?\n', ''
        $content = $content -replace '(?m)^\s*"ANTHROPIC_DEFAULT_HAIKU_MODEL":\s*"\{\{ANTHROPIC_DEFAULT_HAIKU_MODEL\}\}",?\r?\n', ''
    }

    foreach ($k in $Values.Keys) {
        $content = $content.Replace("{{$k}}", $Values[$k])
    }

    if ($content -match '\{\{[A-Z_]+\}\}') {
        throw "Unfilled placeholders remain in settings.json: $($Matches[0])"
    }

    Write-Utf8NoBom -Path $OutPath -Content $content
    Write-Ok "Wrote $OutPath"
}

function Deploy-MCP {
    param([string]$RepoRoot, [string]$Timezone)
    Write-Step 'Phase 4/5: Configuring MCP servers in ~/.claude.json'

    $tpl = Join-Path $RepoRoot 'mcp-servers.windows.json'
    if (-not (Test-Path $tpl)) {
        Write-Warn "MCP template not found ($tpl); skipping MCP setup."
        return
    }
    $raw = (Get-Content -LiteralPath $tpl -Raw -Encoding UTF8) -replace '\{\{TIMEZONE\}\}', $Timezone
    try {
        $mcp = $raw | ConvertFrom-Json
    } catch {
        Write-Warn "MCP template invalid JSON; skipping. $($_.Exception.Message)"
        return
    }

    $cfgPath = Join-Path $env:USERPROFILE '.claude.json'
    $cfg = $null
    if (Test-Path $cfgPath) {
        # Back up the user's global config before touching it.
        $ts = Get-Date -Format 'yyyyMMdd-HHmmss'
        try { Copy-Item -LiteralPath $cfgPath -Destination "$cfgPath.bak.$ts" -Force } catch {}
        try {
            $cfg = Get-Content -LiteralPath $cfgPath -Raw -Encoding UTF8 | ConvertFrom-Json
        } catch {
            Write-Warn '~/.claude.json exists but is not valid JSON; creating a fresh one (old backed up).'
            $cfg = $null
        }
    }
    if (-not $cfg) { $cfg = [pscustomobject]@{} }

    $cfg | Add-Member -NotePropertyName mcpServers -NotePropertyValue $mcp -Force
    # Avoid re-triggering the onboarding wizard for reset/fresh users.
    if (-not ($cfg.PSObject.Properties.Name -contains 'hasCompletedOnboarding')) {
        $cfg | Add-Member -NotePropertyName hasCompletedOnboarding -NotePropertyValue $true -Force
    }

    $json = $cfg | ConvertTo-Json -Depth 100
    Write-Utf8NoBom -Path $cfgPath -Content $json
    $count = @($mcp.PSObject.Properties).Count
    Write-Ok "Configured $count MCP servers in $cfgPath"
}

function Deploy-CodexConfig {
    param([string]$RepoRoot, [string]$CodexHome)
    Write-Step "Deploying Claude Code Codex Strongest config to $CodexHome"

    $src = Join-Path $RepoRoot '.codex'
    if (-not (Test-Path $src)) {
        Write-Warn "Codex template not found ($src); skipping Codex config deployment."
        return
    }

    New-Item -ItemType Directory -Path $CodexHome -Force | Out-Null
    $safeFiles = @('AGENTS.md', 'config.toml', '.gitignore', 'README.md')
    foreach ($file in $safeFiles) {
        $from = Join-Path $src $file
        if (-not (Test-Path $from)) { continue }
        $to = Join-Path $CodexHome $file
        Copy-Item -LiteralPath $from -Destination $to -Force
        Write-Ok "Codex template deployed: $to"
    }
    Write-Info 'Codex auth/runtime files are intentionally not copied. Run `codex login` manually after install.'
}

# ============================================================================
# Verify
# ============================================================================
function Verify-Install {
    param([string]$ClaudeHome, [string]$CodexHome)
    Write-Step 'Phase 5/5: Verifying install'
    $expectedExtensions = @(
        'anthropic.claude-code',
        'openai.chatgpt',
        'ms-ceintl.vscode-language-pack-zh-hans',
        'cweijan.vscode-office'
    )
    $installedExtensions = $null
    if (Test-Command 'code') {
        try { $installedExtensions = @(& code --list-extensions | ForEach-Object { $_.ToLowerInvariant() }) } catch { $installedExtensions = $null }
    }
    $checks = @(
        @{ Name = 'settings.json exists';          Test = { Test-Path (Join-Path $ClaudeHome 'settings.json') } },
        @{ Name = 'settings.json parses';          Test = { try { Get-Content (Join-Path $ClaudeHome 'settings.json') -Raw | ConvertFrom-Json | Out-Null; $true } catch { $false } } },
        @{ Name = 'CLAUDE.md exists';              Test = { Test-Path (Join-Path $ClaudeHome 'CLAUDE.md') } },
        @{ Name = 'docs/ has 4 files';             Test = { @(Get-ChildItem (Join-Path $ClaudeHome 'docs') -File -ErrorAction SilentlyContinue).Count -ge 4 } },
        @{ Name = 'skills/ has >= 30';             Test = { @(Get-ChildItem (Join-Path $ClaudeHome 'skills') -Directory -ErrorAction SilentlyContinue).Count -ge 30 } },
        @{ Name = 'agents/ has >= 20';             Test = { @(Get-ChildItem (Join-Path $ClaudeHome 'agents') -Filter *.md -File -ErrorAction SilentlyContinue).Count -ge 20 } },
        @{ Name = 'commands/ has >= 20';           Test = { @(Get-ChildItem (Join-Path $ClaudeHome 'commands') -Filter *.md -File -ErrorAction SilentlyContinue).Count -ge 20 } },
        @{ Name = 'hooks/ has >= 12 .ps1';         Test = { @(Get-ChildItem (Join-Path $ClaudeHome 'hooks') -Filter *.ps1 -File -ErrorAction SilentlyContinue).Count -ge 12 } },
        @{ Name = 'Codex AGENTS.md exists';         Test = { Test-Path (Join-Path $CodexHome 'AGENTS.md') } },
        @{ Name = 'Codex config.toml exists';       Test = { Test-Path (Join-Path $CodexHome 'config.toml') } },
        @{ Name = 'Codex .gitignore protects auth'; Test = { try { (Get-Content (Join-Path $CodexHome '.gitignore') -Raw -Encoding UTF8) -match 'auth\.json' } catch { $false } } },
        @{ Name = 'VS Code desktop shortcut exists'; Test = { Test-Path (Join-Path ([Environment]::GetFolderPath('DesktopDirectory')) 'Visual Studio Code.lnk') } },
        @{ Name = 'VS Code extensions installed';  Test = { $installedExtensions -and @(Compare-Object -ReferenceObject $expectedExtensions -DifferenceObject $installedExtensions -PassThru | Where-Object { $expectedExtensions -contains $_ }).Count -eq 0 } },
        @{ Name = '~/.claude.json 8 MCPs';         Test = { try { $j = Get-Content (Join-Path $env:USERPROFILE '.claude.json') -Raw -Encoding UTF8 | ConvertFrom-Json; @($j.mcpServers.PSObject.Properties).Count -ge 8 } catch { $false } } }
    )
    $allOk = $true
    foreach ($c in $checks) {
        $ok = & $c.Test
        if ($ok) { Write-Ok $c.Name } else { Write-Err $c.Name; $allOk = $false }
    }
    if (-not $allOk) { throw 'One or more verification checks failed.' }
}

function Show-Success {
    param([string]$ClaudeHome, [string]$CodexHome)
    Write-Host ''
    Write-Host '+============================================================+' -ForegroundColor Green
    Write-Host '|             INSTALLATION COMPLETE!                         |' -ForegroundColor Green
    Write-Host '+============================================================+' -ForegroundColor Green
    Write-Host ''
    Write-Host "  Claude Code config installed at: $ClaudeHome" -ForegroundColor White
    Write-Host "  Claude Code Codex Strongest config installed at: $CodexHome" -ForegroundColor White
    Write-Host '  8 MCP servers configured in ~/.claude.json' -ForegroundColor White
    Write-Host ''
    Write-Host '  IMPORTANT - set up your API key in cc-switch first:' -ForegroundColor Yellow
    Write-Host '    1. cc-switch should have opened. If not, open it from the Start Menu.' -ForegroundColor White
    Write-Host '    2. Click "Add Provider": enter your API key + Base URL' -ForegroundColor White
    Write-Host '       (pick the Claude/Anthropic preset, or your relay -- gpt/OpenAI relays work too).' -ForegroundColor White
    Write-Host '    3. Click "Enable" -- cc-switch writes the config for Claude Code.' -ForegroundColor White
    Write-Host ''
    Write-Host '  Then use Claude Code:' -ForegroundColor Yellow
    Write-Host '    - VS Code: Ctrl+Shift+P -> "Claude Code: Open Chat"' -ForegroundColor White
    Write-Host '    - Terminal: claude' -ForegroundColor White
    Write-Host ''
    Write-Host '  Optional Codex setup:' -ForegroundColor Yellow
    Write-Host '    - Terminal: codex login' -ForegroundColor White
    Write-Host '    - VS Code: open the Codex extension (openai.chatgpt)' -ForegroundColor White
    Write-Host ''
    Write-Host '  Documentation: https://github.com/liujiarui0918/claude-code-codex-strongest' -ForegroundColor Cyan
    Write-Host ''
}

# ============================================================================
# Main
# ============================================================================
try {
    Show-Welcome

    $repoRoot = Get-RepoRoot
    Write-Info "Repo root: $repoRoot"

    if (-not $ClaudeHome) {
        $ClaudeHome = Join-Path $env:USERPROFILE '.claude'
    }
    if (-not $CodexHome) {
        $CodexHome = Join-Path $env:USERPROFILE '.codex'
    }
    Write-Info "Install target: $ClaudeHome"
    Write-Info "Codex target: $CodexHome"
    if ($Reset) { Write-Info 'Mode: RESET (clean reinstall)' }
    Write-Host ''

    if ($Reset) {
        Reset-Environment -ClaudeHome $ClaudeHome
    }

    if (-not $SkipPrereqs) {
        Install-Prerequisites
    } else {
        Write-Warn 'Skipping prerequisites install (-SkipPrereqs).'
    }

    $creds = Get-Creds -ExistingToken $ApiToken -ExistingUrl $BaseUrl -ExistingModel $Model

    if (-not $NoCcSwitch) {
        if ($SkipPrereqs) {
            Write-Warn 'cc-switch install skipped (-SkipPrereqs). Install it yourself or configure creds manually.'
        } else {
            Install-CcSwitch
        }
    }

    Deploy-Repo -RepoRoot $repoRoot -ClaudeHome $ClaudeHome

    $tplPath    = Join-Path $repoRoot 'settings.template.json'
    $outPath    = Join-Path $ClaudeHome 'settings.json'
    $tokenEmpty = [string]::IsNullOrWhiteSpace($creds.Token)
    $urlEmpty   = [string]::IsNullOrWhiteSpace($creds.Url)
    $modelEmpty = [string]::IsNullOrWhiteSpace($creds.Model)
    $vals = @{
        ANTHROPIC_AUTH_TOKEN = $creds.Token
        ANTHROPIC_BASE_URL   = $creds.Url
        CLAUDE_HOME          = $ClaudeHome.Replace('\', '/')
    }
    if (-not $modelEmpty) {
        $vals['ANTHROPIC_MODEL']               = $creds.Model
        $vals['ANTHROPIC_DEFAULT_HAIKU_MODEL'] = $creds.Model
    }
    Render-Settings -TemplatePath $tplPath -OutPath $outPath -TokenEmpty $tokenEmpty -UrlEmpty $urlEmpty -ModelEmpty $modelEmpty -Values $vals

    Deploy-MCP -RepoRoot $repoRoot -Timezone $Timezone
    Deploy-CodexConfig -RepoRoot $repoRoot -CodexHome $CodexHome

    Verify-Install -ClaudeHome $ClaudeHome -CodexHome $CodexHome

    if (-not $NoCcSwitch -and -not $NonInteractive) {
        Open-CcSwitch | Out-Null
    }

    Show-Success -ClaudeHome $ClaudeHome -CodexHome $CodexHome
    exit 0
} catch {
    Write-Host ''
    Write-Err "Install failed: $($_.Exception.Message)"
    if ($_.ScriptStackTrace) { Write-Info $_.ScriptStackTrace }
    Write-Host ''
    Write-Host '  Common fixes:' -ForegroundColor Yellow
    Write-Host '    - Run as Administrator if winget needs elevation' -ForegroundColor White
    Write-Host '    - Check VPN if downloads time out' -ForegroundColor White
    Write-Host '    - Re-run with -SkipPrereqs if tools are already installed' -ForegroundColor White
    Write-Host '    - Try a clean slate: re-run with -Reset' -ForegroundColor White
    Write-Host '    - See: https://github.com/liujiarui0918/claude-code-codex-strongest/issues' -ForegroundColor White
    exit 1
}
