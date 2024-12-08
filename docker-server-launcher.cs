using System;
using System.Diagnostics;
using System.Drawing;
using System.IO;
using System.Text.Json;
using System.Windows.Forms;

class Program
{
    static void Main()
    {
        { string VMName, string VBoxManage } config;
        try
        {
            config = LoadConfig();
        }
        catch (Exception e)
        {
            MessageBox.Show($"Failed to load config: {ex.Message}", "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
            return;
        }

        // Automatically start the VM on app launch
        StartVM(config.VMName, config.VBoxManage);

        // Create the system tray icon
        NotifyIcon trayIcon = new NotifyIcon
        {
            Icon = SystemIcons.Application,
            Text = "Docker VM",
            Visible = true
        };

        // Create the context menu for the tray
        ContextMenu trayMenu = new ContextMenu();
        trayMenu.MenuItems.Add("Start VM", (sender, e) => StartVM(vmName));
        trayMenu.MenuItems.Add("Stop VM", (sender, e) => StopVM(vmName));
        trayMenu.MenuItems.Add("Exit", (sender, e) => Application.Exit());

        trayIcon.ContextMenu = trayMenu;

        // Run the application loop
        Application.Run();
        trayIcon.Dispose();
    }

    static void StartVM(string vmName, string vBoxManage)
    {
        try
        {
            Process.Start(vBoxManage, $"startvm \"{vmName}\" --type headless");
            MessageBox.Show($"VM '{vmName}' started successfully!", "VM Control", MessageBoxButtons.OK, MessageBoxIcon.Information);
        }
        catch (Exception ex)
        {
            MessageBox.Show($"Failed to start VM: {ex.Message}", "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
        }
    }

    static void StopVM(string vmName, string vBoxManage)
    {
        try
        {
            Process.Start(vBoxManage, $"controlvm \"{vmName}\" poweroff");
            MessageBox.Show($"VM '{vmName}' stopped successfully!", "VM Control", MessageBoxButtons.OK, MessageBoxIcon.Information);
        }
        catch (Exception ex)
        {
            MessageBox.Show($"Failed to stop VM: {ex.Message}", "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
        }
    }

    static (string vmName, string VBoxManage) LoadConfig()
    {
        // Get the script's directory and filename without the .csx extension
        var scriptPath = Environment.GetCommandLineArgs()[0];
        var scriptDir = Path.GetDirectoryName(scriptPath) ?? ".";
        var scriptKey = Path.GetFileNameWithoutExtension(scriptPath);

        // Path to the config file
        var configFilePath = Path.Combine(scriptDir, "config.json");

        // Check if the config file exists
        if (!File.Exists(configFilePath))
        {
            throw new Exception("Error: Configuration file 'config.json' not found.");
        }

        // Load and parse the JSON config file
        var configJson = File.ReadAllText(configFilePath);
        var configData = JsonDocument.Parse(configJson).RootElement;

        // Check if the key matching the script's name exists
        if (!configData.TryGetProperty(scriptKey, out var scriptConfig))
        {
            throw new Exception($"Error: The '{scriptKey}' section is missing in the configuration file.");
        }

        // Read the 'VMName' value
        if (!scriptConfig.TryGetProperty("VMName", out var vmNameElement))
        {
            throw new Exception($"Error: The 'VMName' key is missing in the '{scriptKey}' section.");
        }

        // Read the 'VBoxManage' value
        if (!scriptConfig.TryGetProperty("VBoxManage", out var vBoxManageElement))
        {
            throw new Exception($"Error: The 'VBoxManage' key is missing in the '{scriptKey}' section.");
        }

        return (
            vmName = vmNameElement.GetString()
            , VBoxManage = vBoxManageElement.GetString()
        );
    }
}