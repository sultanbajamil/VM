# GUI for spoofing VirtualBox VM hardware details to mimic a physical laptop
# This script runs on the Host Machine

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# 1. Search for VirtualBox installation path
$VBoxPath = "C:\Program Files\Oracle\VirtualBox"
if ($env:VBOX_MSI_INSTALL_PATH) {
    $VBoxPath = $env:VBOX_MSI_INSTALL_PATH.TrimEnd('\')
}
$VBoxManage = Join-Path $VBoxPath "VBoxManage.exe"

# If not in default path, search in system PATH
if (-not (Test-Path $VBoxManage)) {
    $SearchPath = Get-Command VBoxManage.exe -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source
    if ($SearchPath) {
        $VBoxManage = $SearchPath
    }
}

# If VirtualBox is still not found, show a GUI dialog and exit
if (-not (Test-Path $VBoxManage)) {
    [System.Windows.Forms.MessageBox]::Show("VirtualBox was not found on your system!`nPlease make sure it is installed at the default path: C:\Program Files\Oracle\VirtualBox", "Initialization Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    exit
}

# Helper function to generate random strings for serials
function Get-RandomString ($Length, $Characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789") {
    $Result = ""
    for ($i = 0; $i -lt $Length; $i++) {
        $Result += $Characters[(Get-Random) % $Characters.Length]
    }
    return $Result
}

# Create Main Form
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "VirtualBox VM Hardware Spoofer"
$Form.Size = New-Object System.Drawing.Size(550,560)
$Form.StartPosition = "CenterScreen"
$Form.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 46) # Slate Blue Dark Theme
$Form.ForeColor = [System.Drawing.Color]::White
$Form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedSingle
$Form.MaximizeBox = $false

# Title Label
$TitleLabel = New-Object System.Windows.Forms.Label
$TitleLabel.Text = "VirtualBox VM Hardware Spoofer"
$TitleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
$TitleLabel.ForeColor = [System.Drawing.Color]::FromArgb(137, 180, 250) # Light blue accent
$TitleLabel.Location = New-Object System.Drawing.Point(20, 20)
$TitleLabel.Size = New-Object System.Drawing.Size(500, 40)
$TitleLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$Form.Controls.Add($TitleLabel)

# VM Select Label
$LBL_VM = New-Object System.Windows.Forms.Label
$LBL_VM.Text = "Select Virtual Machine (VM):"
$LBL_VM.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$LBL_VM.Location = New-Object System.Drawing.Point(30, 75)
$LBL_VM.Size = New-Object System.Drawing.Size(480, 25)
$Form.Controls.Add($LBL_VM)

# VM Select ComboBox
$ComboVM = New-Object System.Windows.Forms.ComboBox
$ComboVM.Location = New-Object System.Drawing.Point(30, 105)
$ComboVM.Size = New-Object System.Drawing.Size(480, 30)
$ComboVM.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$ComboVM.BackColor = [System.Drawing.Color]::FromArgb(49, 50, 68)
$ComboVM.ForeColor = [System.Drawing.Color]::White
$ComboVM.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
$ComboVM.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$Form.Controls.Add($ComboVM)

# Profile Select Label
$LBL_Profile = New-Object System.Windows.Forms.Label
$LBL_Profile.Text = "Select Laptop Profile to Mimic:"
$LBL_Profile.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$LBL_Profile.Location = New-Object System.Drawing.Point(30, 155)
$LBL_Profile.Size = New-Object System.Drawing.Size(480, 25)
$Form.Controls.Add($LBL_Profile)

# Profile Select ComboBox
$ComboProfile = New-Object System.Windows.Forms.ComboBox
$ComboProfile.Location = New-Object System.Drawing.Point(30, 185)
$ComboProfile.Size = New-Object System.Drawing.Size(480, 30)
$ComboProfile.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$ComboProfile.BackColor = [System.Drawing.Color]::FromArgb(49, 50, 68)
$ComboProfile.ForeColor = [System.Drawing.Color]::White
$ComboProfile.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
$ComboProfile.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$ComboProfile.Items.Add("Lenovo ThinkPad X1 Carbon")
$ComboProfile.Items.Add("Dell Latitude 7490")
$ComboProfile.Items.Add("HP EliteBook 840 G8")
$ComboProfile.Items.Add("Random Profile (Smart Auto-Generate)")
$ComboProfile.SelectedIndex = 0
$Form.Controls.Add($ComboProfile)

# Apply Spoof Button
$BtnApply = New-Object System.Windows.Forms.Button
$BtnApply.Text = "Apply Spoofing"
$BtnApply.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
$BtnApply.Location = New-Object System.Drawing.Point(30, 235)
$BtnApply.Size = New-Object System.Drawing.Size(480, 45)
$BtnApply.BackColor = [System.Drawing.Color]::FromArgb(137, 180, 250)
$BtnApply.ForeColor = [System.Drawing.Color]::FromArgb(17, 17, 27)
$BtnApply.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$BtnApply.Cursor = [System.Windows.Forms.Cursors]::Hand
$Form.Controls.Add($BtnApply)

# Log Label
$LBL_Log = New-Object System.Windows.Forms.Label
$LBL_Log.Text = "Spoofing Log:"
$LBL_Log.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$LBL_Log.Location = New-Object System.Drawing.Point(30, 295)
$LBL_Log.Size = New-Object System.Drawing.Size(480, 20)
$Form.Controls.Add($LBL_Log)

# Log TextBox
$TxtLog = New-Object System.Windows.Forms.TextBox
$TxtLog.Location = New-Object System.Drawing.Point(30, 320)
$TxtLog.Size = New-Object System.Drawing.Size(480, 180)
$TxtLog.Multiline = $true
$TxtLog.ScrollBars = [System.Windows.Forms.ScrollBars]::Vertical
$TxtLog.ReadOnly = $true
$TxtLog.BackColor = [System.Drawing.Color]::FromArgb(24, 24, 37)
$TxtLog.ForeColor = [System.Drawing.Color]::FromArgb(166, 173, 200)
$TxtLog.Font = New-Object System.Drawing.Font("Consolas", 9.5)
$Form.Controls.Add($TxtLog)

# Retrieve registered VMs list
try {
    $VMs = & $VBoxManage list vms
    $VMFound = $false
    foreach ($VM in $VMs) {
        if ($VM -match '"(.+)"\s+\{(.+)\}') {
            $ComboVM.Items.Add($Matches[1]) | Out-Null
            $VMFound = $true
        }
    }
    if ($VMFound) {
        $ComboVM.SelectedIndex = 0
        $TxtLog.AppendText("[+] Ready. Please turn off the target VM before applying spoofing.`r`n")
    } else {
        $TxtLog.AppendText("[-] Warning: No registered VirtualBox VMs found.`r`n")
        $BtnApply.Enabled = $false
    }
} catch {
    $TxtLog.AppendText("[-] Error while getting VM list: $_`r`n")
}

# Apply Button logic
$BtnApply.Add_Click({
    $VMName = $ComboVM.SelectedItem
    if (-not $VMName) {
        [System.Windows.Forms.MessageBox]::Show("Please select a Virtual Machine first!", "Warning", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
        return
    }

    $TxtLog.Clear()
    $TxtLog.AppendText("[*] Starting spoofing process for: $VMName`r`n")

    # Load chosen laptop profile
    $Profile = @{}
    switch ($ComboProfile.SelectedIndex) {
        0 { # Lenovo ThinkPad
            $Profile.Vendor = "LENOVO"
            $Profile.Product = "20XW004JUS"
            $Profile.Version = "ThinkPad X1 Carbon Gen 9"
            $Profile.Family = "ThinkPad X1 Carbon"
            $Profile.BIOSVendor = "LENOVO"
            $Profile.BIOSVersion = "N32ET82W (1.58 )"
            $Profile.BIOSDate = "03/15/2023"
            $Profile.BoardVendor = "LENOVO"
            $Profile.BoardProduct = "20XW004JUS"
            $Profile.BoardVersion = "SDK0J40697 WIN"
            $Profile.ChassisVendor = "LENOVO"
            $Profile.ChassisType = "10"
            $Profile.OUI = @("001B21", "001C42", "0021CC") | Get-Random
        }
        1 { # Dell Latitude
            $Profile.Vendor = "Dell Inc."
            $Profile.Product = "Latitude 7490"
            $Profile.Version = "Not Specified"
            $Profile.Family = "Latitude"
            $Profile.BIOSVendor = "Dell Inc."
            $Profile.BIOSVersion = "1.29.0"
            $Profile.BIOSDate = "02/10/2023"
            $Profile.BoardVendor = "Dell Inc."
            $Profile.BoardProduct = "0P1Y05"
            $Profile.BoardVersion = "A00"
            $Profile.ChassisVendor = "Dell Inc."
            $Profile.ChassisType = "10"
            $Profile.OUI = @("001422", "001D09", "002564") | Get-Random
        }
        2 { # HP EliteBook
            $Profile.Vendor = "HP"
            $Profile.Product = "HP EliteBook 840 G8"
            $Profile.Version = "Not Specified"
            $Profile.Family = "HP EliteBook"
            $Profile.BIOSVendor = "HP"
            $Profile.BIOSVersion = "T95 Val 01.11.00"
            $Profile.BIOSDate = "11/24/2022"
            $Profile.BoardVendor = "HP"
            $Profile.BoardProduct = "880D"
            $Profile.BoardVersion = "KBC Version 12.34.56"
            $Profile.ChassisVendor = "HP"
            $Profile.ChassisType = "10"
            $Profile.OUI = @("001871", "001F29", "0025B3") | Get-Random
        }
        Default { # Random Profile
            $Brands = @("Dell Inc.", "LENOVO", "HP", "ASUSTeK COMPUTER INC.")
            $Brand = $Brands | Get-Random
            $Profile.Vendor = $Brand
            $Profile.BIOSVendor = $Brand
            $Profile.BoardVendor = $Brand
            $Profile.ChassisVendor = $Brand
            $Profile.ChassisType = "10"

            if ($Brand -eq "Dell Inc.") {
                $Profile.Product = "Inspiron 15 3511"
                $Profile.Version = "Not Specified"
                $Profile.Family = "Inspiron"
                $Profile.BIOSVersion = "1.18.0"
                $Profile.BIOSDate = "12/05/2022"
                $Profile.BoardProduct = "0H5K9R"
                $Profile.BoardVersion = "A01"
                $Profile.OUI = "001422"
            } elseif ($Brand -eq "LENOVO") {
                $Profile.Product = "82KU"
                $Profile.Version = "IdeaPad 3 15ALC6"
                $Profile.Family = "IdeaPad"
                $Profile.BIOSVersion = "GLCN50WW"
                $Profile.BIOSDate = "08/11/2022"
                $Profile.BoardProduct = "LNVNB161216"
                $Profile.BoardVersion = "SDK0J40697 WIN"
                $Profile.OUI = "0021CC"
            } else {
                $Profile.Product = "Notebook OS"
                $Profile.Version = "1.0"
                $Profile.Family = "Laptop"
                $Profile.BIOSVersion = "F.12"
                $Profile.BIOSDate = "04/04/2023"
                $Profile.BoardProduct = "Motherboard"
                $Profile.BoardVersion = "A00"
                $Profile.OUI = "001871"
            }
        }
    }

    # Generate Random Serials
    $SysSerial = Get-RandomString 10
    $BoardSerial = Get-RandomString 12
    $ChassisSerial = Get-RandomString 10
    $DiskSerial = Get-RandomString 15
    $UUID = [guid]::NewGuid().ToString().ToUpper()
    $MACAddress = $Profile.OUI + (Get-RandomString 6 "0123456789ABCDEF")
    $DiskModel = @("Samsung SSD 860 EVO 500GB", "WDC WD10JPVX-08JC3T0", "Kingston A400 SATA3 480GB", "Crucial CT500MX500SSD1") | Get-Random

    try {
        # Clear the old incorrect uppercase UUID key to fix the VirtualBox launch error
        & $VBoxManage setextradata "$VMName" "VBoxInternal/Devices/pcbios/0/Config/DmiSystemUUID"
        # Clear old incorrect CD-ROM spoofing keys that break UEFI boot
        & $VBoxManage setextradata "$VMName" "VBoxInternal/Devices/ahci/0/Config/Port1/ModelNumber"
        & $VBoxManage setextradata "$VMName" "VBoxInternal/Devices/ahci/0/Config/Port1/SerialNumber"
        & $VBoxManage setextradata "$VMName" "VBoxInternal/Devices/ahci/0/Config/Port1/FirmwareRevision"
        # Clear old unused IDE spoofing keys that break UEFI SATA-only systems
        & $VBoxManage setextradata "$VMName" "VBoxInternal/Devices/piix3ide/0/Config/PrimaryMaster/ModelNumber"
        & $VBoxManage setextradata "$VMName" "VBoxInternal/Devices/piix3ide/0/Config/PrimaryMaster/SerialNumber"
        & $VBoxManage setextradata "$VMName" "VBoxInternal/Devices/piix3ide/0/Config/PrimaryMaster/FirmwareRevision"

        # 1. Apply DMI (SMBIOS) Settings
        $DMISettings = @{
            "DmiBIOSVendor"       = $Profile.BIOSVendor
            "DmiBIOSVersion"      = $Profile.BIOSVersion
            "DmiBIOSReleaseDate"  = $Profile.BIOSDate
            "DmiSystemVendor"     = $Profile.Vendor
            "DmiSystemProduct"    = $Profile.Product
            "DmiSystemVersion"    = $Profile.Version
            "DmiSystemSerial"     = $SysSerial
            "DmiSystemUuid"       = $UUID
            "DmiSystemFamily"     = $Profile.Family
            "DmiBoardVendor"      = $Profile.BoardVendor
            "DmiBoardProduct"     = $Profile.BoardProduct
            "DmiBoardVersion"     = $Profile.BoardVersion
            "DmiBoardSerial"      = $BoardSerial
            "DmiChassisVendor"    = $Profile.ChassisVendor
            "DmiChassisType"      = $Profile.ChassisType
            "DmiChassisVersion"   = "Not Specified"
            "DmiChassisSerial"    = $ChassisSerial
        }

        foreach ($Key in $DMISettings.Keys) {
            & $VBoxManage setextradata "$VMName" "VBoxInternal/Devices/pcbios/0/Config/$Key" $DMISettings[$Key]
        }
        $TxtLog.AppendText("[+] DMI/SMBIOS information modified successfully.`r`n")

        # 2. Apply Storage Device Spoofing
        & $VBoxManage setextradata "$VMName" "VBoxInternal/Devices/ahci/0/Config/Port0/ModelNumber" $DiskModel
        & $VBoxManage setextradata "$VMName" "VBoxInternal/Devices/ahci/0/Config/Port0/SerialNumber" $DiskSerial
        & $VBoxManage setextradata "$VMName" "VBoxInternal/Devices/ahci/0/Config/Port0/FirmwareRevision" "RVT02B6Q"

        $TxtLog.AppendText("[+] Disk identifiers spoofed to ($DiskModel).`r`n")

        # 3. CPUID Hypervisor Flag Evasion
        & $VBoxManage setextradata "$VMName" "VBoxInternal/CPUM/HostCPUID/40000000/eax" "0x00000000"
        & $VBoxManage setextradata "$VMName" "VBoxInternal/CPUM/HostCPUID/40000000/ebx" "0x00000000"
        & $VBoxManage setextradata "$VMName" "VBoxInternal/CPUM/HostCPUID/40000000/ecx" "0x00000000"
        & $VBoxManage setextradata "$VMName" "VBoxInternal/CPUM/HostCPUID/40000000/edx" "0x00000000"
        
        # Disable Paravirtualization Provider
        & $VBoxManage modifyvm "$VMName" --paravirtprovider none
        $TxtLog.AppendText("[+] CPUID Hypervisor flags and interfaces disabled.`r`n")

        # 4. Network Adapter MAC Spoofing
        & $VBoxManage modifyvm "$VMName" --macaddress1 $MACAddress
        $TxtLog.AppendText("[+] MAC Address spoofed to a valid OUI: $MACAddress`r`n")

        $TxtLog.AppendText("------------------------------------------------`r`n")
        $TxtLog.AppendText("[+] Finished successfully! Applied: $($Profile.Vendor) Profile.`r`n")
        
        [System.Windows.Forms.MessageBox]::Show("VM hardware spoofing applied successfully!`nPlease start the VM and run the guest registry spoofer inside it.", "Success", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
    } catch {
        $TxtLog.AppendText("[-] Error during execution: $_`r`n")
        [System.Windows.Forms.MessageBox]::Show("An error occurred while applying configuration:`n$_", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
})

# Show the GUI Form
$Form.ShowDialog() | Out-Null
