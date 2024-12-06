# Define the folder and share name for new share
$folderPath = "E:\Documents\vanderstack-docker-server\share"

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
$existingShare = Get-SmbShare | Where-Object { $_.Path -eq $folderPath }
if ($existingShare) {
    
    Write-Output "The folder '$folderPath' is shared as $($existingShare.Name)."
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