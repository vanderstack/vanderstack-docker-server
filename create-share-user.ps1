# Define username and password
$username = "vanderstack-share"
$password = ConvertTo-SecureString "foo" -AsPlainText -Force

# Check if the user already exists
if (Get-LocalUser -Name $username -ErrorAction SilentlyContinue) {
    Write-Output "User '$username' already exists."
} else {
    # Create the new user
    New-LocalUser -Name $username -Password $password -FullName "Vanderstack Share User" -Description "User for Vanderstack sharing" -PasswordNeverExpires $true
    Write-Output "User '$username' created successfully."
}

# Add the user to the "Users" group
Add-LocalGroupMember -Group "Users" -Member $username
Write-Output "User '$username' added to the 'Users' group."
