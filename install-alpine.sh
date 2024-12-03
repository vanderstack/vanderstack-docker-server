#!/bin/sh

echo "Adjusting repositories"
# Check if the main repository is already in the file; if not, add it
MAIN_REPO="http://dl-cdn.alpinelinux.org/alpine/v3.20/main"
if ! grep -q "$MAIN_REPO" /etc/apk/repositories; then
    echo "$MAIN_REPO" >> /etc/apk/repositories
    echo "Added main repository: $MAIN_REPO"
else
    echo "Main repository already exists: $MAIN_REPO"
fi

# Check if the community repository is already in the file; if not, add it
COMMUNITY_REPO="http://dl-cdn.alpinelinux.org/alpine/v3.20/community"
if ! grep -q "$COMMUNITY_REPO" /etc/apk/repositories; then
    echo "$COMMUNITY_REPO" >> /etc/apk/repositories
    echo "Added community repository: $COMMUNITY_REPO"
else
    echo "Community repository already exists: $COMMUNITY_REPO"
fi

# Update repositories and install necessary tools
echo "installing packages"
apk update
apk add e2fsprogs syslinux util-linux sfdisk

# Create a partition table with a boot partition and a primary partition
# 1: Boot partition (e.g., 512MB)
# 2: Primary partition (remainder of the disk)
sfdisk /dev/sda <<EOF
label: dos
unit: sectors
1 : start=2048, size=+512M, type=83, bootable
2 : start=, size=, type=83
EOF

# Format the partitions
echo "Formatting /dev/sda1 as FAT32..."
mkfs.vfat -F 32 /dev/sda1

echo "Formatting /dev/sda2 as ext4..."
mkfs.ext4 /dev/sda2

# Mount the root partition
echo "Mounting /dev/sda2 to /mnt..."
mount /dev/sda2 /mnt

# Create and mount the /boot partition
echo "Creating /mnt/boot..."
mkdir -p /mnt/boot

echo "Mounting /dev/sda1 to /mnt/boot..."
mount /dev/sda1 /mnt/boot

# Install the base Alpine Linux system to the mounted partition
set -x
setup-disk -m sys -o /mnt

# Install Syslinux bootloader on /dev/sda1 (boot partition)
# echo "Installing Syslinux bootloader on /dev/sda1..."
# syslinux --install /dev/sda1

# Install MBR bootloader
# cat /usr/share/syslinux/mbr.bin > /dev/sda

# fdisk -l /dev/sda
# ls /mnt
# cat /mnt/etc/fstab
# ls /mnt/bin/init
# ls /mnt/etc

# Configure fstab
# cat <<EOF > /mnt/etc/fstab
# /dev/sda1       /boot       vfat    defaults    0 2
# /dev/sda2       /           ext4    defaults    0 1
# EOF

# Unmount the partition
# umount /mnt

# mount -a

# Inform the user to unmount the DVD and reboot
echo "Installation complete!"
echo "Next Steps:"
echo "1 - shutdown the VM using the command poweroff."
echo "2 - remove the DVD drive and set the virtual disk drive as the startup drive."
echo "This is done by running the creation powershell script choosing to delete the VM but not the disk."
