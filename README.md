# 🛡️ VM: VirtualBox Anti-Detection, Hardware Spoofing & Multi-Seat Suite

**VM** is an administrative and security research toolkit designed to harden and disguise **Oracle VirtualBox** virtual machines, as well as configure concurrent multi-seat Remote Desktop (RDP) environments.

The primary objective of the toolkit is to modify virtual hardware identifiers and guest operating system artifacts so that the virtual machine resembles a physical laptop from major original equipment manufacturers (OEMs)—including **Dell, HP, Lenovo, and ASUS**. This bypasses anti-virtualization checks, sandbox analysis, anti-cheat mechanisms, and proctoring environments.

---

## 📁 Repository Contents

```text
VM/
├── spoof_host_vm.ps1            # Host-side GUI for VirtualBox SMBIOS/DMI hardware spoofing
├── Run_Spoofer_GUI.bat          # One-click launcher for host spoofing GUI
│
├── clean_guest_registry.ps1     # Guest-side GUI for in-VM registry sanitization
├── Run_Guest_Cleaner_GUI.bat    # One-click launcher for guest cleaner GUI
│
├── setup_concurrent_rdp.ps1     # Script enabling concurrent multi-user Windows RDP
├── MultiSeatApp.cs              # C# encrypted multi-seat session manager (DPAPI)
├── MultiSeatConfig.cfg          # Encrypted session credentials configuration
├── Build_Launcher.bat           # Batch compilation script using native csc.exe
│
├── GUEST/                       # Dedicated package to transfer into the Guest VM
│   ├── clean_guest_registry.ps1
│   └── Run_Guest_Cleaner_GUI.bat
│
├── .gitignore                   # Excludes build binaries, archives, and executables
└── README.md                    # Project documentation
```

---

## 🌟 Core Components & Capabilities

### 1. Host-Side Hardware Spoofer (`spoof_host_vm.ps1`)
- **Execution Target**: Runs on the **physical host machine**.
- **Capabilities**:
  - Automatically discovers `VBoxManage.exe` from standard installation paths or the system environment `%PATH%`.
  - Presents a Windows Forms GUI listing all registered VirtualBox VMs.
  - Injects realistic vendor profiles into the VM configuration:
    - **Dell Inc.** (Inspiron / Latitude / XPS)
    - **HP / Hewlett-Packard** (EliteBook / Pavilion)
    - **Lenovo** (ThinkPad T480 / X1 Carbon)
    - **ASUSTeK COMPUTER INC.** (ZenBook)
  - Randomizes system serial numbers, motherboard identifiers, chassis asset tags, and system UUIDs.
  - Spoofs the virtual network adapter's MAC address to replace VirtualBox OUI vendor prefixes (`08:00:27`).

### 2. Guest-Side Registry Cleaner (`clean_guest_registry.ps1`)
- **Execution Target**: Runs **inside the virtual machine guest OS**.
- **Capabilities**:
  - Sanitizes Windows Registry entries commonly queried by anti-VM checks (e.g., `HARDWARE\DESCRIPTION\System\BIOS`).
  - Cleans display adapter, processor, and disk drive strings containing keywords such as `VBOX`, `VirtualBox`, or `QEMU`.
  - Disables VirtualBox Guest Additions tracking mechanisms and background artifacts.

### 3. Concurrent Multi-Seat RDP Manager (`setup_concurrent_rdp.ps1` & `MultiSeatApp.cs`)
- Modifies local Windows policies and settings to enable multiple concurrent Remote Desktop sessions on desktop editions of Windows.
- Provides a C# launcher compiled via the native .NET Framework compiler (`csc.exe`) that utilizes the Windows Data Protection API (**DPAPI**) to securely encrypt credentials for automated background session launching.

---

## 🚀 Step-by-Step Usage Guide

### Phase 1: Spoofing on the Host Machine
1. Ensure the target VirtualBox VM is completely **powered off**.
2. Right-click `Run_Spoofer_GUI.bat` and select **Run as Administrator**.
3. In the graphical interface:
   - Select your target virtual machine from the dropdown menu.
   - Choose your preferred OEM profile (e.g., *Lenovo ThinkPad* or *Dell Latitude*).
   - Click **Apply Hardware Spoofing**.
4. Confirm the success dialogue. Your VM now reports authentic OEM hardware attributes.

### Phase 2: In-Guest Sanitization
1. Power on the virtual machine.
2. Copy the `GUEST` folder into the virtual machine.
3. Inside the VM, right-click `Run_Guest_Cleaner_GUI.bat` and select **Run as Administrator**.
4. Click **Clean & Spoof Guest Registry**.
5. Reboot the guest virtual machine to finalize registry modifications.

### Phase 3: Building the MultiSeat Launcher (Optional)
To recompile `MultiSeatApp.cs` into an executable without Visual Studio:
```cmd
Build_Launcher.bat
```
This invokes the system's native .NET Framework C# compiler (`csc.exe`) to produce `MultiSeatLauncher.exe`.

---

## ⚠️ Disclaimer
This toolkit is provided solely for virtualization research, compatibility testing, and educational purposes. Always adhere to software licensing agreements and terms of service.
