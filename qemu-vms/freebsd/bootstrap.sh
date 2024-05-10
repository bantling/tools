#!/bin/sh
set -eu

# Download setup.sh script, in case it has changed
echo 'Downloading latest setup.sh from github'
curl -o /root/setup.sh "https://github.com/bantling/tools/blob/master/qemu-vms/freebsd/setup.sh"

# Execute setup script
echo 'Executing setup.sh'
sh /root/setup.sh

# Shut down
poweroff
