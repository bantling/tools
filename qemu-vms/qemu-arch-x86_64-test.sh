#!/bin/zsh

if [ ! -f archlinux-x86_64-orig.img ]; then
  echo "Backing up images"
  cp archlinux-x86_64.img archlinux-x86_64-orig.img
  cp archlinux-x86_64-extra.img archlinux-x86_64-extra-orig.img
else
  echo "Restoring images"
  cp archlinux-x86_64-orig.img archlinux-x86_64.img
  cp archlinux-x86_64-extra-orig.img archlinux-x86_64-extra.img
fi

echo "Copying latest resize script into extra image"
hdiutil attach archlinux-x86_64-extra.img
cp qemu-arch-x86_64-resize.sh /Volumes/EXTRA_FILES/resize.sh
hdiutil detach /Volumes/EXTRA_FILES

echo "Expanding images"
qemu-img resize -f raw archlinux-x86_64.img +8G
qemu-img resize -f raw archlinux-x86_64-extra.img +64M

qemu-system-x86_64 -cpu qemu64 -m 2048 -drive file=archlinux-x86_64.img,format=raw,if=virtio -drive file=archlinux-x86_64-extra.img,format=raw,if=virtio -nic user,model=virtio-net-pci
