using System;
using System.Diagnostics;
using System.Drawing;
using System.Windows.Forms;

class Program
{
    static void Main()
    {
        string vmName = "vanderstack-docker-server";

        // Automatically start the VM on app launch
        StartVM(vmName);

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

    static void StartVM(string vmName)
    {
        try
        {
            Process.Start("VBoxManage", $"startvm \"{vmName}\" --type headless");
            MessageBox.Show($"VM '{vmName}' started successfully!", "VM Control", MessageBoxButtons.OK, MessageBoxIcon.Information);
        }
        catch (Exception ex)
        {
            MessageBox.Show($"Failed to start VM: {ex.Message}", "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
        }
    }

    static void StopVM(string vmName)
    {
        try
        {
            Process.Start("VBoxManage", $"controlvm \"{vmName}\" poweroff");
            MessageBox.Show($"VM '{vmName}' stopped successfully!", "VM Control", MessageBoxButtons.OK, MessageBoxIcon.Information);
        }
        catch (Exception ex)
        {
            MessageBox.Show($"Failed to stop VM: {ex.Message}", "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
        }
    }
}
