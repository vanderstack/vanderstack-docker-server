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
# Define the folder and share name for new share
$sharePath = $config.sharePath

# Ensure running as admin
$currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
$adminRole = [Security.Principal.WindowsBuiltInRole]::Administrator
$isAdmin = (New-Object Security.Principal.WindowsPrincipal($currentUser)).IsInRole($adminRole)

if (-not $isAdmin) {
    Write-Host "Restarting PowerShell as administrator..."
    Start-Process -FilePath "powershell.exe" -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs

    # Prevent the window from closing after the program ends
    Write-Host "Press any key to close this window..."
    [void][System.Console]::ReadKey()
    exit
}

# Check if the folder is already shared
$existingShare = Get-SmbShare | Where-Object { $_.Path -eq $sharePath }
if ($existingShare) {
    
    Write-Output "The folder '$sharePath' is shared as $($existingShare.Name)."
}
else {
    Write-Output "The folder is not shared."

    # Prevent the window from closing after the program ends
    Write-Host "Press any key to close this window..."
    [void][System.Console]::ReadKey()
    exit
}

# Get the list of users with access to the share
$shareAccess = Get-SmbShareAccess -Name $existingShare.Name

Write-Output "Revoking access for all users to share '$($existingShare.Name)'."
foreach ($access in $shareAccess) {

    # Try to revoke access for the user
    try {
        Revoke-SmbShareAccess -Name $existingShare.Name -AccountName $access.AccountName -Force
        Write-Output "Revoked access for user '$($access.AccountName)' from share '$($existingShare.Name)'."
    } catch {
        Write-Error "Failed to revoke access for user '$($access.AccountName)' on share '$($existingShare.Name)'. Error: $_"
    }
}

Write-Output "Deleting The share $($existingShare.Name)."
Remove-SmbShare -Name $existingShare.Name -Force

# Prevent the window from closing after the program ends
Write-Host "Press any key to close this window..."
[void][System.Console]::ReadKey()
exit