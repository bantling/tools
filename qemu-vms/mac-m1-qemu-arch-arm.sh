#!/bin/zsh
set -eu

# Self-contained script to Create a bootable QEMU Arch Linux Arm64 qcow2 image

# Follow this process to generate a bootable Arch Linux ARM VM:
# - execute this script as ./setup.sh
# - A QEMU VM will appear after a couple of downloads complete
# - Switch to that VM
# - It will automatically boot a downloaded Arch Linux ISO image
# - The ISO auto logs in as root
# - When the command prompt appears, type in the following command (it is printed to the console for copying)
# mount /dev/vda1 /mnt && /mnt/setup.sh
# - The /mnt/setup.sh script takes about 1 minute to generate a bootable Arch Linux ARM image
# - When the VM quits, execute generated ./run.sh script to launch the new image
# - Quickly switch to the VM and hit Esc to enter the EFI BIOS
#   - Failure to hit Esc fast enough (you have about 5 seconds) results in a long 2 minute or so boot delay
#   - You could hit Ctrl-C and rerun ./run.sh and be faster at hitting Esc to avoid this delay
# - In EFI BIOS, choose Boot Manager, then choose Enter EFI Shell
# - In EFI Shell, let the 5 second delay expire, which runs startup.nsh
# - Log in to Arch as root/root
# - Execute ./set-boot.sh to set the EFI boot order so that the image is first
# - Execute ./resize.sh to resize the ext4 filesystem to fill the empty space in the 8GB image

# The process works as follows:
# - Mac generates 64MB efivars.img raw disk image
# - Mac generates 4GB temp/archlinuxinstall.img to contain a FAT filesystem
#   - This filesystem can be read by both Mac host and temporary Linux VM used to generate the bootable image
#   - The temporary VM is needed because Mac host cannot format an EXT4 filesystem
# - Mac formats and mounts FAT filesystem
# - Mac generates a 2GB arch.img raw disk image, set-boot.sh, resize.sh, and setup.sh inside the FAT filesystem
# - Mac unmounts FAT filesystem
# - Mac downloads QEMU_EFI.img.gz and extracts it to QEMU_EFI.img
# - Mac downloads Arch.Linux.Arm--aarch64.iso image
# - Mac generates and executes temp/install.sh script to boot temporary VM that generates bootable imaage
# - User intervenes and runs command sequence to mount temporary image and execute setup.sh script
# - setup.sh creates bootable image and powers down temporary VM
# - Mac remounts FAT filesystem and converts generated image into a sparse compressed qcow2 image
# - Mac generates run.sh script to run bootable VM
# - Mac removes temp dir to save disk space
# - User can now run ./run.sh to launch bootable image

# The end result is the following new files in the directory of this script:
# archlinux.qcow2 - Bootable 8G sparse compressed image containing bootable Arch Linux ARM
# efivars.img     - EFI BIOS image needed to store persistent EFI vars like boot order
# QEMU_EFI.img    - EFI BIOS image needed to boot Arch Linux ARM
# run.sh          - script to run archlinux.qcow2 with QEMU
# ArchLinux.app   - Mac OS Application Bundle to run the VM from the Finder or Dock

# The following files are needed temporarily, and are deleted when the process completes:
# temp/archlinuxinstall.img - Installer image needed to generate the bootable image
# temp/install.sh           - script to run archlinuxinstall.img with QEMU to generate archlinux.qcow2

cleanup() {
	[ -z "$imgdev" ] || {
		hdiutil detach "$imgdev"
	}
	imgdev=
}

trap cleanup EXIT INT

# cd to dir of this script
cd "`dirname "$0"`"

# Need to delete olf efivars.img to ensure no left over boot order from previous runs
echo "Generating efivars.img..."
rm -f efivars.img
dd if=/dev/zero bs=1 count=0 seek=64M of=efivars.img

# Mac has to create raw image with extension .img to be able to attach it to a device
echo "Generating archlinuxsetup.img..."
mkdir -p temp
rm -f temp/archlinuxinstall.img
dd if=/dev/zero bs=1 count=0 seek=4G of=temp/archlinuxinstall.img

# hdiutil seems like putting spaces and tabs at end of device name, as in "/dev/disk4<space><tab>"
echo "Attaching archlinuxsetup.img to a device..."
imgdev="`hdiutil attach -nomount temp/archlinuxinstall.img | tr -d " \t"`"
echo "${imgdev}"

echo "Creating a FAT filesystem in archlinuxinstall.img..."
diskutil partitionDisk $imgdev MBR FAT32 ARMINSTALL R
mount_point="`diskutil info ${imgdev}s1 | grep "Mount Point" | awk '{print $3}'`"
echo "Mounted at ${mount_point}"

# If a Mac dd command generates the arch.img file, then Mac can read it after it has a bootable image setup on it, and copy it to the host.
# If Linux VM dd or truncate commands generate the arch.img file, the Mac may or may not be able to read it, seemingly at random.
echo "Generating target disk image inside archlinuxinstall.img..."
dd if=/dev/zero bs=1 count=0 seek=2G "of=${mount_point}/arch.img"

echo "Generating set-boot.sh script inside archlinuxinstall.img..."
cat << END > "${mount_point}/set-boot.sh"
#!/bin/bash

# Init pacman keys
pacman-key --init
pacman-key --populate archlinuxarm

# Install some packages needed by this script and resize.sh script
[ -f /usr/bin/efibootmgr ] || pacman --noconfirm -Sy efibootmgr gptfdisk parted

# Determine boot entry position for this VM, which may not exist
boot_entry="\`efibootmgr | grep "Arch Linux ARM" | awk '{print \$1}' | tr -d 'A-Za-z*'\`"
if [ -z "\$boot_entry" ]; then
	# No such boot entry, create it, which makes it first boot choice
	root_id="\`lsblk -no UUID /dev/vda2\`"
	efibootmgr --disk /dev/vda --part 1 --create --label "Arch Linux ARM" --loader /Image --unicode "root=UUID=\$root_id rw initrd=\initramfs-linux.img" --verbose
else
	# Entry exists, make it only boot choice
	efibootmgr -o "\$boot_entry"
fi

END

echo "Generating resize.sh script inside archlinuxinstall.img..."
cat << END > "${mount_point}/resize.sh"
#!/bin/bash

# Extend second partition to end of physical partition, by deleting and recreating
root_name="\`lsblk -no PARTLABEL /dev/vda2\`"
sgdisk -d 2 /dev/vda
sgdisk -n 2:0:0 -t 2:8300 -c "2:\$root_name" /dev/vda

# Wait 5 seconds for partprobe to cause kernel to reload partition information
partprobe
sleep 5

# Resize extfs to fill rest of partition
resize2fs /dev/vda2

END

echo "Generating setup.sh script inside archlinuxinstall.img..."
cat << END > "${mount_point}/setup.sh"
#!/bin/bash

finish() {
	echo "Unmounting filesystems..."
	umount /archlinux/boot 2> /dev/null
	umount /archlinux 2> /dev/null

	echo "Destroying loopback device..."
	[ -z "\$lodev" ] || losetup -d \$lodev

	echo "Shutting down..."
	sleep 2
	halt -p
}

trap finish EXIT

# CD to dir of this script
cd "\`dirname "\$0"\`"

img=arch.img

# Create a 200MB EFI System partition and fill rest with an EXT4 partition
echo Partitioning disk image...
sgdisk -n 1:0:+200M -t 1:EF00 -c 1:AARCH64BOOT -A 1:set:2 -n 2:0:0 -t 2:8300 -c 2:AARCH64ROOT \$img

echo Creating loopback device for disk image...
lodev="\`losetup --show -Pf \$img\`"

echo Creating boot filesystem...
mkfs.vfat -F 32 -n EFI_SYSTEM \${lodev}p1

echo Creating root filesystem...
mkfs.ext4 -L ROOT \${lodev}p2

echo Mounting filesystems...
mkdir -p /archlinux
mount \${lodev}p2 /archlinux
mkdir /archlinux/boot
mount \${lodev}p1 /archlinux/boot

echo Extracting base image...
curl -Lo - http://os.archlinuxarm.org/os/ArchLinuxARM-aarch64-latest.tar.gz | bsdtar -xpf - -C /archlinux

echo Grabbing filesystem uuids...
# Wait until after extracting base image - it takes some number of seconds after mkfs before the UUID is available via lsblk
# It will definitely be available after extracting the base image, which takes about 30 to 45 seconds with fast internet
boot_id="\`lsblk -no UUID \${lodev}p1\`"
root_id="\`lsblk -no UUID \${lodev}p2\`"
echo BOOT="\$boot_id" ROOT="\$root_id"

echo Setup up fstab entries...
echo "/dev/disk/by-uuid/\$root_id / ext4 defaults 0 0
/dev/disk/by-uuid/\$boot_id /boot vfat defaults 0 0" >> /archlinux/etc/fstab

echo Copying set-boot.sh script for execution on first boot...
install -m 0700 ./set-boot.sh /archlinux/root/set-boot.sh

echo Copying resize.sh script for execution on first boot...
install -m 0700 ./resize.sh /archlinux/root/resize.sh

echo Creating start.nsh file for first boot...
echo "Image root=UUID=\$root_id rw initrd=\initramfs-linux.img" > /archlinux/boot/startup.nsh

END

echo "Downloading QEMU EFI bios image..."
[ -f QEMU_EFI.img ] || curl -Lo - http://snapshots.linaro.org/components/kernel/leg-virt-tianocore-edk2-upstream/latest/QEMU-AARCH64/RELEASE_GCC5/QEMU_EFI.img.gz | gzip -dc > QEMU_EFI.img

echo "Downloading Arch ISO image..."
[ -f Arch.Linux.Arm--aarch64.iso ] || curl -LO https://github.com/IComplainInComments/archiso/releases/download/v2.0/Arch.Linux.Arm--aarch64.iso

echo "Generating temp/install.sh script to launch QEMU with archlinuxinstall.img..."
cat << END > temp/install.sh
#!/bin/zsh

qemu-system-aarch64 \\
	-cpu host \\
	-accel hvf \\
	-M virt \\
	-m 1024 \\
	-drive if=pflash,media=disk,file=QEMU_EFI.img,cache=writethrough,format=raw \\
	-drive if=pflash,media=disk,file=efivars.img,cache=writethrough,format=raw \\
	-device virtio-gpu-pci \\
	-drive file=temp/archlinuxinstall.img,format=raw,if=virtio \\
	-drive file=Arch.Linux.Arm--aarch64.iso,format=raw,if=virtio \\
	-device qemu-xhci \\
	-device usb-kbd \\
	-device usb-tablet \\
	-display cocoa

END
chmod +x temp/install.sh

echo "Run the following command sequence in the target VM:
mount /dev/vda1 /mnt && /mnt/setup.sh"
temp/install.sh

echo Copying generated archlinux.img from archlinuxinstall.img to host...
mount_dos_line="`hdiutil attach temp/archlinuxinstall.img | grep FAT_32`"
echo $mount_dos_line
imgdev="`echo $mount_dos_line | awk '{print $1}'`"
imgdir="`echo $mount_dos_line | awk '{print $3}'`"

echo "Converting archlinux.img to qcow2 format..."
qemu-img convert -c -p -f raw -O qcow2 "${imgdir}/arch.img" archlinux.qcow2

echo Resizing qcow2 image...
qemu-img resize archlinux.qcow2 8G

echo Unmounting FAT filesystem...
hdiutil detach "$imgdev"
imgdev=

echo Generating run.sh script to launch QEMU with generated archlinux.qcow2...
cat << END > run.sh
#!/bin/zsh

cd "\`dirname "\$0"\`"

"`which qemu-system-aarch64`" \\
	-cpu host \\
	-accel hvf \\
	-M virt \\
	-m 1024 \\
	-drive if=pflash,media=disk,file=QEMU_EFI.img,cache=writethrough,format=raw \\
	-drive if=pflash,media=disk,file=efivars.img,cache=writethrough,format=raw \\
	-device virtio-gpu-pci \\
	-drive file=archlinux.qcow2,if=virtio \\
	-netdev user,id=vnet,hostfwd=tcp::2222-:22,hostfwd=tcp::4445-:445 \\
	-device virtio-net-pci,netdev=vnet \\
	-device qemu-xhci \\
	-device usb-kbd \\
	-device usb-tablet \\
	-display cocoa,show-cursor=on

END
chmod +x run.sh

echo Downloading App Bundle...
curl -Lo - https://raw.githubusercontent.com/bantling/tools/master/qemu-vms/ArchLinux.app.xz | tar xJf -

echo "Done

On first boot, do the following:
- Execute run.sh to launch QEMU with generated archlinux.img
- Quickly switch to the VM, hit Esc, and choose Boot Manager > EFI Internal Shell
- Wait 5 second delay to run startup.nsh
- Login as root/root, and execute the following commands:
  ./set-boot.sh
  ./resize.sh
- Future boots will just boot up without having to use the EFI Internal Shell

The run.sh script has the following useful features:
- Forwards host port 2222 to guest port 22 for SSH (ssh is preconfigured to startup)
- Forwards host port 4445 to guest port 445 for Samba (you have to install that yourself)
- Uses the display option show-cursor=on in case you want to run a graphical X system

There is a ArchLinux.app bundle that can be run from the Finder or Dock.
See https://raw.githubusercontent.com/bantling/tools/master/qemu-vms/README.adoc for details."
