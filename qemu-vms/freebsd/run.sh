#!/bin/zsh
set -eu

usage() {
  [ "$#" -eq 0 ] || echo -e "error: $1\n\n"

  echo "
$0: [ -m ] [ -s ] [ image ]

Use qemu to run an x86_64 image. Arguments must be passed in the order described.
-m: Use the current memory stick image as the boot device
-s: use serial port booting rather than default windowed mode
image: The image name to run, the default is the only file in the current dir that matches *.img but does not match
       *memstick*.img.
  "

  exit 1
}

# Check if -m is passed to use current memory stick image as boot device
bootMemstickImage=""
if [ "$#" -gt 0 ]; then
  if [ "$1" = "-m" ]; then
    bootMemstickImage=`ls *.img | grep '.*memstick.*.img'`,format=raw,if=virtio
    shift
  fi
fi

# Check if -s is passed to use serial port booting
serial=""
if [ "$#" -gt 0 ]; then
  if [ "$1" = "-s" ]; then
    serial="-nographic"
    shift
  fi
fi

# Check if there are no more args, and not exactly one *.img file
if [ "$#" -eq 0 -a "`ls *.img | grep -v '.*memstick.*.img' | wc -l`" -ne 1 ]; then
  usage "The image name must be provided, unless there is exactly one image named *.img"
fi

# Get image passed, or use only *.img file
if [ "$#" -ne 0 ]; then
  image="$1"
  shift
else
  image="`ls *.img | grep -v '.*memstick.*.img'`"
fi

# Assume a single *.img file in this dir that is the image to run
if [ -n "$bootMemstickImage" ]; then
  qemu-system-x86_64 -boot c -cpu qemu64 -m 2048 -drive file=$bootMemstickImage,format=raw,if=virtio -drive file=$image,format=raw,if=virtio -nic user,model=virtio-net-pci,hostfwd=tcp::9999-:22 $serial
else
  qemu-system-x86_64 -boot c -cpu qemu64 -m 2048 -drive file=$image,format=raw,if=virtio -nic user,model=virtio-net-pci,hostfwd=tcp::9999-:22 $serial
fi
