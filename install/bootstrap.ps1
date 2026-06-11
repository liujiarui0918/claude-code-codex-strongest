#requires -version 5.1
<#
.SYNOPSIS
    No-clone bootstrap for claude-code-codex-strongest (Windows).

.DESCRIPTION
    Downloads the repository as a zip (no git required), extracts it to a temp
    folder, and runs install-windows.ps1. Any extra arguments are passed through
    to the installer.

    One-liner (PowerShell):
      irm https://raw.githubusercontent.com/liujiarui0918/claude-code-codex-strongest/main/install/bootstrap.ps1 | iex

    With arguments (download then run):
      .\bootstrap.ps1 -Reset
      .\bootstrap.ps1 -ApiToken sk-ant-xxx -NonInteractive

    Pin a version/branch via env var:
      $env:CCS_REF = 'v1.0.0'; irm .../bootstrap.ps1 | iex
#>
[CmdletBinding()]
param([Parameter(ValueFromRemainingArguments = $true)] $PassThru)

$ErrorActionPreference = 'Stop'
$ProgressPreference    = 'SilentlyContinue'

$repo = 'liujiarui0918/claude-code-codex-strongest'
$ref  = if ($env:CCS_REF) { $env:CCS_REF } else { 'main' }

# Version tags (v1.0.0 / 1.0.0) live under refs/tags; everything else is a branch.
if ($ref -match '^v?\d') {
    $zipUrl = "https://github.com/$repo/archive/refs/tags/$ref.zip"
} else {
    $zipUrl = "https://github.com/$repo/archive/refs/heads/$ref.zip"
}

Write-Host ">>> Claude Code Codex Strongest bootstrap (ref: $ref)" -ForegroundColor Cyan

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$tmp = Join-Path $env:TEMP ('ccs-' + [guid]::NewGuid().ToString('N').Substring(0, 8))
[void](New-Item -ItemType Directory -Path $tmp -Force)
$zip = Join-Path $tmp 'repo.zip'

try {
    Write-Host '    Downloading...' -ForegroundColor Gray
    Invoke-WebRequest -Uri $zipUrl -OutFile $zip -UseBasicParsing
} catch {
    Write-Host "    Download failed from $zipUrl" -ForegroundColor Red
    Write-Host '    If you are in mainland China, turn on a VPN and try again.' -ForegroundColor Yellow
    exit 1
}

Write-Host '    Extracting...' -ForegroundColor Gray
Expand-Archive -Path $zip -DestinationPath $tmp -Force

$extracted = @(Get-ChildItem -Path $tmp -Directory -Filter 'claude-code-codex-strongest-*')[0]
if (-not $extracted) {
    Write-Host '    Extraction failed: repo folder not found.' -ForegroundColor Red
    exit 1
}

$installer = Join-Path $extracted.FullName 'install\install-windows.ps1'
if (-not (Test-Path $installer)) {
    Write-Host "    Installer not found at $installer" -ForegroundColor Red
    exit 1
}

Write-Host '>>> Running installer...' -ForegroundColor Cyan
if ($PassThru) { & $installer @PassThru } else { & $installer }
$code = $LASTEXITCODE

try { Remove-Item -Path $tmp -Recurse -Force -ErrorAction SilentlyContinue } catch {}
exit $code
