# // SPDX-License-Identifier: Apache-2.0

# Build a FreeBSD x86_64 bootable image with the following basic steps:
# - Determine latest release of FreeBSD memstick image
# - Download latest release and hash file
# - Use packer to automate basic install steps
#   - Verify known hash of memstick image matches generated hash of memstick image
#   - Create target raw formatted image
#   - Use QEMU to launch a VM with one of mac (hvf), windows (whpx,kernel-irqchip=off), linux (kvm), or none (tcg) accelerators
#   - Boot up and enter shell
#   - Execute a provided shell script
#     - Set kernel tuning params for podman network performance
#       - /boot/loader.conf:
#         - hw.vtnet.X.csum_disable=1
#         - hw.vtnet.lro_disable=1
#       - /etc/sysctl.conf:
#         - net.link.bridge.pfil_member=0
#         - net.link.bridge.pfil_bridge=0
#         - net.link.bridge.pfil_onlyip=0
#       - /etc/rc.local:
#         - ifconfig vtnet0 -rxcsum
#   - Set boot delay to 1 second
#     - /boot/loader.conf:
#       - autoboot_delay="1"
#   - Enable gpt labels and ids to show under /dev/gpt and /dev/gptid
#     - /boot/loader.conf:
#       - kern.geom.label.disk_ident.enable="0"
#       - kern.geom.label.gpt.enable="1"
#       - kern.geom.label.gptid.enable="1"
#   - Create boot and zfs filesystems
#   - Set zfs ashift = 12
#   - Use a zvol for swap
#   - Install a base system (base, kernel)
#   - Set hostname, timezone, and DHCP
#   - Install podman

.PHONY: download-latest-amd64
download-latest-amd64:
	./download-latest-amd64.sh
