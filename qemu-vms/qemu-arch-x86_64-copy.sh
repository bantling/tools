#!/bin/zsh

# Script does not use set -eu due to technical considerations of using timeout to use ssh commands and status of result

# Must provide a file to copy
usage() {
  [ "$#" -eq 0 ] || echo -e "error: $1\n\n"

  echo "$0: srcFile tgtFile vmImage [ userName ]

  Copies srcFile to vmImage as tgtFile via scp connecting as userName. If userName is not provided, it defaults to user.
  QEMU is launched for the given vmImage, using virtio drivers for disk and networking.
  Host port 9999 is mapped to guest port 22.
  The qemu monitor is used to shut down, due to likely event that userName cannot shut down without a password.
  The name of the socket used for the monitor is qemu-monitor-{vmImage}-socket.
  "

  exit 1
}

[ "$#" -eq 0 ] && usage "srcFile is required"
srcFile="$1"
[ -f "$srcFile" ] || usage "file $srcFile does not exist, or is not a file"
shift

[ "$#" -eq 0 ] && usage "tgtFile is required"
tgtFile="$1"
shift

[ "$#" -eq 0 ] && usage "vmImage is required"
vmImage="$1"
[ -f "$vmImage" ] || usage "vmImage file $vmImage does not exist, or is not a file"
shift

userName=user
if [ "$#" -gt 0 ]; then
  userName="$1"
  shift
fi

socket="qemu-monitor-${vmImage}-socket"

# Start qemu with freshly created image
echo "Starting up guest"
qemu-system-x86_64 -cpu qemu64 -m 2048 -drive file=archlinux-x86_64.img,format=raw,if=virtio -nic user,model=virtio-net-pci,hostfwd=tcp::9999-:22 -monitor unix:${socket},server,nowait -nographic > /dev/null 2> /dev/null &
QEMU_PID=$!
echo QEMU PID = $QEMU_PID

# Keep trying to upload resize script until it succeeds, maximum wait of 2 minutes, which is 120 seconds / 5 seconds per try = 24 tries
echo -n "Waiting for SSH to copy file "
TRIES_LEFT=24
while [ "$TRIES_LEFT" -gt 0 ]; do
  echo -n "."
  sleep 5
  timeout 5 scp -o "UserKnownHostsFile=/dev/null" -o "StrictHostKeyChecking=no" -P 9999 ${srcFile} ${userName}@localhost:${tgtFile} > /dev/null 2> /dev/null
  if [ "$?" -eq 0 ]; then
    echo " copied"
    break
  fi

  ((TRIES_LEFT--))
done

# Shut down whether it copied or not
echo "system_powerdown" | socat - unix-connect:${socket} > /dev/null 2> /dev/null

# Keep checking that qemu has quit untl it succeeds, maximum wait of 1 minute
echo -n "Waiting for guest to quit "
TRIES_LEFT=60
while [ "$TRIES_LEFT" -gt 0 ]; do
  echo -n "."
  sleep 1
  ps -a $QEMU_PID > /dev/null 2> /dev/null
  if [ "$?" -eq 1 ]; then
    echo " done"
    break
  fi

  ((TRIES_LEFT--))
done

# Kill qemu if still running, must not be stopping for some reason
kill -9 $QEMU_PID > /dev/null 2> /dev/null
