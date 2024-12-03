#!/bin/sh

# Enable tracing so that all commands are shown in the terminal
set -x

# Set variables for disk and partition
DISK="/dev/sda"       # Adjust this if your disk is not /dev/sda
PARTITION="${DISK}1" # Primary partition
MOUNTPOINT="/mnt"

# Update repositories and install necessary tools
apk update
apk add e2fsprogs syslinux util-linux sfdisk

# Create a partition table and a single primary partition
sfdisk ${DISK} <<EOF
label: dos
label-id: 0x83
unit: sectors

1 : start=2048, size=, type=83, bootable
EOF

# Format the partition with ext4
mkfs.ext4 ${PARTITION}

# Mount the partition
mount ${PARTITION} ${MOUNTPOINT}

# Install the base Alpine Linux system to the mounted partition
setup-disk -m sys ${MOUNTPOINT} <<EOF
$DISK
EOF

# Install syslinux bootloader
syslinux --install ${PARTITION}

# Install MBR bootloader
cat /usr/share/syslinux/mbr.bin > ${DISK}

# Configure fstab
cat <<EOF > ${MOUNTPOINT}/etc/fstab
${PARTITION}    /    ext4    defaults    0 1
EOF

# Unmount the partition
umount ${MOUNTPOINT}

# Inform the user to unmount the DVD and reboot
echo "Installation complete! Unmount the ISO from the DVD drive and reboot the VM to boot from disk."
