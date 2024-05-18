#!/bin/sh
set -eu

# Remount root fs read/write - we always need this, as we always download latest bootstrap-setup.sh script
mount -u -w /

# Get network running, this script only ever runs in QEMU with a single virtio nic
# Ignore errors, as it is probably due to user manually bringing up the interface to download this script
dhclient vtnet0 || :

# Download bootstrap-setup.sh
echo "get bootstrap-setup.sh" | tftpd 10.0.2.2

# Run bootstrap-setup.sh
sh /bootstrap-setup.sh

# Shut down
echo 'Shutting down'
poweroff
