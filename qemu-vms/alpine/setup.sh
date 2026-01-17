#!/bin/sh

# Die if any command has a non-zero status code
set -eu

# Add zfs package
apk add sgdisk dosfstools zfs

# Load kernel module
modprobe zfs

# Create a EFI and  ZFS partitions
sgdisk -n 1:0:+512M -t 1:ef00 -n 2:0:-1 -t 2:bf00 /dev/sdb

# Format EFI partition
mkfs.fat -F 32 -n EFI /dev/sdb1

# Ensure new partition device entries are loaded now
mdev -s

# Remove any existing ZFS labels on the target drive
# It complains if no labels exist
zpool labelclear -f /dev/sdb 2> /dev/null || :

# Create the zpool and bootable ROOT dataset
zpool create -f -o ashift=12 \
 -O compression=lz4 \
 -O acltype=posixacl \
 -O xattr=sa \
 -O relatime=on \
 -o autotrim=on \
 -m none zroot /dev/sdb2
zfs create -o mountpoint=/ zroot/ROOT
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
