#!/bin/sh

usage() {
  echo "$0 { device } [ -n ] [ -p poolname ] [ -a ]

-n: no swap volume
-p poolname: use specified pool name install of default zroot
-a : autologin as root

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

# Use a simple loop to handle remaining optional args in any order
swap=1
poolname=zroot
autologin=0

while [ "$#" -gt 0 ]; do
  case "$1" in
    -n)
      swap=0
      ;;

    -p)
      shift
      [ "$#" -gt 0 ] || usage
      poolname="$1"
      ;;

    -a)
      autologin=1
      ;;

    *)
      usage
      ;;
  esac

  shift
done

# Check if /boot/loader.conf contains lines for disk identification settings (not present by default)
grep -q 'kern.geom.label' /boot/loader.conf || {
  echo 'Configuring boot delay and gptid disk identification'
  sleep 1

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
sleep 1
gpart destroy -F "$dev" 2> /dev/null || :

## Create an empty GPT partition table
echo 'Creating gpt partiton table'
sleep 1
gpart create -s gpt "$dev"

## Create boot and zfs partitions
echo 'Creating gpt boot and root partitions'
sleep 1
gpart add -t freebsd-boot -l zboot -s 512k "$dev"
gpart add -t freebsd-zfs  -l "$poolname" "$dev"

## Install boot code
echo 'Installing gpt boot sector and gpt partition boot loader'
sleep 1
gpart bootcode -b /boot/pmbr -p /boot/gptzfsboot -i 1 "$dev"

## Get gpt id for "$poolname" label
echo 'Retrieving gpt root partition id'
sleep 1
zpool_dev="/dev/gptid/`glabel status | grep "gptid.*${dev}p2" | awk '{print $1}' | awk -F/ '{print $2}'`"

## Create temp mountpoint
echo 'Creating temp mount point'
sleep 1
mkdir -p /tmp/zfs

## Create zfs pool
echo 'Creating zpool'
sleep 1
zpool labelclear -f $zpool_dev
zpool create -m / -R /tmp/zfs "$poolname" $zpool_dev

## Install base and kernel distributions
echo 'Entering temp mount point'
sleep 1
cd /tmp/zfs

echo 'Installing kernel'
sleep 1
xz -dkv --stdout /usr/freebsd-dist/kernel.txz | tar xf -
tar xvJf /usr/freebsd-dist/kernel.txz

echo 'Installing base'
sleep 1
xz -dkv --stdout /usr/freebsd-dist/base.txz | tar xf -

# Copy setup script and base and kernel sets
echo 'Copying setup.sh'
sleep 1
cp /setup.sh .
chmod +x setup.sh

echo 'Copying base and kernel sets'
mkdir -p usr/freebsd-dist
cp /usr/freebsd-dist/base.txz usr/freebsd-dist
cp /usr/freebsd-dist/kernel.txz usr/freebsd-dist

## Create swap space, if desired
[ "$swap" -eq 0 ] || {
  echo 'Creating swap space'
  sleep 1
  zfs create -V 4G "$poolname"/swap

  echo 'Setting freebsd swap property and lzjb compression'
  sleep 1
  zfs set org.freebsd:swap=on "$poolname"/swap
  zfs set compression=lzjb "$poolname"/swap
}

echo 'Creating fstab'
sleep 1
echo -e "#Device\t\tMountpoint\tFSType\tOptions\t\tDump\tPass\n$poolname\t\t/\t\tzfs\trw,noatime\t0\t0" > etc/fstab

echo -n 'Creating rc.local to start DHCP for all non-loop network devices at boot, tuned for podman'
[ "$autologin" -eq 0 ] || echo -n 'and autologin'
echo
sleep 1
cat <<-EOF > etc/rc.local
#!/bin/sh
for netdev in \`ifconfig -a | sed -r '/^\t/d;s,^([^:]*).*,\1,' | grep -v lo\`; do
  ifconfig \$netdev -rxcsum
  dhclient \$netdev
done
`[ "$autologin" -eq 0 ] || echo "/bin/sh"`
EOF
chmod +x etc/rc.local

echo 'Setting autoboot delay to 1 second'
sleep 1
echo 'autoboot_delay="1"' >> boot/loader.conf

echo 'Configuring boot loader to enable gptid and use zfs'
sleep 1
echo 'kern.geom.label.disk_ident.enable="0"' >> boot/loader.conf
echo 'kern.geom.label.gpt.enable="0"' >> boot/loader.conf
echo 'kern.geom.label.gptid.enable="1"' >> boot/loader.conf
echo 'zfs_load="YES"' >> boot/loader.conf
echo "vfs.root.mountfrom=\"zfs:$poolname\"" >> boot/loader.conf

echo 'Tuning boot loader and sysctl for podmman network performance'
sleep 1
echo 'hw.vtnet.X.csum_disable=1' >> boot/loader.conf
echo 'hw.vtnet.lro_disable=1' >> boot/loader.conf
echo 'net.link.bridge.pfil_member=0' >> etc/sysctl.conf
echo 'net.link.bridge.pfil_bridge=0' >> etc/sysctl.conf
echo 'net.link.bridge.pfil_onlyip=0' >> etc/sysctl.conf

## Chroot and set up some stuff
echo 'Chrooting into temp mount point'
sleep 1

cat <<-EOF | chroot .
echo 'Configuring rc.conf'
sleep 1
sysrc zfs_enable="YES"
sysrc hostname="freebsd"

echo 'Setting timezone to UTC'
sleep 1
cp usr/share/zoneinfo/UTC etc/localtime

echo 'Adjusting kernel time zone'
sleep 1
adjkerntz -a

exit
EOF
