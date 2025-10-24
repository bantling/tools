#!/bin/sh
set -e

usage() {
  [ $# -eq 0 ] || printf "$1"
  echo "$0:
-h
-d device [ -l label ] [ -n ] [ -p poolname ] [ -a ]
-m -d device -l label -p poolname

-h         : display help
-d device  : device to use
-l label   : use specified label instead of default hd
-n         : no swap volume
-p poolname: use specified pool name instead of default zroot
-a         : autologin as user
-m         : add additional device as a mirror

Notes:
- If -h occurs anywhere, all other options are ignored
- when -m is provided, device, label, and poolname are all required
  the device given is the device to add to the pool
- without -m, only device is required, remaining options have defaults

Setup a bootable ZFS filesystem on the specified device:
- Create a gpt label on specified device of the form {poolname}-{label}
- The gpt label is used by the zpool, making it easier to identify which drive failed
- A 4G swap zvol (unless suppressed by -n)
- Networking tuned for podman performance
- Use UTC timezone
- /etc/rc.local starts up DHCP on all non-loop network devices
- /etc/ttys and /etc/gettytab are configured to autologin as ordinary user named user
  "
  exit 1
}

# Use a simple loop to handle remaining optional args in any order
device=""
labelDefault=hd
swap=1
poolnameDefault=zroot
autologin=0
mirror=0

while [ "$#" -gt 0 ]; do
  case "$1" in
    -h)
      usage
      break
      ;;

    -d)
      shift
      [ "$#" -gt 0 ] || usage "no device"
      device="$1"
      ;;

    -l)
      shift
      [ "$#" -gt 0 ] || usage "no label"
      label="$1"
      ;;

    -n)
      swap=0
      ;;

    -p)
      shift
      [ "$#" -gt 0 ] || usage "no poolname"
      poolname="$1"
      ;;

    -a)
      autologin=1
      ;;

    -m)
      mirror=1
      ;;

    *)
      usage "unknown option $1"
      ;;
  esac

  shift
done

# If we are mirroring, then device and poolname are required
# otherwise, default label and poolname if not provided
if [ "$mirror" -eq 1 ]; then
  [ -n "$device" -a -n "$poolname" ] || usage "mirroring requires a device to add as a mirror and a pool to add it to"
  echo "Add $device as a mirror to $poolname labelled as $label"
else
  [ -n "$label" ] || label="$labelDefault"
  [ -n "$poolname" ] || echo "defaulted poolname to $poolname"
  echo "Setup pool $poolname with device $device labelled as $label"
fi

read -p "Are you sure? [y/N]: " yn
[ "$yn" = "y" -o "$yn" = "Y" ] || {
  exit
}

# Perform setup of a pool if we're not mirroring
if [ "$mirror" -eq 0 ]; then
  # Alter /boot/loader.conf autoboot_delay to 0
  grep -q 'autoboot_delay' /boot/loader.conf || {
    echo 'Configuring boot delay'
    sleep 1

    # Append lines to the end
    echo 'autoboot_delay="0"' >> /boot/loader.conf
  }

  ## Unmount all partitions on the specified device
  ## Could be mounts from a previous attempt to run this script that failed
  echo 'Unmounting any mounted filesystems'
  umount -A || :

  ## Destroy any existing gpt partitions
  ## The command fails if no partitions exist
  echo 'Destroying gpt partition table'
  sleep 1
  gpart destroy -F "$device" 2> /dev/null || :

  ## Create an empty GPT partition table
  echo 'Creating gpt partiton table'
  sleep 1
  gpart create -s gpt "$device"

  ## Create partitions
  echo 'Creating gpt boot, efi, and zfs partitions'
  sleep 1
  gpart add       -t freebsd-boot -l "freebsd-boot-${label}" -s 512k "$device"
  gpart add -a 4K -t efi          -l "efi-${label}"          -s 512m "$device"
  gpart add -a 4K -t freebsd-zfs  -l "${poolname}-${label}"          "$device"

  ## Install mbr boot sector and partition code
  echo 'Installing gpt boot sector and gpt partition boot loader'
  sleep 1
  gpart bootcode -b /boot/pmbr -p /boot/gptzfsboot -i 1 "$device"

  ## Create EFI filesystem
  echo 'Creating EFI filesystem'
  sleep 1
  newfs_msdos -F 16 -L EFI "$device"p2

  ## Create temp EFI mountpoint
  echo 'Creating temp EFI mount point'
  sleep 1
  mkdir -p /tmp/efi

  ## Mount EFI
  echo 'Mounting EFI filesystem'
  sleep 1
  mount -t msdosfs /dev/"$device"p2 /tmp/efi

  ## Install efi boot partition code
  echo 'Installing EFI boot code'
  sleep 1
  mkdir -p /tmp/efi/EFI/BOOT
  cp /boot/boot1.efi /tmp/efi/EFI/BOOT/BOOTX64.EFI

  echo 'Setting zpool device by gpart label'
  sleep 1
  zpool_dev="gpt/${poolname}-${label}"

  ## Create temp mountpoint
  echo 'Creating temp ZFS mount point'
  sleep 1
  mkdir -p /tmp/zfs

  ## Create zfs pool
  echo 'Creating zpool'
  sleep 1
  zpool labelclear -f $zpool_dev || :
  zpool create -o ashift=12 -O compression=lz4 -m / -R /tmp/zfs $poolname $zpool_dev

  ## Install base and kernel distributions
  echo 'Entering temp ZFS mount point'
  sleep 1
  cd /tmp/zfs

  echo 'Installing kernel'
  sleep 1
  tar xf /usr/freebsd-dist/kernel.txz

  echo 'Installing base'
  sleep 1
  tar xf /usr/freebsd-dist/base.txz

  # Copy setup script and base and kernel sets
  echo 'Copying setup.sh and base and kernel sets'
  sleep 1
  cp /setup.sh .
  chmod +x setup.sh
  mkdir -p usr/freebsd-dist
  cp /usr/freebsd-dist/base.txz usr/freebsd-dist
  cp /usr/freebsd-dist/kernel.txz usr/freebsd-dist

  ## Create swap space, if desired
  [ "$swap" -eq 0 ] || {
    echo 'Creating 4GB swap zvol'
    sleep 1
    zfs create -V 4G -o org.freebsd:swap=on "$poolname"/swap
  }

  echo 'Creating fstab'
  sleep 1
  echo -e "#Device\t\tMountpoint\tFSType\tOptions\t\tDump\tPass\n$poolname\t\t/\t\tzfs\trw,noatime\t0\t0" > etc/fstab

  echo -n 'Creating rc.local to start DHCP for all non-loop network devices at boot, tuned for podman'
  [ "$autologin" -eq 0 ] || echo -n ', and autologin'
  echo
  sleep 1

cat <<-EOF > etc/rc.local
  #!/bin/sh
  for netdev in \`ifconfig -a | sed -r '/^[ \t]/d;s,^([^:]*).*,\1,' | grep -v lo\`; do
    ifconfig \$netdev -rxcsum
    dhclient \$netdev
  done
EOF

  sleep 1
cat <<-EOF | chroot .
  echo 'Setting root password to toor, and terminal to vt100'
  echo 'toor' | pw usermod -n root -h 0
  sed -i '' 's,TERM=.*,TERM=vt100,'    /root/.profile
  sed -i '' 's,PAGER=less,PAGER=more,' /root/.profile

  echo 'Creating user with password resu, and terminal is vt100'
  sleep 1
  echo 'resu' | pw useradd -n user -c User -G wheel -m -h 0
  sed -i ''    's,# TERM=.*,TERM=vt100,'  /home/user/.profile
  sed -i '' -r 's,(.*fortune),# \1,'      /home/user/.profile
  sed -i ''    's,PAGER=less,PAGER=more,' /home/user/.profile
  exit
EOF

  [ "$autologin" -eq 0 ] || {
    echo 'Modifying etc/ttys to use autologin for ttyv0'
    sleep 1
    sed -i '' -r 's,(ttyv0.*)Pc,\1al.Pc,' etc/ttys

  # Use awk to:
  # - print out all lines as is up to but not including a line containing al.Pc
  # - print the al.Pc line as is
  # - get next line
  # - modify next line replacing root with user
  # - print modified next line
  # - print all remaining lines as is
  # Net effect is modify two line config of al.Pc to autologin as user instead of root,
  # leaving the rest of the file as is
    echo 'Modifying etc/gettytab to autologin as user'
    sleep 1
    awk '/al.Pc/ {
  print;
  getline;
  sub(/root/, "user");
  print $0;
  next;
  }
  {print;}
  '    etc/gettytab     > etc/gettytab.new
    mv etc/gettytab.new   etc/gettytab
  }

  echo 'Setting autoboot delay to 1 second'
  sleep 1
  echo 'autoboot_delay="1"' >> boot/loader.conf

  echo 'Configuring boot loader to use zfs'
  sleep 1
  echo 'zfs_load="YES"' >> boot/loader.conf
  echo "vfs.root.mountfrom=\"zfs:$poolname\"" >> boot/loader.conf

  echo 'Tuning boot loader and sysctl for podman network performance'
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

echo 'Setup complete'
sleep 1

exit
EOF

else
  # Add additional mirror device
  echo "Adding mirror device"

  ## Unmount all partitions on the specified device
  ## Could be mounts from a previous attempt to run this script that failed
  echo 'Unmounting any mounted filesystems'
  umount -A || :

  zpool status

  # Get the label of first device, which is of the form poolname-labelname
  # We only want the labelname part
  first_label="`zpool status "$poolname" | grep -o 'gpt/[^ ]*' | grep -o '/.*' | tr -d '/' | sed "s,${poolname}-,," | head -n 1`"

  echo "Label of first device of $poolname = $first_label"

  first_device="`gpart show -l | awk -v label=$first_label '
    NF == 6 {device=$4}
    $4 ~ $label {print device;exit}
  '`"

  echo "First device of $poolname = $first_device"
  echo "Cloning gpt partition table of $first_device into $device, changing label from $first_label to $label"
  read -p "Are you sure? [y/N]: " yn
  [ "$yn" = "y" -o "$yn" = "Y" ] || {
    exit
  }

  ## Destroy any existing gpt partitions
  ## The command fails if no partitions exist
  echo 'Destroying gpt partition table'
  sleep 1
  gpart destroy -F "$device" 2> /dev/null || :

  ## Create an empty GPT partition table
  echo 'Creating gpt partiton table'
  sleep 1
  gpart create -s gpt "$device"

  ## Create partitions
  echo 'Creating gpt boot, efi, and zfs partitions'
  sleep 1
  gpart add       -t freebsd-boot -l "freebsd-boot-${label}" -s 512k "$device"
  gpart add -a 4K -t efi          -l "efi-${label}"          -s 512m "$device"
  gpart add -a 4K -t freebsd-zfs  -l "${poolname}-${label}"          "$device"

  ## Install mbr boot sector and partition code
  echo 'Installing gpt boot sector and gpt partition boot loader'
  sleep 1
  gpart bootcode -b /boot/pmbr -p /boot/gptzfsboot -i 1 "$device"

  ## Attach second disk as clone of the first
  zpool attach $poolname "gpt/${poolname}-${first_label}" "gpt/${poolname}-${label}"

  ## Show zpool status
  zpool status
fi
