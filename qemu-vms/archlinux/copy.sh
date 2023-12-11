#!/bin/zsh

# Script does not use set -eu due to technical considerations of using timeout to use ssh commands and status of result

# Must provide a file or dir to copy
usage() {
  [ "$#" -eq 0 ] || echo -e "error: $1\n\n"

  echo "$0: srcFile tgtFile vmImage [ userName ]
            srcDir  tgtDir  vmImage [ userName ]

  First form copies srcFile to vmImage as tgtFile via scp connecting as userName. The tgtFile must be a plain file name,
  not a path.

  Second form copies srcDir to vmImage as tgtDir via ssh connecting as userName. The tgtDir must be a plain dir name,
  not a path. The dir is tarred and compressed using xz compression on the source side, then decompressed and untarred
  on the server side.

  If userName is not provided, it defaults to user.

  QEMU is launched for the given vmImage, using virtio drivers for disk and networking. Host port 9999 is mapped to
  guest port 22.

  The qemu monitor is used to shut down, due to the likely event that userName cannot shut down without a password.
  The name of the socket used for the monitor is qemu-monitor-{vmImage}-socket.
  "

  exit 1
}

[ "$#" -eq 0 ] && usage "srcFile/srcDir is required"
srcFile="$1"
[ -f "$srcFile" -o -d "$srcFile" ] || usage "file/dir $srcFile does not exist, or is not a file/dir"
shift

[ "$#" -eq 0 ] && usage "tgtFile/tgtDir is required"
tgtFile="$1"
shift

[[ ! "$tgtFile" =~ / ]] || usage "target file/dir $tgtFile contains a /"

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
qemu-system-x86_64 -cpu qemu64 -m 2048 -drive "file=$vmImage",format=raw,if=virtio -nic user,model=virtio-net-pci,hostfwd=tcp::9999-:22 -monitor unix:${socket},server,nowait -nographic > /dev/null 2> /dev/null &
QEMU_PID=$!
echo QEMU PID = $QEMU_PID

# Wait for SSH to respond until it succeeds, maximum wait of 2 minutes, which is 120 seconds / 5 seconds per try = 24 tries
echo -n "Waiting for SSH to respond"
TRIES_LEFT=24
while [ "$TRIES_LEFT" -gt 0 ]; do
  echo -n "."
  sleep 5
  timeout 5 ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -p 9999 ${userName}@localhost "echo" > /dev/null 2> /dev/null
  if [ "$?" -eq 0 ]; then
    echo " responded"
    break
  fi

  ((TRIES_LEFT--))
done

[ "$TRIES_LEFT" -gt 0 ] || {
  echo " failed"
  exit 1
}

# If srcFile is a file, upload it via scp
if [ -f "$srcFile" ]; then
  echo -n "Waiting for scp to copy file:"
  scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -P 9999 "${srcFile}" ${userName}@localhost:"${tgtFile}" > /dev/null 2> /dev/null
  if [ "$?" -eq 0 ]; then
    echo " copied"
  else
    echo " failed"
  fi
else
  # If srcFile is a dir, upload via tar/ssh

  # If the source and target dir name are the same, then just untar.
  # If they are different, then use mv to rename dir to target dir name after untar completes.
  if [ "$srcFile" = "$tgtFile" ]; then
    cmd="tar -xJf -"
  else
    cmd='tar -xJf -; mv "'${srcFile}'" "'${tgtFile}'"'
  fi

  echo -n "Waiting for tar/ssh to copy dir "
  tar -cJf - "${srcFile}" | ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -p 9999 ${userName}@localhost "$cmd" > /dev/null 2> /dev/null
  if [ "$?" -eq 0 ]; then
    echo " copied"
  else
    echo " failed"
  fi
fi

# Shut down whether it copied or not
echo "system_powerdown" | socat - unix-connect:${socket} > /dev/null 2> /dev/null

# Keep checking that qemu has quit until it succeeds, maximum wait of 1 minute
echo -n "Waiting for guest to quit"
TRIES_LEFT=60
while [ "$TRIES_LEFT" -gt 0 ]; do
  echo -n "."
  sleep 1
  ps -a $QEMU_PID > /dev/null 2> /dev/null
  if [ "$?" -eq 1 ]; then
    echo " done"
    exit
  fi

  ((TRIES_LEFT--))
done

# Kill qemu if still running, must not be stopping for some reason
kill -9 $QEMU_PID > /dev/null 2> /dev/null
if [ "$?" -eq 0 ]; then
  echo " killed"
else
  echo " could not kill"
fi
