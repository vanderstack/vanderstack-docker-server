# Configuration variables
$VBoxManage = "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe"
$VMFolder = "E:\vanderstack-docker-server"
$VMName = "docker-host-server"
$VMMemory = 2048          # Memory in MB
$VMCPUs = 2               # Number of CPUs
$VMDiskSize = 20000       # Disk size in MB
$OSType = "linux_64"     # OS type (adjust as needed)
$ISOPath = "alpine-docker-v3.20-x86_64.iso"

Write-Host ""
$IsVirtualBoxLocated = Test-Path $VBoxManage
if ($IsVirtualBoxLocated) {
    Write-Host "Using VirtualBox Manager $VBoxManage."
} else {
    Write-Warning "VirtualBox Manager is required. VirtualBox Manager was not found at $VBoxManage. Exiting script."
    exit
}

Write-Host ""
Write-Host "VM will be created with the name $VMName."
Write-Host "VM will be created with $VMMemory MB RAM."
Write-Host "VM will be created with $VMCPUs CPU(s)."
Write-Host "virtual hard disk will be created with $VMDiskSize MB (optional)."

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
$IsVMRegistered = & $VBoxManage list vms | Select-String -Pattern $VMName
$IsVMCreated = Test-Path "$VMFolder\$VMName\$VMName.vbox"
if ($IsVMRegistered -or $IsVMCreated) {
    $DeleteVMResponse = Read-Host "The VM already exists. Do you want to configure the build plan to delete it? (Y/N)"
    $DeleteVMResponse = $DeleteVMResponse.ToUpper()
    if ($DeleteVMResponse -eq "Y") {
        Write-Host "VM with name $VMName will be deleted..."
        $CanDeleteVM = "Y"
    } elseif ($DeleteVMResponse -eq "N") {
        Write-Host "Existing VM will not be modified. Exiting script."
        exit
    } else {
        Write-Host "Invalid response. Exiting script."
        exit
    }
} else {
    Write-Host "VM with name $VMName not found. Configuring the build plan to create a new VM."
    $CanDeleteVM = "N"
}

# Ensure the ISO file exists
# When the ISO file does not exist exit early
if (Test-Path $ISOPath) {
    Write-Host "Configuring the build plan to use the installer ISO file $ISOPath."
} else {
    Write-Warning "An installer ISO file is required. The installer ISO file not found at $ISOPath. Exiting script."
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
    exit
} else {
    Write-Host "Invalid response. Exiting script."
    exit
}

# Delete the VM if needed
if ($CanDeleteVM -eq "Y") {

    # Delete the VM
    Write-Host "Deleting existing VM: $VMFolder\$VMName\$VMName.vbox"

    if ($IsVMRegistered) {
        # Get the Info for the VM Name
        $VMInfo = & $VBoxManage list vms | Select-String -Pattern $VMName

        # Extract the UUID of the VM
        $VMUUID = $VMName -replace '^.*{(.*)}.*$', '$1'

        # Check if the VM is running
        $RunningVMs = & $VBoxManage list runningvms | Select-String -Pattern $VMName

        if ($RunningVMs) {
            # Power off the VM
            & $VBoxManage controlvm $VMUUID poweroff
        }

        # Unregister the VM without deleting the disk
        & $VBoxManage unregistervm $VMUUID
    }
    
    if ($IsVMCreated) {
        Remove-Item -Path "$VMFolder\$VMName\$VMName.vbox" -Force
    }
}

# Create the VM
Write-Host "Creating VM: $VMName"
& $VBoxManage createvm --name $VMName --ostype $OSType --register --basefolder $VMFolder

# Set memory and CPUs
& $VBoxManage modifyvm $VMName --memory $VMMemory --cpus $VMCPUs --ioapic on

# Configure network (BRIDGED)
& $VBoxManage modifyvm $VMName --nic1 bridged --bridgeadapter1 $AdapterName

# Add the ISO file as a CD/DVD
& $VBoxManage storagectl $VMName --name "IDE Controller" --add ide
& $VBoxManage storageattach $VMName --storagectl "IDE Controller" --port 0 --device 0 --type dvddrive --medium $ISOPath
Write-Host "The installer ISO file has been mounted to the virtual DVD drive."

# Set DVD as first boot order
& $VBoxManage modifyvm $VMName --boot1 dvd

# Set additional options
& $VBoxManage modifyvm $VMName --audio none --usb off --vrde on

# Enable scaled window mode because we like nice things
& $VBoxManage setextradata $VMName "GUI/LastScaleWindowPosition" "1,29,958,1002"
& $VBoxManage setextradata $VMName "GUI/Scale" "true"

Write-Host "VM $VMName created successfully."
