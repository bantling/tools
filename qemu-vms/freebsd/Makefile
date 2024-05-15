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
ISO_BASE_URL_AMD64 := https://download.freebsd.org/releases/amd64/amd64/ISO-IMAGES

# Define a script to get the latest x86 RELEASE version
define GET_LATEST_AMD64_RELEASE
for version in $$(curl -sL $(ISO_BASE_URL_AMD64) | grep '<a href="[0-9]' | sed -r 's,.*href="([^/]*)/.*,\1,' | sort -rV); do \
	[ $$(curl -sL $(ISO_BASE_URL_AMD64)/$$version | grep 'href="FreeBSD.*RELEASE' | wc -l) -gt 0 ] || continue; \
	echo $$version; \
	break; \
done
endef

# Define release vars
LATEST_AMD64_RELEASE         := $(shell $(GET_LATEST_AMD64_RELEASE))
LATEST_AMD64_MEMSTICK        := FreeBSD-$(LATEST_AMD64_RELEASE)-RELEASE-amd64-memstick.img
LATEST_AMD64_MEMSTICK_F      := .$(LATEST_AMD64_MEMSTICK)
LATEST_AMD64_XZ_MEMSTICK     := $(LATEST_AMD64_MEMSTICK).xz
LATEST_AMD64_XZ_MEMSTICK_F   := .$(LATEST_AMD64_MEMSTICK).xz
LATEST_AMD64_XZ_URL          := $(ISO_BASE_URL_AMD64)/$(LATEST_AMD64_RELEASE)/$(LATEST_AMD64_XZ_MEMSTICK)
LATEST_AMD64_XZ_CKSUM_F      := .$(LATEST_AMD64_XZ_MEMSTICK).sha512
LATEST_AMD64_XZ_CKSUM_URL    := $(ISO_BASE_URL_AMD64)/$(LATEST_AMD64_RELEASE)/CHECKSUM.SHA512-FreeBSD-$(LATEST_AMD64_RELEASE)-RELEASE-amd64
LATEST_AMD64_XZ_CKSUM_GEN_F  := $(LATEST_AMD64_XZ_CKSUM_F).gen
LATEST_AMD64_XZ_CKSUM_CMP_F  := $(LATEST_AMD64_XZ_CKSUM_F).cmp
LATEST_AMD64_MEMSTICK_CONF_F := $(LATEST_AMD64_MEMSTICK_F).conf

# Define other vars
COMMA                        := ,
QEMU_ACCEL_HVF               := $(shell qemu-system-x86_64 -accel help | grep hvf)
QEMU_ACCEL_WHPX              := $(shell qemu-system-x86_64 -accel help | grep whpx)
QEMU_ACCEL_KVM               := $(shell qemu-system-x86_64 -accel help | grep kvm)
QEMU_ACCEL                   := $(if $(QEMU_ACCEL_HVF),hvf,$(if $(QEMU_ACCEL_WHPX),whpx$(COMMA)kernel-irqchip=off,$(if $(QEMU_ACCEL_KVM),kvm,tcg)))
IMAGE_AMD64                  := FreeBSD-$(LATEST_AMD64_RELEASE).img
IMAGE_AMD64_PHYS             := FreeBSD-$(LATEST_AMD64_RELEASE).phys.img

# Silent by default
# Run "make VERBOSE=1 ..." to show output of each recipe invoked
ifndef VERBOSE
.SILENT:
endif

# Default target
.PHONY: all
all: $(LATEST_AMD64_MEMSTICK_CONF_F)

# Download latest image if we don't have it
$(LATEST_AMD64_XZ_MEMSTICK_F):
	echo "Removing older images"; \
	find . -maxdepth 1 -type f -name '.FreeBSD-*-RELEASE-amd64-memstick.img*' \! -name '.FreeBSD-$(LATEST_AMD64_RELEASE)-RELEASE-amd64-memstick.img*' -print0 | xargs -0 rm; \
	echo "Downloading the $(LATEST_AMD64_RELEASE) image"; \
	curl --progress-bar -Lo $@ $(LATEST_AMD64_XZ_URL)

# Download latest image checksum if we don't have it
$(LATEST_AMD64_XZ_CKSUM_F): $(LATEST_AMD64_XZ_MEMSTICK_F)
	echo "Downloading checksum"; \
	curl -sLo - $(LATEST_AMD64_XZ_CKSUM_URL) | grep amd64-memstick.img.xz | awk '-F=' '{print $$2}' | tr -d ' ' > $@

# Generate a checksum to compare against downloaded checksum
$(LATEST_AMD64_XZ_CKSUM_GEN_F): $(LATEST_AMD64_XZ_CKSUM_F)
	echo "Generating checksum"; \
	sha512sum -b $(LATEST_AMD64_XZ_MEMSTICK_F) | awk '{print $$1}' > $@

# Compare checksums
$(LATEST_AMD64_XZ_CKSUM_CMP_F): $(LATEST_AMD64_XZ_CKSUM_F) $(LATEST_AMD64_XZ_CKSUM_GEN_F)
	echo "Comparing checksums"; \
	diff $^ > /dev/null || { \
	  echo "Downloaded checksum does not match generated checksum"; \
	  exit 1; \
	}; \
	touch $@

# Decompress image
# For some reason, we need to touch the extracted file after extracting it, to ensure it has a date newer than
# the prerequisite. Otherwise, it keeps extracting.
$(LATEST_AMD64_MEMSTICK_F): $(LATEST_AMD64_XZ_CKSUM_CMP_F)
	echo "Extracting image"; \
	xz --verbose -kd $@.xz; \
	touch $@

# Create the target images, always recreate them so we can keep running the process to test installation scripts
#.PHONY: $(IMAGE_AMD64) $(IMAGE_AMD64_PHYS)
$(IMAGE_AMD64) $(IMAGE_AMD64_PHYS): $(LATEST_AMD64_MEMSTICK_F)
	qemu-img create -f raw $@ 8G

# Modify the memstick image to install bootstrap.sh script
# vsftpd /Users/user/dev/homebrew/etc/vsftpd.conf
$(LATEST_AMD64_MEMSTICK_CONF_F): $(IMAGE_AMD64) $(IMAGE_AMD64_PHYS)
	echo '1. Remount root as read/write:'
	echo 'mount -u -w /'
	echo
	echo '2. Get network up'
	echo 'dhclient vtnet0'
	echo
	echo '3. Download bootstrap script:'
	echo "{printf \"GET /bantling/tools/master/qemu-vms/freebsd/bootstrap.sh HTTP/1.0\\\r\\\nHOST: raw.githubusercontent.com\\\r\\\n\\\r\\\n\"; sleep 2} | openssl s_client -connect raw.githubusercontent.com:443 -quiet | sed -n '/#\!/,\$p' > /bootstrap.sh"
	echo
	echo '4. Run bootstrap.sh:'
	echo 'sh /bootstrap.sh'
	echo
	qemu-system-x86_64 \
	  -accel "$(QEMU_ACCEL)" \
	  -boot c \
	  -cpu qemu64 \
	  -m 1024 \
	  -drive file=$(LATEST_AMD64_MEMSTICK_F),format=raw,if=virtio \
	  -drive file=$(IMAGE_AMD64),format=raw,if=virtio \
	  -drive file=$(IMAGE_AMD64_PHYS),format=raw,if=virtio \
	  -nic user,model=virtio-net-pci
	touch $@

# Run the target image, after ensuring it has been installed
.PHONY: run
run: $(LATEST_AMD64_MEMSTICK_CONF_F)
	qemu-system-x86_64 \
	  -accel "$(QEMU_ACCEL)" \
	  -boot c \
	  -cpu qemu64 \
	  -m 1024 \
	  -drive file=$(IMAGE_AMD64),format=raw,if=virtio \
	  -nic user,model=virtio-net-pci

.PHONY: clean
clean:
	find . -maxdepth 1 -type f -name 'FreeBSD-*-RELEASE-amd64-memstick.img*' -print0 | xargs -0 rm;

.PHONY: push
push:
	git add -A
	git commit -m Changes
	git push

.PHONY: vars
vars:
	echo "ISO_BASE_URL_AMD64           = $(ISO_BASE_URL_AMD64)"
	echo "LATEST_AMD64_RELEASE         = $(LATEST_AMD64_RELEASE)"
	echo "LATEST_AMD64_MEMSTICK        = $(LATEST_AMD64_MEMSTICK)"
	echo "LATEST_AMD64_MEMSTICK_F      = $(LATEST_AMD64_MEMSTICK_F)"
	echo "LATEST_AMD64_XZ_MEMSTICK     = $(LATEST_AMD64_XZ_MEMSTICK)"
	echo "LATEST_AMD64_XZ_MEMSTICK_F   = $(LATEST_AMD64_XZ_MEMSTICK_F)"
	echo "LATEST_AMD64_XZ_URL          = $(LATEST_AMD64_XZ_URL)"
	echo "LATEST_AMD64_XZ_CKSUM_F      = $(LATEST_AMD64_XZ_CKSUM_F)"
	echo "LATEST_AMD64_XZ_CKSUM_URL    = $(LATEST_AMD64_XZ_CKSUM_URL)"
	echo "LATEST_AMD64_XZ_CKSUM_GEN_F  = $(LATEST_AMD64_XZ_CKSUM_GEN_F)"
	echo "LATEST_AMD64_XZ_CKSUM_CMP_F  = $(LATEST_AMD64_XZ_CKSUM_CMP_F)"
	echo "LATEST_AMD64_MEMSTICK_CONF_F = $(LATEST_AMD64_MEMSTICK_CONF_F)"
	echo "QEMU_ACCEL_HVF               = $(QEMU_ACCEL_HVF)"
	echo "QEMU_ACCEL_WHPX              = $(QEMU_ACCEL_WHPX)"
	echo "QEMU_ACCEL_KVM               = $(QEMU_ACCEL_KVM)"
	echo "QEMU_ACCEL                   = $(QEMU_ACCEL)"
	echo "IMAGE_AMD64                  = $(IMAGE_AMD64)"
	echo "IMAGE_AMD64_PHYS             = $(IMAGE_AMD64_PHYS)"
