#!/bin/zsh
set -eu

# Script to setup an Arch Linux x86_86 virtual image by scripting an ISO installer via the emulated serial port with an expect script

usage() {
  [ "$#" -eq 0 ] || { echo -e "\nERROR: $1\n" }

  echo "$0: [ -n hdImage ] [-s hdSize ] [ -zfs ]

Arguments must be provided in above order.

Generates a bootable Arch Linux x86_64 virtual image named {hdImage} using qemu. If hdImage already has one or more
extensions, it is used as is, else the extension .img is added. If hdImage exists, it is overwritten with a new blank
image after verifying with a prompt.

-n hdImage: The name of the image to generate. The default name is archlinux-x86_64.img.

-s hdSize: Specifies the size of image to create, default is 8GB. The hdSize value must be acceptable to qemu-img create.
  If extra files are provided with -e, the actual image size will be the given hdSize + the size of all extra files.

-zfs: Creates a bootable zfs filesystem instead of default ext4. The zpool name will be zpool-{partitionUUID},to
  guarantee that it will not conflict with any other generated zfs image. The root dataset will
  be zpool-{partitionUUID}/root.

  A /root/resize.sh script is installed that can automatically expand the last partition of a disk to the remaining
  space on the disk, and if the partition has an ext4 filesystem, expand it to fill the partition.
"
  exit
}

# hasExt status code is 0 if argument has at least one dot, 1 if it has no dots
# eg:
# ext archlinux     returns 1
# ext archlinux.img returns 0
hasExt() {
  [ "`echo "$1" | awk -F. '{print NF-1}'`" -gt 0 ]
}

# yn translates 1/0 into yes/no
yn() {
  [ "$1" -eq 1 ] && { echo -n "yes"; exit }
  echo -n "no"
}

# imageName
hdImage="archlinux-x86_64.img"
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

# Are we making a ZFS image?
zfs=0
[[ ! -v 1 ]] || [ "$1" != "-zfs" ] || {
  zfs=1
  shift
}

# Any more parameters are an error
[ "$#" -eq 0 ] || {
  usage "Unrecognized parameters: $@"
}

# iso and checksum files
isoImage="/tmp/archlinux-x86_64.iso"
isoDlSum="/tmp/archlinux-x86_64.iso.b2sum"
isoGenSum="${isoDlSum}.gen"

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
zfs             = `yn ${zfs}`
install SSH Key = `yn ${haveSSHPubKey}`
"

proceed=
while [[ ! "$proceed" =~ [YyNn] ]]; do {
  read -q "proceed?Do you want to continue? (y/n)"
}; done
[[ "$proceed" =~ [Yy] ]] || exit

# Always download the b2sum for installer iso, there may be a newer installer
echo -e "\n\nDownloading ISO checksum"
curl https://arch.mirror.winslow.cloud/iso/latest/b2sums.txt | grep archlinux-x86_64.iso | awk '{print $1}' > "$isoDlSum"

# If there is already a generated checksum that differs from the downloaded one, then there is a newer installer
{ [ -f "$isoImage" -a -f "$isoGenSum" ] && diff "$isoDlSum" "$isoGenSum" > /dev/null } || {
  echo "Downloading ISO"
  curl "https://arch.mirror.winslow.cloud/iso/latest/archlinux-x86_64.iso" -o "$isoImage"

  echo "Generating checksum"
  b2sum "$isoImage" | awk '{print $1}' > "$isoGenSum"

  echo "Comparing checksum"
  diff "$isoDlSum" "$isoGenSum" > /dev/null || {
    echo "Downloaded checksum does not match generated checksum"
    exit 1
  }
}

# Create a disk image to install arch into. Recreate each time in case a previous run failed.
echo -e "\nCreating virtual disk image"
qemu-img create -f raw "$hdImage" "$hdSize"

# Fire up a VM to install arch, using downloaded ISO, generated disk image, and generated extra files image
echo -e "\nRunning expect script"
./qemu-arch-x86_64-expect.sh "$isoImage" "$hdImage" $sshPubKey

#qemu-system-x86_64 -cdrom /tmp/archlinux-x86_64.iso -cpu qemu64 -m 2048 -drive file=archlinux-x86_64.img,format=raw,if=virtio -nic user,model=virtio-net-pci
#qemu-system-x86_64 -cpu qemu64 -m 2048 -drive file=archlinux-x86_64.img,format=raw,if=virtio -nic user,model=virtio-net-pci
