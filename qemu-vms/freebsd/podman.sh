#!/bin/sh

# Enable and start pf, or podman cannot start
sysrc pf_enable=YES
cp /usr/share/examples/pf/pf.conf /etc
service pf start

# Enable and start linux emulation, or podman cannot run linux images
#sysrc linux_enable=YES
#service linux start

# Install podman
echo y | env ASSUME_ALWAYS_YES=yes pkg install podman

# Pull alpine, run it to echo hello, and remove it
#podman pull --os=linux docker.io/library/alpine
#podman run --os=linux --rm alpine echo hello
#podman image rm docker.io/library/alpine

mkdir build
cd build
mkdir system
(cd system; xz -dkv --stdout /usr/freebsd-dist/*.txz | tar xf -)
