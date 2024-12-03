#!/bin/sh

# Enable tracing so that all commands are shown in the terminal
set -x

# Set variables for disk and partition
DISK="/dev/sda"       # Adjust this if your disk is not /dev/sda
PARTITION="${DISK}1" # Primary partition
MOUNTPOINT="/mnt"

# Define the repository URLs to add
MAIN_REPO="http://dl-cdn.alpinelinux.org/alpine/v3.20/main"
COMMUNITY_REPO="http://dl-cdn.alpinelinux.org/alpine/v3.20/community"

# Check if the main repository is already in the file; if not, add it
if ! grep -q "$MAIN_REPO" /etc/apk/repositories; then
    echo "$MAIN_REPO" >> /etc/apk/repositories
    echo "Added main repository: $MAIN_REPO"
else
    echo "Main repository already exists: $MAIN_REPO"
fi

# Check if the community repository is already in the file; if not, add it
if ! grep -q "$COMMUNITY_REPO" /etc/apk/repositories; then
    echo "$COMMUNITY_REPO" >> /etc/apk/repositories
    echo "Added community repository: $COMMUNITY_REPO"
else
    echo "Community repository already exists: $COMMUNITY_REPO"
fi

# Wait for user to acknowledge commands already run
read

# Update repositories and install necessary tools
apk update
apk add e2fsprogs syslinux util-linux sfdisk

# Wait for user to acknowledge commands already run
read

## Create a partition table and a single primary partition
#sfdisk ${DISK} <<EOF
#label: dos
#label-id: 0x83
#unit: sectors
#
#1 : start=2048, size=, type=83, bootable
#EOF

# Create partitions using sfdisk
echo "Creating partitions on /dev/sda..."
sfdisk /dev/sda <<EOF
/dev/sda1   *  ext4
/dev/sda2      vfat
EOF

# Refresh partition table
partprobe /dev/sda

# Wait for user to acknowledge commands already run
read

## Format the partition with ext4
#mkfs.ext4 ${PARTITION}

# Format the partitions
echo "Formatting /dev/sda1 as ext4..."
mkfs.ext4 /dev/sda1

echo "Formatting /dev/sda2 as FAT32..."
mkfs.vfat -F 32 /dev/sda2

# Wait for user to acknowledge commands already run
read

# Mount the partition
#mount ${PARTITION} ${MOUNTPOINT}

# Mount the root partition
echo "Mounting /dev/sda1 to /mnt..."
mount /dev/sda1 /mnt

# Create and mount the /boot partition
echo "Creating and mounting /mnt/boot..."
mkdir /mnt/boot
mount /dev/sda2 /mnt/boot

# Wait for user to acknowledge commands already run
read

# Install the base Alpine Linux system to the mounted partition
setup-disk -m sys ${MOUNTPOINT} <<EOF
$DISK
EOF

# Wait for user to acknowledge commands already run
read

## Install syslinux bootloader
#syslinux --install ${PARTITION}

# Install Syslinux bootloader on /dev/sda2 (boot partition)
echo "Installing Syslinux bootloader on /dev/sda2..."
syslinux --install /dev/sda2

# Wait for user to acknowledge commands already run
read

# Install MBR bootloader
cat /usr/share/syslinux/mbr.bin > ${DISK}

# Wait for user to acknowledge commands already run
read

# Configure fstab
cat <<EOF > ${MOUNTPOINT}/etc/fstab
${PARTITION}    /    ext4    defaults    0 1
/dev/sda2       /boot       vfat    defaults    0 2
EOF

# Wait for user to acknowledge commands already run
read

# Unmount the partition
umount ${MOUNTPOINT}

mount -a

# Wait for user to acknowledge commands already run
read

# Inform the user to unmount the DVD and reboot
echo "Installation complete!"
echo "Next Steps:"
echo "1 - shutdown the VM using the command poweroff."
echo "2 - remove the DVD drive and set the virtual disk drive as the startup drive."
echo "This is done by running the creation powershell script choosing to delete the VM but not the disk."