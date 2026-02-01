# SPDX-License-Identifier: Apache-2.0
# Make a docker container named multiarch/crossbuild-wx based on multiarch/crossbuild

# Default target
.PHONY: all
all: docker-multiarch.crossbuild-wx 

# Pull multiarch/crossbuild if we don't already have it
.PHONY: docker-multiarch.crossbuild
docker-multiarch.crossbuild:
	if [ "`docker images -q --filter "reference=multiarch/crossbuild:latest" | wc -l`" -eq 0 ]; then \
	  docker pull multiarch/crossbuild; \
	fi

# Build multiarch/crossbuild-wx if it does not exist, or changes have been made to the Dockerfile
.PHONY: docker-multiarch.crossbuild-wx
docker-multiarch.crossbuild-wx: docker-multiarch.crossbuild
	docker build -t multiarch/crossbuild-wx .

# Build FreeBSD qemu image to include in the docker multiarch/crossbuild-wx image.
# The qemu image can fire up FreeBSD with kvm acceleration and compile code against FreeBSD wxWidgets library. 
.PHONY: docker-multiarch.crossbuild-fbsd
docker-multiarch.crossbuild-fbsd:
	qemu-img create fbsd.img 8G
	qemu-system-x86_64 \
	  -accel kvm \
	  -m 256 \
	  -name FreeBSD \
	  -cdrom /home/user/VirtualBox/Machines/FreeBSD/FreeBSD-13.0-RELEASE-amd64-disc1.iso \
	  -drive file=fbsd.img,format=raw \
	  -boot d \
	  -display gtk

	qemu-system-x86_64 \
	  -accel kvm \
	  -m 256 \
	  -name FreeBSD \
	  -drive file=fbsd.img,format=raw \
	  -drive file=linux.img,format=raw \
	  -boot c \
	  -display gtk \
	  -netdev user,id=mynet0,ipv6=off \
	  -net user,hostfwd=tcp::5222-:22 \
	  -net nic
	  