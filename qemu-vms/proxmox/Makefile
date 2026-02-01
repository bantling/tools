# // SPDX-License-Identifier: Apache-2.0

# Build a Proxmox x86_64 bootable image with the following basic steps:
# - Determine latest release of Proxmox image
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

# We need to determine the latest release version of proxmox ve
# EG:
# We grab contents of https://enterprise.proxmox.com/iso/:
#
#SHA256SUMS                                         12-Dec-2025 15:59                1789
#SHA256SUMS.asc                                     12-Dec-2025 15:59                 833
#SHA256SUMS.bookworm-key.asc                        12-Dec-2025 15:59                 833
#proxmox-backup-server_1.1-1.iso                    15-Apr-2021 07:50           710651904
#proxmox-backup-server_2.4-1.iso                    29-Mar-2023 11:00           861995008
#proxmox-backup-server_3.4-1.iso                    10-Apr-2025 11:00          1306435584
#proxmox-backup-server_4.0-1.iso                    06-Aug-2025 13:00          1341806592
#proxmox-backup-server_4.1-1.iso                    26-Nov-2025 12:00          1514835968
#proxmox-datacenter-manager_1.0-2.iso               11-Dec-2025 16:00          1480003584
#proxmox-mail-gateway_8.2-1.iso                     27-Feb-2025 13:30          1579073536
#proxmox-mail-gateway_9.0-1.iso                     01-Oct-2025 10:01          1632059392
#proxmox-mailgateway_5.2-1.iso                      26-Mar-2019 09:43           792434688
#proxmox-mailgateway_6.4-1.iso                      30-Mar-2021 07:29          1024268288
#proxmox-mailgateway_7.3-1.iso                      28-Mar-2023 11:00          1139914752
#proxmox-ve_3.4-102d4547-6.iso                      27-May-2015 05:47           680990720
#proxmox-ve_4.4-eb2d6f1e-2.iso                      15-Dec-2016 09:22           547141632
#proxmox-ve_5.4-1.iso                               11-Apr-2019 08:25           687079424
#proxmox-ve_6.4-1.iso                               28-Apr-2021 06:47           928993280
#proxmox-ve_7.4-1.iso                               23-Mar-2023 09:00          1122861056
#proxmox-ve_8.4-1.iso                               09-Apr-2025 10:00          1571895296
#proxmox-ve_9.0-1.iso                               05-Aug-2025 14:00          1641615360
#proxmox-ve_9.1-1.iso                               19-Nov-2025 12:00          1831886848
#
# We want the latest proxmox-ve iso version (9.1-1 in this case)

# URL to get recent releases:
ISO_URL           := https://enterprise.proxmox.com/iso

# Get the latest release version
VERSION           := $(shell curl -sL $(ISO_URL) | grep -e '-ve_' | sed -r 's,.*>(proxmox-ve_[^<]*iso).*,\1,' | sort -rV | head -1)

# The file that contains the latest release version
RELEASE_F         := .iso.release

# Get the url to download the latest extended X86_64 iso
RELEASE_ISO_URL   := $(ISO_URL)/$(VERSION)

# The file to download the latest extended X86_64 iso into
ISO_IMG           := .iso

# Get the url to download the sha256 sums
ISO_CKSUM_URL     := $(ISO_URL)/SHA256SUMS

# The file that contains the latest release download
ISO_CKSUM         := $(ISO_IMG).sha256

# The file that contains the latest release download
ISO_CKSUM_GEN     := $(ISO_CKSUM).gen

# The file gets updated when the checksums match
ISO_CKSUM_CMP     := $(ISO_CKSUM).cmp

# OVMF vars
OVMF_REPO         := rust-osdev/ovmf-prebuilt
OVMF_API          := https://api.github.com/repos/$(OVMF_REPO)
OVMF_RELEASE      := $(shell curl -s $(OVMF_API)/releases | jq -r '.[].tag_name' | grep stable | head -n 1)
OVMF_RELEASE_F    := .edk2.release
OVMF_DOWNLOAD     := https://github.com/$(OVMF_REPO)/releases/download/$(OVMF_RELEASE)/$(OVMF_RELEASE)-bin.tar.xz
OVMF_TAR_XZ       := .edk2.tar.xz
OVMF_TAR_X64_CODE := $(OVMF_RELEASE)-bin/x64/code.fd
OVMF_TAR_X64_VARS := $(OVMF_RELEASE)-bin/x64/vars.fd
OVMF_CODE         := .OVMF_CODE.fd
OVMF_VARS         := .OVMF_VARS.fd

# QEMU Acceleration vars
COMMA                  := ,
QEMU_ACCEL_OPTS        := $(shell qemu-system-x86_64 -accel help | sed 1d)
QEMU_ACCEL_HVF         := $(shell echo $(QEMU_ACCEL_OPTS) | grep hvf)
QEMU_ACCEL_WHPX        := $(shell echo $(QEMU_ACCEL_OPTS) | grep whpx)
QEMU_ACCEL_KVM         := $(shell echo $(QEMU_ACCEL_OPTS) | grep kvm)
QEMU_ACCEL             := $(if $(QEMU_ACCEL_HVF),hvf,$(if $(QEMU_ACCEL_WHPX),whpx$(COMMA)kernel-irqchip=off,$(if $(QEMU_ACCEL_KVM),kvm,tcg)))

# The image to install Proxmox into
PROXMOX_IMG            := .proxmox.img

# The file to indicate Proxmox has been installed in the image
PROXMOX_INST           := $(PROXMOX_IMG).inst

# The file to indicate Proxmox has been tested with the zfs system rescue cd, see https://github.com/nchevsky/systemrescue-zfs
PROXMOX_RESCUE         := $(PROXMOX_IMG).rescue

# The file to indicate that podman and Emby are installed in the image
PROXMOX_EMBY           := $(PROXMOX_IMG).emby

.PHONY: all
all: generate-proxmox-release \
     $(ISO_CKSUM_CMP) \
     generate-edk2-release \
     ovmf \
     $(PROXMOX_IMG) \
     $(PROXMOX_EMBY)

.PHONY: generate-proxmox-release
generate-proxmox-release:
	echo 'Checking Proxmox release'
	[ -f "$(RELEASE_F)" -a "`cat "$(RELEASE_F)" 2> /dev/null`" = "$(VERSION)" ] || echo "$(VERSION)" > "$(RELEASE_F)"

# Download latest image if we don't have it
$(ISO_IMG): $(RELEASE_F)
	echo "Downloading the $(VERSION) image"
	curl --progress-bar -Lo $@ $(RELEASE_ISO_URL)

# Download latest sha256 checksum if we don't have it
$(ISO_CKSUM): $(ISO_IMG)
	echo "Download the $(VERSION) image checksum"
	curl -sLo - $(ISO_CKSUM_URL) | grep $(VERSION) | awk '{print $$1}' > $@

# Generate a checksum of the downloaded extended iso image
$(ISO_CKSUM_GEN): $(ISO_CKSUM)
	echo "Generating the $(VERSION) image checksum"
	sha256sum -b $(ISO_IMG) | awk '{print $$1}' > $@

# Compare the downloaded and generated checksums
$(ISO_CKSUM_CMP): $(ISO_CKSUM) $(ISO_CKSUM_GEN)
	echo "Comparing checksums"
	diff $^ > /dev/null || { echo "Downloaded checksum does not match generated checksum"; exit 1; }
	touch $@

# Generate the edk2 file if:
# - It does not exist
# - It contains a different version than the current one
.PHONY: generate-edk2-release
generate-edk2-release:
	echo 'Checking edk2 release'
	[ -f "$(OVMF_RELEASE_F)" -a "`cat "$(OVMF_RELEASE_F)" 2> /dev/null`" = "$(OVMF_RELEASE)" ] || echo "$(OVMF_RELEASE)" > "$(OVMF_RELEASE_F)"

# Download the edk2 tar file
$(OVMF_TAR_XZ): $(OVMF_RELEASE_F)
	echo 'Downloading the $(OVMF_RELEASE) compressed archive'
	curl -Lo $@ $(OVMF_DOWNLOAD)

# Extract the AMD EFI code from edk2 tar file
$(OVMF_CODE): $(OVMF_TAR_XZ)
	echo 'Extracting $(OVMF_TAR_X64_CODE) from $< into $@'
	tar xfO $< $(OVMF_TAR_X64_CODE) > $@

# Extract the AMD EFI vars from edk2 tar file
$(OVMF_VARS): $(OVMF_TAR_XZ)
	echo 'Extracting $(OVMF_TAR_X64_VARS) from $< into $@'
	tar xfO $< $(OVMF_TAR_X64_VARS) > $@

# Phony target to ensure we have latest ovmf code and vars
.PHONY: ovmf
ovmf: $(OVMF_CODE) $(OVMF_VARS)

# Create the image
$(PROXMOX_IMG):
	echo 'Creating image $@'
	qemu-img create -f raw $@ 8G

# Install Alpine into the image
# Note usage of cache-writeback instead of none for ISO image
# In some scenarios (like image on a USB external enclosure), qemu will emit an error about the image is not aligned,
# even though the image is both a multiple of 512 bytes and 4K, and qemu will not state what alignment it expects.
# cache-writeback avoids this issue.
$(PROXMOX_INST):
	echo 'Installing Proxmox into the image'
	echo
	echo 'Enter hostname of proxmox.local, and IP of 192.168.2.254, gateway 10.0.2.2, dns server 10.0.2.3'
	echo
	qemu-system-x86_64 \
	  -accel "$(QEMU_ACCEL)" \
	  -cpu qemu64 \
	  -m 2048 \
	  -boot c \
	  -drive if=pflash,media=disk,file=$(OVMF_CODE),cache=writethrough,format=raw \
	  -drive if=pflash,media=disk,file=$(OVMF_VARS),cache=writethrough,format=raw \
	  -drive file=$(ISO_IMG),format=raw,id=disk0,cache=writeback,if=none \
	  -drive file=$(PROXMOX_IMG),format=raw,id=disk1,cache=writeback,if=none \
	  -device ahci,id=ahci \
	  -device ide-hd,drive=disk0,bus=ahci.0 \
	  -device ide-hd,drive=disk1,bus=ahci.1 \
	  -nic user,model=virtio-net-pci
	touch $@

# Boot Systemrescuecd to change zpool to use partition guid for device
# Systemrescuecd release are at https://github.com/nchevsky/systemrescue-zfs
$(PROXMOX_RESCUE): $(PROXMOX_INST)
	echo 'Boot zfs rescue cd'
	echo
	echo 'Run zpool import -d /dev/disk/by-partuuid/<uuid for sdb3> rpool to switch to a partition guid'
	echo 'Then zpool export rpool and zpool import rpool and zpool status to verify it now uses by-partuuid'
	echo
	qemu-system-x86_64 \
	  -accel "$(QEMU_ACCEL)" \
	  -cpu qemu64 \
	  -m 2048 \
	  -boot c \
	  -drive if=pflash,media=disk,file=$(OVMF_CODE),cache=writethrough,format=raw \
	  -drive if=pflash,media=disk,file=$(OVMF_VARS),cache=writethrough,format=raw \
	  -drive file=systemrescue+zfs-12.00+2.3.1-amd64.iso,format=raw,id=disk0,cache=writeback,if=none \
	  -drive file=$(PROXMOX_IMG),format=raw,id=disk1,cache=writeback,if=none \
	  -device ahci,id=ahci \
	  -device ide-hd,drive=disk0,bus=ahci.0 \
	  -device ide-hd,drive=disk1,bus=ahci.1 \
	  -nic user,model=virtio-net-pci
	touch $@

# Boot the configured image so emby can be configured on it
# Don't create the target file, so we can always rerun it again
$(PROXMOX_EMBY): $(PROXMOX_RESCUE)
	echo 'Booting Proxmox to set up podman and emby'
	echo
	echo 'Run apt install podman'
	echo
	echo 'Run useradd -c User -s /usr/bin/bash -m user to create an ordinary user'
	echo 'Run echo "user:pass" | chpasswd to set the user password'
	echo 'Run mkdir -p ~user/.local/share/containers/storage'
	echo
	echo 'As user,run podman pull docker.io/emby/embyserver'
	echo
	qemu-system-x86_64 \
	  -accel "$(QEMU_ACCEL)" \
	  -cpu qemu64 \
	  -m 1024 \
	  -boot c \
	  -drive if=pflash,media=disk,file=$(OVMF_CODE),cache=writethrough,format=raw \
	  -drive if=pflash,media=disk,file=$(OVMF_VARS),cache=writethrough,format=raw \
	  -drive file=$(PROXMOX_IMG),format=raw,id=disk0,cache=writeback,if=none \
	  -device ahci,id=ahci \
	  -device ide-hd,drive=disk0,bus=ahci.0
	touch $@

.PHONY: clean
clean:
	rm -f .* 2> /dev/null || :

.PHONY: vars
vars:
	echo "ISO_URL           = $(ISO_URL)"
	echo "VERSION           = $(VERSION)"
	echo "RELEASE_F         = $(RELEASE_F)"
	echo "RELEASE_ISO_URL   = $(RELEASE_ISO_URL)"
	echo "ISO_IMG           = $(ISO_IMG)"
	echo "ISO_CKSUM_URL     = $(ISO_CKSUM_URL)"
	echo "ISO_CKSUM         = $(ISO_CKSUM)"
	echo "ISO_CKSUM_GEN     = $(ISO_CKSUM_GEN)"
	echo "ISO_CKSUM_CMP     = $(ISO_CKSUM_CMP)"
	echo "OVMF_REPO         = $(OVMF_REPO)"
	echo "OVMF_API          = $(OVMF_API)"
	echo "OVMF_RELEASE      = $(OVMF_RELEASE)"
	echo "OVMF_RELEASE_F    = $(OVMF_RELEASE_F)"
	echo "OVMF_DOWNLOAD     = $(OVMF_DOWNLOAD)"
	echo "OVMF_TAR_XZ       = $(OVMF_TAR_XZ)"
	echo "OVMF_TAR_X64_CODE = $(OVMF_TAR_X64_CODE)"
	echo "OVMF_TAR_X64_VARS = $(OVMF_TAR_X64_VARS)"
	echo "OVMF_CODE          = $(OVMF_CODE)"
	echo "OVMF_VARS          = $(OVMF_VARS)"
	echo "QEMU_ACCEL_OPTS    = $(QEMU_ACCEL_OPTS)"
	echo "QEMU_ACCEL_HVF     = $(QEMU_ACCEL_HVF)"
	echo "QEMU_ACCEL_WHPX    = $(QEMU_ACCEL_WHPX)"
	echo "QEMU_ACCEL_KVM     = $(QEMU_ACCEL_KVM)"
	echo "QEMU_ACCEL         = $(QEMU_ACCEL)"
	echo "PROXMOX_IMG        = $(PROXMOX_IMG)"
	echo "PROXMOX_INST       = $(PROXMOX_INST)"
	echo "PROXMOX_RESCUE     = $(PROXMOX_RESCUE)"
	echo "PROXMOX_EMBY       = $(PROXMOX_EMBY)"
