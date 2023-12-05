#!/bin/bash
set -eu

# Call with one argument: device to resize, eg /dev/vda

usage() {
  [ "$#" -eq 0 ] || echo -e "$1\n"

  echo "$0: device

    Resize last partition of device to fill the remaining space on the device.
    The last partition mustbe an ext4 filesystem.
  "

  exit
}

# Must provide device
[ "$#" -eq 1 ] || {
  usage "Must provide a device to resize"
}

# Ensure device is a block device that is a whole disk, not a partition
[ "`lsblk -ndo TYPE "$1"`" = "disk" ] || usage "$1 is not a disk device"

# Get last partition number of device
lastPart="`lsblk -nlo PARTN "$1" | tail -n 1 | awk '{print $1}'`"

# Automate parted resizing of mounted partition
echo 'set timeout -1
spawn parted '"$1"'
match_max 100000
expect "*(parted) "
send "resizepart\r"
expect {
  "*Fix/Ignore? " {
    send "f\r"
    exp_continue
  }
  "*Partition number? " {
    send '"$lastPart\r"'
  }
}
expect {
  "*Yes/No? " {
    send "y\r"
    exp_continue
  }
  "*\]? " {
    send "100%\r"
  }
}
expect "*(parted) "
send "w\r"
expect "*(parted) "
send "q\r"
expect eof
' | expect

# Is it an EXT4 filesystem?
[ "`lsblk -ndo FSTYPE "$1$lastPart"`" != "ext4" ] || {
  # If the fs is unmounted, check the filesystem to be certain resizing will work
  [ -n "`lsblk -ndo MOUNTPOINTS "$1$lastPart"`" ] || {
    e2fsck -f "$1$lastPart"
  }

  # Resize filesystem
  resize2fs "$1$lastPart"

  # Show new size
  df -h "$1$lastPart"
}
