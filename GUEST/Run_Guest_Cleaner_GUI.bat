@echo off
:: Check for administrator permissions
net session >nul 2>&1
if %errorLevel% == 0 (
    goto :admin
) else (
    goto :elevate
)

:elevate
:: Create a temporary VBScript to elevate this batch script to Admin
echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"
echo UAC.ShellExecute "%~s0", "", "", "runas", 1 >> "%temp%\getadmin.vbs"
"%temp%\getadmin.vbs"
del "%temp%\getadmin.vbs"
exit /B

:admin
cd /d "%~dp0"
title Guest VM Spoofer Launcher
:: Launch the guest cleaner GUI silently
powershell -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "%~dp0clean_guest_registry.ps1"
