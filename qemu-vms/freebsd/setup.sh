#!/bin/sh

usage() {
  echo "$0 { device } [ -n ]

-n: no swap volume

Setup a bootable ZFS filesystem on the specified device:
- A 4G swap zvol (unless suppressed by -n)
- Networking tuned for podman performance
- Use UTC timezone
- /etc/rc.local starts up DHCP on all non-loop network devices
  "
  exit 1
}

# Verify we have a parameter passed for which device to setup
[ -n "$1" ] || usage
dev="$1"
shift

# Check if the -n option was passed
swap=1
[ "$1" != "-n" ] || {
  shift
  swap=0
}

# Check if /boot/loader.conf contains lines for disk identification settings (not present by default)
grep -q 'kern.geom.label' /boot/loader.conf || {
  echo 'Configuring boot delay and gptid disk identification'

  # Append lines to the end
  {
    echo 'autoboot_delay="0"'
    echo 'kern.geom.label.disk_ident.enable="0"'
    echo 'kern.geom.label.gpt.enable="0"'
    echo 'kern.geom.label.gptid.enable="1"'
  } >> /boot/loader.conf

  echo 'Rebooting'
  reboot
}

## Destroy any existing gpt partition on second drive
## The command fails if no partitions exist
echo 'Destroying gpt partition table'
gpart destroy -F "$dev" 2> /dev/null || :

## Create an empty GPT partition table
echo 'Creating gpt partiton table'
gpart create -s gpt "$dev"

## Create boot and zfs partitions
echo 'Creating gpt boot and root partitions'
gpart add -t freebsd-boot -l zboot -s 512k "$dev"
gpart add -t freebsd-zfs  -l zroot "$dev"

## Install boot code
echo 'Installing gpt boot sector and gpt partition boot loader'
gpart bootcode -b /boot/pmbr -p /boot/gptzfsboot -i 1 "$dev"

## Get gpt id for zroot label
echo 'Retrieving gpt root partition id'
zroot_dev="/dev/gptid/`glabel status | grep "gptid.*${dev}p2" | awk '{print $1}' | awk -F/ '{print $2}'`"

## Create temp mountpoint
echo 'Creating temp mount point'
mkdir /tmp/zfs

## Create zfs pool
echo 'Creating zpool'
zpool labelclear -f $zroot_dev
zpool create -m / -R /tmp/zfs zroot $zroot_dev

## Set bootfs property
echo 'Setting bootfs property'
zpool set bootfs=zroot zroot

## Install base and kernel distributions
echo 'Entering temp mount point'
cd /tmp/zfs

echo 'Installing base'
tar xvJf /usr/freebsd-dist/base.txz

echo 'Installing kernel'
tar xvJf /usr/freebsd-dist/kernel.txz

## Create swap space, if desired
[ "$swap" -eq 0 ] || {
  echo 'Creating swap space'
  zfs create -V 4G zroot/swap

  echo 'Setting freebsd swap property'
  zfs set org.freebsd:swap=on zroot/swap
}

echo 'Creating fstab'
echo -e '#Device\t\tMountpoint\tFSType\tOptions\t\tDump\tPass\nzroot\t\t/\t\tzfs\trw,noatime\t0\t0' > etc/fstab

echo 'Creating rc.local to start DHCP for all non-loop network devices at boot, tuned for podman'
cat <<-EOF > etc/rc.local
#!/bin/sh
for netdev in \`ifconfig -a | sed -r '/^\t/d;s,^([^:]*).*,\1,' | grep -v lo\`; do
  ifconfig \$netdev -rxcsum
  dhclient \$netdev
done
EOF
chmod +x etc/rc.local

echo 'Configuring boot loader to enable gptid and use zfs'
echo 'kern.geom.label.disk_ident.enable="0"' >> boot/loader.conf
echo 'kern.geom.label.gpt.enable="0"' >> boot/loader.conf
echo 'kern.geom.label.gptid.enable="1"' >> boot/loader.conf
echo 'zfs_load="YES"' >> boot/loader.conf
echo 'vfs.root.mountfrom="zfs:zroot"' >> boot/loader.conf

echo 'Tuning boot loader and sysctl for podmman network performance'
echo 'hw.vtnet.X.csum_disable=1' >> boot/loader.conf
echo 'hw.vtnet.lro_disable=1' >> boot/loader.conf
echo 'net.link.bridge.pfil_member=0' >> etc/sysctl.conf
echo 'net.link.bridge.pfil_bridge=0' >> etc/sysctl.conf
echo 'net.link.bridge.pfil_onlyip=0' >> etc/sysctl.conf

## Chroot and set up some stuff
echo 'Chrooting into temp mount point'

cat <<-EOF | chroot .
echo 'Configuring rc.conf'
sysrc zfs_enable="YES"
sysrc hostname="freebsd"

echo 'Setting timezone to UTC'
cp usr/share/zoneinfo/UTC etc/localtime

echo 'Adjusting kernel time zone'
adjkerntz -a

exit
EOF
