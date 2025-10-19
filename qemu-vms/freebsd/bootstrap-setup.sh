#!/bin/sh
set -eu

# Check if the /boot/loader.conf file has an entry for setting the autoboot delay to 1
grep -q autoboot_delay /boot/loader.conf || {
  # Inform user
  echo 'Setting autoboot delay to 1 second'
  sleep 1

  # Modify boot loader
  echo 'autoboot_delay="1"' >> /boot/loader.conf

  # Don't bother rebooting, setup.sh will do that
}

# Check if /etc/rc.local runs this script automatically at boot
grep -q bootstrap.sh /etc/rc.local || {
  # Inform user
  echo 'Ensuring bootstrap.sh runs automatically at boot'
  sleep 1

  # Modify /etc/rc.local
  sed -rie '1s,(.*),\1\n\nsh /bootstrap.sh\nexit,' /etc/rc.local

  # Don't bother rebooting, setup.sh will do that
}

# Download setup.sh script, in case it has changed
echo 'Downloading latest setup.sh'
sleep 1
echo "get setup.sh" | tftp 10.0.2.2

# Execute setup script
echo 'Executing setup.sh (no swap, poolname = zinstall, autologin)'
sleep 1
sh /setup.sh ada1 -n -p zinstall -a

# Auto login as root
echo 'Autologin as root'
sleep 1
echo '/bin/sh' >> /tmp/zfs/etc/rc.local
chmod +x /tmp/zfs/etc/rc.local

# Shut down
echo 'Shutting down'
poweroff
