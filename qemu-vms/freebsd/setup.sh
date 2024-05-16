#!/bin/sh

usage {
  echo "$0 { device }

Setup a bootable ZFS filesystem on the specified device:
- A 4G swap zvol
- Networking tuned for podman performance
- Use UTC timezone
- /etc/rc.local starts up DHCP on first non-loop network device
- An executable copy of this script at /setup.sh
- A copy of /usr/freebsd-dist/base.txz and /usr/freebsd-dist/kernel.txz
  "
  exit 1
}

## Verify we have a parameter passed for which device to setup
[ -n "$1" ] || usage

## Destroy any existing gpt partition on second drive
echo 'Destroying gpt partition table'
gpart destroy -F "$1"

## Create an empty GPT partition table
echo 'Creating gpt partiton table'
gpart create -s gpt "$1"

## Create boot and zfs partitions
echo 'Creating gpt boot and root partitions'
gpart add -t freebsd-boot -l zboot -s 512k "$1"
gpart add -t freebsd-zfs  -l zroot "$1"

## Install boot code
echo 'Installing gpt boot sector and gpt partition boot loader'
gpart bootcode -b /boot/pmbr -p /boot/gptzfsboot -i 1 "$1"

## Get gpt id for zroot label
echo 'Retrieving gpt root partition id'
zroot_dev="/dev/gptid/`glabel status | grep "gptid.*${1}p2" | awk '{print $1}' | awk -F/ '{print $2}'`"

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

## Create swap space
echo 'Creating swap space'
zfs create -V 4G zroot/swap
echo 'Setting freebsd swap property'
zfs set org.freebsd:swap=on zroot/swap

## Install base and kernel distributions
echo 'Entering temp mount point'
cd /tmp/zfs

echo 'Installing base'
tar xvJf /usr/freebsd-dist/base.txz

echo 'Installing kernel'
tar xvJf /usr/freebsd-dist/kernel.txz

echo 'Creating fstab'
echo -e '#Device\t\tMountpoint\tFSType\tOptions\t\tDump\tPass\nzroot\t\t/\t\tzfs\trw,noatime\t0\t0' > etc/fstab

echo 'Creating rc.local to start DHCP for first non-loop network device at boot, tuned for podman'
cat <<-EOF > etc/rc.local
#!/bin/sh
netdev="\`ifconfig -a | sed -r '/^\t/d;s,^([^:]*).*,\1,' | grep -v lo | head -1\`"
ifconfig \$netdev -rxcsum
dhclient \$netdev
EOF
chmod +x etc/rc.local

echo 'Copying this script to /setup.sh and base and kernel sets to /usr/freebsd-dist'
mkdir -p usr/freebsd-dist
cp "$0" setup.sh
chmod +x usr/freebsd-dist
cp /usr/freebsd-dist/base.txz usr/freebsd-dist
cp /usr/freebsd-dist/kernel.txz usr/freebsd-dist

echo 'Configuring boot loader to use zfs'
echo 'zfs_load="YES"' >> boot/loader.conf
echo 'vfs.root.mountfrom="zfs:zroot"' >> boot/loader.conf

echo 'Tuning boot loader for podmman network performance'
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
