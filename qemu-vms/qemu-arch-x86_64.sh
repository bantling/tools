#!/bin/zsh
set -eu

# Script to setup an Arch Linux x86_86 virtual image by scripting an ISO installer via the emulated serial port with an expect script

usage() {
  [ -z "$1" ] || { echo $1 }

  echo "$0: [ -n hdImage ] [-e {extraFiles}* ] [-s hdSize ] [ -zfs ] [ -expand ]

Arguments must be provided in above order.

Generates a bootable Arch Linux x86_64 virtual image named {hdImage} using qemu. If hdImage already has one or more
extensions, it is used as is, else the extension img is added. If hdImage exists, it is overwritten with a new blank
image after verifying with a prompt.

If one or more extraFiles are provided, they are added to the generated image at /install, otherwise there is no
/install dir.

-n hdImage: The name of the image to generate. The default name is archlinux-x86_64.img.

-e extraFiles: Optional additional files to place in /install.

-s hdSize: Specifies the size of image to create, default is 8GB. The hdSize value must be acceptable to qemu-img create.
  If extra files are provided with -e, the actual image size will be the given hdSize + the size of all extra files.

-zfs: Creates a bootable zfs filesystem instead of default ext4. The zpool name will be zpool-{partitionUUID},to
  guarantee that it will not conflict with any other generated zfs image. The root dataset will
  be zpool-{partitionUUID}/root.

-expand: Adds an /install/expand.sh script to automatically expand the last partition of a disk to the remaining space
  on the disk, mount the partition, and expand the filesystem to fill the partition. This is particularly useful with
  -e generatedImage, where generatedImage is another bootable image embedded inside this generated image. This image can
  be copied to a USB stick, plugged into a physical machine, and the embedded generated image in /install can be copied
  to the physical hard drive. The /install/expand.sh script can then be executed to expand the physical filesystem to
  fill the remaining space.
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

# Are there extra files?
extraFiles=()
[[ ! -v 1 ]] || [ "$1" != "-e" ] || {
  [[ -v 2 ]] || {
    usage "-e must be followed by at least one extra file"
  }

  shift

  while [[ -v 1 ]] && [ "$1" != "-s" -a "$1" != "-zfs" -a "$1" != "-expand" ]; do {
    [ -f "$1" ] || usage "-e: file \"$1\" does not exist"
    extraFiles+=("$1")
    shift
  }; done
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

# Are we copying an installer image into the new image?
expand=0
[[ ! -v 1 ]] || [ "$1" != "-expand" ] || {
  expand=1
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

# Display parameters, ask user to confirm
echo "Parameters:
hdImage    = ${hdImage}
extraFiles = ${extraFiles}
hdSize     = ${hdSize}
zfs        = `yn ${zfs}`
expand     = `yn ${expand}`
"

proceed=

while [[ ! "$proceed" =~ [YyNn] ]]; do {
  read -q "proceed?Do you want to continue? (y/n)"
}; done

[[ "$proceed" =~ [Yy] ]] || exit

# Always download the b2sum for installer iso, there may be a newer installer
echo -e "\n\nDownloading ISO checksum"
curl https://mirror.csclub.uwaterloo.ca/archlinux/iso/latest/b2sums.txt | grep archlinux-x86_64.iso | awk '{print $1}' > "$isoDlSum"

# If there is already a generated checksum that differs from the downloaded one, then there is a newer installer
{ [ -f "$isoImage" -a -f "$isoGenSum" ] && diff "$isoDlSum" "$isoGenSum" > /dev/null } || {
  echo "Downloading ISO"
  curl "https://mirror.csclub.uwaterloo.ca/archlinux/iso/latest/archlinux-x86_64.iso" -o "$isoImage"

  echo "Generating checksum"
  b2sum "$isoImage" | awk '{print $1}' > "$isoGenSum"

  echo "Comparing checksum"
  diff "$isoDlSum" "$isoGenSum" > /dev/null || {
    echo "Downloaded checksum does not match generated checksum"
    exit 1
  }
}

# Create a disk image to install arch into. Recreate each time in case a previous run failed.
echo "Creating virtual disk image"
qemu-img create -f raw "$hdImage" "$hdSize"

# Fire up a VM to install arch, using downloaded ISO and generated disk image
echo "Running expect script"
./qemu-arch-x86_64-expect.sh "$isoImage" "$hdImage"
#qemu-system-x86_64 -cdrom "$isoImage" -cpu qemu64 -m 2048 -drive file="$hdimage",format=raw,if=virtio -nic user,model=virtio-net-pci
#qemu-system-x86_64 -cpu qemu64 -m 2048 -drive file=archlinux-x86_64.img,format=raw,if=virtio -nic user,model=virtio-net-pci
