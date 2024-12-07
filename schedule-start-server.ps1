# Define variables
$taskName = "VanderstackDockerServer"
$taskDescription = "Run Vanderstack Docker Server on system boot"
$exePath = "E:\vanderstack-docker-server\vanderstack-docker-server.exe"
$exeArguments = ""  # Add arguments if needed, otherwise leave empty

if (-not $isAdmin) {
    Write-Host "Restarting PowerShell as administrator..."
    Start-Process -FilePath "powershell.exe" -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs

    # Prevent the window from closing after the program ends
    Write-Host "Press any key to close this window..."
    [void][System.Console]::ReadKey()
    exit
}

# Check if Task Scheduler already has the task
if (Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue) {
    Write-Output "Task '$taskName' already exists. Deleting existing task..."
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
}

# Create a new task action
$action = New-ScheduledTaskAction -Execute $exePath -Argument $exeArguments

# Set the trigger to run at system startup
$trigger = New-ScheduledTaskTrigger -AtStartup

# Specify task settings
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable

# Register the task with the local system account
Register-ScheduledTask -TaskName $taskName `
                       -Description $taskDescription `
                       -Action $action `
                       -Trigger $trigger `
                       -Settings $settings `
                       -User "SYSTEM" `
                       -RunLevel Highest

Write-Output "Task '$taskName' has been added to Task Scheduler and will run at system boot."

# Prevent the window from closing after the program ends
Write-Host "Press any key to close this window..."
[void][System.Console]::ReadKey()
exit
