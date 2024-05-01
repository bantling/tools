#!/bin/zsh
set -eu

# Script to setup a FreeBSD x86_86 virtual image by scripting an ISO installer via the emulated serial port with an expect script

usage() {
  [ "$#" -eq 0 ] || { echo -e "\nERROR: $1\n" }

  echo "$0: [ -n hdImage ] [-s hdSize ]

Arguments must be provided in above order.

Generates a bootable FreeBSD x86_64 virtual image named {hdImage} using qemu. If hdImage already has one or more
extensions, it is used as is, else the extension .img is added. If hdImage exists, it is overwritten with a new blank
image after verifying with a prompt.

-n hdImage: The name of the image to generate. The default name is freebsd-x86_64.img.

-s hdSize: Specifies the size of image to create, default is 8GB. The hdSize value must be acceptable to qemu-img create.

The latest installer and B2 checksum will be copied into the current directory as freebsd-x86_64.boot, and
freebsd-x86_64.boot.b2sum. An additional file freebsd-x86_64.boot.b2sum.gen contains the generated checksum for
comparison. If this script is run again, the latest checksum is downloaded, and if it differs from the previously
generated sum, it is assumed that a new installer is available. The local boot and checksum are replaced with a new
download, and a new generated checksum is compared.

A user named user is created that can use sudo to run any command, where sudo will require entering the password for
user. Both root and user have a 16 character crytoprahically generated random password, which are stored in a file
called {hdImage}.pwd. Every time this script is run with the same image name, a new {hdImage}.pwd is generated with
new passwords.

If the file \$HOME/.ssh/id_ecdsa.pub exists on the host, it is copied into the ~user/.ssh/authorized_keys file on the
image, where .ssh and .ssh/authorized_keys have correct privileges.

A /root/resize.sh script is installed that can automatically expand the last partition of a disk to the remaining space
on the disk, and if the partition has as ufs filesystem, expand it to fill the partition. The partition may be mounted
or unmounted.

The script has a hard-coded mirror to download the boot from.
"
  exit
}

thisDir="`dirname "$0"`"

# hasExt status code is 0 if argument has at least one dot, 1 if it has no dots
# eg:
# hasExt freebsd.img returns 0
# hasExt freebsd     returns 1
hasExt() {
  [ "`echo "$1" | awk -F. '{print NF-1}'`" -gt 0 ]
}

# yn translates 1/0 into yes/no
yn() {
  [ "$1" -eq 1 ] && { echo -n "yes"; exit }
  echo -n "no"
}

# imageName
hdImage="freebsd-x86_64.img"
[[ ! -v 1 ]] || [ "$1" != "-n" ] || {
  [[ -v 2 ]] || {
    usage "-n must be followed by an image name"
  }
  hdImage="$2"

  # If imageName has no extension, add .img
  hasExt "$hdImage" || {
    hdImage="${hdImage}.img"
  }

  shift
  shift
}

# Is there a custom image size?
hdSize="8G"
[[ ! -v 1 ]] || [ "$1" != "-s" ] || {
  [[ -v 2 ]] || {
    usage "-s must be followed by an image size"
  }
  hdSize="$2"

  shift
  shift
}

# Any more parameters are an error
[ "$#" -eq 0 ] || {
  usage "Unrecognized parameters: $@"
}

# Generate 16 character root and user passwords
hdPwd="${hdImage}.pwd"
rootPwd="`openssl rand -base64 12`"
userPwd="`openssl rand -base64 12`"

# Get the ssh public key
sshPubKey=
haveSSHPubKey=0
[ ! -f $HOME/.ssh/id_ecdsa.pub ] || {
  sshPubKey="`cat $HOME/.ssh/id_ecdsa.pub`"
  haveSSHPubKey=1
}

# Display parameters, ask user to confirm
echo -n "Parameters:
hdImage         = ${hdImage}`[ ! -f ${hdImage} ] || echo -n ' (overwrite)'`
hdSize          = ${hdSize}
hdPwd           = ${hdPwd}
install SSH Key = `yn ${haveSSHPubKey}`
"

proceed=
while [[ ! "$proceed" =~ [YyNn] ]]; do {
  read -q "proceed?Do you want to continue? (y/n) "
}; done
[[ "$proceed" =~ [Yy] ]] || exit

echo

# Get latest version number
latestVersion="`curl -so - "https://download.freebsd.org/releases/amd64/amd64/ISO-IMAGES/" | grep "<a href" | tail -n 1 | grep -Eo '([0-9.]*)' | head -n 1`"

# boot image and checksum files
bootImage="FreeBSD-$latestVersion-RELEASE-amd64-memstick.img"
bootDlSum="${bootImage}.xz.sha512"
bootGenSum="${bootDlSum}.gen"
bootManSerial="${bootImage}.serial"

# Download image if we don't have it
[ -f "$bootImage" ] || {
  ls "FreeBSD*disc1.boot*" > /dev/null 2> /dev/null && {
    # Assume any existing boots (and checksums) are older versions
    echo -e "\nRemoving older boot images"
    rm FreeBSD*disc1.boot*
  }

  echo -e "\nDownloading the $latestVersion image"
  curl --progress-bar -Lo - "https://download.freebsd.org/releases/amd64/amd64/ISO-IMAGES/$latestVersion/FreeBSD-$latestVersion-RELEASE-amd64-memstick.img.xz" > "$bootImage.xz"
}

# Download the checksum if we don't have it
[ -f "$bootDlSum" ] || {
  echo -e "\nDownloading the $latestVersion checksum"
  curl -sLo - "https://download.freebsd.org/releases/amd64/amd64/ISO-IMAGES/$latestVersion/CHECKSUM.SHA512-FreeBSD-$latestVersion-RELEASE-amd64" | grep amd64-memstick.img.xz | awk '-F=' '{print $2}' | tr -d ' ' > "$bootDlSum"
}

# Generate our own sha512 checksum for comparison
[ -f "$bootGenSum" ] || {
  sha512sum -b "$bootImage.xz" | awk '{print $1}' > "$bootGenSum"
}

diff "$bootDlSum" "$bootGenSum" > /dev/null || {
  echo -e "\nDownloaded checksum does not match generated checksum"
  exit 1
}

[ -f "$bootImage" ] || {
  echo -e "\nExtracting boot"
  xz -d "$bootImage.xz" || {
    echo "Failed to decompress $bootImage.xz"
    [ ! -f rm "$bootImage" ] || { rm "$bootImage" }
  }
}

# Check if manual steps to "fix" boot to be able to boot with serial have been completed
[ -f "$bootManSerial" ] || {
  echo "
Running FreeBSD graphically to alter boot menu to allow serial booting.

Temporarily change root to rw:
mount -u -w /

vi /boot/loader.conf
- add following lines for serial booting

boot_multicons=”YES”
boot_serial=”YES”
comconsole_speed=”115200″
console=”comconsole,vidconsole”

- add following lines to allow creation of /dev/gptid entries
kern.geom.label.disk_ident.enable="0"
kern.geom.label.gpt.enable="1"
kern.geom.label.gptid.enable="1"

Quit:
halt -p
"
  qemu-system-x86_64 -cpu qemu64 -m 2048 -vga virtio -drive "file=${bootImage},format=raw,if=virtio"

  echo -e "\n"
  proceed=
  while [[ ! "$proceed" =~ [YyNn] ]]; do {
    read -q "proceed?Test that image boots in serial mode? (y/n) "
  }; done
  [[ "$proceed" =~ [Yy] ]] || exit

  qemu-system-x86_64 -cpu qemu64 -m 2048 -nographic -drive "file=${bootImage},format=raw,if=virtio"

  touch "$bootManSerial"
  echo
}

# Create a disk image to install freebsd into. Recreate each time in case a previous run failed.
echo -e "\nCreating virtual disk image"
qemu-img create -f raw "$hdImage" "$hdSize"

# Generate pwd file
echo -e "\nCreating password file"
echo -e "root:$rootPwd\nuser:$userPwd" > "$hdPwd"

# Generate base64 coded string of resize.sh script
#resizeScript="`base64 -i "${thisDir}/resize.sh"`"
resizeScript="blahdy"

# Fire up a VM to install arch, using downloaded ISO, generated disk image, and generated extra files image
echo -e "\nRunning expect script"
qemu-system-x86_64 -cpu qemu64 -m 2048 -nographic -drive "file=${bootImage},format=raw,if=virtio" -drive "file=${hdImage},format=raw,if=virtio" -nic user,model=virtio-net-pci
#"${thisDir}"/expect.sh "$bootImage" "$hdImage" "$rootPwd" "$userPwd" "$resizeScript" $sshPubKey

## Manual install steps
## See https://forums.freebsd.org/threads/installing-freebsd-manually-no-installer.63201/ for basic ZFS install steps

## Create an empty GPT partition table
# gpart create -s gpt vtbd1

## Create boot and zfs partitions
# gpart add -t freebsd-boot -l zboot -s 512k vtbd1
# gpart add -t freebsd-zfs  -l zroot vtbd1

## Create temp moutpoint
# mkdir /tmp/zfs

## Get gpt ids for zboot and zroot labels
# zboot_dev="/dev/gptid/`glabel status | grep 'gptid.*vtbd1p1' | awk '{print $1}' | awk -F/ '{print $2}'`"
# zroot_dev="/dev/gptid/`glabel status | grep 'gptid.*vtbd1p2' | awk '{print $1}' | awk -F/ '{print $2}'`"

## Create zfs pool
# zpool create -m / -R /tmp/zfs zroot $zroot_dev
## Set bootfs property
# zpool set bootfs=zroot zroot

## Create swap space
# zfs create -V 4G zroot/swap
# zfs set org.freebsd:swap=on zroot/swap

## Install base system
# cd /tmp/zfs
# tar xvJf /usr/freebsd-dist/base.txz
# tar xvJf /usr/freebsd-dist/kernel.txz
# tar xvJf /usr/freebsd-dist/lib32.txz

## Install boot code
# gpart bootcode -b /boot/pmbr -p /boot/gptzfsboot -i 1 vtbd1

## Configure loader.conf settings
# echo 'zfs_load="YES"' >> boot/loader.conf
# echo 'vfs.root.mountfrom="zfs:zroot"' >> boot/loader.conf

## Configure rc.conf settings
# echo 'zfs_enable="YES"' >> etc/rc.conf

## Chroot and set up some stuff
# chroot .
## Set timezone to UTC
# cp usr/share/zoneinfo/UTC etc/localtime
# adjkerntz -a
## Set hostname
# hostname freebsd
# echo 'hostname="freebsd"' >> etc/rc.conf

# sysrc ifconfig_vtnet0="DHCP"

# geom disk list identifies the relationship between /dev/diskid/NAME entries and /dev/adaX entries
# Look at Geom name: ada0 which contains line ident: QM00001, which means /dev/diskid/QM00001 = /dev/ada0
# EG:
# Geom name: cd0
# Providers:
# 1. Name: cd0
#    Mediasize: 0 (0B)
#    Sectorsize: 2048
#    Mode: r0w0e0
#    descr: QEMU QEMU DVD-ROM
#    ident: (null)
#    rotationrate: unknown
#    fwsectors: 0
#    fwheads: 0
#
# Geom name: ada0
# Providers:
# 1. Name: ada0
#    Mediasize: 1360155136 (1.3G)
#    Sectorsize: 512
#    Mode: r1w0e1
#    descr: QEMU HARDDISK
#    ident: QM00001
#    rotationrate: unknown
#    fwsectors: 63
#    fwheads: 16
#
# Geom name: ada1
# Providers:
# 1. Name: ada1
#    Mediasize: 8589934592 (8.0G)
#    Sectorsize: 512
#    Mode: r0w0e0
#    descr: QEMU HARDDISK
#    ident: QM00002
#    rotationrate: unknown
#    fwsectors: 63
#    fwheads: 16

# QEMU add options for raw disk sector sizes: physical_block_size=4096,logical_block_size=512

# Server sda is PHYS 4096 LOG 512
# Server sdb is PHYS  512 LOG 512
# Server ashift is 12 = 4096
