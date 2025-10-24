# // SPDX-License-Identifier: Apache-2.0

# Build a FreeBSD x86_64 bootable image with the following basic steps:
# - Determine latest release of FreeBSD memstick image
# - Download latest release and hash file
# - Generate a hash file, and commpare against downloaded hash file
# - Make a copy of memstick image
# - MBR boot copy of memstick
# - Modify memstick image so that it has autologin, and a bootstrap script
# - Run bootstrap script to modify a second drive that is an installer
# - Auto powers off once installer is setup
# - MBR boot installer image to install into a test image
# - User manually runs installer, and powers off
# - EFI boot test image to verify it boots up, user can login on and poweroff

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
AMD64_MEMSTICK_INST := .amd64.inst
AMD64_MEMSTICK_TEST := .amd64.test
AMD64_OVMF_IMAGE    := scjalliance/ovmf-builder:stable202505
AMD64_OVMF_CODE     := .amd64.OVMF_CODE.fd
AMD64_OVMF_VARS     := .amd64.OVMF_VARS.fd

# Define other vars
COMMA                        := ,
QEMU_ACCEL_HVF               := $(shell qemu-system-x86_64 -accel help | grep hvf)
QEMU_ACCEL_WHPX              := $(shell qemu-system-x86_64 -accel help | grep whpx)
QEMU_ACCEL_KVM               := $(shell qemu-system-x86_64 -accel help | grep kvm)
QEMU_ACCEL                   := $(if $(QEMU_ACCEL_HVF),hvf,$(if $(QEMU_ACCEL_WHPX),whpx$(COMMA)kernel-irqchip=off,$(if $(QEMU_ACCEL_KVM),kvm,tcg)))
AMD64_IMAGE_INSTALL          := amd64.install.img
AMD64_IMAGE_TEST             := amd64.test.img
AMD64_IMAGE_TEST2            := amd64.test2.img

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
# By default, xz extracts the file using the date inside the archive.
# We need to update the extracted file to the current date to avoid always re-extracting.
$(AMD64_MEMSTICK): $(AMD64_XZ_CKSUM_CMP)
	echo "Extracting memstick image"
	xz --verbose -kfd $@.xz
	touch $@

# Make an installer copy of the decompressed memstick image every time it is extracted or bootstrap.sh is modified
$(AMD64_MEMSTICK_BOOT): $(AMD64_MEMSTICK) bootstrap.sh
	echo "Copying memstick image for manual modification"
	cp $< $@

# Create the install image
.PHONY: AMD64_IMAGE_INSTALL
$(AMD64_IMAGE_INSTALL):
	qemu-img create -f raw $@ 8G

# Modify the memstick image to install bootstrap.sh script
# The target file is not created by make - it is created by bootstrap.sh as last command, but only if it succeeds
$(AMD64_MEMSTICK_CONF): $(AMD64_MEMSTICK_BOOT) $(AMD64_IMAGE_INSTALL) bootstrap-setup.sh setup.sh
	echo
	echo '#### Configure copy of memstick image to auto install'
	echo
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
	  -cpu qemu64 \
	  -m 1024 \
	  -boot c\
	  -drive file=$(AMD64_MEMSTICK_BOOT),format=raw,id=disk0,cache=writeback,if=none \
	  -drive file=$(AMD64_IMAGE_INSTALL),format=raw,id=disk1,cache=writeback,if=none \
	  -device ahci,id=ahci \
	  -device ide-hd,drive=disk0,bus=ahci.0 \
	  -device ide-hd,drive=disk1,bus=ahci.1 \
	  -nic user,model=virtio-net-pci,tftp=.
	touch $@

.PHONY: $(AMD64_IMAGE_TEST)
$(AMD64_IMAGE_TEST):
	qemu-img create -f raw $@ 8G

# Install into a test image using the install image with real world devices, to manually test installing to another drive
# Touches both AMD64_MEMSTICK_CONF file and target file:
# - The AMD64_IMAGE_INSTALL is modified by the process of starting it up, as it is a regular read/write filesystem
# - Causes the AMD64_IMAGE_INSTALL to have a newer date than AMD64_MEMSTICK_CONF
# - Causes the AMD64_MEMSTICK_CONF target to re-execute on next make, since it is older than the AMD64_IMAGE_INSTALL prereq
# By touching the AMD64_MEMSTICK_CONF file after QEMU quits, it has a newer date than the AMD64_IMAGE_INSTALL prereq,
# which prevents endless make loop
$(AMD64_MEMSTICK_INST): $(AMD64_MEMSTICK_CONF) $(AMD64_IMAGE_TEST)
	echo
	echo '#### Use modified memstick image to auto install into a test image'
	echo
	echo 'When prompt appears, login as root (password toor) and run /setup.sh ada1'
	echo 'The default is to have swap, a label of hd, and name the pool zroot, you can run /setup.sh -d ada1 [ -l label ] [ -n ] [ -p poolname ] [ -a ]'
	echo "Where -l sets a different label, -n means no swap, -p poolname provides an alternate pool name (don't use zinstall), and -a means autologin"
	echo
	echo 'When the setup completes, run poweroff to quit and test the target image under EFI'
	qemu-system-x86_64 \
	  -accel "$(QEMU_ACCEL)" \
	  -cpu qemu64 \
	  -m 1024 \
	  -boot c \
	  -drive file=$(AMD64_IMAGE_INSTALL),format=raw,id=disk0,cache=writeback,if=none \
	  -drive file=$(AMD64_IMAGE_TEST),format=raw,id=disk1,cache=writeback,if=none \
	  -device ahci,id=ahci \
	  -device ide-hd,drive=disk0,bus=ahci.0 \
	  -device ide-hd,drive=disk1,bus=ahci.1 \
	  -nic user,model=virtio-net-pci
	touch $< $@

# Download the OVMF files
$(AMD64_OVMF_CODE) $(AMD64_OVMF_VARS):
	# See if the podman image exists
	[ "`podman images -n --filter "reference=$(AMD64_OVMF_IMAGE)" | wc -l`" -eq 1 ] || \
		podman pull $(AMD64_OVMF_IMAGE)
	# Grab the file from the image
	podman run --rm -v $(PWD):/host --userns=keep-id $(AMD64_OVMF_IMAGE) sh -c "cp $(@:.amd64.%=/data/%) /host/$@"

.PHONY: $(AMD64_IMAGE_TEST2)
$(AMD64_IMAGE_TEST2):
	qemu-img create -f raw $@ 8G

# Test the test image boots
# Touches AMD64_MEMSTICK_INST, AMD64_MEMSTICK_CONF, and target file for same reasons as above for AMD64_MEMSTICK_INST target
$(AMD64_MEMSTICK_TEST): $(AMD64_MEMSTICK_INST) $(AMD64_IMAGE_TEST2) $(AMD64_OVMF_CODE) $(AMD64_OVMF_VARS)
	echo
	echo '#### Boot test image, with same network config as auto install image'
	echo
	echo 'When login prompt appears, login as root, no password will be required'
	echo 'Both network cards should work, where 192.168.0.1 and 192.168.1.1 are the gateways'
	echo "tftp can be used on 192.168.1.2"
	echo
	qemu-system-x86_64 \
		-accel "$(QEMU_ACCEL)" \
		-cpu qemu64 \
		-m 1024 \
		-boot c \
		-drive if=pflash,media=disk,file=$(AMD64_OVMF_CODE),cache=writethrough,format=raw \
		-drive if=pflash,media=disk,file=$(AMD64_OVMF_VARS),cache=writethrough,format=raw \
		-drive file=$(AMD64_IMAGE_TEST),format=raw,id=disk0,if=none \
		-drive file=$(AMD64_IMAGE_TEST2),format=raw,id=disk1,if=none \
		-device ahci,id=ahci \
		-device ide-hd,drive=disk0,bus=ahci.0 \
		-device ide-hd,drive=disk1,bus=ahci.1 \
		-nic user,model=e1000,net=192.168.0.0/24,dhcpstart=192.168.0.1 \
		-nic user,model=rtl8139,net=192.168.1.0/24,dhcpstart=192.168.1.1,tftp=.
	touch $< $(AMD64_MEMSTICK_CONF) $@

.PHONY: recopy
recopy:
	rm -f $(AMD64_MEMSTICK_BOOT)
	$(MAKE)

.PHONY: reconfig
reconfig:
	rm -f $(AMD64_MEMSTICK_CONF)
	$(MAKE)

.PHONY: reinstall
reinstall:
	rm -f $(AMD64_MEMSTICK_INST)
	$(MAKE)

.PHONY: retest
retest:
	rm -f $(AMD64_MEMSTICK_TEST)
	$(MAKE)

.PHONY: clean
clean:
	find . -maxdepth 1 -type f \( -name 'amd64*' -o -name '.amd64*' \) -a \! \( -name '$(AMD64_RELEASE_F)' -o -name '$(AMD64_XZ_MEMSTICK)' \) -print0 | xargs -0 rm

.PHONY: push
push:
	git add -A
	git commit -m Changes
	git push

.PHONY: vars
vars:
	echo "AMD64_ISO_BASE_URL    = $(AMD64_ISO_BASE_URL)"
	echo "AMD64_RELEASE         = $(AMD64_RELEASE)"
	echo "AMD64_RELEASE_F       = $(AMD64_RELEASE_F)"
	echo "AMD64_XZ_URL          = $(AMD64_XZ_URL)"
	echo "AMD64_MEMSTICK        = $(AMD64_MEMSTICK)"
	echo "AMD64_XZ_MEMSTICK     = $(AMD64_XZ_MEMSTICK)"
	echo "AMD64_XZ_CKSUM_URL    = $(AMD64_XZ_CKSUM_URL)"
	echo "AMD64_XZ_CKSUM        = $(AMD64_XZ_CKSUM)"
	echo "AMD64_XZ_CKSUM_GEN    = $(AMD64_XZ_CKSUM_GEN)"
	echo "AMD64_XZ_CKSUM_CMP    = $(AMD64_XZ_CKSUM_CMP)"
	echo "AMD64_MEMSTICK_BOOT   = $(AMD64_MEMSTICK_BOOT)"
	echo "AMD64_MEMSTICK_CONF   = $(AMD64_MEMSTICK_CONF)"
	echo "AMD64_MEMSTICK_INST   = $(AMD64_MEMSTICK_INST)"
	echo "AMD64_MEMSTICK_TEST   = $(AMD64_MEMSTICK_TEST)"
	echo "AMD64_OVMF_IMAGE      = $(AMD64_OVMF_IMAGE)"
	echo "AMD64_OVMF_CODE       = $(AMD64_OVMF_CODE)"
	echo "AMD64_OVMF_VARS       = $(AMD64_OVMF_VARS)"
	echo "QEMU_ACCEL_HVF        = $(QEMU_ACCEL_HVF)"
	echo "QEMU_ACCEL_WHPX       = $(QEMU_ACCEL_WHPX)"
	echo "QEMU_ACCEL_KVM        = $(QEMU_ACCEL_KVM)"
	echo "QEMU_ACCEL            = $(QEMU_ACCEL)"
	echo "AMD64_IMAGE_INSTALL   = $(AMD64_IMAGE_INSTALL)"
	echo "AMD64_IMAGE_TEST      = $(AMD64_IMAGE_TEST)"
