#!/bin/sh

# Show usage
usage() {
	echo "Usage: $0 -t freebsd [ -a | -v version | -c version ]

Download an OS that requires manual installation or manipulation of a supplied image to make it
possible to automate further changes to the OS with qemu.

Currently, the only type of OS supported is FreeBSD, and only versions availabe at the this URL:
https://download.freebsd.org/releases/VM-IMAGES

By default, the latest version available is downloaded, which is the simply the last version
listed on the above page. If a version is supplied with the -v option, then it must one of the
versions on the above page, or an error occurs.

If the -a option is passed, it lists all versions available at above URL, to aid in deciding
what version to pass with -v on another execution. For each available version, it also shows
whether or not it is already downloaded.

If none of -a, -d, or -v are passed, the default action is -a.  
"

	exit 1  
}

# Set vars
vms_dir="$HOME/.qemu-vms"
available="`curl -sL https://download.freebsd.org/releases/VM-IMAGES/ | grep -Po '(?<=href=")[^/]*' | sed '/^[^0-9]/d;s/-RELEASE//' | tac`"; \
downloaded="`[ -d $vms_dir/freebsd ] && { cd $vms_dir/freebsd && ls *.qcow2; }`"
type=
version=latest

# Display a simple report of available versions, and yes/no are they installed
showAvailable() {
	{
		for a in $available; do
			echo -n "$a "
			for d in $downloaded; do
			  [ "$a" = "$d" ] && { echo "Downloaded"; break; }
			done
			echo "Available"
		done
	}
}

saveVersion() {
	[ -f "$vms_dir/freebsd/FreeBSD-${version}-RELEASE-amd64.qcow2" ] && {
		echo "Already have that FreeBSD version downloaded"
		showAvailable
		exit
	}
	
	if mkdir -p "$vms_dir" && {
		# Download and decompress file, showing progress, resume in case it failed last time
		curl -LC - https://download.freebsd.org/releases/VM-IMAGES/${version}/amd64/Latest/FreeBSD-${version}-RELEASE-amd64.qcow2.xz \
		| unxz > "$vms_dir/freebsd/FreeBSD-${version}-RELEASE-amd64.qcow2" \
		&& {
			# Set file perm to read only
			chmod 0444 "$vms_dir/freebsd/FreeBSD-${version}-RELEASE-amd64.qcow2" || {
				echo "Error setting read only perms for $vms_dir/freebsd/FreeBSD-${version}-RELEASE-amd64.qcow2"
				exit 1
			}
		}
	}
}

createAutomatedVersion() {
	# Verify image we need to make automatable has been downloaded
	[ "$vms_dir/freebsd/FreeBSD-${version}-RELEASE-amd64.qcow2" ] || {
		echo "Error: that version has not been downloaded yet"
		usage
	}

	# Create a child image that user can manually change, unless it ready exists
	[ -f "$vms_dir/freebsd/FreeBSD-${version}-RELEASE-amd64-automate.qcow2" ] || {
		qemu-img create -f qcow2 -b "$vms_dir/freebsd/FreeBSD-${version}-RELEASE-amd64.qcow2" -F qcow2 "$vms_dir/freebsd/FreeBSD-${version}-RELEASE-amd64-automate.qcow2" || {
			echo "Error: could not create modifiable image $vms_dir/freebsd/FreeBSD-${version}-RELEASE-amd64-automate.qcow2"
			exit 1
		}
	}

	# Provide user directions on how to change the automate image so it is suitable for automation
	echo "Execute the following two commands in the automate image:
echo 'console="comconsole"' > /boot/loader.conf
echo 'autoboot_delay="0"' >> /boot/loader.conf"

	# Run qemu with a separate window to allow user to manually boot and make changes
	qemu-system-x86_64 \
		-accel kvm \
		-boot c \
		-m 256 \
		-drive file="$vms_dir/freebsd/FreeBSD-${version}-RELEASE-amd64-automate.qcow2",if=none,id=hd \
		-device virtio-blk,drive=hd \
		-display gtk
}

# Parse options
fn=showAvailable
while getopts "t:av:c:" opt; do
  case "$opt" in
    t) type=$OPTARG;;
    a) fn=showAvailable;;
    v) fn=saveVersion; version=$OPTARG;;
    c) fn=createAutomatedVersion; version=$OPTARG;;
  esac
done

# Must specify type for future compatibility if other systems added
[ -z "type" ] && usage

# If version is latest, choose first version available,
# otherwise verify it is a valid version
found=0
for a in $available; do
	if [ "$version" = "latest" -o "$version" = "$a" ]; then
		version="$a"
		found=1
		break
	fi
done
[ "$found" -eq 1 ] || {
	echo "Error: version $version is not valid"
	showAvailable
	usage
}

# Execute chosen function, or showAvailable by default
$fn
