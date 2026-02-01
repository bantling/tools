#!/bin/sh

# Die if any command has a non-zero status code
set -eu

# Add zfs package
apk add sgdisk dosfstools zfs syslinux

# Load kernel module
modprobe zfs

# Create a EFI and  ZFS partitions
sgdisk -n 1:0:+512M -t 1:ef00 -n 2:0:-1 -t 2:bf00 /dev/sdb

# Ensure new partition device entries are loaded now
mdev -s

# Format EFI partition, and mount it
mkfs.vfat -n EFI /dev/sdb1

# Remove any existing ZFS labels on the target drive
# It complains if no labels exist
zpool labelclear -f /dev/sdb :

# Get partition GUID to use as zpool device
ls -l /dev/disk/by-uuid | grep sdb2 | awk '{print $9}' > sdb2.uuid

# Create the zpool and bootable ROOT dataset
zpool create \
 -f \
 -O acltype=posixacl \
 -O compression=lz4 \
 -O dnodesize=auto \
 -O mountpoint=none \
 -O normalization=formD \
 -O relatime=on \
 -O xattr=sa \
 -o ashift=12 \
 -m none \
 zroot \
 /dev/disk/by-uuid/

zfs create -o canmount=noauto -o mountpoint=legacy zroot/root

# Mount root and ESP
mount -t zfs zroot/root /mnt
mkdir /mnt/boot
mount -t vfat /dev/sdb1 /mnt/boot

# Install system
BOOTLOADER=none setup-disk -k lts -v /mnt

# Install rEFInd bootloader
apk add curl
curl -L https://sourceforge.net/projects/refind/files/0.14.2/refind-bin-0.14.2.zip/download -o refind.zip
unzip refind.zip

mkdir -p /mnt/boot/EFI/BOOT
cp refind-bin-0.14.2/refind/refind_x64.efi /mnt/boot/EFI/BOOT/BOOTX64.EFI
echo '"Alpine Linux" "root=ZFS=zroot/root"' > /mnt/boot/refind-linux.conf

###########

zpool set bootfs=zroot/ROOT zroot

# Export pool and reimport temporarily mounting to /mnt
zpool export zroot
zpool import -N -R /mnt zroot

# Install base system
apk --arch x86_64 \
    -X http://dl-cdn.alpinelinux.org/alpine/latest-stable/main \
    -U --allow-untrusted \
    --root /mnt \
    --initdb add alpine-base

# Copy some files we already setup
cp /etc/resolv.conf /mnt/etc
cp /etc/apk/repositories /mnt/etc/apk
cp /etc/network/interfaces /mnt/etc/network

# Chroot into the new os and set some stuff up
mount --rbind /dev /mnt/dev
mount --rbind /sys /mnt/sys
mount --rbind /proc /mnt/proc
chroot /mnt

# Set root password
echo "root:toor" | chpasswd

# Enable services
rc-update add hwdrivers sysinit
rc-update add networking
rc-update add hostname

# Install zfs
apk add zfs zfs-lts zfs-scripts
rc-update add zfs-import sysinit
rc-update add zfs-mount sysinit
