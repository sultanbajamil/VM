param (
    [switch]$AutoClean
)

$ErrorActionPreference = "SilentlyContinue"

# 1. Relaunch as Admin if not already elevated (Only for GUI mode, silent mode runs as SYSTEM already)
$IsAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $IsAdmin -and -not $AutoClean) {
    $Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    Start-Process -FilePath "powershell.exe" -ArgumentList $Arguments -Verb RunAs
    Exit
}

# Function to execute spoofing logic
function Start-Spoofing ($ProfileIndex) {
    # Aligned profile data
    $FakeVendor = "LENOVO"
    $FakeProduct = "20XW004JUS"
    $FakeFamily = "ThinkPad X1 Carbon"
    $FakeBIOSVendor = "LENOVO"
    $FakeBIOSVersion = "N32ET82W (1.58 )"
    $FakeBIOSDate = "03/15/2023"
    $FakeBoardProduct = "20XW004JUS"
    $FakeBoardVersion = "SDK0J40697 WIN"

    if ($ProfileIndex -eq 1) { # Dell
        $FakeVendor = "Dell Inc."
        $FakeProduct = "Latitude 7490"
        $FakeFamily = "Latitude"
        $FakeBIOSVendor = "Dell Inc."
        $FakeBIOSVersion = "1.29.0"
        $FakeBIOSDate = "02/10/2023"
        $FakeBoardProduct = "0P1Y05"
        $FakeBoardVersion = "A00"
    } elseif ($ProfileIndex -eq 2) { # HP
        $FakeVendor = "HP"
        $FakeProduct = "HP EliteBook 840 G8"
        $FakeFamily = "HP EliteBook"
        $FakeBIOSVendor = "HP"
        $FakeBIOSVersion = "T95 Val 01.11.00"
        $FakeBIOSDate = "11/24/2022"
        $FakeBoardProduct = "880D"
        $FakeBoardVersion = "KBC Version 12.34.56"
    }

    # Apply BIOS & System Info
    $BIOSPaths = @(
        "HKLM:\HARDWARE\DESCRIPTION\System",
        "HKLM:\HARDWARE\DESCRIPTION\System\BIOS",
        "HKLM:\SYSTEM\CurrentControlSet\Control\SystemInformation"
    )
    foreach ($Path in $BIOSPaths) {
        if (-not (Test-Path $Path)) { New-Item -Path $Path -Force | Out-Null }
    }

    Set-ItemProperty -Path "HKLM:\HARDWARE\DESCRIPTION\System\BIOS" -Name "BiosVendor" -Value $FakeBIOSVendor
    Set-ItemProperty -Path "HKLM:\HARDWARE\DESCRIPTION\System\BIOS" -Name "BiosVersion" -Value $FakeBIOSVersion
    Set-ItemProperty -Path "HKLM:\HARDWARE\DESCRIPTION\System\BIOS" -Name "BiosReleaseDate" -Value $FakeBIOSDate
    Set-ItemProperty -Path "HKLM:\HARDWARE\DESCRIPTION\System\BIOS" -Name "SystemManufacturer" -Value $FakeVendor
    Set-ItemProperty -Path "HKLM:\HARDWARE\DESCRIPTION\System\BIOS" -Name "SystemProductName" -Value $FakeProduct
    Set-ItemProperty -Path "HKLM:\HARDWARE\DESCRIPTION\System\BIOS" -Name "SystemFamily" -Value $FakeFamily
    Set-ItemProperty -Path "HKLM:\HARDWARE\DESCRIPTION\System\BIOS" -Name "BaseBoardManufacturer" -Value $FakeVendor
    Set-ItemProperty -Path "HKLM:\HARDWARE\DESCRIPTION\System\BIOS" -Name "BaseBoardProduct" -Value $FakeBoardProduct
    Set-ItemProperty -Path "HKLM:\HARDWARE\DESCRIPTION\System\BIOS" -Name "BaseBoardVersion" -Value $FakeBoardVersion

    Set-ItemProperty -Path "HKLM:\HARDWARE\DESCRIPTION\System" -Name "SystemBiosVersion" -Value $FakeBIOSVersion
    Set-ItemProperty -Path "HKLM:\HARDWARE\DESCRIPTION\System" -Name "VideoBiosVersion" -Value "Intel HD Graphics BIOS"

    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SystemInformation" -Name "SystemManufacturer" -Value $FakeVendor
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SystemInformation" -Name "SystemProductName" -Value $FakeProduct

    # Spoof Storage SCSI names
    $FakeDisks = @("Samsung SSD 860 EVO 500GB", "WDC WD10JPVX-08JC3T0", "Kingston A400 SATA3 480GB")
    $FakeDisk = $FakeDisks | Get-Random

    Get-ChildItem -Path "HKLM:\HARDWARE\DEVICEMAP\Scsi" -Recurse | ForEach-Object {
        $SubPath = $_.Name -replace "HKEY_LOCAL_MACHINE", "HKLM:"
        $Identifier = (Get-ItemProperty -Path $SubPath -Name "Identifier" -ErrorAction SilentlyContinue).Identifier
        if ($Identifier -and ($Identifier -like "*VBOX*" -or $Identifier -like "*VirtualBox*" -or $Identifier -like "*QEMU*")) {
            Set-ItemProperty -Path $SubPath -Name "Identifier" -Value $FakeDisk
        }
    }

    # Clean Disk enum registry
    Get-ChildItem -Path "HKLM:\SYSTEM\CurrentControlSet\Services\disk\Enum" | ForEach-Object {
        $SubPath = $_.Name -replace "HKEY_LOCAL_MACHINE", "HKLM:"
        foreach ($ValName in $_.GetValueNames()) {
            $Val = $_.GetValue($ValName)
            if ($Val -and ($Val -like "*VBOX*" -or $Val -like "*VirtualBox*")) {
                $NewVal = $Val -replace "VBOX_HARDDISK", "SAMSUNG_SSD" -replace "VirtualBox", "GenuineDisk"
                Set-ItemProperty -Path $SubPath -Name $ValName -Value $NewVal
            }
        }
    }

    # Video Driver Description
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000" -Name "DriverDesc" -Value "Intel(R) UHD Graphics 620"
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000" -Name "ProviderName" -Value "Intel Corporation"
}

# 2. If launched in AutoClean mode (via Startup Task), run silently and exit
if ($AutoClean) {
    # Default to Lenovo profile for silent startup runs
    Start-Spoofing -ProfileIndex 0
    Exit
}

# 3. Create Windows Forms GUI for interactive mode
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$Form = New-Object System.Windows.Forms.Form
$Form.Text = "Guest VM Registry Cleaner"
$Form.Size = New-Object System.Drawing.Size(550,560)
$Form.StartPosition = "CenterScreen"
$Form.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 46) # Dark theme matching host
$Form.ForeColor = [System.Drawing.Color]::White
$Form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedSingle
$Form.MaximizeBox = $false

# Title Label
$TitleLabel = New-Object System.Windows.Forms.Label
$TitleLabel.Text = "Guest VM Registry Cleaner & Spoofer"
$TitleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 15, [System.Drawing.FontStyle]::Bold)
$TitleLabel.ForeColor = [System.Drawing.Color]::FromArgb(137, 180, 250)
$TitleLabel.Location = New-Object System.Drawing.Point(20, 20)
$TitleLabel.Size = New-Object System.Drawing.Size(500, 40)
$TitleLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$Form.Controls.Add($TitleLabel)

# Profile Label
$LBL_Profile = New-Object System.Windows.Forms.Label
$LBL_Profile.Text = "Select Hardware Profile (Match Host Spoofer):"
$LBL_Profile.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$LBL_Profile.Location = New-Object System.Drawing.Point(30, 80)
$LBL_Profile.Size = New-Object System.Drawing.Size(480, 25)
$Form.Controls.Add($LBL_Profile)

# Profile Select ComboBox
$ComboProfile = New-Object System.Windows.Forms.ComboBox
$ComboProfile.Location = New-Object System.Drawing.Point(30, 110)
$ComboProfile.Size = New-Object System.Drawing.Size(480, 30)
$ComboProfile.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$ComboProfile.BackColor = [System.Drawing.Color]::FromArgb(49, 50, 68)
$ComboProfile.ForeColor = [System.Drawing.Color]::White
$ComboProfile.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
$ComboProfile.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$ComboProfile.Items.Add("Lenovo ThinkPad X1 Carbon")
$ComboProfile.Items.Add("Dell Latitude 7490")
$ComboProfile.Items.Add("HP EliteBook 840 G8")
$ComboProfile.SelectedIndex = 0
$Form.Controls.Add($ComboProfile)

# Clean Button
$BtnApply = New-Object System.Windows.Forms.Button
$BtnApply.Text = "Clean & Spoof Registry"
$BtnApply.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
$BtnApply.Location = New-Object System.Drawing.Point(30, 160)
$BtnApply.Size = New-Object System.Drawing.Size(480, 45)
$BtnApply.BackColor = [System.Drawing.Color]::FromArgb(137, 180, 250)
$BtnApply.ForeColor = [System.Drawing.Color]::FromArgb(17, 17, 27)
$BtnApply.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$BtnApply.Cursor = [System.Windows.Forms.Cursors]::Hand
$Form.Controls.Add($BtnApply)

# Log Label
$LBL_Log = New-Object System.Windows.Forms.Label
$LBL_Log.Text = "Clean-up Log:"
$LBL_Log.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$LBL_Log.Location = New-Object System.Drawing.Point(30, 220)
$LBL_Log.Size = New-Object System.Drawing.Size(480, 20)
$Form.Controls.Add($LBL_Log)

# Log TextBox
$TxtLog = New-Object System.Windows.Forms.TextBox
$TxtLog.Location = New-Object System.Drawing.Point(30, 245)
$TxtLog.Size = New-Object System.Drawing.Size(480, 190)
$TxtLog.Multiline = $true
$TxtLog.ScrollBars = [System.Windows.Forms.ScrollBars]::Vertical
$TxtLog.ReadOnly = $true
$TxtLog.BackColor = [System.Drawing.Color]::FromArgb(24, 24, 37)
$TxtLog.ForeColor = [System.Drawing.Color]::FromArgb(166, 173, 200)
$TxtLog.Font = New-Object System.Drawing.Font("Consolas", 9.5)
$Form.Controls.Add($TxtLog)

# Startup Task Button
$BtnTask = New-Object System.Windows.Forms.Button
$BtnTask.Text = "Register Startup Clean Task (Highly Recommended)"
$BtnTask.Font = New-Object System.Drawing.Font("Segoe UI", 9.5, [System.Drawing.FontStyle]::Bold)
$BtnTask.Location = New-Object System.Drawing.Point(30, 455)
$BtnTask.Size = New-Object System.Drawing.Size(480, 40)
$BtnTask.BackColor = [System.Drawing.Color]::FromArgb(49, 50, 68)
$BtnTask.ForeColor = [System.Drawing.Color]::White
$BtnTask.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$BtnTask.Cursor = [System.Windows.Forms.Cursors]::Hand
$Form.Controls.Add($BtnTask)

# Status update
$TxtLog.AppendText("[+] Application loaded successfully.`r`n")
$TxtLog.AppendText("[+] Administrative privileges confirmed.`r`n")

# Apply Action
$BtnApply.Add_Click({
    $TxtLog.Clear()
    $TxtLog.AppendText("[*] Initiating VM registry clean-up and spoofing...`r`n")
    
    try {
        Start-Spoofing -ProfileIndex $ComboProfile.SelectedIndex
        
        $TxtLog.AppendText("[+] System and BIOS information modified.`r`n")
        $TxtLog.AppendText("[+] Dynamic SCSI storage identifiers spoofed successfully.`r`n")
        $TxtLog.AppendText("[+] Disk enumeration driver keys cleaned.`r`n")
        $TxtLog.AppendText("[+] Video driver display names spoofed to Intel UHD.`r`n")
        $TxtLog.AppendText("------------------------------------------------`r`n")
        $TxtLog.AppendText("[+] Finished successfully! Please reboot your VM.`r`n")

        [System.Windows.Forms.MessageBox]::Show("Guest VM Registry modifications applied successfully!`nPlease restart the VM to complete.", "Success", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
    } catch {
        $TxtLog.AppendText("[-] Error during execution: $_`r`n")
    }
})

# Register Task Action
$BtnTask.Add_Click({
    $ScriptPath = $MyInvocation.MyCommand.Path
    if ($ScriptPath) {
        $TaskName = "SystemHardwareSpoofer"
        $Action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-NoProfile -WindowStyle Hidden -File `"$ScriptPath`" -AutoClean"
        $Trigger = New-ScheduledTaskTrigger -AtStartup
        $Principal = New-ScheduledTaskPrincipal -UserId "NT AUTHORITY\SYSTEM" -LogonType ServiceAccount -RunLevel Highest
        
        Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false 2>$null
        Register-ScheduledTask -TaskName $TaskName -Action $Action -Trigger $Trigger -Principal $Principal | Out-Null
        
        $TxtLog.AppendText("[+] Startup Task '$TaskName' registered successfully.`r`n")
        [System.Windows.Forms.MessageBox]::Show("Startup cleaning task registered successfully!`nIt will clean registry details automatically on every boot.", "Success", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
    } else {
        $TxtLog.AppendText("[-] Error: Could not resolve script path to schedule task.`r`n")
    }
})

# Display Form
$Form.ShowDialog() | Out-Null
