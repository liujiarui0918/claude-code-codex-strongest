@echo off
setlocal
title Claude Code Codex Strongest Installer
echo ============================================================
echo    Claude Code Codex Strongest - One-Click Installer (Windows)
echo ============================================================
echo.
echo This downloads the latest setup and installs everything:
echo   VS Code + desktop shortcut + Claude Code CLI + anthropic.claude-code VS Code extension + Codex CLI + openai.chatgpt VS Code extension + cc-switch + Claude Code Codex Strongest / claude-code-codex-strongest config + 33 skills / 22 agents / 8 MCPs
echo.
echo No API-key box: when it finishes, cc-switch opens so you enter your key there.
echo.
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop';[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12;$tmp=Join-Path $env:TEMP ('ccs-'+[guid]::NewGuid().ToString('N').Substring(0,8));[void](New-Item -ItemType Directory -Path $tmp -Force);$zip=Join-Path $tmp 'r.zip';Write-Host 'Downloading...' -ForegroundColor Cyan;try{Invoke-WebRequest -Uri 'https://github.com/liujiarui0918/claude-code-codex-strongest/archive/refs/heads/main.zip' -OutFile $zip -UseBasicParsing}catch{Write-Host 'Download failed. If you are in mainland China, turn on a VPN and try again.' -ForegroundColor Red;exit 1};Write-Host 'Extracting...' -ForegroundColor Cyan;Expand-Archive -Path $zip -DestinationPath $tmp -Force;$d=@(Get-ChildItem -Path $tmp -Directory -Filter 'claude-code-codex-strongest-*')[0];if(-not $d){Write-Host 'Extract failed.' -ForegroundColor Red;exit 1};$inst=Join-Path $d.FullName 'install\install-windows.ps1';& $inst;$ec=$LASTEXITCODE;Remove-Item -Path $tmp -Recurse -Force -ErrorAction SilentlyContinue;exit $ec"
echo.
echo Done. Press any key to close this window.
pause >nul
endlocal
