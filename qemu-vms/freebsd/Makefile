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

# We need a target to determine the latest release version of FreeBSD
# This is a nuisance because there may be a beta version that is newer than the current release
# EG:
# We grab contents of https://download.freebsd.org/releases/amd64/amd64/ISO-IMAGES:
#
# 12.4/
# 13.2/
# 13.3/
# 14.0/
# 14.1/
#
# But if we list contents of https://download.freebsd.org/releases/amd64/amd64/ISO-IMAGES/14.1, we see it is a beta:
# FreeBSD-14.1-BETA1-amd64-memstick.img.xz
#
# So we need to fall back on the previous 14.0 version:
# FreeBSD-14.0-RELEASE-amd64-memstick.img.xz
#
# Eventually, the 14.1 beta will be replaced by a release, and the script will use that instead if 14.0

# URL to get available versions of FreeBSD
AMD64_ISO_BASE_URL := https://download.freebsd.org/releases/amd64/amd64/ISO-IMAGES

# Define a script to get the latest x86 RELEASE version
define AMD64_GET_RELEASE
for version in $$(curl -sL $(AMD64_ISO_BASE_URL) | grep '<a href="[0-9]' | sed -r 's,.*href="([^/]*)/.*,\1,' | sort -rV); do \
	[ $$(curl -sL $(AMD64_ISO_BASE_URL)/$$version | grep 'href="FreeBSD.*RELEASE' | wc -l) -gt 0 ] || continue; \
	echo $$version; \
	break; \
done
endef

# Define release vars
AMD64_RELEASE       := $(shell $(AMD64_GET_RELEASE))
AMD64_RELEASE_F     := .amd64.release
AMD64_XZ_URL        := $(AMD64_ISO_BASE_URL)/$(AMD64_RELEASE)/FreeBSD-$(AMD64_RELEASE)-RELEASE-amd64-memstick.img.xz
AMD64_MEMSTICK      := .amd64-memstick.img
AMD64_XZ_MEMSTICK   := $(AMD64_MEMSTICK).xz
AMD64_XZ_CKSUM_URL  := $(AMD64_ISO_BASE_URL)/$(AMD64_RELEASE)/CHECKSUM.SHA512-FreeBSD-$(AMD64_RELEASE)-RELEASE-amd64
AMD64_XZ_CKSUM      := .amd64.sha512
AMD64_XZ_CKSUM_GEN  := $(AMD64_XZ_CKSUM).gen
AMD64_XZ_CKSUM_CMP  := $(AMD64_XZ_CKSUM).cmp
AMD64_MEMSTICK_BOOT := .amd64.boot.img
AMD64_MEMSTICK_CONF := .amd64.conf
AMD64_MEMSTICK_TEST := .amd64.test

# Define other vars
COMMA                        := ,
QEMU_ACCEL_HVF               := $(shell qemu-system-x86_64 -accel help | grep hvf)
QEMU_ACCEL_WHPX              := $(shell qemu-system-x86_64 -accel help | grep whpx)
QEMU_ACCEL_KVM               := $(shell qemu-system-x86_64 -accel help | grep kvm)
QEMU_ACCEL                   := $(if $(QEMU_ACCEL_HVF),hvf,$(if $(QEMU_ACCEL_WHPX),whpx$(COMMA)kernel-irqchip=off,$(if $(QEMU_ACCEL_KVM),kvm,tcg)))
AMD64_IMAGE_INSTALL          := amd64.install.img
AMD64_IMAGE_TEST             := amd64.test.img

# Silent by default
# Run "make VERBOSE=1 ..." to show output of each recipe invoked
ifndef VERBOSE
.SILENT:
endif

# Default target
.PHONY: all
all: generate-release $(AMD64_MEMSTICK_TEST)

# Generate the release file if:
# - It does not exist
# - It contains a different version that the current one
.PHONY: generate-release
generate-release:
	[ -f "$(AMD64_RELEASE_F)" -a "`cat "$(AMD64_RELEASE_F)" 2> /dev/null`" = "$(AMD64_RELEASE)" ] || echo "$(AMD64_RELEASE)" > "$(AMD64_RELEASE_F)"

# Download latest image if we don't have it
$(AMD64_XZ_MEMSTICK): $(AMD64_RELEASE_F)
	echo "Downloading the $(AMD64_RELEASE) compressed memstick image"
	curl --progress-bar -Lo $@ $(AMD64_XZ_URL)

# Download latest image checksum if we don't have it
$(AMD64_XZ_CKSUM): $(AMD64_XZ_MEMSTICK)
	echo "Downloading checksum"
	curl -sLo - $(AMD64_XZ_CKSUM_URL) | grep amd64-memstick.img.xz | awk '-F=' '{print $$2}' | tr -d ' ' > $@

# Generate a checksum to compare against downloaded checksum
$(AMD64_XZ_CKSUM_GEN): $(AMD64_XZ_CKSUM)
	echo "Generating checksum"
	sha512sum -b $(AMD64_XZ_MEMSTICK) | awk '{print $$1}' > $@

# Compare checksums
$(AMD64_XZ_CKSUM_CMP): $(AMD64_XZ_CKSUM) $(AMD64_XZ_CKSUM_GEN)
	echo "Comparing checksums"
	diff $^ > /dev/null || { \
	  echo "Downloaded checksum does not match generated checksum"; \
	  exit 1; \
	}
	touch $@

# Decompress image
# For some reason, we need to touch the extracted file after extracting it, to ensure it has a date newer than
# the prerequisite. Otherwise, it keeps extracting.
$(AMD64_MEMSTICK): $(AMD64_XZ_CKSUM_CMP)
	echo "Extracting memstick image"
	xz --verbose -kd $@.xz
	touch $@

# Make a copy of the decompressed memstick image every time it is extracted or bootstrap.sh is modified
$(AMD64_MEMSTICK_BOOT): $(AMD64_MEMSTICK) bootstrap.sh
	echo "Copying memstick image for manual modification"
	cp $< $@

# Create the install image
$(AMD64_IMAGE_INSTALL):
	qemu-img create -f raw $@ 8G

# Modify the memstick image to install bootstrap.sh script
# The target file is not created by make - it is created by bootstrap.sh as last command, but only if it succeeds
$(AMD64_MEMSTICK_CONF): $(AMD64_MEMSTICK_BOOT) $(AMD64_IMAGE_INSTALL) bootstrap-setup.sh setup.sh
	echo '1. Remount root as read/write:'
	echo 'mount -u -w /'
	echo
	echo '2. Get network up'
	echo 'dhclient vtnet0'
	echo
	echo '3. Download bootstrap script:'
	echo 'echo "get bootstrap.sh" | tftp 10.0.2.2'
	echo
	echo '4. Run bootstrap.sh:'
	echo 'sh /bootstrap.sh'
	echo
	qemu-system-x86_64 \
	  -accel "$(QEMU_ACCEL)" \
	  -boot c \
	  -cpu qemu64 \
	  -m 1024 \
	  -drive file=$(AMD64_MEMSTICK_BOOT),format=raw,if=virtio \
	  -drive file=$(AMD64_IMAGE_INSTALL),format=raw,if=virtio \
	  -nic user,model=virtio-net-pci,tftp=.
	touch $@

$(AMD64_IMAGE_TEST):
	qemu-img create -f raw $@ 8G

# Run the target image with real world devices, to manually test installing to another drive
$(AMD64_MEMSTICK_TEST): $(AMD64_MEMSTICK_CONF) $(AMD64_IMAGE_TEST)
	qemu-system-x86_64 \
	  -accel "$(QEMU_ACCEL)" \
	  -boot c \
	  -cpu qemu64 \
	  -m 1024 \
	  -drive file=$(AMD64_IMAGE_INSTALL),format=raw,if=none,id=disk0 \
	  -drive file=$(AMD64_IMAGE_TEST),format=raw,if=none,id=disk1 \
		-device ich9-ahci,id=ahci \
		-device ide-hd,drive=disk0,bus=ahci.0 \
		-device ide-hd,drive=disk1,bus=ahci.1 \
	  -nic user,model=e1000,net=192.168.0.0/24,dhcpstart=192.168.0.1 \
	  -nic user,model=rtl8139,net=192.168.1.0/24,dhcpstart=192.168.1.1
	touch $@

.PHONY: clean
clean:
	find . -maxdepth 1 -type f -name '*FreeBSD*' -print0 | xargs -0 rm;

.PHONY: push
push:
	git add -A
	git commit -m Changes
	git push

.PHONY: vars
vars:
	echo "AMD64_ISO_BASE_URL    = $(AMD64_ISO_BASE_URL)"
	echo "AMD64_RELEASE         = $(AMD64_RELEASE)"
	echo "AMD64_XZ_URL          = $(AMD64_XZ_URL)"
	echo "AMD64_MEMSTICK        = $(AMD64_MEMSTICK)"
	echo "AMD64_XZ_MEMSTICK     = $(AMD64_XZ_MEMSTICK)"
	echo "AMD64_XZ_CKSUM_URL    = $(AMD64_XZ_CKSUM_URL)"
	echo "AMD64_XZ_CKSUM        = $(AMD64_XZ_CKSUM)"
	echo "AMD64_XZ_CKSUM_GEN    = $(AMD64_XZ_CKSUM_GEN)"
	echo "AMD64_XZ_CKSUM_CMP    = $(AMD64_XZ_CKSUM_CMP)"
	echo "AMD64_MEMSTICK_CONF   = $(AMD64_MEMSTICK_CONF)"
	echo "AMD64_MEMSTICK_TEST   = $(AMD64_MEMSTICK_TEST)"
	echo "QEMU_ACCEL_HVF        = $(QEMU_ACCEL_HVF)"
	echo "QEMU_ACCEL_WHPX       = $(QEMU_ACCEL_WHPX)"
	echo "QEMU_ACCEL_KVM        = $(QEMU_ACCEL_KVM)"
	echo "QEMU_ACCEL            = $(QEMU_ACCEL)"
	echo "AMD64_IMAGE_INSTALL   = $(AMD64_IMAGE_INSTALL)"
	echo "AMD64_IMAGE_TEST      = $(AMD64_IMAGE_TEST)"
