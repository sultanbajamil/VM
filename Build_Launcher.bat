@echo off
title Multi-Seat App Compiler
echo [*] Searching for C# Compiler (csc.exe)...

:: Check for 64-bit .NET Framework
set CSC="C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe"
if not exist %CSC% (
    :: Fallback to 32-bit .NET Framework
    set CSC="C:\Windows\Microsoft.NET\Framework\v4.0.30319\csc.exe"
)

if not exist %CSC% (
    echo [-] Error: csc.exe C# compiler was not found. Please make sure .NET Framework 4.0 or newer is installed.
    pause
    exit /b
)

echo [+] Found C# Compiler at %CSC%
echo [*] Compiling MultiSeatApp.cs...

:: Compile the C# file into a Windows executable
%CSC% /target:winexe /out:"%~dp0MultiSeatLauncher_v2.exe" /r:System.dll,System.Windows.Forms.dll,System.Drawing.dll,System.Security.dll "%~dp0MultiSeatApp.cs"

if %errorlevel% == 0 (
    echo ==========================================
    echo [✔] Compilation successful!
    echo [✔] Generated executable: MultiSeatLauncher_v2.exe
    echo ==========================================
) else (
    echo [-] Compilation failed with error code: %errorlevel%
)
pause
