#!/bin/sh
set -eu

# Check if /etc/rc.local runs this script automatically at boot
grep -q bootstrap.sh /etc/rc.local || {
  # Inform user
  echo 'Ensuring bootstrap.sh runs automatically at boot'

  # Modify /etc/rc.local
  sed -rie '1s,(.*),\1\n\nsh /bootstrap.sh\nexit,' /etc/rc.local

  # Don't bother rebooting, setup.sh will do that
}

# Download setup.sh script, in case it has changed
echo 'Downloading latest setup.sh'
echo "get setup.sh" | tftp 10.0.2.2

# Execute setup script
echo 'Executing setup.sh'
sh /setup.sh vtbd1 -n

# If this is first time running setup.sh, it reboots, and this code does not execute until next boot
echo 'Copying setup.sh and base and kernel sets to new zfs filesystem'
cp /setup.sh /tmp/zfs
chmod +x /tmp/zfs/setup.sh

mkdir -p /tmp/zfs/usr/freebsd-dist
cp /usr/freebsd-dist/base.txz /tmp/zfs/usr/freebsd-dist
cp /usr/freebsd-dist/kernel.txz /tmp/zfs/usr/freebsd-dist

# Shut down
echo 'Shutting down'
poweroff
