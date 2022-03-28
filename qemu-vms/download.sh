#!/bin/sh

# Show usage
usage() {
	echo "Usage: $0 -t [ fbsd | wx ] [ -v version ] [ -a | -d | -c | -e ]

Download an OS (or library for it) that requires manual installation or manipulation of a supplied image to make it
possible to automate further changes to the OS with qemu.

Currently, the only type of OS supported is FreeBSD, and only versions available at the this URL:
https://download.freebsd.org/releases/VM-IMAGES.

By default, the latest version available is downloaded, which is the simply the last version
listed on the above page. If a version is supplied with the -d or -c options, then it must one of the
versions on the above page, or an error occurs.

Currently, the only library supported is wxWidget, and only releases available at this URL:
https://github.com/wxWidgets/wxWidgets/releases.

If the -v option is passed, it selects a version, which may the word latest.
If not passed, the default is latest.

If the -a option is passed, it lists all versions available at above URL, to aid in deciding
what version to pass with -d or -c on another execution. For each available version, it also shows
whether or not it is already downloaded.

-d downloads the specified version and marks it read only unless it already exists.

-c creates a child image, displays the commands to make the child image automatable via the console,
and runs qemu to allow the user to manually execute the displayed commands.

-e runs the child image to see if it really is automatable  

If none of -a, -d, -c, or -e are passed, the default action is -a. 
"

	exit 1  
}

# Set vars
vms_dir="$HOME/.qemu-vms"
type=
version=latest

#### FreeBSD

fbsd_getAvailable() {
	fbsd_available="`curl -sL https://download.freebsd.org/releases/VM-IMAGES/ | grep -Po '(?<=href=")[^/]*' | sed '/^[^0-9]/d;s/-RELEASE//' | tac`";
}

# Display a simple report of available versions, and yes/no are they installed
fbsd_showAvailable() {
	fbsd_getAvailable
	fbsd_downloaded="`[ -d $vms_dir/freebsd ] && { cd $vms_dir/freebsd && ls *amd64.qcow2 2> /dev/null | sed -r 's/FreeBSD-([^-]*).*/\1/'; }`"
	
	for a in $fbsd_available; do
		echo -n "$a Available"
		for d in $fbsd_downloaded; do
		  [ "$a" = "$d" ] && { echo -n " Downloaded "; break; }
		done
		echo
	done
}

fbsd_saveVersion() {
	# Create dir in case it does not exist
	mkdir -p "$vms_dir/freebsd" || {
		echo "Error: unable to create dir $vms_dir/freebsd"
		usage
	}
	
	# Check if unarchived file exists. If so, we've already downloaded and extracted it.
	if [ -f "$vms_dir/freebsd/FreeBSD-${version}-RELEASE-amd64.qcow2" ]; then
		echo "version ${version} is already downloaded and extracted"
		return
	fi
	 
	# If file exists, assume the file may need to resume downloading
	actualSize="`stat --printf=%s "$vms_dir/freebsd/FreeBSD-${version}-RELEASE-amd64.qcow2.xz" 2>/dev/null`"
	expectedSize="$(curl -s --head https://download.freebsd.org/releases/VM-IMAGES/${version}-RELEASE/amd64/Latest/FreeBSD-${version}-RELEASE-amd64.qcow2.xz | sed -nr 's/^Content-Length: *([0-9]*)/\1/p' | tr -d '\r\n')"
	if [ "$expectedSize" != "$actualSize" ]; then
		# Download and decompress file, showing progress, resume in case it failed last time
		echo "Downloading image"
		curl -LC - https://download.freebsd.org/releases/VM-IMAGES/${version}-RELEASE/amd64/Latest/FreeBSD-${version}-RELEASE-amd64.qcow2.xz \
		> "$vms_dir/freebsd/FreeBSD-${version}-RELEASE-amd64.qcow2.xz"
		
		# May have quit prematurely, or user hit Ctrl-C. Check size again.
		expectedSize="$(curl -s --head https://download.freebsd.org/releases/VM-IMAGES/${version}-RELEASE/amd64/Latest/FreeBSD-${version}-RELEASE-amd64.qcow2.xz | sed -nr 's/^Content-Length: *([0-9]*)/\1/p' | tr -d '\r\n')"
		if [ "$expectedSize" != "$actualSize" ]; then
			echo "Error: download did not complete"
			exit 1
		fi
	fi
	
	# Unarchive the download, showing progress with pv command
	echo "Extracting image"
	unxz -v "$vms_dir/freebsd/FreeBSD-${version}-RELEASE-amd64.qcow2.xz"
	
	# Verify we do not have the .xz file and we do have the .qcow2, indicating unxz completed successfully.
	# If not, then complain. If not((not a) and b)) = if (a or (not b)) 
	if [ -f "$vms_dir/freebsd/FreeBSD-${version}-RELEASE-amd64.qcow2.xz" -o \! -f "$vms_dir/freebsd/FreeBSD-${version}-RELEASE-amd64.qcow2" ]; then
		echo "Error: $vms_dir/freebsd/FreeBSD-${version}-RELEASE-amd64.qcow2.xz did not fully decompress"
		exit 1
	fi
	
	# Set file perm to read only
	chmod 0444 "$vms_dir/freebsd/FreeBSD-${version}-RELEASE-amd64.qcow2" || {
		echo "Error setting read only perms for $vms_dir/freebsd/FreeBSD-${version}-RELEASE-amd64.qcow2"
		exit 1
	}
	echo "Image downloaded, extracted, and marked as read only"
}

fbsd_createAutomatedVersion() {
	# Verify image we need to make automatable has been downloaded
	[ -f "$vms_dir/freebsd/FreeBSD-${version}-RELEASE-amd64.qcow2" ] || {
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
echo 'console="comconsole"' >> /boot/loader.conf
echo 'autoboot_delay="0"' >> /boot/loader.conf
halt -p"

	# Run qemu with a separate window to allow user to manually boot and make changes
	qemu-system-x86_64 \
		-accel kvm \
		-boot c \
		-m 256 \
		-drive file="$vms_dir/freebsd/FreeBSD-${version}-RELEASE-amd64-automate.qcow2",if=none,id=hd \
		-device virtio-blk,drive=hd \
		-display gtk
}

fbsd_testAutomatedVersion() {
	# Test automatable qemu image to see if it works
	qemu-system-x86_64 \
		-accel kvm \
		-boot c \
		-m 256 \
		-drive file="$vms_dir/freebsd/FreeBSD-${version}-RELEASE-amd64-automate.qcow2",if=none,id=hd \
		-device virtio-blk,drive=hd \
		-display gtk
}

#### wxWidgets

wx_getAvailable() {
	wx_available="`
		curl -sL https://api.github.com/repos/wxWidgets/wxWidgets/releases | jq -r '
		  [
		    .[].assets[]
		    | {name, url: .browser_download_url}
		    | select(.name | contains("wxWidgets"))
		    | select(.name | contains("bz2"))
		    | select(.name | contains("docs") | not)
		    | . + {"name": .name | match("([0-9]+(?:[.][0-9]+)+)").captures[0].string}
		  ] | sort_by(
		        .name
		        | split(".")
		        | map(tonumber)
		  ) | reverse
		    | map(.name + "|" + .url)
		    | @sh
	    '
	`" 
}

wx_showAvailable() {
	wx_getAvailable 
	wx_downloaded="`[ -d $vms_dir/wx ] && { cd $vms_dir/wx && ls *.tar.bz2 2> /dev/null; }`"
	
	for a in $wx_available; do
	  # Strip single quotes jq provided around string
	  a=${a#"'"}
	  a=${a%"'"}
	  
	  # Seperate name|url into two vars
	  name="${a%|*}"
	  url="${a#*|}"
	  
	  echo "${name} Available"
	done
}

#### Main

type=
op=
fn="showAvailable"

# Can only specify one operation 
check_op() {
	[ -z "${op}" ] || usage
	
	op="$1"
}

# Parse options
while getopts "t:v:adce" opt; do
  case "$opt" in
    t) type=$OPTARG;;
    v) version=$OPTARG;;
    *) check_op "$opt";;
  esac
done

# Type must be freebsd or wx
case "$type" in
	freebsd) ;;
	wx) ;;
	*) usage;;
esac

# If no operation is provided, default to a (available)
[ -n "${op}" ] || op="a"

# Determine a function to call based on the op
case "$op" in
	a) fn=showAvailable;;
	d) fn=saveVersion;;
	c) fn=createAutomatedVersion;;
	e) fn=testAutomatedVersion;;
esac

# If version is latest, choose first version available,
# otherwise verify it is a valid version
found=0
case "$type" in
	fbsd)
		fbsd_getAvailable
		for a in $fbsd_available; do
			if [ "$version" = "latest" -o "$version" = "$a" ]; then
				version="$a"
				found=1
				break
			fi
		done
		
		[ "$found" -eq 1 ] || {
			echo "Error: version $version is not valid"
			fbsd_showAvailable
			usage
		}
		;;
	wx)
		;;
esac

# Execute function
${type}_${fn}
