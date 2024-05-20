#!/bin/sh
set -eu

# Remount root fs read/write - we always need this, as we always download latest bootstrap-setup.sh script
echo "Remounting / read/write"
mount -u -w /

# Get network running, this script only ever runs in QEMU with a single virtio nic
# Ignore errors, as it is probably due to user manually bringing up the interface to download this script
echo "Bringing up vtnet0"
dhclient vtnet0 || :

# Download bootstrap-setup.sh
echo "Downloading bootstrap.sh"
echo "get bootstrap-setup.sh" | tftp 10.0.2.2

# Run bootstrap-setup.sh
echo "Executing bootstrap.sh"
sh /bootstrap-setup.sh

# Shut down
echo 'Shutting down'
poweroff
