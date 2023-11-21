#!/usr/bin/expect -f

# Found general approach to this script at https://blog.stefan-koch.name/2020/05/31/automation-archlinux-qemu-installation
set prompt "*@archiso*~*#* "
set chroot_prompt "*root@archiso* "
set timeout -1

# Start qemu with iso image to boot from, disk image to install Arch into, and possibly an extra files disk image
puts "numargs = [llength $argv] [lindex $argv 2]"
if { [llength $argv] == 2 } {
  # Without extra files disk image
  puts "no extra files"
  spawn qemu-system-x86_64 -cdrom [lindex $argv 0] -cpu qemu64 -m 2048 -drive file=[lindex $argv 1],format=raw,if=virtio -nic user,model=virtio-net-pci -nographic
} else {
  # With extra files disk image
  puts "extra files"
  spawn qemu-system-x86_64 -cdrom [lindex $argv 0] -cpu qemu64 -m 2048 -drive file=[lindex $argv 1],format=raw,if=virtio -drive file=[lindex $argv 2],format=raw,if=virtio -nic user,model=virtio-net-pci -nographic
}

# Wait for boot loader
match_max 100000
expect "*Automatic boot in*"

# Modify default menu entry to use serial console
send "\t"
expect "*initramfs-linux.img*"
send " console=ttyS0,38400\r"

# Wait for login prompt
expect "archiso login: "
send "root\r"

# Partition disk to have one BIOS ext4 bootable partition
expect $prompt
send "sgdisk -n 1:0:0 -A 1:set:2 /dev/vda\r"

# Make an ext4 filesystem
expect $prompt
send "mkfs.ext4 /dev/vda1\r"

# Mount ext4 filesystem
expect $prompt
send "mount /dev/vda1 /mnt\r"

# Generate pacman.conf file
expect $prompt
send "echo -e '\[options\]\\nHoldPkg = pacman glibc\\nSigLevel = DatabaseOptional\\nLocalFileSigLevel = Optional\\nDisableDownloadTimeout' > /tmp/pacman.conf\r"
expect $prompt
send "echo -e '\\n\[core\]' >> /tmp/pacman.conf\r"
expect $prompt
send "date -d '-7 days' +'Server = https://archive.archlinux.org/repos/%Y/%m/%d/core/os/x86_64/' >> /tmp/pacman.conf\r"
expect $prompt
send "echo -e '\\n\[extra\]' >> /tmp/pacman.conf\r"
expect $prompt
send "date -d '-7 days' +'Server = https://archive.archlinux.org/repos/%Y/%m/%d/extra/os/x86_64/' >> /tmp/pacman.conf\r"
expect $prompt
send "echo -e '\\n\[community\]' >> /tmp/pacman.conf\r"
expect $prompt
send "date -d '-7 days' +'Server = https://archive.archlinux.org/repos/%Y/%m/%d/community/os/x86_64/' >> /tmp/pacman.conf\r"

# Display contents of pacman.conf
expect $prompt
send "cat /tmp/pacman.conf\r"

# Wait for pacman init to finish, or else pacstrap will be unable to verify GPG signatures and fail
expect $prompt
send "echo waiting for pacman init to be done\r"
expect $prompt
send "while \[ \! `systemctl show pacman-init.service | grep SubState=exited` \]; do echo ...; sleep 10; done\r"

# Run pacstrap to install basic system, just enough to get a bootable system with networking
# Add:
# vim (editing text files)
# gptfdisk (provides sgdisk)
# e2fsprogs (provides resize2fs)
# which (provides which command, very useful)
# So that bootable system can resize partition and fs
expect $prompt
send "pacstrap -K -C /tmp/pacman.conf /mnt base linux linux-firmware syslinux networkmanager vim gptfdisk e2fsprogs which\r"

# Generate fstab file using partiton uuid for mounting root
expect $prompt
send "genfstab -U /mnt >> /mnt/etc/fstab\r"

# Enter arch-chroot to configure root filesystem
expect $prompt
send "arch-chroot /mnt\r"

# pacstrap already ran mkinitcpio, but there is no way to tell pacstrap to include the virtio modules
expect $chroot_prompt
send "sed -i 's/^MODULES=()/MODULES=(virtio virtio_blk virtio_pci virtio_net)/' /etc/mkinitcpio.conf\r"
expect $chroot_prompt
send "grep '^MODULES=' /etc/mkinitcpio.conf\r"
expect $chroot_prompt
send "mkinitcpio -P\r"

# Set timezone to UTC
expect $chroot_prompt
send "ln -sf /usr/share/zoneinfo/UTC /etc/localtime\r"
expect $chroot_prompt
send "hwclock --systohc\r"

# Set locale to US English UTF-8
expect $chroot_prompt
send "echo 'en_US.UTF-8 UTF-8' >> /etc/locale.gen\r"
expect $chroot_prompt
send "locale-gen\r"
expect $chroot_prompt
send "echo 'LANG=en_US.UTF-8' > /etc/locale.conf\r"

# Set hostname to arch-qemu
expect $chroot_prompt
send "echo arch-qemu > /etc/hostname\r"

# Create hosts file with ipv4 and ipv6 localhost entries
expect $chroot_prompt
send "echo -e '127.0.0.1  localhost\\n::1  localhost' >> /etc/hosts\r"

# Enable networking
expect $chroot_prompt
send "systemctl enable NetworkManager.service\r"

# Install BIOS bootloader
expect $chroot_prompt
send "syslinux-install_update -i -a -m\r"

# Install MBR code
expect $chroot_prompt
send "dd bs=440 count=1 conv=notrunc if=/usr/lib/syslinux/bios/gptmbr.bin of=/dev/vda\r"

# Modify default bootloader entry to point to the root partition UUID from the fstab file
expect $chroot_prompt
send "grep UUID /etc/fstab | awk -F= '{print \$2}' | awk '{print \"    APPEND root=UUID=\"\$1\" rw\"}' > /tmp/uuid.txt\r"
expect $chroot_prompt
send "cat /tmp/uuid.txt\r"
expect $chroot_prompt
send "sed -e '/root=\\/dev\\/sda3/r /tmp/uuid.txt' -e '/root=\\/dev\\/sda3/d' /boot/syslinux/syslinux.cfg > /tmp/syslinux.cfg\r"
expect $chroot_prompt
send "mv /tmp/syslinux.cfg /boot/syslinux/syslinux.cfg\r"

# Display bootloader config
expect $chroot_prompt
send "cat /boot/syslinux/syslinux.cfg\r"

# Set root password to root
expect $chroot_prompt
send "passwd\r"
expect "New password: "
send "root\r"
expect "Retype new password: "
send "root\r"

# Copy extra files, if there are any
if { [llength $argv] >= 3 } {
  # mount second drive on /mnt - note this is /mnt inside ext4 system, not /mnt of iso system we booted from
  expect $chroot_prompt
  send "echo Copying files from extra files disk image to /install\r"
  expect $chroot_prompt
  send "mount /dev/vdb1 /mnt\r"
  expect $chroot_prompt
  send "mkdir /install\r"
  expect $chroot_prompt
  send "cp /mnt/* /install\r"
  expect $chroot_prompt
  send "umount /mnt\r"
}

# Exit arch-chroot
expect $chroot_prompt
send "exit\r"

# Shutdown bootable system
expect $prompt
send "halt -p\r"

# We need to wait for eof to allow qemu to finish shutting down
expect eof
