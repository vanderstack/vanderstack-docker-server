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

    # Get the user object from local users
    $userExists = Get-LocalUser -Name $username -ErrorAction SilentlyContinue

    # Confirm user creation
    if ($userExists) {
        Write-Output "User '$username' has been created successfully."

        # Add the user to the 'Users' group
        Write-Output "Adding User '$username' to the Users group."
        Add-LocalGroupMember -Group "Users" -Member $username

        # Disable the user's ability to log in interactively by setting their account to disabled
        Write-Output "Setting User '$username' account status to disabled to prevent login."
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

    # Get NTFS access rules
    $acl = Get-Acl -Path $folderPath

    # Disable NTFS access permissions inheritance and do not copy the existing permissions
    $acl.SetAccessRuleProtection($true, $false)

    # Create access rule for local users granting read/write access to the folder
    $usersAccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
        "Users", # group the rule applies to
        "ReadData, WriteData", # grant read and write permissions
        "ContainerInherit,ObjectInherit", # apply permissions to subfolders and files
        "None", # no specific flags for the rule
        "Allow" # rule type is allow rather than deny
    )

    # Add access to Users
    $acl.SetAccessRule($usersAccessRule)

    # Create access rule for Administrators granting full access to the folder
    $adminAccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
        "Administrators", # group the rule applies to
        "FullControl", # grant read and write permissions
        "ContainerInherit,ObjectInherit", # apply permissions to subfolders and files
        "None", # no specific flags for the rule
        "Allow" # rule type is allow rather than deny
    )
    
    # Add access to Users
    $acl.SetAccessRule($adminAccessRule)

    # Update NTFS access rules
    Set-Acl -Path $folderPath -AclObject $acl
    Write-Host "Granted Read/Write access for 'Users' (local only) to '$folderPath'."
    Write-Host "Granted Full Control for 'Administrators' to '$folderPath'."

} else {
    Write-Host "The folder '$folderPath' already exists."
}

# Check if the folder is already shared
$existingShare = Get-SmbShare | Where-Object { $_.Path -eq $folderPath }
if ($existingShare) {
    
    Write-Output "The folder '$folderPath' is already shared as $($existingShare.Name)."

} else {
    
    # Share the folder with the group "Users" having read/write
    Write-Output "Sharing the folder '$folderPath' as '$shareName'. with Read/Write granted to Users."
    New-SmbShare -Name $shareName -Path $folderPath -ChangeAccess "Users"
    Write-Host "Folder '$folderPath' shared as '$shareName' with 'Users' granting Read/Write control."
}

# Prevent the window from closing after the program ends
Write-Host "Press any key to close this window..."
[void][System.Console]::ReadKey()