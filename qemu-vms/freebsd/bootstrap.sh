#!/bin/sh
set -eu

# Remount root fs read/write - we always need this, as we always download latest setup.sh script
mount -u -w /

# Ensure we have networking running
dhclient "`ifconfig -a | sed -r '/^\t/d;s/^([^:]*).*/\1/' | grep -v lo\"

# Do we need to reboot?
reboot=0

# Check if /boot/loader.conf contains lines for disk identification settings (not present by default)
grep -q 'kern.geom.label' /boot/loader.conf || {
  # We need to reboot for these settings to take effect
  reboot=1

  # Inform user
  echo 'Configuring gptid disk identification'

  # Append lines to the end
  {
    echo 'kern.geom.label.disk_ident.enable="0"'
    echo 'kern.geom.label.gpt.enable="0"'
    echo 'kern.geom.label.gptid.enable="1"'
  } >> /boot/loader.conf
}

# Check if /etc/rc.local runs this script automatically at boot
grep -q bootstrap.sh /etc/rc.local || {
  # Rebooting allows user to manually test this script launches automatically
  reboot=1

  # Inform user
  echo 'Ensuring bootstrap.sh runs automatically at boot'

  # Modify /etc/rc.local
  sed -rie '1s,(.*),\1\n\nsh /bootstrap.sh\nexit,' /etc/rc.local
}

# Reboot if necessary
[ "$reboot" -eq 0 ] || {
  # Inform user
  echo 'Rebooting'

  reboot
}

# Download setup.sh script, in case it has changed
echo 'Downloading latest setup.sh'
(printf "GET /bantling/tools/master/qemu-vms/freebsd/setup.sh HTTP/1.0\r\nHOST: raw.githubusercontent.com\r\n\r\n"; sleep 2) | openssl s_client -connect raw.githubusercontent.com:443 -quiet | sed -n '/#!/,$p' > /setup.sh

# Execute setup script
echo 'Executing setup.sh'
sh /setup.sh

# Shut down
poweroff
