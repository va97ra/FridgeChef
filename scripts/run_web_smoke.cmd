@echo off
setlocal

where pwsh >nul 2>nul
if errorlevel 1 (
  echo Error: pwsh.exe not found. Install PowerShell 7 or add it to PATH. 1>&2
  exit /b 1
)

set "SCRIPT_DIR=%~dp0"
pwsh -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%run_web_smoke.ps1" %*
exit /b %ERRORLEVEL%
