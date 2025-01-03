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
$username = $config.username
$password = ConvertTo-SecureString $config.password -AsPlainText -Force
$sharePath = $config.sharePath
$shareName = $config.shareName

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
    New-LocalUser -Name $username -Password $password -FullName "VanderStack Share User" -Description "User for $shareName access" -Confirm:$false

    # Get the user object from local users
    $userExists = Get-LocalUser -Name $username -ErrorAction SilentlyContinue

    # Confirm user creation
    if ($userExists) {
        Write-Output "User '$username' has been created successfully."

        # Add the user to the 'Users' group
        Write-Output "Adding User '$username' to the Users group."
        Add-LocalGroupMember -Group "Users" -Member $username

        # Disable the user's ability to log in interactively by setting their account to disabled
        # Account being disabled does not prevent mounting or file access with NTFS and share access to Users
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
if (-Not (Test-Path -Path $sharePath)) {
    Write-Host "The folder '$sharePath' does not exist. Creating it now..."
    New-Item -Path $sharePath -ItemType Directory -Force | Out-Null
    Write-Host "Folder created successfully."

    # Get NTFS access rules
    $acl = Get-Acl -Path $sharePath

    # Disable NTFS access permissions inheritance and do not copy the existing permissions
    Write-Host "Disabling access control inheritance. Access will require an explicitly allow rule."
    $acl.SetAccessRuleProtection($true, $false)

    $FullControl = [System.Security.AccessControl.FileSystemRights]::FullControl
    $ReadWrite = $FullControl -band (-bnot [System.Security.AccessControl.FileSystemRights]::ExecuteFile)

    # Define inheritance and propagation flags
    $InheritanceFlags = [System.Security.AccessControl.InheritanceFlags]::ContainerInherit -bor [System.Security.AccessControl.InheritanceFlags]::ObjectInherit
    $PropagationFlags = [System.Security.AccessControl.PropagationFlags]::None
    $AccessControlType = [System.Security.AccessControl.AccessControlType]::Allow

    # this is not required to mount or make changes
    # $usernameAccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
    #     "$username",
    #     $FullControl,
    #     $InheritanceFlags,
    #     $PropagationFlags,
    #     $AccessControlType
    # )

    # $acl.SetAccessRule($usernameAccessRule)
    # Write-Host "Granted $($usernameAccessRule.FileSystemRights) access for $($usernameAccessRule.IdentityReference) to '$sharePath'."

    # Without Read/Write access for Users touch results in permission denied
    $usersAccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
        "Users",
        $ReadWrite,
        $InheritanceFlags,
        $PropagationFlags,
        $AccessControlType
    )

    # without this rule mount has permissions but touching a file results in permission denied
    # $acl.SetAccessRule($usersAccessRule)
    Write-Host "Granted $($usersAccessRule.FileSystemRights) access for $($usersAccessRule.IdentityReference) to '$sharePath'."

    # Create access rule for Administrators granting full access to the folder
    $adminAccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
        "Administrators",
        $FullControl,
        $InheritanceFlags,
        $PropagationFlags,
        $AccessControlType
    )
    
    $acl.SetAccessRule($adminAccessRule)
    Write-Host "Granted $($adminAccessRule.FileSystemRights) for $($adminAccessRule.IdentityReference) to '$sharePath'."

    # Update NTFS access rules
    Set-Acl -Path $sharePath -AclObject $acl
} else {
    Write-Host "The folder '$sharePath' already exists."
}

# Check if the folder is already shared
$existingShare = Get-SmbShare | Where-Object { $_.Path -eq $sharePath }
if ($existingShare) {
    
    Write-Output "The folder '$sharePath' is already shared as $($existingShare.Name)."

} else {
    
    Write-Output "Sharing the folder '$sharePath' as '$shareName'."
    New-SmbShare -Name $shareName -Path $sharePath
    
    # $usernameShareRule = @{
    #     Name = $shareName
    #     AccountName = $username
    #     AccessRight = "Full"
    # }

    $usersShareRule = @{
        Name = $shareName
        AccountName = "Users"
        AccessRight = "Change"
    }

    # this is not required to mount or make changes
    # Write-Host "Granting $($usernameShareRule.AccountName) $($usernameShareRule.AccessRight) access to '$shareName'."
    # Grant-SmbShareAccess @usernameShareRule -Confirm:$false

    # Without this rule mount results in permission denied
    # Without this rule granting change touch results in permission denied
    # Full is not required to read/write/delete/list directory contents
    Write-Host "Granting $($usersShareRule.AccountName) $($usersShareRule.AccessRight) access to '$shareName'."
    Grant-SmbShareAccess @usersShareRule -Confirm:$false
    
    Revoke-SmbShareAccess -Name $shareName -AccountName "Everyone" -Confirm:$false
}

# Prevent the window from closing after the program ends
Write-Host "Press any key to close this window..."
[void][System.Console]::ReadKey()