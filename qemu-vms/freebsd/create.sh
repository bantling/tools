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

The latest installer and B2 checksum will be copied into the current directory as freebsd-x86_64.iso, and
freebsd-x86_64.iso.b2sum. An additional file freebsd-x86_64.iso.b2sum.gen contains the generated checksum for
comparison. If this script is run again, the latest checksum is downloaded, and if it differs from the previously
generated sum, it is assumed that a new installer is available. The local iso and checksum are replaced with a new
download, and a new generated checksum is compared.

A user named user is created that can use sudo to run any command, where sudo will require entering the password for
user. Both root and user have a 16 character crytoprahically generated random password, which are stored in a file
called {hdImage}.pwd. Every time this script is run with the same image name, a new {hdImage}.pwd is generated with
new passwords.

If the file \$HOME/.ssh/id_ecdsa.pub exists on the host, it is copied into the ~user/.ssh/authorized_keys file on the
image, where .ssh and .ssh/authorized_keys have correct privileges.

A /root/resize.sh script is installed that can automatically expand the last partition of a disk to the remaining space
on the disk, and if the partition has an ext4 filesystem, expand it to fill the partition. The partition may be mounted
or unmounted.

The script has a hard-coded mirror to download the iso from.
"
  exit
}

thisDir="`dirname "$0"`"

# hasExt status code is 0 if argument has at least one dot, 1 if it has no dots
# eg:
# hasExt archlinux.img returns 0
# hasExt archlinux     returns 1
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

# Get latest version number
latestVersion="`curl -so - "https://download.freebsd.org/releases/amd64/amd64/ISO-IMAGES/" | grep "<a href" | tail -n 1 | grep -Eo '([0-9.]*)' | head -n 1`"

# iso and checksum files
thisDir="`dirname "$0"`"
isoImage="$thisDir/FreeBSD-$latestVersion-RELEASE-amd64-disc1.iso"
isoDlSum="${isoImage}.sha512"
isoGenSum="${isoDlSum}.gen"

# Download iso if we don't have it
[ -f "$isoImage" ] || {
  echo "Removing any older iso images"
  rm -f FreeBSD*disc1.iso*

  echo "Downloading the $latestVersion ISO"
  curl --pregress-bar -so - "https://download.freebsd.org/releases/amd64/amd64/ISO-IMAGES/$latestVersion/FreeBSD-$latestVersion-RELEASE-amd64-disc1.iso.xz" | xz -d - > "$isoImage"
}

# Download the checksum if we don't have it
[ -f "$isoDlSum" ] || {
  echo "Downloading the $latestVersion checksum"
  curl -so - "https://download.freebsd.org/releases/amd64/amd64/ISO-IMAGES/$latestVersion/CHECKSUM.SHA512-FreeBSD-$latestVersion-RELEASE-amd64" | grep disc1.iso.xz | awk '-F=' '{print $2}' | tr -d ' '
}

# Generate our own sha512 checksum for comparison
[ -f "$isoGenSum" ] || {
  sha512sum -b "$isoImage" | awk '{print $1}' > "$isoGenSum"
}

diff "$isoDlSum" "$isoGenSum" > /dev/null || {
  echo "Downloaded checksum does not match generated checksum"
  exit 1
}

echo "here"
exit

# Create a disk image to install arch into. Recreate each time in case a previous run failed.
echo -e "\nCreating virtual disk image"
qemu-img create -f raw "$hdImage" "$hdSize"

# Generate pwd file
echo -e "\nCreating password file"
echo -e "root:$rootPwd\nuser:$userPwd" > "$hdPwd"

# Generate base64 coded string of resize.sh script
resizeScript="`base64 -i "${thisDir}/resize.sh"`"

# Fire up a VM to install arch, using downloaded ISO, generated disk image, and generated extra files image
echo -e "\nRunning expect script"
"${thisDir}"/expect.sh "$isoImage" "$hdImage" "$rootPwd" "$userPwd" "$resizeScript" $sshPubKey
