using System;
using System.Diagnostics;
using System.Drawing;
using System.Windows.Forms;

class Program
{
    static void Main()
    {
        NotifyIcon trayIcon = new NotifyIcon
        {
            Icon = SystemIcons.Application,
            Text = "VirtualBox VM Control",
            Visible = true
        };

        ContextMenu trayMenu = new ContextMenu();
        trayMenu.MenuItems.Add("Start VM", StartVM);
        trayMenu.MenuItems.Add("Stop VM", StopVM);
        trayMenu.MenuItems.Add("Exit", (sender, e) => Application.Exit());

        trayIcon.ContextMenu = trayMenu;

        Application.Run();
        trayIcon.Dispose();
    }

    static void StartVM(object sender, EventArgs e)
    {
        Process.Start("VBoxManage", "startvm \"Your_VM_Name\" --type headless");
    }

    static void StopVM(object sender, EventArgs e)
    {
        Process.Start("VBoxManage", "controlvm \"Your_VM_Name\" poweroff");
    }
}
