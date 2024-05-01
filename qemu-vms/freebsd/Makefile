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

COMMA                        := ,
QEMU_ACCEL_HVF               := $(shell qemu-system-x86_64 -accel help | grep hvf)
QEMU_ACCEL_WHPX              := $(shell qemu-system-x86_64 -accel help | grep whpx)
QEMU_ACCEL_KVM               := $(shell qemu-system-x86_64 -accel help | grep kvm)
QEMU_ACCEL                   := $(if $(QEMU_ACCEL_HVF),hvf,$(if $(QEMU_ACCEL_WHPX),whpx$(COMMA)kernel-irqchip=off,$(if $(QEMU_ACCEL_KVM),kvm,tcg)))
ISO_BASE_URL_AMD64           := https://download.freebsd.org/releases/amd64/amd64/ISO-IMAGES
LATEST_AMD64_VERSION         := $(shell curl -so - $(ISO_BASE_URL_AMD64)/ | grep "<a href" | tail -n 1 | grep -Eo "[0-9.]*" | head -n 1)
LATEST_AMD64_MEMSTICK        := FreeBSD-$(LATEST_AMD64_VERSION)-RELEASE-amd64-memstick.img
LATEST_AMD64_XZ_MEMSTICK     := $(LATEST_AMD64_MEMSTICK).xz
LATEST_AMD64_XZ_URL          := $(ISO_BASE_URL_AMD64)/$(LATEST_AMD64_VERSION)/$(LATEST_AMD64_XZ_MEMSTICK)
LATEST_AMD64_CKSUM           := .$(LATEST_AMD64_XZ_MEMSTICK).sha512
LATEST_AMD64_CKSUM_URL       := $(ISO_BASE_URL_AMD64)/$(LATEST_AMD64_VERSION)/CHECKSUM.SHA512-FreeBSD-$(LATEST_AMD64_VERSION)-RELEASE-amd64
LATEST_AMD64_CKSUM_GEN       := $(LATEST_AMD64_CKSUM).gen
LATEST_AMD64_CKSUM_CMP       := $(LATEST_AMD64_CKSUM).cmp
LATEST_AMD64_MEMSTICK_SERIAL := .$(LATEST_AMD64_MEMSTICK).serial
IMAGE_AMD64                  := FreeBSD-$(LATEST_AMD64_VERSION).img
IMAGE_AMD64_INSTALL          := .$(IMAGE_AMD64).install

# Silent by default
# Run "make VERBOSE=1 ..." to show output of each recipe invoked
ifndef VERBOSE
.SILENT:
endif

# Default target
.PHONY:
all: $(IMAGE_AMD64_INSTALL)

# Download latest image if we don't have it
$(LATEST_AMD64_XZ_MEMSTICK):
	echo "Removing older images"; \
	find . -maxdepth 1 -type f -name 'FreeBSD-*-RELEASE-amd64-memstick.img*' -print0 | xargs -0 rm; \
	echo "Downloading the $(LATEST_AMD64_VERSION) image"; \
	curl --progress-bar -LO $(LATEST_AMD64_XZ_URL)

# Download latest image checksum if we don't have it
$(LATEST_AMD64_CKSUM): $(LATEST_AMD64_XZ_MEMSTICK)
	echo "Downloading checksum"; \
	curl -sLo - $(LATEST_AMD64_CKSUM_URL) | grep amd64-memstick.img.xz | awk '-F=' '{print $$2}' | tr -d ' ' > $@

# Generate a checksum to compare against downloaded checksum
$(LATEST_AMD64_CKSUM_GEN): $(LATEST_AMD64_CKSUM)
	echo "Generating checksum"; \
	sha512sum -b $(LATEST_AMD64_XZ_MEMSTICK) | awk '{print $$1}' > $@

# Compare checksums
$(LATEST_AMD64_CKSUM_CMP): $(LATEST_AMD64_CKSUM) $(LATEST_AMD64_CKSUM_GEN)
	echo "Comparing checksums"; \
	diff $^ > /dev/null || { \
	  echo "Downloaded checksum does not match generated checksum"; \
	  exit 1; \
	}; \
	touch $@

# Decompress image
# For some reason, we need to touch the extracted file after extracting it, to ensure it has a date newer than
# the prerequisite. Otherwise, it keeps extracting.
$(LATEST_AMD64_MEMSTICK): $(LATEST_AMD64_CKSUM_CMP)
	echo "Extracting image"; \
	xz --verbose -kd $@.xz; \
	touch $@

# Modify the memstick image to enable serial port booting
$(LATEST_AMD64_MEMSTICK_SERIAL): $(LATEST_AMD64_MEMSTICK)
	echo '1. Remount root as read/write:'
	echo 'mount -u -w /'
	echo
	echo '2. Modify boot looader config:'
	echo 'vi /boot/loader.conf'
	echo 'Add the following lines to enable serial booting:'
	echo
	echo 'boot_multicons="YES"'
	echo 'boot_serial="YES"'
	echo 'comconsole_speed="115200"'
	echo 'console="comconsole,vidconsole"'
	echo
	echo 'Add the following lines to enable /dev/gpt and /dev/gptid:'
	echo 'kern.geom.label.disk_ident.enable="0"'
	echo 'kern.geom.label.gpt.enable="1"'
	echo 'kern.geom.label.gptid.enable="1"'
	echo
	echo '2. Disable booting up installer'
	echo 'vi /etc/rc.local'
	echo 'Add an exit command after comments'
	echo
	echo '3. Quit'
	echo 'poweroff'
	qemu-system-x86_64 \
	  -accel "$(QEMU_ACCEL)" \
	  -boot c \
	  -cpu qemu64 \
	  -m 1024 \
	  -drive file=$(LATEST_AMD64_MEMSTICK),format=raw,if=virtio
	touch $@

# Create the target image
$(IMAGE_AMD64): $(LATEST_AMD64_MEMSTICK_SERIAL)
	qemu-img create -f raw $@ 8G

# Run the memstick image with the target image to partition, format, and install FreeBSD as zfs root
$(IMAGE_AMD64_INSTALL): $(IMAGE_AMD64)
	./expect.sh "$(QEMU_ACCEL)" "$(LATEST_AMD64_MEMSTICK)" "$(IMAGE_AMD64)"
	#touch $@

# Run the above install target with a more convenient target name
.PHONY: install
install: $(IMAGE_AMD64_INSTALL)

# Run the target image, after ensuring it has been installed
.PHONY: run
run: $(IMAGE_AMD64)
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
	echo "QEMU_ACCEL_HVF               = $(QEMU_ACCEL_HVF)"
	echo "QEMU_ACCEL_WHPX              = $(QEMU_ACCEL_WHPX)"
	echo "QEMU_ACCEL_KVM               = $(QEMU_ACCEL_KVM)"
	echo "QEMU_ACCEL                   = $(QEMU_ACCEL)"
	echo "ISO_BASE_URL_AMD64           = $(ISO_BASE_URL_AMD64)"
	echo "LATEST_AMD64_VERSION         = $(LATEST_AMD64_VERSION)"
	echo "LATEST_AMD64_MEMSTICK        = $(LATEST_AMD64_MEMSTICK)"
	echo "LATEST_AMD64_XZ_MEMSTICK     = $(LATEST_AMD64_XZ_MEMSTICK)"
	echo "LATEST_AMD64_XZ_URL          = $(LATEST_AMD64_XZ_URL)"
	echo "LATEST_AMD64_CKSUM           = $(LATEST_AMD64_CKSUM)"
	echo "LATEST_AMD64_CKSUM_URL       = $(LATEST_AMD64_CKSUM_URL)"
	echo "LATEST_AMD64_CKSUM_GEN       = $(LATEST_AMD64_CKSUM_GEN)"
	echo "LATEST_AMD64_CKSUM_CMP       = $(LATEST_AMD64_CKSUM_CMP)"
	echo "LATEST_AMD64_MEMSTICK_SERIAL = $(LATEST_AMD64_MEMSTICK_SERIAL)"
	echo "IMAGE_AMD64                  = $(IMAGE_AMD64)"
	echo "IMAGE_AMD64_INSTALL          = $(IMAGE_AMD64_INSTALL)"
