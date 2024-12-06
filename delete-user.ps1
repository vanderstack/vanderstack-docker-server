$username = "vanderstack-share"

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

# Check if the user exists
$userExists = Get-LocalUser -Name $username -ErrorAction SilentlyContinue
if ($userExists) {
    
    Write-Output "Deleting User '$username'."
    Remove-LocalUser -Name $username
    Write-Output "User '$username' deleted."
} else {
    Write-Output "User '$username' not found."
}

# Prevent the window from closing after the program ends
Write-Host "Press any key to close this window..."
[void][System.Console]::ReadKey()
exit