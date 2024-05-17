#!/bin/sh
set -eu

# Remount root fs read/write - we always need this, as we always download latest setup.sh script
mount -u -w /

# Check if /etc/rc.local runs this script automatically at boot
grep -q bootstrap.sh /etc/rc.local || {
  # Inform user
  echo 'Ensuring bootstrap.sh runs automatically at boot'

  # Modify /etc/rc.local
  sed -rie '1s,(.*),\1\n\nsh /bootstrap.sh\nexit,' /etc/rc.local
}

# Get network running, this script only ever runs in QEMU with a single virtio nic
dhclient vtnet0

# Download setup.sh script, in case it has changed
echo 'Downloading latest setup.sh'
(printf "GET /bantling/tools/master/qemu-vms/freebsd/setup.sh HTTP/1.0\r\nHOST: raw.githubusercontent.com\r\n\r\n"; sleep 2) | openssl s_client -connect raw.githubusercontent.com:443 -quiet | sed -n '/#!/,$p' > /setup.sh

# Execute setup script
echo 'Executing setup.sh'
sh /setup.sh

echo 'Copying setup.sh and base and kernel sets to new zfs filesystem'
cp /setup.sh /tmp/zfs
chmod +x /tmp/zfs/setup.sh

mkdir -p /tmp/zfs/usr/freebsd-dist
cp /usr/freebsd-dist/base.txz /tmp/zfs/usr/freebsd-dist
cp /usr/freebsd-dist/kernel.txz /tmp/zfs/usr/freebsd-dist

# Shut down
echo 'Shutting down'
poweroff
