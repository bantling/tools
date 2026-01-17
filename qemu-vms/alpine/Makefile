# // SPDX-License-Identifier: Apache-2.0

# Build an Alpine x86_64 bootable image with the following basic steps:
# - Determine latest release of Alpine image
# - Download latest release and hash file
# - Generate a hash file, and compare against downloaded hash file
# - Generate a virtual disk
# - Obtain latest OVMF EFI boot code
# - Create EFI code and vars files
# - EFI boot installer and virtual disk

# Execute all recipe lines in one shell
.ONESHELL:

# Turn off default rules
.SUFFIXES:

# Silent by default
# Run "make VERBOSE=1 ..." to show output of each recipe invoked
ifndef VERBOSE
.SILENT:
endif

# We need to determine the latest release version of Alpine
# EG:
# We grab contents of https://dl-cdn.alpinelinux.org/alpine/:
#
# edge/
# latest-stable/
# v3.0/
# v3.1/
# v3.10/
# v3.11/
# ...
# v3.2/
# v3.20/
# v3.21/
# v3.22/
# v3.23/
# v3.3/
# ...
#
# We want the latest stable version (don't want to asssume it is latest version 3.23 in this case)
# Contents of https://dl-cdn.alpinelinux.org/alpine/latest-stable/ is:
#
# community/
# main/
# releases/
#
# We want releases
# Contents of https://dl-cdn.alpinelinux.org/alpine/latest-stable/releases is:
#
# aarch64/
# armhf/
# armv7/
# cloud/
# loongarch64/
# ppc64le/
# riscv64/
# s390x/
# x86/
# x86_64/
#
# We want x86_64
# Contents of https://dl-cdn.alpinelinux.org/alpine/latest-stable/releases/x86_64 is:
# Note that <version> denotes possibly multiple versions, always the same set of versions
#
# netboot/
# netboot-<versions>/
# alpine-extended-<versions>-x86_64.{iso,iso.asc,iso.sha256,iso.sha512}
# alpine-minirootfs-<versions>-x86_64.{iso,iso.asc,iso.sha256,iso.sha512}
# alpine-netboot-<versions>-x86_64.{iso,iso.asc,iso.sha256,iso.sha512}
# alpine-standard-<versions>-x86_64.{iso,iso.asc,iso.sha256,iso.sha512}
# alpine-virt-<versions>-x86_64.{iso,iso.asc,iso.sha256,iso.sha512}
# alpine-xen-<versions>-x86_64.{iso,iso.asc,iso.sha256,iso.sha512}
# latest-releases.yaml
#
# latest-release.yaml indicates the purpose of each type of release:
# - miniroot: containers and chroots
# - netboot : boot over network
# - standard: physical install
# - extended: most common stuff, runs from ram, routers and servers
# - virtual : slimmed down standard for VMs
# - xen     : for Xen hypervisor
#
# We want alpine-standard-<latest_version>-x86_64.{iso,iso.sha512}
# The extended images include the zfs kernel module

# URL to get latest stable x86_64 releases:
X86_64_ISO_VERSION_URL := https://dl-cdn.alpinelinux.org/alpine/latest-stable/releases/x86_64

# Get the latest extended X86_64 version
X86_64_RELEASE         := $(shell curl -sL $(X86_64_ISO_VERSION_URL)/ | grep alpine-extended | sed -r 's,.*>alpine-extended-(.*)-x86_64.*,\1,' | sort -urV | head -1)

# Get the major.minor Alpine release
X86_64_MAJOR_MINOR     := $(shell echo $(X86_64_RELEASE) | sed -r 's,(.*)[.][0-9]+,\1,')

# The file that contains the latest release download
X86_64_RELEASE_F       := .x86_64.release

# Get the url to download the latest extended X86_64 iso
X86_64_ISO_URL         := $(X86_64_ISO_VERSION_URL)/alpine-extended-$(X86_64_RELEASE)-x86_64.iso

# The file to download the latest extended X86_64 iso into
X86_64_ISO_IMG         := .x86_64.iso

# Get the url to download the latest extended X86_64 iso sha512 sum file
X86_64_ISO_CKSUM_URL   := $(X86_64_ISO_URL).sha512

# The file that contains the latest release download
X86_64_ISO_CKSUM       := $(X86_64_ISO_IMG).sha512

# The file that contains the latest release download
X86_64_ISO_CKSUM_GEN   := $(X86_64_ISO_CKSUM).gen

# The file gets updated when the checksums match
X86_64_ISO_CKSUM_CMP   := $(X86_64_ISO_CKSUM).cmp

# OVMF vars
OVMF_REPO              := rust-osdev/ovmf-prebuilt
OVMF_API               := https://api.github.com/repos/$(OVMF_REPO)
OVMF_RELEASE           := $(shell curl -s $(OVMF_API)/releases | jq -r '.[].tag_name' | grep stable | head -n 1)
OVMF_RELEASE_F         := .edk2.release
OVMF_DOWNLOAD          := https://github.com/$(OVMF_REPO)/releases/download/$(OVMF_RELEASE)/$(OVMF_RELEASE)-bin.tar.xz
OVMF_TAR_XZ            := .edk2.tar.xz
OVMF_TAR_X64_CODE      := $(OVMF_RELEASE)-bin/x64/code.fd
OVMF_TAR_X64_VARS      := $(OVMF_RELEASE)-bin/x64/vars.fd
X86_64_OVMF_CODE       := .x86_64.OVMF_CODE.fd
X86_64_OVMF_VARS       := .x86_64.OVMF_VARS.fd

# QEMU Acceleration vars
COMMA                  := ,
QEMU_ACCEL_OPTS        := $(shell qemu-system-x86_64 -accel help | sed 1d)
QEMU_ACCEL_HVF         := $(shell echo $(QEMU_ACCEL_OPTS) | grep hvf)
QEMU_ACCEL_WHPX        := $(shell echo $(QEMU_ACCEL_OPTS) | grep whpx)
QEMU_ACCEL_KVM         := $(shell echo $(QEMU_ACCEL_OPTS) | grep kvm)
QEMU_ACCEL             := $(if $(QEMU_ACCEL_HVF),hvf,$(if $(QEMU_ACCEL_WHPX),whpx$(COMMA)kernel-irqchip=off,$(if $(QEMU_ACCEL_KVM),kvm,tcg)))

# The image to install Alpine into
X86_64_IMAGE           := .x86_64.img

# The file to indicate Alpine has been installed in the image
X86_64_IMAGE_ALPINE    := $(X86_64_IMAGE).alpine

# The file to indicate that podman and Emby are installed in the image
X86_64_IMAGE_EMBY      := $(X86_64_IMAGE).emby

.PHONY: all
all: $(X86_64_IMAGE_ALPINE)

.PHONY: generate-alpine-release
generate-alpine-release:
	echo 'Checking Alpine release'
	[ -f "$(X86_64_RELEASE_F)" -a "`cat "$(X86_64_RELEASE_F)" 2> /dev/null`" = "$(X86_64_RELEASE)" ] || echo "$(X86_64_RELEASE)" > "$(X86_64_RELEASE_F)"

# Download latest image if we don't have it
$(X86_64_ISO_IMG): $(X86_64_RELEASE_F)
	echo "Downloading the $(X86_64_RELEASE) extended image"
	curl --progress-bar -Lo $@ $(X86_64_ISO_URL)

# Download latest sha512 checksum if we don't have it
$(X86_64_ISO_CKSUM): $(X86_64_ISO_IMG)
	echo "Download the $(X86_64_RELEASE) extended image checksum"
	curl -sLo - $(X86_64_ISO_CKSUM_URL) | awk '{print $$1}' > $@

# Generate a checksum of the downloaded extended iso image
$(X86_64_ISO_CKSUM_GEN): $(X86_64_ISO_CKSUM)
	echo "Generating extended image checksum"
	sha512sum -b $(X86_64_ISO_IMG) | awk '{print $$1}' > $@

# Commpare the downloaded and generated checksums
$(X86_64_ISO_CKSUM_CMP): $(X86_64_ISO_CKSUM) $(X86_64_ISO_CKSUM_GEN)
	echo "Comparing checksums"
	diff $^ > /dev/null || { echo "Downloaded checksum does not match generated checksum"; exit 1; }
	touch $@

# Create the image
$(X86_64_IMAGE): $(X86_64_ISO_CKSUM_CMP)
	echo 'Creating image $@'
	qemu-img create -f raw $@ 32G

# Generate the edk2 file if:
# - It does not exist
# - It contains a different version than the current one
.PHONY: generate-edk2-release
generate-edk2-release:
	echo 'Checking edk2 release'
	[ -f "$(OVMF_RELEASE_F)" -a "`cat "$(OVMF_RELEASE_F)" 2> /dev/null`" = "$(OVMF_RELEASE)" ] || echo "$(OVMF_RELEASE)" > "$(OVMF_RELEASE_F)"

# Download the edk2 tar file
$(OVMF_TAR_XZ):
	echo 'Downloading the $(OVMF_RELEASE) compressed archive'
	curl -Lo $@ $(OVMF_DOWNLOAD)

# Extract the AMD EFI code from edk2 tar file
$(X86_64_OVMF_CODE): $(OVMF_TAR_XZ)
	echo 'Extracting $(OVMF_TAR_X64_CODE) from $< into $@'
	tar xfO $< $(OVMF_TAR_X64_CODE) > $@

# Extract the AMD EFI vars from edk2 tar file
$(X86_64_OVMF_VARS): $(OVMF_TAR_XZ)
	echo 'Extracting $(OVMF_TAR_X64_VARS) from $< into $@'
	tar xfO $< $(OVMF_TAR_X64_VARS) > $@

.PHONY: ovmf
ovmf: $(X86_64_OVMF_CODE) $(X86_64_OVMF_VARS)

# Install Alpine into the image
$(X86_64_IMAGE_ALPINE): generate-alpine-release $(X86_64_IMAGE) generate-edk2-release ovmf
	echo 'Installing Alpine into the image'
	echo
	echo 'Run the following commands:'
	echo 'setup-interfaces'
	echo '/etc/init.d/networking restart'
	echo 'echo "https://dl-cdn.alpinelinux.org/alpine/v$(X86_64_MAJOR_MINOR)/main" >> /etc/apk/repositories'
	echo 'apk update && apk upgrade && apk add tftp-hpa'
	echo 'tftp 10.0.2.2 -m octet -c get setup.sh'
	echo 'modprobe zfs'
	echo
	echo 'Choose the "sys" type of disk setup'
	echo 'Set root password to toortoor'
	echo 'Leave everything else as defaults'
	echo
	qemu-system-x86_64 \
	  -accel "$(QEMU_ACCEL)" \
	  -cpu qemu64 \
	  -m 1024 \
	  -boot c \
	  -drive if=pflash,media=disk,file=$(X86_64_OVMF_CODE),cache=writethrough,format=raw \
	  -drive if=pflash,media=disk,file=$(X86_64_OVMF_VARS),cache=writethrough,format=raw \
	  -drive file=$(X86_64_ISO_IMG),format=raw,id=disk0,cache=none,if=none \
	  -drive file=$(X86_64_IMAGE),format=raw,id=disk1,cache=writeback,if=none \
	  -device ahci,id=ahci \
	  -device ide-hd,drive=disk0,bus=ahci.0 \
	  -device ide-hd,drive=disk1,bus=ahci.1 \
	  -nic user,model=virtio-net-pci,tftp=.
	touch $@

# Boot the configured image so emby can be configured on it
$(X86_64_IMAGE_EMBY): $(X86_64_IMAGE_ALPINE)
	echo 'Booting Alpine to set up podman and emby'
	echo
	echo 'Emby image located at docker.io/emby/embyserver'
	echo
	qemu-system-x86_64 \
	  -accel "$(QEMU_ACCEL)" \
	  -cpu qemu64 \
	  -m 1024 \
	  -boot c \
	  -drive if=pflash,media=disk,file=$(X86_64_OVMF_CODE),cache=writethrough,format=raw \
	  -drive if=pflash,media=disk,file=$(X86_64_OVMF_VARS),cache=writethrough,format=raw \
	  -drive file=$(X86_64_ISO_IMG),format=raw,id=disk0,cache=none,if=none \
	  -drive file=$(X86_64_IMAGE),format=raw,id=disk1,cache=writeback,if=none \
	  -device ahci,id=ahci \
	  -device ide-hd,drive=disk0,bus=ahci.0 \
	  -device ide-hd,drive=disk1,bus=ahci.1 \
	  -nic user,model=virtio-net-pci,tftp=.
	touch $@

.PHONY: clean
clean:
	rm -f .* 2> /dev/null || :

.PHONY: vars
vars:
	echo "X86_64_ISO_VERSION_URL    = $(X86_64_ISO_VERSION_URL)"
	echo "X86_64_RELEASE            = $(X86_64_RELEASE)"
	echo "X86_64_MAJOR_MINOR        = $(X86_64_MAJOR_MINOR)"
	echo "X86_64_RELEASE_F          = $(X86_64_RELEASE_F)"
	echo "X86_64_ISO_URL            = $(X86_64_ISO_URL)"
	echo "X86_64_ISO_IMG            = $(X86_64_ISO_IMG)"
	echo "X86_64_ISO_CKSUM_URL      = $(X86_64_ISO_CKSUM_URL)"
	echo "X86_64_ISO_CKSUM          = $(X86_64_ISO_CKSUM)"
	echo "X86_64_ISO_CKSUM_GEN      = $(X86_64_ISO_CKSUM_GEN)"
	echo "X86_64_ISO_CKSUM_CMP      = $(X86_64_ISO_CKSUM_CMP)"
	echo "OVMF_REPO                 = $(OVMF_REPO)"
	echo "OVMF_API                  = $(OVMF_API)"
	echo "OVMF_RELEASE              = $(OVMF_RELEASE)"
	echo "OVMF_RELEASE_F            = $(OVMF_RELEASE_F)"
	echo "OVMF_DOWNLOAD             = $(OVMF_DOWNLOAD)"
	echo "OVMF_TAR_XZ               = $(OVMF_TAR_XZ)"
	echo "OVMF_TAR_X64_CODE         = $(OVMF_TAR_X64_CODE)"
	echo "OVMF_TAR_X64_VARS         = $(OVMF_TAR_X64_VARS)"
	echo "X86_64_OVMF_CODE          = $(X86_64_OVMF_CODE)"
	echo "X86_64_OVMF_VARS          = $(X86_64_OVMF_VARS)"
	echo "QEMU_ACCEL_OPTS           = $(QEMU_ACCEL_OPTS)"
	echo "QEMU_ACCEL_HVF            = $(QEMU_ACCEL_HVF)"
	echo "QEMU_ACCEL_WHPX           = $(QEMU_ACCEL_WHPX)"
	echo "QEMU_ACCEL_KVM            = $(QEMU_ACCEL_KVM)"
	echo "QEMU_ACCEL                = $(QEMU_ACCEL)"
	echo "X86_64_IMAGE              = $(X86_64_IMAGE)"
	echo "X86_64_IMAGE_ALPINE       = $(X86_64_IMAGE_ALPINE)"
	echo "X86_64_IMAGE_EMBY         = $(X86_64_IMAGE_EMBY)"
