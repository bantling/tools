#!/bin/sh

# Do we need to reboot?
reboot=0

# Remount root fs read/write
mount -u -w /

# Check if /boot/loader.conf contains lines for disk identification settings (not present by default)
grep -q 'kern.geom.label' /boot/loader.conf || {
  # We need to reboot for these settings to take effect
  reboot=1

  # Inform user
  echo 'Configuring gptid disk identification'

  # Append lines to the end
  {
    echo 'kern.geom.label.disk_ident.enable="0"'
    echo 'kern.geom.label.gpt.enable="0"'
    echo 'kern.geom.label.gptid.enable="1"'
  } >> /boot/loader.conf
}

# Check if /etc/rc.local runs this script automatically at boot
grep -q bootstrap.sh /etc/rc.local || {
  # Rebooting allows user to manually test this script launches automatically
  reboot=1

  # Inform user
  echo 'Ensuring bootstrap.sh runs automatically at boot'

  # Modify /etc/rc.local
  sed -rie '1s,(.*),\1\n\nsh /root/bootscript.sh\nexit,' /etc/rc.local
}

# Reboot if necessary
[ "$reboot" -eq 0 ] || {
  # Inform user
  echo 'Rebooting'

  reboot
}

## Destroy any existing gpt partition on second drive
echo 'Destroying gpt partition table'
gpart destroy -F vtbd1

## Create an empty GPT partition table
echo 'Creating gpt partiton table'
gpart create -s gpt vtbd1

## Create boot and zfs partitions
echo 'Creating gpt boot and root partitions'
gpart add -t freebsd-boot -l zboot -s 512k vtbd1
gpart add -t freebsd-zfs  -l zroot vtbd1

## Install boot code
echo 'Installing gpt boot sector and gpt partition boot loader'
gpart bootcode -b /boot/pmbr -p /boot/gptzfsboot -i 1 vtbd1

## Get gpt id for zroot label
echo 'Retrieving gpt root partition id'
zroot_dev="/dev/gptid/`glabel status | grep 'gptid.*vtbd1p2' | awk '{print $1}' | awk -F/ '{print $2}'`"

## Create temp moutpoint
echo 'Creating temp mount point'
mkdir /tmp/zfs

## Create zfs pool
echo 'Creating zpool'
zpool create -m / -R /tmp/zfs zroot $zroot_dev

## Set bootfs property
echo 'Setting bootfs property'
zpool set bootfs=zroot zroot

## Create swap space
echo 'Creating swap space'
zfs create -V 4G zroot/swap
echo 'Setting freebsd swap property'
zfs set org.freebsd:swap=on zroot/swap

## Install base and kernel distributions
echo 'Entering temp mount point'
cd /tmp/zfs

echo 'Installing base'
tar xvJf /usr/freebsd-dist/base.txz > /dev/null

echo 'Installing kernel'
tar xvJf /usr/freebsd-dist/kernel.txz > /dev/null

## Chroot and set up some stuff
echo 'Chrooting into temp mount point'
chroot .

## Configure loader.conf settings
echo 'Configuring boot loader to use zfs'
sysrc -f boot/loader.conf zfs_load="YES"
sysrc -f boot/loader.conf vfs.root.mountfrom="zfs:zroot"

## Configure rc.conf settings
echo 'Configuring rc.conf'
sysrc zfs_enable="YES"
sysrc hostname="freebsd"
sysrc ifconfig_vtnet0="DHCP"

## Set timezone to UTC
echo 'Setting timezone to UTC'
cp usr/share/zoneinfo/UTC etc/localtime
echo 'Adjusting kernel time zone'
adjkerntz -a

## Exit chroot
exit
