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

Write-Host ""
$IsVirtualBoxLocated = Test-Path $config.VBoxManage
if ($IsVirtualBoxLocated) {
    Write-Host "Using VirtualBox Manager $($config.VBoxManage)."
} else {
    Write-Warning "VirtualBox Manager is required. VirtualBox Manager was not found at $($config.VBoxManage). Exiting script."
    
    # Prevent the window from closing after the program ends
    Write-Host "Press any key to close this window..."
    [void][System.Console]::ReadKey()
    exit
}

Write-Host ""
Write-Host "VM will be created with the name $($config.VMName)."
Write-Host "VM will be created with $($config.VMMemory) MB RAM."
Write-Host "VM will be created with $($config.VMCPUs) CPU(s)."
Write-Host "virtual hard disk will be created with $($config.VMDiskSize) MB (optional)."

# Configure build plan:
# Step 1 - Handle Existing VM
# Step 2 - Handle Installer ISO
Write-Host ""
Write-Host "Configuring build plan. Confirmation will be required prior to taking any action."
Write-Host ""

# Configure build plan: Step 1 - Handle Existing VM
# Check if the VM already exists
# When it does exist ask if it can be deleted
# When it cannot be deleted exit early
# When it can be deleted set a flag to delete it
$IsVMRegistered = & $config.VBoxManage list vms | Select-String -Pattern $config.VMName
$IsVMCreated = Test-Path "$($config.VMFolder)\$($config.VMName)\$($config.VMName).vbox"
if ($IsVMRegistered -or $IsVMCreated) {
    $DeleteVMResponse = Read-Host "The VM already exists. Do you want to configure the build plan to delete it? (Y/N)"
    $DeleteVMResponse = $DeleteVMResponse.ToUpper()
    if ($DeleteVMResponse -eq "Y") {
        Write-Host "VM with name $($config.VMName) will be deleted..."
        $CanDeleteVM = "Y"
    } elseif ($DeleteVMResponse -eq "N") {
        Write-Host "Existing VM will not be modified. Exiting script."
        
        # Prevent the window from closing after the program ends
        Write-Host "Press any key to close this window..."
        [void][System.Console]::ReadKey()
        exit
    } else {
        Write-Host "Invalid response. Exiting script."
        
        # Prevent the window from closing after the program ends
        Write-Host "Press any key to close this window..."
        [void][System.Console]::ReadKey()
        exit
    }
} else {
    Write-Host "VM with name $($config.VMName) not found. Configuring the build plan to create a new VM."
    $CanDeleteVM = "N"
}

# Ensure the ISO file exists
# When the ISO file does not exist exit early
if (Test-Path $config.ISOPath) {
    Write-Host "Configuring the build plan to use the installer ISO file $($config.ISOPath)."
} else {
    Write-Warning "An installer ISO file is required. The installer ISO file not found at $($config.ISOPath). Exiting script."
    
    # Prevent the window from closing after the program ends
    Write-Host "Press any key to close this window..."
    [void][System.Console]::ReadKey()
    exit
}

Write-Host ""
Write-Host "Configure network adapter"

# Get a list of network adapters with status 'Up' and display them with numbers, link speed, and description
$adapters = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' }
$adapters | ForEach-Object -Begin { $index = 1 } {
    # Display the adapter's name, link speed, and description
    Write-Host "$($index): $($_.Name) - Speed: $($_.LinkSpeed) - Description: $($_.InterfaceDescription)"
    $index++
}

# If no adapters are found, display a message and exit
if ($adapters.Count -eq 0) {
    Write-Host "No network adapters with status 'Up' found."
    
    # Prevent the window from closing after the program ends
    Write-Host "Press any key to close this window..."
    [void][System.Console]::ReadKey()
    exit
}

# Ask the user to select an adapter by number
$AdapterResponse = -1
while ($AdapterResponse -lt 1 -or $AdapterResponse -gt $adapters.Count) {
    $AdapterResponse = Read-Host "Enter the number of the adapter you want to select (1 to $($adapters.Count))"

    # Check if the selection is a valid number within the valid range
    if ($AdapterResponse -gt 0 -and $AdapterResponse -le $adapters.Count) {
        # VBoxManage assigns an adapter using the Interface Description rather than name
        $AdapterName = $adapters[$AdapterResponse - 1].InterfaceDescription
        Write-Host "You selected the adapter: $AdapterName"
    } else {
        Write-Host "Invalid selection. Please enter a valid number between 1 and $($adapters.Count)."
    }
}

Write-Host ""
Write-Host "Configuring build plan complete:"

if ($CanDeleteVM -eq "Y") {
    Write-Host "Step 1 - The existing VM will be deleted."
    Write-Host "Step 2 - A new VM will be created with a bridged network adapter connected to $AdapterName"
    Write-Host "Step 3 - The installer ISO file will be mounted."
} else {
    Write-Host "Step 1 - A new VM will be created with a bridged network adapter connected to $AdapterName."
    Write-Host "Step 2 - The installer ISO file will be mounted."
}

$CanStart = Read-Host "Accept this build plan and run script? WARNING - THIS ACTION CANNOT BE UNDONE! (Y/N)"
$CanStart = $CanStart.ToUpper()
if ($CanStart -eq "Y") {
    Write-Host "Running script."
    Write-Host "Building VM."
} elseif ($CanStart -eq "N") {
    Write-Host "Exiting script."
    
    # Prevent the window from closing after the program ends
    Write-Host "Press any key to close this window..."
    [void][System.Console]::ReadKey()
    exit
} else {
    Write-Host "Invalid response. Exiting script."
    
    # Prevent the window from closing after the program ends
    Write-Host "Press any key to close this window..."
    [void][System.Console]::ReadKey()
    exit
}

# Delete the VM if needed
if ($CanDeleteVM -eq "Y") {

    # Delete the VM
    Write-Host "Deleting existing VM: $($config.VMFolder)\$($config.VMName)\$($config.VMName).vbox"

    if ($IsVMRegistered) {
        # Extract the UUID of the VM
        $VMUUID = $config.VMName -replace '^.*{(.*)}.*$', '$1'

        # Check if the VM is running
        $RunningVMs = & $config.VBoxManage list runningvms | Select-String -Pattern $config.VMName

        if ($RunningVMs) {
            # Power off the VM
            & $config.VBoxManage controlvm $VMUUID poweroff
        }

        # Unregister the VM without deleting the disk
        & $config.VBoxManage unregistervm $VMUUID
    }
    
    if ($IsVMCreated) {
        Remove-Item -Path "$($config.VMFolder)\$($config.VMName)\$($config.VMName).vbox" -Force
    }
}

# Create the VM
Write-Host "Creating VM: $($config.VMName)"
& $config.VBoxManage createvm --name $config.VMName --ostype $config.OSType --register --basefolder $config.VMFolder

# Set memory and CPUs
& $config.VBoxManage modifyvm $config.VMName --memory $config.VMMemory --cpus $config.VMCPUs --ioapic on

# Configure network (BRIDGED)
& $config.VBoxManage modifyvm $config.VMName --nic1 bridged --bridgeadapter1 $AdapterName

# Add the ISO file as a CD/DVD
& $config.VBoxManage storagectl $config.VMName --name "IDE Controller" --add ide
& $config.VBoxManage storageattach $config.VMName --storagectl "IDE Controller" --port 0 --device 0 --type dvddrive --medium $config.ISOPath
Write-Host "The installer ISO file has been mounted to the virtual DVD drive."

# Set DVD as first boot order
& $config.VBoxManage modifyvm $config.VMName --boot1 dvd

# Set additional options
& $config.VBoxManage modifyvm $config.VMName --audio none --usb off --vrde on

# Enable scaled window mode because we like nice things
& $config.VBoxManage setextradata $config.VMName "GUI/LastScaleWindowPosition" "1,29,958,1002"
& $config.VBoxManage setextradata $config.VMName "GUI/Scale" "true"

Write-Host "VM $($config.VMName) created successfully."

# Prevent the window from closing after the program ends
Write-Host "Press any key to close this window..."
[void][System.Console]::ReadKey()
exit