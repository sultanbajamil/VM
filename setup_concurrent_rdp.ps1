# PowerShell configuration script to enable Concurrent RDP sessions on Windows
# This script must run as Administrator on the host machine

$ErrorActionPreference = "Stop"

# 1. Check for Administrative Privileges
$IsAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $IsAdmin) {
    Write-Warning "Please run PowerShell as Administrator first!"
    Read-Host "Press Enter to exit..."
    Exit
}

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "   Configuring Windows Concurrent RDP...  " -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

# 2. Enable Remote Desktop Service (Registry Settings)
Write-Host "[*] Enabling Remote Desktop Connections..." -ForegroundColor Yellow
$TSPath = "HKLM:\System\CurrentControlSet\Control\Terminal Server"
Set-ItemProperty -Path $TSPath -Name "fDenyTSConnections" -Value 0 -Force
Set-ItemProperty -Path $TSPath -Name "fSingleSessionPerUser" -Value 0 -Force

# 3. Enable RDP through Windows Firewall
Write-Host "[*] Configuring Firewall rules..." -ForegroundColor Yellow
Enable-NetFirewallRule -DisplayGroup "Remote Desktop" -ErrorAction SilentlyContinue

# Ensure Remote Desktop service (TermService) is running and set to Automatic
Write-Host "[*] Starting Remote Desktop Service..." -ForegroundColor Yellow
Set-Service -Name "TermService" -StartupType Automatic
Start-Service -Name "TermService" -ErrorAction SilentlyContinue

# 4. Download and Install RDP Wrapper Library (Stascorp v1.6.2)
# RDP Wrapper allows Windows Home/Pro editions to run concurrent sessions locally.
Write-Host "[*] Downloading RDP Wrapper Library..." -ForegroundColor Yellow
$DownloadUrl = "https://github.com/stascorp/rdpwrap/releases/download/v1.6.2/RDPWrap-v1.6.2.zip"
$ZipPath = Join-Path $env:TEMP "RDPWrap.zip"
$ExtractPath = Join-Path $env:TEMP "RDPWrap"

# Remove old files if they exist
if (Test-Path $ZipPath) { Remove-Item $ZipPath -Force }
if (Test-Path $ExtractPath) { Remove-Item $ExtractPath -Recurse -Force }

try {
    Invoke-WebRequest -Uri $DownloadUrl -OutFile $ZipPath
    Expand-Archive -Path $ZipPath -DestinationPath $ExtractPath -Force
    Write-Host "[+] RDP Wrapper downloaded and extracted successfully." -ForegroundColor Green
    
    Write-Host "[*] Running RDP Wrapper installer..." -ForegroundColor Yellow
    # Change directory to run the installer bat file
    Push-Location $ExtractPath
    $InstallProcess = Start-Process -FilePath "cmd.exe" -ArgumentList "/c install.bat" -Wait -NoNewWindow -PassThru
    Pop-Location
    
    if ($InstallProcess.ExitCode -eq 0) {
        Write-Host "[+] RDP Wrapper installed successfully!" -ForegroundColor Green
    } else {
        Write-Warning "RDP Wrapper installer returned exit code: $($InstallProcess.ExitCode)"
    }
} catch {
    Write-Error "Failed to download or install RDP Wrapper: $_"
}

# 5. Check RDP Wrapper Listener status
$ProgramFilesRDP = "C:\Program Files\RDP Wrapper"
$RDPConf = Join-Path $ProgramFilesRDP "RDPConf.exe"
Write-Host "`n==========================================" -ForegroundColor Cyan
Write-Host "[✔] Configuration complete!" -ForegroundColor Green
Write-Host "Please check the RDP Wrapper status using:" -ForegroundColor Yellow
Write-Host "  $RDPConf" -ForegroundColor Green
Write-Host "If 'Listener state' is 'Not supported', you might need to update the rdpwrap.ini file for your specific Windows version." -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

Read-Host "Press Enter to finish..."
