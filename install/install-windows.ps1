#requires -version 5.1
<#
.SYNOPSIS
    One-click installer for claude-code-strongest on Windows.

.DESCRIPTION
    Installs VS Code, Claude Code CLI, official VS Code extension, and deploys
    the full ~/.claude/ configuration (skills, agents, commands, hooks) plus the
    8 MCP servers into ~/.claude.json.

.PARAMETER ClaudeHome
    Override the default ~/.claude install location.

.PARAMETER ApiToken
    Anthropic API key (sk-ant-... or your relay token). If empty, prompts.

.PARAMETER BaseUrl
    Anthropic API base URL. Empty = official api.anthropic.com.

.PARAMETER Reset
    Clean reinstall: back up and remove the existing ~/.claude and ~/.claude.json,
    log out of Claude Code, and uninstall+reinstall the VS Code extension. Use this
    when a machine already has VS Code / Claude Code with old or broken config.

.PARAMETER Timezone
    IANA timezone for the 'time' MCP server. Default: Asia/Shanghai.

.PARAMETER Force
    Overwrite existing ~/.claude without prompting (backs up first).

.PARAMETER NonInteractive
    Skip all prompts. ApiToken must be provided via -ApiToken.

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
    [string]$ApiToken     = '',
    [string]$BaseUrl      = '',
    [switch]$Reset,
    [string]$Timezone     = 'Asia/Shanghai',
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
    $here = Split-Path -Parent $MyInvocation.MyCommand.Path
    if (-not $here) { $here = $PSScriptRoot }
    return (Resolve-Path (Join-Path $here '..')).Path
}

function Show-Welcome {
    $line = '+' + ('-' * 60) + '+'
    Write-Host ''
    Write-Host $line -ForegroundColor Magenta
    Write-Host '|     Claude Code Strongest - One-Click Setup (Windows)     |' -ForegroundColor Magenta
    Write-Host '|                                                            |' -ForegroundColor Magenta
    Write-Host '|   Installs: VS Code + Claude Code CLI + extension          |' -ForegroundColor Magenta
    Write-Host '|   Deploys:  33 skills / 22 agents / 25 commands /          |' -ForegroundColor Magenta
    Write-Host '|             12 hooks / 8 MCP servers                       |' -ForegroundColor Magenta
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
    $vscodeOverride = '/VERYSILENT /SP- /MERGETASKS=!runcode,addcontextmenufiles,addcontextmenufolders,associatewithfiles,addtopath'
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

    # VS Code extension
    Write-Step 'Installing Claude Code VS Code extension'
    if (Test-Command 'code') {
        try {
            & code --install-extension anthropic.claude-code --force 2>&1 | Out-Null
            Write-Ok 'VS Code extension installed: anthropic.claude-code'
        } catch {
            Write-Warn "code --install-extension failed: $($_.Exception.Message)"
            Write-Info 'Install manually in VS Code: Extensions panel > search "Claude Code" by Anthropic'
        }
    } else {
        Write-Warn '`code` CLI not on PATH; VS Code extension skipped.'
        Write-Info 'After installing VS Code, run: code --install-extension anthropic.claude-code'
    }

    Write-Host ''
}

# ============================================================================
# User input (token + URL)
# ============================================================================
function Get-Creds-WinForms {
    param([string]$ExistingToken, [string]$ExistingUrl)
    try {
        Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop
        Add-Type -AssemblyName System.Drawing       -ErrorAction Stop
    } catch {
        return $null
    }

    $form           = New-Object System.Windows.Forms.Form
    $form.Text      = 'Claude Code Strongest - Credentials'
    $form.Size      = New-Object System.Drawing.Size(520, 280)
    $form.StartPosition = 'CenterScreen'
    $form.FormBorderStyle = 'FixedDialog'
    $form.MaximizeBox = $false
    $form.MinimizeBox = $false

    $lblToken = New-Object System.Windows.Forms.Label
    $lblToken.Text = 'Anthropic API Key (sk-ant-... or relay token):'
    $lblToken.Location = New-Object System.Drawing.Point(20, 20)
    $lblToken.Size = New-Object System.Drawing.Size(460, 20)
    $form.Controls.Add($lblToken)

    $txtToken = New-Object System.Windows.Forms.TextBox
    $txtToken.UseSystemPasswordChar = $true
    $txtToken.Location = New-Object System.Drawing.Point(20, 45)
    $txtToken.Size = New-Object System.Drawing.Size(460, 24)
    $txtToken.Text = $ExistingToken
    $form.Controls.Add($txtToken)

    $lblUrl = New-Object System.Windows.Forms.Label
    $lblUrl.Text = 'Anthropic Base URL (leave empty for official api.anthropic.com):'
    $lblUrl.Location = New-Object System.Drawing.Point(20, 85)
    $lblUrl.Size = New-Object System.Drawing.Size(460, 20)
    $form.Controls.Add($lblUrl)

    $txtUrl = New-Object System.Windows.Forms.TextBox
    $txtUrl.Location = New-Object System.Drawing.Point(20, 110)
    $txtUrl.Size = New-Object System.Drawing.Size(460, 24)
    $txtUrl.Text = $ExistingUrl
    $form.Controls.Add($txtUrl)

    $lblHint = New-Object System.Windows.Forms.Label
    $lblHint.Text = "Tip: Get API key from https://console.anthropic.com/settings/keys`r`nFor relay services (Chinese users), enter your relay URL here."
    $lblHint.Location = New-Object System.Drawing.Point(20, 145)
    $lblHint.Size = New-Object System.Drawing.Size(460, 40)
    $lblHint.ForeColor = [System.Drawing.Color]::DimGray
    $form.Controls.Add($lblHint)

    $btnOk = New-Object System.Windows.Forms.Button
    $btnOk.Text = 'Install'
    $btnOk.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $btnOk.Location = New-Object System.Drawing.Point(290, 200)
    $btnOk.Size = New-Object System.Drawing.Size(90, 30)
    $form.Controls.Add($btnOk)
    $form.AcceptButton = $btnOk

    $btnCancel = New-Object System.Windows.Forms.Button
    $btnCancel.Text = 'Cancel'
    $btnCancel.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $btnCancel.Location = New-Object System.Drawing.Point(390, 200)
    $btnCancel.Size = New-Object System.Drawing.Size(90, 30)
    $form.Controls.Add($btnCancel)
    $form.CancelButton = $btnCancel

    $form.Topmost = $true
    $result = $form.ShowDialog()
    if ($result -ne [System.Windows.Forms.DialogResult]::OK) {
        return $null
    }
    return @{
        Token = $txtToken.Text.Trim()
        Url   = $txtUrl.Text.Trim()
    }
}

function Get-Creds-Console {
    param([string]$ExistingToken, [string]$ExistingUrl)
    Write-Host ''
    Write-Step 'Enter credentials'
    Write-Info 'Get API key from: https://console.anthropic.com/settings/keys'
    Write-Info '(Or for Chinese users using a relay, enter your relay token + URL)'
    Write-Host ''

    $token = $ExistingToken
    if (-not $token) {
        $sec = Read-Host -Prompt 'Anthropic API Key (input hidden)' -AsSecureString
        $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($sec)
        try {
            $token = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
        } finally {
            [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
        }
    }
    $url = $ExistingUrl
    if (-not $url) {
        $url = Read-Host -Prompt 'Anthropic Base URL (leave empty for official, press Enter to skip)'
    }
    return @{ Token = $token.Trim(); Url = $url.Trim() }
}

function Get-Creds {
    param([string]$ExistingToken, [string]$ExistingUrl)
    if ($NonInteractive) {
        return @{ Token = $ExistingToken.Trim(); Url = $ExistingUrl.Trim() }
    }
    $r = Get-Creds-WinForms -ExistingToken $ExistingToken -ExistingUrl $ExistingUrl
    if ($null -eq $r) {
        Write-Warn 'WinForms dialog unavailable or cancelled; falling back to console prompt.'
        $r = Get-Creds-Console -ExistingToken $ExistingToken -ExistingUrl $ExistingUrl
    }
    if ([string]::IsNullOrWhiteSpace($r.Token)) {
        throw 'API token is required.'
    }
    return $r
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
    Move-Item -Path $Path -Destination $backup -Force
    Write-Ok "Backup at $backup"
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
        [bool]$UrlEmpty
    )
    Write-Step 'Phase 3/5: Rendering settings.json from template'
    if (-not (Test-Path $TemplatePath)) {
        throw "Template not found: $TemplatePath"
    }
    $content = Get-Content -LiteralPath $TemplatePath -Raw -Encoding UTF8

    if ($UrlEmpty) {
        # Strip the ANTHROPIC_BASE_URL line entirely so Claude Code uses the default.
        $content = $content -replace '(?m)^\s*"ANTHROPIC_BASE_URL":\s*"\{\{ANTHROPIC_BASE_URL\}\}",?\r?\n', ''
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

# ============================================================================
# Verify
# ============================================================================
function Verify-Install {
    param([string]$ClaudeHome)
    Write-Step 'Phase 5/5: Verifying install'
    $checks = @(
        @{ Name = 'settings.json exists';      Test = { Test-Path (Join-Path $ClaudeHome 'settings.json') } },
        @{ Name = 'settings.json parses';      Test = { try { Get-Content (Join-Path $ClaudeHome 'settings.json') -Raw | ConvertFrom-Json | Out-Null; $true } catch { $false } } },
        @{ Name = 'CLAUDE.md exists';          Test = { Test-Path (Join-Path $ClaudeHome 'CLAUDE.md') } },
        @{ Name = 'docs/ has 4 files';         Test = { @(Get-ChildItem (Join-Path $ClaudeHome 'docs') -File -ErrorAction SilentlyContinue).Count -ge 4 } },
        @{ Name = 'skills/ has >= 30';         Test = { @(Get-ChildItem (Join-Path $ClaudeHome 'skills') -Directory -ErrorAction SilentlyContinue).Count -ge 30 } },
        @{ Name = 'agents/ has >= 20';         Test = { @(Get-ChildItem (Join-Path $ClaudeHome 'agents') -Filter *.md -File -ErrorAction SilentlyContinue).Count -ge 20 } },
        @{ Name = 'commands/ has >= 20';       Test = { @(Get-ChildItem (Join-Path $ClaudeHome 'commands') -Filter *.md -File -ErrorAction SilentlyContinue).Count -ge 20 } },
        @{ Name = 'hooks/ has >= 12 .ps1';     Test = { @(Get-ChildItem (Join-Path $ClaudeHome 'hooks') -Filter *.ps1 -File -ErrorAction SilentlyContinue).Count -ge 12 } },
        @{ Name = '~/.claude.json 8 MCPs';     Test = { try { $j = Get-Content (Join-Path $env:USERPROFILE '.claude.json') -Raw -Encoding UTF8 | ConvertFrom-Json; @($j.mcpServers.PSObject.Properties).Count -ge 8 } catch { $false } } }
    )
    $allOk = $true
    foreach ($c in $checks) {
        $ok = & $c.Test
        if ($ok) { Write-Ok $c.Name } else { Write-Err $c.Name; $allOk = $false }
    }
    if (-not $allOk) { throw 'One or more verification checks failed.' }
}

function Show-Success {
    param([string]$ClaudeHome)
    Write-Host ''
    Write-Host '+============================================================+' -ForegroundColor Green
    Write-Host '|             INSTALLATION COMPLETE!                         |' -ForegroundColor Green
    Write-Host '+============================================================+' -ForegroundColor Green
    Write-Host ''
    Write-Host "  Claude Code config installed at: $ClaudeHome" -ForegroundColor White
    Write-Host '  8 MCP servers configured in ~/.claude.json' -ForegroundColor White
    Write-Host ''
    Write-Host '  Next steps:' -ForegroundColor Yellow
    Write-Host '    1. Open VS Code (or run: code .)' -ForegroundColor White
    Write-Host '    2. Press Ctrl+Shift+P -> "Claude Code: Open Chat"' -ForegroundColor White
    Write-Host '    3. Try a command: "/doctor" to verify your setup' -ForegroundColor White
    Write-Host ''
    Write-Host '  Or from a terminal:' -ForegroundColor Yellow
    Write-Host '    claude' -ForegroundColor White
    Write-Host ''
    Write-Host '  Documentation: https://github.com/liujiarui0918/claude-code-strongest' -ForegroundColor Cyan
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
    Write-Info "Install target: $ClaudeHome"
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

    $creds = Get-Creds -ExistingToken $ApiToken -ExistingUrl $BaseUrl
    Write-Ok 'Credentials captured'

    Deploy-Repo -RepoRoot $repoRoot -ClaudeHome $ClaudeHome

    $tplPath = Join-Path $repoRoot 'settings.template.json'
    $outPath = Join-Path $ClaudeHome 'settings.json'
    $urlEmpty = [string]::IsNullOrWhiteSpace($creds.Url)
    Render-Settings -TemplatePath $tplPath -OutPath $outPath -UrlEmpty $urlEmpty -Values @{
        ANTHROPIC_AUTH_TOKEN = $creds.Token
        ANTHROPIC_BASE_URL   = $creds.Url
        CLAUDE_HOME          = $ClaudeHome.Replace('\', '/')
    }

    Deploy-MCP -RepoRoot $repoRoot -Timezone $Timezone

    Verify-Install -ClaudeHome $ClaudeHome

    Show-Success -ClaudeHome $ClaudeHome
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
    Write-Host '    - See: https://github.com/liujiarui0918/claude-code-strongest/issues' -ForegroundColor White
    exit 1
}
