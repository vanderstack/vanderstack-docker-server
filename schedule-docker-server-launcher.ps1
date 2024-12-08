# Get the script's directory and filename without the .ps1 extension
$scriptPath = $MyInvocation.MyCommand.Path
$scriptDir = Split-Path -Parent $scriptPath
$scriptKey = [IO.Path]::GetFileNameWithoutExtension($scriptPath)

# Path to the config file
$configFilePath = Join-Path -Path $scriptDir -ChildPath "config.json"

# Check if the config file exists
if (-Not (Test-Path -Path $configFilePath)) {
    Write-Error "Configuration file not found at $configFilePath."
    
    # Prevent the window from closing after the program ends
    Write-Host "Press any key to close this window..."
    [void][System.Console]::ReadKey()
    exit 1
}

# Load and parse the JSON config file
try {
    $configData = Get-Content -Path $configFilePath -Raw | ConvertFrom-Json
} catch {
    Write-Error "Failed to parse the configuration file as JSON: $_"
    
    # Prevent the window from closing after the program ends
    Write-Host "Press any key to close this window..."
    [void][System.Console]::ReadKey()
    exit 1
}

# Extract the section corresponding to the script's filename
if (-Not $configData.$scriptKey) {
    Write-Error "The '$scriptKey' section is missing in the configuration file."
    
    # Prevent the window from closing after the program ends
    Write-Host "Press any key to close this window..."
    [void][System.Console]::ReadKey()
    exit 1
}

$config = $configData.$scriptKey

# Define variables
$taskName = $config.taskName
$taskDescription = $config.taskDescription
$exePath = $config.exePath
$exeArguments = $config.exeArguments # Add arguments if needed, otherwise leave empty

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
