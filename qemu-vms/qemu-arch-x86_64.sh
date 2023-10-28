#!/bin/zsh
set -eu

# Script to setup an Arch Linux x86_86 virtual image by scripting an ISO installer via the emulated serial port with an expect script

# Download the latest arch installer iso
isoimage="/tmp/archlinux-x86_64.iso"
[ -f "$isoimage" ] || curl -o "$isoimage" https://mirror.csclub.uwaterloo.ca/archlinux/iso/latest/archlinux-x86_64.iso

# Download the b2sum for installer iso
chksum="/tmp/archlinux-x86_64.iso.b2sum"
[ -f "$chksum" ] || curl https://mirror.csclub.uwaterloo.ca/archlinux/iso/latest/b2sums.txt | grep archlinux-x86_64.iso | awk '{print $1}' > "$chksum"

# Verify the b2 sums match
gensum="${chksum}.gen"
[ -f "$gensum" ] || b2sum "$isoimage" | awk '{print $1}' > "$gensum"

# Diff the two sums, die if they differ
diff "$chksum" "$gensum" || exit

# Create a disk image to install arch into. Recreate each time in case a previous run failed.
hdimage="archlinux-x86_64.img"
qemu-img create -f raw "$hdimage" 8G

# Fire up a VM to install arch, using downloaded ISO and generated disk image
./qemu-arch-x86_64-expect.sh
#qemu-system-x86_64 -cpu qemu64 -m 2048 -drive file=archlinux-x86_64.img,format=raw,if=virtio -nic user,model=virtio-net-pci
