#!/bin/bash
set -eu

usage() {
  [ "$#" -eq 0 ] || { echo -e "\nERROR: $1\n" }

  echo "$0: { -p | -f } { disk_device }

  Expand the last partition on disk_device to fill the remaining space on the disk, except for the last 100MB.
  Then expand the filesystem in that partition to fill the new extra space.

  -p: extend the partition. If the device is the root filesystem, a restart is required to reread the partition table.

  -f: extend the filesystem
  "

  exit 1
}

# Ensure we have two params
[ "$#" -eq 2 ] || usage "two parameters are required: -p or -f, and a device"

# First is -p or -f
partition=""
if [ "$1" = "-p" ]; then {
  partition=1
} elif [ "$1" = "-f" ]; then {
  partition=0
} else {
  usage "$1 is not valid, must be -p or -f"
}

# Ensure we have a disk device parameter
[ -n "$2" ] || usage "disk_device must be provided"

# Convert device name to last path part (eg vda), and remove any partition number
dev="`echo $2 | awk -F/ '{print $NF}' | tr -d '[0-9]'`"

# Find last partition of device
last_part="`sgdisk -p $dev | tail -n 1 | awk '{print $1}'`"

# Device must actually be a block device, and actually have partitions on it
[ -n "$last_part" ] || usage "Device $dev is not a block device, or does not have any partitions on it"

# Get fs type of last partition
fs_type="`lsblk /dev/${dev}${last_part} -no FSTYPE`"

# Test if last partition is ext4
[ "$fs_type" = "ext4" ] || {
  usage "The last partition of $dev is not ext4"
}

if [ "$partition" -eq 1 ]; then {
  # Resize ext4 partition to fill all space by deleting and recreating it
  sgdisk -d "$last_part" -n "${last_part}:0:-100M" -A "${last_part}:set:2" /dev/$dev
  echo "Partition resized, reboot if it is the root filesystem so the kernel can see the change before resizing"
} else {
  # Resize filesystem to fill new partition size
  resize2fs /dev/${dev}${last_part}
  df -h /dev/${dev}${last_part}
  echo "Check filesystem size shown above is as expected"
}
