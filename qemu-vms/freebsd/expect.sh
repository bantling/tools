#!/usr/bin/expect -f

set accel "[lindex $argv 0]"
set memstick "[lindex $argv 1]"
set image "[lindex $argv 2]"
set prompt "*root@:~ #"

puts "Accel    = $accel"
puts "Memstick = $memstick"
puts "Image    = $image"
puts "Hit return to continue or Ctrl-C to stop"
set timeout -1
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
set timeout 15
expect "*login "

# Login as root (No password)
send -- "root\r"
set timeout -1
expect "$prompt"

# Install steps, inspired by https://forums.freebsd.org/threads/installing-freebsd-manually-no-installer.63201/
# Create an empty GPT partition table
send -- "gpart create -s gpt vtbd1\r"
expect "$prompt"

# Create boot and zfs partitions
send -- "gpart add -t freebsd-boot -l zboot -s 512k vtbd1\r"
expect "$prompt"

send -- "gpart add -t freebsd-zfs  -l zroot vtbd1\r"
expect "$prompt"

# Create temp moutpoint
send -- "mkdir /tmp/zfs\r"
expect "$prompt"

# Get gpt ids for zboot and zroot labels
send -- "zboot_dev=\"/dev/gptid/\`glabel status | grep 'gptid.*vtbd1p1' | awk '{print \$1}' | awk -F/ '{print \$2}'\`\"\r"
expect "$prompt"

send -- "zroot_dev=\"/dev/gptid/\`glabel status | grep 'gptid.*vtbd1p2' | awk '{print \$1}' | awk -F/ '{print \$2}'\`\"\r"
expect "$prompt"

# Create zfs pool
send -- "zpool create -m / -R /tmp/zfs zroot \$zroot_dev\r"
expect "$prompt"

# Set bootfs property
send -- "zpool set bootfs=zroot zroot\r"
expect "$prompt"

# Create swap space
send -- "zfs create -V 4G zroot/swap\r"
expect "$prompt"

send -- "zfs set org.freebsd:swap=on zroot/swap\r"
expect "$prompt"

# Install base system
send -- "cd /tmp/zfs\r"
expect "$prompt"

send -- "tar xvJf /usr/freebsd-dist/base.txz\r"
expect "$prompt"

send -- "tar xvJf /usr/freebsd-dist/kernel.txz\r"
expect "$prompt"

send -- "tar xvJf /usr/freebsd-dist/lib32.txz\r"
expect "$prompt"

# Install boot code
send -- "gpart bootcode -b /boot/pmbr -p /boot/gptzfsboot -i 1 vtbd1\r"
expect "$prompt"

# Configure loader.conf settings
send -- "echo 'zfs_load=\"YES\"' >> boot/loader.conf\r"
expect "$prompt"

send -- "echo 'vfs.root.mountfrom=\"zfs:zroot\"' >> boot/loader.conf\r"
expect "$prompt"

# Configure rc.conf settings
send -- "echo 'zfs_enable=\"YES\"' >> etc/rc.conf\r"
expect "$prompt"

# Chroot
send -- "chroot .\r"
expect "$prompt"

# Set timezone to UTC
send -- "cp usr/share/zoneinfo/UTC etc/localtime\r"
expect "$prompt"

send -- "adjkerntz -a\r"
expect "$prompt"

# Set hostname
#send -- "hostname freebsd"
#expect "$prompt"
send -- "echo 'hostname=\"freebsd\"' >> etc/rc.conf\r"
expect "$prompt"

# Set DHCP
send -- "sysrc ifconfig_vtnet0=\"DHCP\"\r"
expect "$prompt"

# Exit chroot
send -- "exit\r"
expect "$prompt"

# Shut down
send -- "poweroff\r"
expect eof
