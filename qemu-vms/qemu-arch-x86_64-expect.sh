#!/usr/bin/expect -f

# Found general approach to this script at https://blog.stefan-koch.name/2020/05/31/automation-archlinux-qemu-installation
set prompt "*@archiso*~*#* "
set chroot_prompt "*root@archiso* "
set timeout -1
spawn qemu-system-x86_64 -cdrom /tmp/archlinux-x86_64.iso -cpu qemu64 -m 2048 -drive file=archlinux-x86_64.img,format=raw,if=virtio -nic user,model=virtio-net-pci -nographic
match_max 100000
expect "*Automatic boot in*"
send -- "\t"
expect "*initramfs-linux.img*"
send -- " console=ttyS0,38400\r"
expect "archiso login: "
send -- "root\r"
expect $prompt
send -- "fdisk /dev/vda\r"
expect "Command (m for help): "
send -- "n\r"
expect "Select (default p): "
send -- "\r"
expect "Partition number (1-4, default 1): "
send -- "\r"
expect "First sector*: "
send -- "\r"
expect "Last sector*: "
send -- "\r"
expect "Command (m for help): "
send -- "a\r"
expect "Command (m for help): "
send -- "w\r"
expect $prompt
send -- "mkfs.ext4 /dev/vda1\r"
expect $prompt
send -- "mount /dev/vda1 /mnt\r"
expect $prompt
send -- "echo -e '\[options\]\\nHoldPkg = pacman glibc\\nSigLevel = DatabaseOptional\\nLocalFileSigLevel = Optional\\nDisableDownloadTimeout' > /tmp/pacman.conf\r"
expect $prompt
send -- "echo -e '\\n\[core\]' >> /tmp/pacman.conf\r"
expect $prompt
send -- "date -d '-7 days' +'Server = https://archive.archlinux.org/repos/%Y/%m/%d/core/os/x86_64/' >> /tmp/pacman.conf\r"
expect $prompt
send -- "echo -e '\\n\[extra\]' >> /tmp/pacman.conf\r"
expect $prompt
send -- "date -d '-7 days' +'Server = https://archive.archlinux.org/repos/%Y/%m/%d/extra/os/x86_64/' >> /tmp/pacman.conf\r"
expect $prompt
send -- "echo -e '\\n\[community\]' >> /tmp/pacman.conf\r"
expect $prompt
send -- "date -d '-7 days' +'Server = https://archive.archlinux.org/repos/%Y/%m/%d/community/os/x86_64/' >> /tmp/pacman.conf\r"
expect $prompt
send -- "cat /tmp/pacman.conf\r"
expect $prompt
send -- "echo waiting for pacman keyring init to be done\r"
# Found this snippet to wait for key ring init to complete at https://bbs.archlinux.org/viewtopic.php?id=283075
expect_before "*SubState=exited*" {
    expect $prompt
    send -- "pacstrap -K -C /tmp/pacman.conf /mnt base linux linux-firmware syslinux networkmanager\r"
}
expect $prompt {
    sleep 10
    send -- "systemctl show pacman-init.service | grep SubState\r"
    exp_continue
}
expect $prompt
send -- "genfstab -U /mnt >> /mnt/etc/fstab\r"
expect $prompt
send -- "arch-chroot /mnt\r"
expect $chroot_prompt
send -- "sed -i 's/^MODULES=()/MODULES=(virtio virtio_blk virtio_pci virtio_net)/' /etc/mkinitcpio.conf\r"
expect $chroot_prompt
send -- "grep '^MODULES=' /etc/mkinitcpio.conf\r"
expect $chroot_prompt
send -- "mkinitcpio -P\r"
expect $chroot_prompt
send -- "ln -sf /usr/share/zoneinfo/UTC /etc/localtime\r"
expect $chroot_prompt
send -- "hwclock --systohc\r"
expect $chroot_prompt
send -- "echo 'en_US.UTF-8 UTF-8' >> /etc/locale.gen\r"
expect $chroot_prompt
send -- "locale-gen\r"
expect $chroot_prompt
send -- "echo 'LANG=en_US.UTF-8' > /etc/locale.conf\r"
expect $chroot_prompt
send -- "echo arch-qemu > /etc/hostname\r"
expect $chroot_prompt
send -- "echo -e '127.0.0.1  localhost\\n::1  localhost' >> /etc/hosts\r"
expect $chroot_prompt
send -- "systemctl enable NetworkManager.service\r"
expect $chroot_prompt
send -- "syslinux-install_update -i -a -m\r"
expect $chroot_prompt
send -- "dd bs=440 count=1 conv=notrunc if=/usr/lib/syslinux/bios/mbr.bin of=/dev/vda\r"
expect $chroot_prompt
send -- "grep UUID /etc/fstab | awk -F= '{print \$2}' | awk '{print \"    APPEND root=UUID=\"\$1\" rw\"}' > /tmp/uuid.txt\r"
expect $chroot_prompt
send -- "cat /tmp/uuid.txt\r"
expect $chroot_prompt
send -- "sed -e '/root=\\/dev\\/sda3/r /tmp/uuid.txt' -e '/root=\\/dev\\/sda3/d' /boot/syslinux/syslinux.cfg > /tmp/syslinux.cfg\r"
expect $chroot_prompt
send -- "mv /tmp/syslinux.cfg /boot/syslinux/syslinux.cfg\r"
expect $chroot_prompt
send -- "cat /boot/syslinux/syslinux.cfg\r"
expect $chroot_prompt
send -- "passwd\r"
expect "New password: "
send -- "root\r"
expect "Retype new password: "
send -- "root\r"
expect $chroot_prompt
send -- "exit\r"
expect $prompt
send -- "halt -p\r"
expect eof
