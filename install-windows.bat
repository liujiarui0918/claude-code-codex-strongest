@echo off
REM ============================================================================
REM Claude Code Strongest - Double-click launcher for Windows
REM
REM Just double-click this file in File Explorer.
REM ============================================================================
setlocal
cd /d "%~dp0"

echo.
echo Launching Claude Code Strongest installer...
echo.

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0install\install-windows.ps1" %*

echo.
echo (Install script finished. Press any key to close this window.)
pause >nul

endlocal
