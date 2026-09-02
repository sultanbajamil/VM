using System;
using System.Diagnostics;
using System.Drawing;
using System.IO;
using System.Net;
using System.Runtime.InteropServices;
using System.Security.Cryptography;
using System.Security.Principal;
using System.Text;
using System.Threading;
using System.Windows.Forms;
using Microsoft.Win32;

namespace MultiSeatLauncher
{
    public class Program
    {
        [DllImport("user32.dll", SetLastError = true)]
        private static extern IntPtr FindWindow(string lpClassName, string lpWindowName);

        [DllImport("user32.dll", SetLastError = true)]
        private static extern bool MoveWindow(IntPtr hWnd, int X, int Y, int nWidth, int nHeight, bool bRepaint);

        [DllImport("user32.dll", SetLastError = true)]
        private static extern int GetWindowLong(IntPtr hWnd, int nIndex);

        [DllImport("user32.dll")]
        private static extern int SetWindowLong(IntPtr hWnd, int nIndex, int dwNewLong);

        [DllImport("user32.dll")]
        private static extern bool SetForegroundWindow(IntPtr hWnd);

        private const int GWL_STYLE = -16;
        private const int WS_CAPTION = 0x00C00000;
        private const int WS_THICKFRAME = 0x00040000;

        private static Form loginForm;
        private static ComboBox cmbUsers;
        private static TextBox txtPass;
        private static CheckBox chkAuto;
        private static Button btnLaunch;
        private static Label lblStatus;
        private static System.Windows.Forms.Timer autoConnectTimer;
        private static int countdownSeconds = 3;
        private static bool isAutoConnecting = false;
        private static string initSetupResult = "";

        [STAThread]
        public static void Main()
        {
            Application.EnableVisualStyles();
            Application.SetCompatibleTextRenderingDefault(false);

            // Force TLS 1.2 globally to fix WebClient SSL/TLS secure channel errors
            try
            {
                ServicePointManager.SecurityProtocol = (SecurityProtocolType)3072;
            }
            catch {}

            // 1. Check for Administrative Privileges and Auto-Elevate
            if (!IsRunningAsAdmin())
            {
                ElevatePrivileges();
                return;
            }

            // Create login Form
            loginForm = new Form();
            // Text: "مطلق الجلسة المزدوجة التلقائي"
            loginForm.Text = "\u0645\u0637\u0644\u0642 \u0627\u0644\u062C\u0644\u0633\u0629 \u0627\u0644\u0645\u0632\u062F\u0648\u062C\u0629 \u0627\u0644\u062A\u0644\u0642\u0627\u0626\u064A";
            loginForm.Size = new Size(420, 390);
            loginForm.StartPosition = FormStartPosition.CenterScreen;
            loginForm.BackColor = Color.FromArgb(30, 30, 46); // Dark theme
            loginForm.ForeColor = Color.White;
            loginForm.FormBorderStyle = FormBorderStyle.FixedDialog;
            loginForm.MaximizeBox = false;
            loginForm.MinimizeBox = false;
            loginForm.RightToLeft = RightToLeft.Yes;
            loginForm.RightToLeftLayout = true;

            // Title
            Label title = new Label();
            title.Text = "\u0645\u0637\u0644\u0642 \u0627\u0644\u062C\u0644\u0633\u0629 \u0627\u0644\u0645\u0632\u062F\u0648\u062C\u0629";
            title.Font = new Font("Segoe UI", 16, FontStyle.Bold);
            title.ForeColor = Color.FromArgb(137, 180, 250);
            title.Location = new Point(20, 15);
            title.Size = new Size(380, 35);
            title.TextAlign = ContentAlignment.MiddleCenter;
            loginForm.Controls.Add(title);

            // Setup Status Label
            lblStatus = new Label();
            // Text: "جاري تهيئة البيئة التلقائية للاتصال..."
            lblStatus.Text = "\u062C\u0627\u0631\u064A \u062A\u0647\u064A\u0624\u0629 \u0627\u0644\u0628\u064A\u0626\u0629 \u0627\u0644\u062A\u0644\u0642\u0627\u0626\u064A\u0629 \u0644\u0644\u0627\u062A\u0635\u0627\u0644...";
            lblStatus.Font = new Font("Segoe UI", 8.5f, FontStyle.Italic);
            lblStatus.ForeColor = Color.FromArgb(137, 180, 250);
            lblStatus.Location = new Point(20, 50);
            lblStatus.Size = new Size(380, 20);
            lblStatus.TextAlign = ContentAlignment.MiddleCenter;
            loginForm.Controls.Add(lblStatus);

            // Username Label & ComboBox
            Label lblUser = new Label();
            // Text: "اختر الحساب الثاني للمستخدم:"
            lblUser.Text = "\u062E\u062A\u0631 \u0627\u0644\u062D\u0633\u0627\u0628 \u0627\u0644\u062B\u0627\u0646\u064A \u0644\u0644\u0645\u0633\u062A\u062E\u062F\u0645:";
            lblUser.Font = new Font("Segoe UI", 9.5f, FontStyle.Bold);
            lblUser.Location = new Point(30, 90);
            lblUser.Size = new Size(360, 20);
            loginForm.Controls.Add(lblUser);

            cmbUsers = new ComboBox();
            cmbUsers.Font = new Font("Segoe UI", 10);
            cmbUsers.BackColor = Color.FromArgb(49, 50, 68);
            cmbUsers.ForeColor = Color.White;
            cmbUsers.Location = new Point(30, 115);
            cmbUsers.Size = new Size(345, 25);
            cmbUsers.DropDownStyle = ComboBoxStyle.DropDownList;
            loginForm.Controls.Add(cmbUsers);

            // Populate local users
            string[] localUsers = GetLocalUsers();
            if (localUsers.Length > 0)
            {
                cmbUsers.Items.AddRange(localUsers);
                cmbUsers.SelectedIndex = 0;
            }
            else
            {
                cmbUsers.DropDownStyle = ComboBoxStyle.DropDown;
            }

            // Password Label & Input
            Label lblPass = new Label();
            // Text: "كلمة مرور الحساب الثاني:"
            lblPass.Text = "\u0643\u0644\u0645\u0629 \u0645\u0631\u0648\u0631 \u0627\u0644\u062D\u0633\u0627\u0628 \u0627\u0644\u062B\u0627\u0646\u064A:";
            lblPass.Font = new Font("Segoe UI", 9.5f, FontStyle.Bold);
            lblPass.Location = new Point(30, 155);
            lblPass.Size = new Size(360, 20);
            loginForm.Controls.Add(lblPass);

            txtPass = new TextBox();
            txtPass.Font = new Font("Segoe UI", 10);
            txtPass.PasswordChar = '●';
            txtPass.BackColor = Color.FromArgb(49, 50, 68);
            txtPass.ForeColor = Color.White;
            txtPass.Location = new Point(30, 180);
            txtPass.Size = new Size(345, 25);
            loginForm.Controls.Add(txtPass);

            // Auto-Connect CheckBox
            chkAuto = new CheckBox();
            // Text: "حفظ البيانات والاتصال تلقائياً"
            chkAuto.Text = "\u062D\u0641\u0638 \u0627\u0644\u0628\u064A\u0627\u0646\u0627\u062A \u0648\u0627\u0644\u0627\u062A\u0635\u0627\u0644 \u062A\u0644\u0642\u0627\u0626\u064A\u0627\u064B";
            chkAuto.Font = new Font("Segoe UI", 9.5f);
            chkAuto.Location = new Point(30, 220);
            chkAuto.Size = new Size(345, 25);
            chkAuto.ForeColor = Color.FromArgb(166, 227, 161);
            loginForm.Controls.Add(chkAuto);

            // Launch Button
            btnLaunch = new Button();
            // Text: "اتصال وتقسيم الشاشة"
            btnLaunch.Text = "\u0627\u062A\u0635\u0627\u0644 \u0648\u062A\u0642\u0633\u064A\u0645 \u0627\u0644\u0634\u0627\u0634\u0629";
            btnLaunch.Font = new Font("Segoe UI", 11, FontStyle.Bold);
            btnLaunch.Location = new Point(30, 265);
            btnLaunch.Size = new Size(345, 45);
            btnLaunch.BackColor = Color.FromArgb(137, 180, 250);
            btnLaunch.ForeColor = Color.FromArgb(17, 17, 27);
            btnLaunch.FlatStyle = FlatStyle.Flat;
            btnLaunch.Cursor = Cursors.Hand;
            btnLaunch.Enabled = false; // Disabled initially
            loginForm.Controls.Add(btnLaunch);

            btnLaunch.Click += BtnLaunch_Click;

            // Load saved config without autoconnecting yet (autoconnect will be handled after setup finishes)
            string savedUser, savedPass;
            bool autoConnect;
            if (LoadConfig(out savedUser, out savedPass, out autoConnect))
            {
                if (!string.IsNullOrEmpty(savedUser))
                {
                    if (cmbUsers.DropDownStyle == ComboBoxStyle.DropDownList)
                    {
                        int idx = cmbUsers.FindStringExact(savedUser);
                        if (idx >= 0) cmbUsers.SelectedIndex = idx;
                    }
                    else
                    {
                        cmbUsers.Text = savedUser;
                    }
                }
                txtPass.Text = savedPass;
                chkAuto.Checked = autoConnect;
            }

            // Start background setup thread so window opens instantly
            Thread setupThread = new Thread(new ThreadStart(delegate
            {
                string result = AutoSetupSystem();
                if (loginForm != null && !loginForm.IsDisposed)
                {
                    try
                    {
                        loginForm.Invoke((MethodInvoker)delegate
                        {
                            initSetupResult = result;
                            lblStatus.Text = result;
                            lblStatus.ForeColor = result.Contains("Failed") || result.Contains("\u0641\u0634\u0644") ? Color.FromArgb(243, 139, 168) : Color.FromArgb(166, 227, 161);
                            btnLaunch.Enabled = true;

                            // Start auto-connect if enabled and configuration is valid
                            if (chkAuto.Checked && !string.IsNullOrEmpty(cmbUsers.Text) && !string.IsNullOrEmpty(txtPass.Text))
                            {
                                if (!initSetupResult.Contains("Failed") && !initSetupResult.Contains("\u0641\u0634\u0644"))
                                {
                                    StartAutoConnectTimer();
                                }
                            }
                        });
                    }
                    catch {}
                }
            }));
            setupThread.IsBackground = true;
            setupThread.Start();

            Application.Run(loginForm);
        }

        private static void StartAutoConnectTimer()
        {
            isAutoConnecting = true;
            btnLaunch.BackColor = Color.FromArgb(243, 139, 168); // Red-ish for cancel action
            // Text: "إلغاء الاتصال التلقائي (3 ث)"
            btnLaunch.Text = string.Format("\u0625\u0644\u063A\u0627\u0621 \u0627\u0644\u0627\u062A\u0635\u0627\u0644 \u062A\u0644\u0642\u0627\u0626\u064A ({0} \u062B)", countdownSeconds);

            autoConnectTimer = new System.Windows.Forms.Timer();
            autoConnectTimer.Interval = 1000;
            autoConnectTimer.Tick += AutoConnectTimer_Tick;
            autoConnectTimer.Start();
        }

        private static void CancelAutoConnect()
        {
            if (autoConnectTimer != null)
            {
                autoConnectTimer.Stop();
                autoConnectTimer.Dispose();
                autoConnectTimer = null;
            }
            isAutoConnecting = false;
            btnLaunch.BackColor = Color.FromArgb(137, 180, 250);
            // Text: "اتصال وتقسيم الشاشة"
            btnLaunch.Text = "\u0627\u062A\u0635\u0627\u0644 \u0648\u062A\u0642\u0633\u064A\u0645 \u0627\u0644\u0634\u0627\u0634\u0629";
        }

        private static void AutoConnectTimer_Tick(object sender, EventArgs e)
        {
            countdownSeconds--;
            if (countdownSeconds > 0)
            {
                btnLaunch.Text = string.Format("\u0625\u0644\u063A\u0627\u0621 \u0627\u0644\u0627\u062A\u0635\u0627\u0644 \u062A\u0644\u0642\u0627\u0626\u064A ({0} \u062B)", countdownSeconds);
            }
            else
            {
                autoConnectTimer.Stop();
                autoConnectTimer.Dispose();
                autoConnectTimer = null;
                isAutoConnecting = false;
                ExecuteConnection();
            }
        }

        private static void BtnLaunch_Click(object sender, EventArgs e)
        {
            if (isAutoConnecting)
            {
                CancelAutoConnect();
            }
            else
            {
                ExecuteConnection();
            }
        }

        private static void ExecuteConnection()
        {
            // If setup failed, alert the user and ask if they still want to proceed
            if (initSetupResult.Contains("Failed") || initSetupResult.Contains("\u0641\u0634\u0644"))
            {
                // Title: "تحذير الإعداد" (Setup Warning)
                // Message: "تحذير: فشل إعداد RDP. قد لا يتمكن البرنامج من الاتصال. هل تريد المتابعة على أي حال؟\n\nالخطأ: "
                string warningMsg = string.Format("\u062A\u062D\u0630\u064A\u0631: \u0641\u0634\u0644 \u0625\u0639\u062F\u0627\u062F RDP. \u0642\u062F \u0644\u0627 \u064A\u062A\u0645\u0643\u0646 \u0627\u0644\u0628\u0631\u0646\u0627\u0645\u062C \u0645\u0646 \u0627\u0644\u0627\u062A\u0635\u0627\u0644. \u0647\u0644 \u062A\u0631\u064A\u062F \u0627\u0644\u0645\u062A\u0627\u0628\u0639\u0629 \u0639\u0644\u0649 \u0623\u064A \u062D\u0627\u0644\u061F\n\n{0}", initSetupResult);
                DialogResult dr = MessageBox.Show(warningMsg, "\u062A\u062D\u0630\u064A\u0631 \u0627\u0644\u0625\u0639\u062F\u0627\u062F", MessageBoxButtons.YesNo, MessageBoxIcon.Warning);
                if (dr == DialogResult.No) return;
            }

            string username = cmbUsers.Text.Trim();
            string password = txtPass.Text;

            if (string.IsNullOrEmpty(username))
            {
                // "يرجى اختيار اسم مستخدم للحساب الثاني."
                MessageBox.Show("\u064A\u0631\u062C\u064A \u0627\u062E\u062A\u064A\u0627\u0631 \u0627\u0633\u0645 \u0645\u0633\u062A\u062E\u062F\u0645 \u0644\u0644\u062D\u0633\u0627\u0628 \u0627\u0644\u062B\u0627\u0646\u064A.", "\u062E\u0637\u0623 \u0641\u064A \u0627\u0644\u062A\u062D\u0642\u0642", MessageBoxButtons.OK, MessageBoxIcon.Warning);
                return;
            }

            // Save config if checked
            SaveConfig(username, password, chkAuto.Checked);

            loginForm.Hide();

            try
            {
                // Ensure the selected user has RDP permissions
                EnsureUserInRdpGroup(username);

                // 1. Securely register credentials locally using Windows cmdkey
                RunCommand("cmdkey.exe", string.Format("/generic:TERMSRV/127.0.0.1 /user:\"{0}\" /pass:\"{1}\"", username, password));

                // 2. Generate a temporary RDP file
                string tempRdpPath = Path.Combine(Path.GetTempPath(), "temp_split.rdp");
                int halfWidth = Screen.PrimaryScreen.Bounds.Width / 2;
                int height = Screen.PrimaryScreen.Bounds.Height;

                using (StreamWriter sw = new StreamWriter(tempRdpPath, false))
                {
                    sw.WriteLine("screen mode id:i:1"); // Windowed mode
                    sw.WriteLine(string.Format("desktopwidth:i:{0}", halfWidth));
                    sw.WriteLine(string.Format("desktopheight:i:{0}", height));
                    sw.WriteLine("smart sizing:i:1");
                    sw.WriteLine("username:s:" + username);
                    sw.WriteLine("full address:s:127.0.0.1");
                    sw.WriteLine("prompt for credentials:i:0");
                    sw.WriteLine("displayconnectionbar:i:0"); // Disable the top connection bar
                }

                // 3. Launch mstsc.exe with the custom RDP file
                Process.Start("mstsc.exe", string.Format("\"{0}\"", tempRdpPath));

                // 4. Wait for RDP Window and position it on the right side of the screen
                IntPtr rdpWnd = IntPtr.Zero;
                for (int i = 0; i < 40; i++) // Timeout after 8 seconds
                {
                    Thread.Sleep(200);
                    rdpWnd = FindWindow("TscShellContainerClass", null);
                    if (rdpWnd != IntPtr.Zero) break;
                }

                if (rdpWnd != IntPtr.Zero)
                {
                    // Remove Window title bar and borders for a seamless flat integration
                    int style = GetWindowLong(rdpWnd, GWL_STYLE);
                    SetWindowLong(rdpWnd, GWL_STYLE, style & ~WS_CAPTION & ~WS_THICKFRAME);

                    // Position it to fill the right half of the screen
                    MoveWindow(rdpWnd, halfWidth, 0, halfWidth, height, true);
                    SetForegroundWindow(rdpWnd);
                }
                else
                {
                    // "لم يتم العثور على نافذة سطح المكتب البعيد."
                    MessageBox.Show("\u0644\u0645 \u064A\u062A\u0645 \u0627\u0644\u0639\u062B\u0648\u0631 \u0639\u0644\u0649 \u0646\u0627\u0641\u0630\u0629 \u0633\u0637\u062D \u0627\u0644\u0645\u0633\u0643\u062A\u0628 \u0627\u0644\u0628\u0639\u064A\u062F.", "\u062E\u0637\u0623 \u0641\u064A \u0627\u0644\u0627\u062A\u0635\u0627\u0644", MessageBoxButtons.OK, MessageBoxIcon.Error);
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show("An error occurred: " + ex.Message, "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
            finally
            {
                // 5. Clean up credentials from cmdkey for security
                RunCommand("cmdkey.exe", "/delete:TERMSRV/127.0.0.1");
                Application.Exit();
            }
        }

        private static bool IsRunningAsAdmin()
        {
            using (WindowsIdentity identity = WindowsIdentity.GetCurrent())
            {
                WindowsPrincipal principal = new WindowsPrincipal(identity);
                return principal.IsInRole(WindowsBuiltInRole.Administrator);
            }
        }

        private static void ElevatePrivileges()
        {
            ProcessStartInfo info = new ProcessStartInfo();
            info.FileName = Application.ExecutablePath;
            info.Verb = "runas"; // Requests UAC elevation
            try
            {
                Process.Start(info);
            }
            catch
            {
                // "هذا البرنامج يتطلب صلاحيات المسؤول للتشغيل."
                MessageBox.Show("\u0647\u0630\u0627 \u0627\u0644\u0628\u0631\u0646\u0627\u0645\u062C \u064A\u062A\u0637\u0644\u0628 \u0635\u0644\u0627\u062D\u064A\u0627\u062A \u0627\u0644\u0645\u0633\u062E\u0648\u0644 \u0644\u0644\u062A\u0634\u063A\u064A\u0644.", "\u062A\u0645 \u0631\u0641\u0636 \u0627\u0644\u0648\u0635\u0648\u0644", MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
            Application.Exit();
        }

        private static int RunCommand(string fileName, string arguments)
        {
            try
            {
                ProcessStartInfo info = new ProcessStartInfo(fileName, arguments)
                {
                    CreateNoWindow = true,
                    UseShellExecute = false
                };
                using (Process p = Process.Start(info))
                {
                    p.WaitForExit();
                    return p.ExitCode;
                }
            }
            catch
            {
                return -1;
            }
        }

        private static string[] GetLocalUsers()
        {
            try
            {
                ProcessStartInfo ps = new ProcessStartInfo("powershell.exe", "-NoProfile -Command \"Get-LocalUser | Where-Object Enabled | Select-Object -ExpandProperty Name\"")
                {
                    CreateNoWindow = true,
                    UseShellExecute = false,
                    RedirectStandardOutput = true
                };
                using (Process p = Process.Start(ps))
                {
                    string output = p.StandardOutput.ReadToEnd();
                    p.WaitForExit();
                    string[] lines = output.Split(new char[] { '\r', '\n' }, StringSplitOptions.RemoveEmptyEntries);
                    System.Collections.Generic.List<string> users = new System.Collections.Generic.List<string>();
                    string current = Environment.UserName.ToLower();
                    foreach (string line in lines)
                    {
                        string u = line.Trim();
                        if (string.IsNullOrEmpty(u)) continue;
                        string uLower = u.ToLower();
                        if (uLower != current &&
                            uLower != "administrator" &&
                            uLower != "guest" &&
                            uLower != "defaultaccount" &&
                            uLower != "wdgutilityaccount" &&
                            uLower != "wdagutilityaccount")
                        {
                            users.Add(u);
                        }
                    }
                    return users.ToArray();
                }
            }
            catch
            {
                return new string[0];
            }
        }

        private static void EnsureUserInRdpGroup(string username)
        {
            try
            {
                SecurityIdentifier rdpGroupSid = new SecurityIdentifier(WellKnownSidType.BuiltinRemoteDesktopUsersSid, null);
                NTAccount rdpGroupAccount = (NTAccount)rdpGroupSid.Translate(typeof(NTAccount));
                string localizedRdpGroupName = rdpGroupAccount.Value;
                if (localizedRdpGroupName.Contains("\\"))
                {
                    localizedRdpGroupName = localizedRdpGroupName.Substring(localizedRdpGroupName.IndexOf('\\') + 1);
                }

                RunCommand("net.exe", string.Format("localgroup \"{0}\" \"{1}\" /add", localizedRdpGroupName, username));
            }
            catch {}
        }

        private static string GetConfigPath()
        {
            return Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "MultiSeatConfig.cfg");
        }

        private static void SaveConfig(string username, string password, bool autoConnect)
        {
            try
            {
                string encryptedPass = "";
                if (!string.IsNullOrEmpty(password))
                {
                    byte[] passBytes = Encoding.UTF8.GetBytes(password);
                    byte[] encrypted = ProtectedData.Protect(passBytes, null, DataProtectionScope.CurrentUser);
                    encryptedPass = Convert.ToBase64String(encrypted);
                }

                using (StreamWriter sw = new StreamWriter(GetConfigPath(), false))
                {
                    sw.WriteLine("Username=" + username);
                    sw.WriteLine("Password=" + encryptedPass);
                    sw.WriteLine("AutoConnect=" + autoConnect.ToString());
                }
            }
            catch {}
        }

        private static bool LoadConfig(out string username, out string password, out bool autoConnect)
        {
            username = "";
            password = "";
            autoConnect = false;
            try
            {
                string path = GetConfigPath();
                if (!File.Exists(path)) return false;

                string[] lines = File.ReadAllLines(path);
                foreach (string line in lines)
                {
                    int idx = line.IndexOf('=');
                    if (idx <= 0) continue;
                    string key = line.Substring(0, idx).Trim();
                    string val = line.Substring(idx + 1).Trim();

                    if (key == "Username") username = val;
                    else if (key == "AutoConnect") bool.TryParse(val, out autoConnect);
                    else if (key == "Password" && !string.IsNullOrEmpty(val))
                    {
                        try
                        {
                            byte[] encrypted = Convert.FromBase64String(val);
                            byte[] decrypted = ProtectedData.Unprotect(encrypted, null, DataProtectionScope.CurrentUser);
                            password = Encoding.UTF8.GetString(decrypted);
                        }
                        catch {}
                    }
                }
                return true;
            }
            catch
            {
                return false;
            }
        }

        private static string AutoSetupSystem()
        {
            try
            {
                // Force TLS 1.2 in WebClient operations
                try
                {
                    ServicePointManager.SecurityProtocol = (SecurityProtocolType)3072;
                }
                catch {}

                // Enable RDP Connections in Registry
                Registry.SetValue(@"HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Terminal Server", "fDenyTSConnections", 0, RegistryValueKind.DWord);
                Registry.SetValue(@"HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Terminal Server", "fSingleSessionPerUser", 0, RegistryValueKind.DWord);

                // Configure Remote Desktop services (TermService) to run automatically
                RunCommand("sc.exe", "config TermService start= auto");
                RunCommand("sc.exe", "start TermService");

                // Open Firewall rule for RDP
                RunCommand("netsh.exe", "advfirewall firewall set rule group=\"remote desktop\" new enable=Yes");

                // Add Windows Defender exclusions to avoid quarantining RDP Wrapper files
                RunCommand("powershell.exe", "-NoProfile -Command \"Add-MpPreference -ExclusionPath 'C:\\Program Files\\RDP Wrapper' -ErrorAction SilentlyContinue\"");
                RunCommand("powershell.exe", "-NoProfile -Command \"Add-MpPreference -ExclusionPath '$env:TEMP\\RDPWrapExtract' -ErrorAction SilentlyContinue\"");

                // Check and install RDP Wrapper silently if not installed
                string rdpDllPath = @"C:\Program Files\RDP Wrapper\rdpwrap.dll";
                string iniPath = @"C:\Program Files\RDP Wrapper\rdpwrap.ini";

                if (!File.Exists(rdpDllPath))
                {
                    string zipUrl = "https://github.com/stascorp/rdpwrap/releases/download/v1.6.2/RDPWrap-v1.6.2.zip";
                    string tempZip = Path.Combine(Path.GetTempPath(), "RDPWrap.zip");
                    string tempDir = Path.Combine(Path.GetTempPath(), "RDPWrapExtract");

                    using (WebClient wc = new WebClient())
                    {
                        wc.DownloadFile(zipUrl, tempZip);
                    }

                    if (Directory.Exists(tempDir)) Directory.Delete(tempDir, true);
                    Directory.CreateDirectory(tempDir);

                    // Extract zip via PowerShell silently
                    string psArgs = string.Format("-NoProfile -ExecutionPolicy Bypass -Command \"Expand-Archive -Path '{0}' -DestinationPath '{1}' -Force\"", tempZip, tempDir);
                    RunCommand("powershell.exe", psArgs);

                    // Run install.bat silently
                    ProcessStartInfo installInfo = new ProcessStartInfo("cmd.exe", "/c install.bat")
                    {
                        WorkingDirectory = tempDir,
                        CreateNoWindow = true,
                        UseShellExecute = false
                    };
                    using (Process p = Process.Start(installInfo))
                    {
                        p.WaitForExit();
                    }
                }

                // Check INI compatibility with the termsrv.dll version
                string termsrvDll = Path.Combine(Environment.SystemDirectory, "termsrv.dll");
                string termsrvVer = "";
                if (File.Exists(termsrvDll))
                {
                    FileVersionInfo vi = FileVersionInfo.GetVersionInfo(termsrvDll);
                    termsrvVer = string.Format("{0}.{1}.{2}.{3}", vi.FileMajorPart, vi.FileMinorPart, vi.FileBuildPart, vi.FilePrivatePart);
                }

                bool isSupported = false;
                if (File.Exists(iniPath) && !string.IsNullOrEmpty(termsrvVer))
                {
                    string iniContent = File.ReadAllText(iniPath);
                    if (iniContent.Contains("[" + termsrvVer + "]"))
                    {
                        isSupported = true;
                    }
                }

                // If not supported, download the latest community updated rdpwrap.ini
                if (!isSupported && !string.IsNullOrEmpty(termsrvVer))
                {
                    // Stop Remote Desktop Services to unlock the file
                    RunCommand("net.exe", "stop TermService /y");

                    try
                    {
                        using (WebClient wc = new WebClient())
                        {
                            string updatedIni = wc.DownloadString("https://raw.githubusercontent.com/sebaxakerhtc/rdpwrap.ini/master/rdpwrap.ini");
                            if (!string.IsNullOrEmpty(updatedIni))
                            {
                                File.WriteAllText(iniPath, updatedIni);
                            }
                        }
                    }
                    catch {}

                    // Start Remote Desktop Services again
                    RunCommand("net.exe", "start TermService");
                }

                // Text: "تم إعداد النظام بنجاح للتوصيل المزدوج."
                return "\u062A\u0645 \u0625\u0639\u062F\u0627\u062F \u0627\u0644\u0646\u0638\u0627\u0645 \u0628\u0646\u062C\u0627\u062D \u0644\u0644\u062A\u0648\u0635\u064A\u0644 \u0627\u0644\u0645\u0632\u062F\u0648\u062C.";
            }
            catch (Exception ex)
            {
                // Text: "فشل الإعداد التلقائي: "
                return "\u0641\u0634\u0644 \u0627\u0644\u0625\u0639\u062F\u0627\u062F \u0627\u0644\u062A\u0644\u0642\u0627\u0626\u064A: " + ex.Message;
            }
        }
    }
}
