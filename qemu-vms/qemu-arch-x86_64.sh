#!/bin/zsh
set -eu

# Script to setup an Arch Linux x86_86 virtual image by scripting an ISO installer via the emulated serial port with an expect script

usage() {
  [ -z "$1" ] || { echo -e "\nERROR: $1\n" }

  echo "$0: [ -n hdImage ] [-e {extraFile}+ ] [-p {extraPackage}+ ] [-s hdSize ] [ -zfs ] [ -expand ]

Arguments must be provided in above order.

Generates a bootable Arch Linux x86_64 virtual image named {hdImage} using qemu. If hdImage already has one or more
extensions, it is used as is, else the extension img is added. If hdImage exists, it is overwritten with a new blank
image after verifying with a prompt.

If one or more extraFiles are provided, they are added to the generated image at /install, otherwise there is no
/install dir.

-n hdImage: The name of the image to generate. The default name is archlinux-x86_64.img.

-e extraFile(s): Optional additional files to place in /install.

-p extraPackage(s): Optional additional packages to install above minimum requried to boot and use networking

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
set -A extraFiles
[[ ! -v 1 ]] || [ "$1" != "-e" ] || {
  [[ -v 2 ]] || {
    usage "-e must be followed by at least one extra file"
  }

  shift

  while [[ -v 1 ]] && [ "$1" != "-p" -a "$1" != "-s" -a "$1" != "-zfs" -a "$1" != "-expand" ]; do {
    [ -f "$1" ] || usage "-e: file \"$1\" does not exist"
    extraFiles+="$1"
    shift
  }; done
}

# Are there extra packages?
set -A extraPackages
[[ ! -v 1 ]] || [ "$1" != "-p" ] || {
  [[ -v 2 ]] || {
    usage "-p must be followed by at least one extra package"
  }

  shift

  while [[ -v 1 ]] && [ "$1" != "-s" -a "$1" != "-zfs" -a "$1" != "-expand" ]; do {
    extraPackages+="$1"
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

# Are we copying an expand script into the image?
expand=0
[[ ! -v 1 ]] || [ "$1" != "-expand" ] || {
  expand=1
  shift
}

# Any more parameters are an error
[ "$#" -eq 0 ] || {
  usage "Unrecognized parameters: $@"
}

# Generate a disk image name to contain the extra files
extraImage=""
[ ${#extraFiles[@]} -eq 0 ] || {
  extraImage="`echo -n "$hdImage" | awk -F. '{print $1}'`-extra.img"
}

# Ensure that the extraImage was not listed in the extra files.
# Calculate size of any extra files to add to the image size.
extraFileSize=0
for f in ${extraFiles}; do
  [ "$f" != "$extraImage" ] || {
    usage "-e cannot specify the extra file disk image $extraImage"
  }

  ((extraFileSize += `du -k "$f" | awk '{print $1}'`))
done

# Round up extraFileSize to a multiple of 4K to be safe
[ $((extraFileSize % 4)) -eq 0 ] || {
  ((extraFileSize = (extraFileSize / 4 + 1) * 4))
}

# The minimum size for OSX to partition a FAT filesystem is more than 32MB (33MB fails, 34MB is ok).
# Make sure it is at least 64MB (65536K) just to be safe.
extraImageSize=$extraFileSize
[ $extraImageSize -eq 0 -o $extraImageSize -ge 65536 ] || {
  extraImageSize=65536
}

# iso and checksum files
isoImage="/tmp/archlinux-x86_64.iso"
isoDlSum="/tmp/archlinux-x86_64.iso.b2sum"
isoGenSum="${isoDlSum}.gen"

# Display parameters, ask user to confirm
echo -n "Parameters:
hdImage        = ${hdImage}`[ ! -f ${hdImage} ] || echo -n ' (overwrite)'`
hdSize         = ${hdSize}"

[ -z "$extraImage" ] || echo -n "
extraImage     = ${extraImage}
extraFiles     = ${extraFiles}
extraFileSize  = ${extraFileSize}K (added to hdSize to ensure image is large enough for extraFiles)
extraPackages  = ${extraPackages}
extraImageSize = ${extraImageSize}K (minimum 65536K for partitioning)"

echo "
zfs            = `yn ${zfs}`
expand         = `yn ${expand}`
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
echo -e "\nCreating virtual disk image"
qemu-img create -f raw "$hdImage" "$hdSize"

[ ${extraFileSize} -eq 0 ] || {
  echo -e "\nAdding ${extraFileSize}K to disk image for extra files"
  qemu-img resize -f raw "$hdImage" "+${extraFileSize}K"

  echo -e "\nCreating extra file disk image"
  qemu-img create -f raw "$extraImage" "$((extraImageSize + 64))K"

  echo -e "\nCreating a FAT filesystem in extra file disk image"
  extraDev="`hdiutil attach -nomount ${extraImage} | tr -d " \t"`"
  diskutil partitionDisk "$extraDev" MBR FAT32 EXTRA_FILES R
  extraMountPoint="`diskutil info "${extraDev}s1" | grep "Mount Point" | awk '{print $3}'`"

  echo -en "\nCopying extra files into extra file disk image"
  for f in ${extraFiles}; do
    cp "$f" "$extraMountPoint"
    echo -n "."
  done
  echo

  echo -e "\nUnmounting extra file disk image"
  hdiutil detach "${extraDev}"
}

# Fire up a VM to install arch, using downloaded ISO and generated disk image
echo -e "\nRunning expect script"
if [ -z "$extraImage" ]; then
  ./qemu-arch-x86_64-expect.sh "$isoImage" "$hdImage"
else
  ./qemu-arch-x86_64-expect.sh "$isoImage" "$hdImage" "$extraImage"
fi
#qemu-system-x86_64 -cdrom "$isoImage" -cpu qemu64 -m 2048 -drive file="$hdimage",format=raw,if=virtio -nic user,model=virtio-net-pci
#qemu-system-x86_64 -cpu qemu64 -m 2048 -drive file=archlinux-x86_64.img,format=raw,if=virtio -nic user,model=virtio-net-pci
