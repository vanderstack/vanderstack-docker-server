# Define the username and password for the new user
$username = "vanderstack-share"
$password = ConvertTo-SecureString "!!PLACEHOLDER!!" -AsPlainText -Force

# Define the folder and share name for new share
$folderPath = "E:\Documents\vanderstack-docker-server\share"
$shareName = "vanderstack-share$"

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
    
    Write-Output "User '$username' already exists."
} else {

    # Create the new user
    Write-Output "Creating User '$username'."
    New-LocalUser -Name $username -Password $password -FullName "VanderStack Share User" -Description "User for vanderstack-share access" -Confirm:$false

    # Confirm user creation
    # Get the user object from local users
    $userExists = Get-LocalUser -Name $username -ErrorAction SilentlyContinue

    if ($userExists) {
        Write-Output "User '$username' has been created successfully."

        # Add the user to the 'Users' group
        Write-Output "Adding User '$username' to the Users group."
        Add-LocalGroupMember -Group "Users" -Member $username

        Write-Output "Setting User '$username' account status to disabled to prevent login."
        # Disable the user's ability to log in interactively by setting their account to disabled
        Disable-LocalUser -Name $username

    } else {
        Write-Output "Failed to create user '$username'."
        
        # Prevent the window from closing after the program ends
        Write-Host "Press any key to close this window..."
        [void][System.Console]::ReadKey()
        exit
    }
}

# Check if the folder exists
if (-Not (Test-Path -Path $folderPath)) {
    Write-Host "The folder '$folderPath' does not exist. Creating it now..."
    New-Item -Path $folderPath -ItemType Directory -Force | Out-Null
    Write-Host "Folder created successfully."
} else {
    Write-Host "The folder '$folderPath' already exists."
}

# Check if the folder is already shared
$existingShare = Get-SmbShare | Where-Object { $_.Path -eq $folderPath }
if ($existingShare) {
    
    Write-Output "The folder '$folderPath' is already shared as $($existingShare.Name)."

} else {
    
    # Create the share. Deny access to "Everyone" otherwise it will be accessible by default.
    Write-Output "Sharing the folder '$folderPath' as '$shareName'. without any user permissions."
    New-SmbShare -Name $shareName -Path $folderPath -NoAccess "Everyone"

    # Grant the user read and write access to the share
    Write-Output "Granting read and write access to user '$username' for share '$shareName'."
    Grant-SmbShareAccess -Name $shareName -AccountName $username -AccessRight Change -Confirm:$false
}

# Prevent the window from closing after the program ends
Write-Host "Press any key to close this window..."
[void][System.Console]::ReadKey()


# Define folder path and share name
$folderPath = "C:\foo"
$shareName = "foo"

# Create the folder if it doesn't exist
if (-Not (Test-Path -Path $folderPath)) {
    New-Item -Path $folderPath -ItemType Directory | Out-Null
    Write-Host "Folder '$folderPath' created."
} else {
    Write-Host "Folder '$folderPath' already exists."
}

# Grant "Everyone" full access to the folder
$acl = Get-Acl -Path $folderPath
$accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule("Everyone", "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
$acl.SetAccessRule($accessRule)
Set-Acl -Path $folderPath -AclObject $acl
Write-Host "Granted 'Everyone' full access to '$folderPath'."

# Share the folder with "Everyone" having full access
New-SmbShare -Name $shareName -Path $folderPath -FullAccess "Everyone"
Write-Host "Folder '$folderPath' shared as '$shareName' with 'Everyone' full access."
