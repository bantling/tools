#!/usr/bin/expect -f

set accel "[lindex $argv 0]"
set memstick "[lindex $argv 1]"
set image "[lindex $argv 2]"
set prompt "*root@:~ #"

puts "Accel    = $accel"
puts "Memstick = $memstick"
puts "Image    = $image"
puts "Hit \` when the login: prompt appears"
puts "Hit return to continue or Ctrl-C to stop"
expect_user -re "(.*)\n"

# Fire up qemu
spawn qemu-system-x86_64 \
  -accel "$accel" \
  -boot c \
  -cpu qemu64 \
  -m 1024 \
  -drive "file=$memstick,format=raw,if=virtio" \
  -drive "file=$image,format=raw,if=virtio" \
  -nic user,model=virtio-net-pci \
  -nographic

match_max 100000
# Hit return at boot menu for default option
expect "*Autoboot in*"
send -- "\r"

# Wait for user to hit backtick and assume login: prompt has appeared
# For some reason, can't get expect to match against this, even with match_max = 10 million
#interact ` return
expect "*login "
set timeout 15

# Login as root (No password)
send -- "root\r"
expect "$prompt"

# Install steps, inspired by https://forums.freebsd.org/threads/installing-freebsd-manually-no-installer.63201/
# Create an empty GPT partition table
send -- "gpart create -s gpt vtbd1"
expect "$prompt"

# Create boot and zfs partitions
send -- "gpart add -t freebsd-boot -l zboot -s 512k vtbd1"
expect "$prompt"

send -- "gpart add -t freebsd-zfs  -l zroot vtbd1"
expect "$prompt"

# Create temp moutpoint
send -- "mkdir /tmp/zfs"
expect "$prompt"

# Get gpt ids for zboot and zroot labels
send -- "zboot_dev=\"/dev/gptid/\`glabel status | grep 'gptid.*vtbd1p1' | awk '{print \$1}' | awk -F/ '{print \$2}'\`\""
expect "$prompt"

send -- "zroot_dev=\"/dev/gptid/\`glabel status | grep 'gptid.*vtbd1p2' | awk '{print \$1}' | awk -F/ '{print \$2}'\`\""
expect "$prompt"

# Create zfs pool
send -- "zpool create -m / -R /tmp/zfs zroot \$zroot_dev"
expect "$prompt"

# Set bootfs property
send -- "zpool set bootfs=zroot zroot"
expect "$prompt"

# Create swap space
send -- "zfs create -V 4G zroot/swap"
expect "$prompt"

send -- "zfs set org.freebsd:swap=on zroot/swap"
expect "$prompt"

# Install base system
send -- "cd /tmp/zfs"
expect "$prompt"

send -- "tar xvJf /usr/freebsd-dist/base.txz"
expect "$prompt"

send -- "tar xvJf /usr/freebsd-dist/kernel.txz"
expect "$prompt"

send -- "tar xvJf /usr/freebsd-dist/lib32.txz"
expect "$prompt"

# Install boot code
send -- "gpart bootcode -b /boot/pmbr -p /boot/gptzfsboot -i 1 vtbd1"
expect "$prompt"

# Configure loader.conf settings
send -- "echo 'zfs_load=\"YES\"' >> boot/loader.conf"
expect "$prompt"

send -- "echo 'vfs.root.mountfrom=\"zfs:zroot\"' >> boot/loader.conf"
expect "$prompt"

# Configure rc.conf settings
send -- "echo 'zfs_enable=\"YES\"' >> etc/rc.conf"
expect "$prompt"

# Chroot
send -- "chroot ."
expect "$prompt"

# Set timezone to UTC
send -- "cp usr/share/zoneinfo/UTC etc/localtime"
expect "$prompt"

send -- "adjkerntz -a"
expect "$prompt"

# Set hostname
#send -- "hostname freebsd"
#expect "$prompt"
send -- "echo 'hostname=\"freebsd\"' >> etc/rc.conf"
expect "$prompt"

# Set DHCP
send -- "sysrc ifconfig_vtnet0=\"DHCP\""
expect "$prompt"

# Exit chroot
send -- "exit"
expect "$prompt"

# Shut down
send -- "poweroff\r"
expect eof
