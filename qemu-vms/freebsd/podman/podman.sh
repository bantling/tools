#!/bin/sh

# Enable and start pf, or podman cannot start
[ -f /etc/pf.conf ] || sudo cp /usr/share/examples/pf/pf.conf /etc
sudo sysrc pf_enable=YES
[ "`ps aux | grep '\[pf' | grep -v grep | wc -l`" -gt 0 ] || sudo service pf start

# Enable and start linux emulation, or podman cannot run linux images
#sysrc linux_enable=YES
#service linux start

# Install podman
pkg query %n = podman > /dev/null || echo y | env ASSUME_ALWAYS_YES=yes sudo pkg install podman

# Install pv
pkg query %n = pv > /dev/null || echo y | env ASSUME_ALWAYS_YES=yes sudo pkg install pv

# Pull alpine, run it to echo hello, and remove it
#podman pull --os=linux docker.io/library/alpine
#podman run --os=linux --rm alpine echo hello
#podman image rm docker.io/library/alpine

mkdir -p build/system
cd build
(cd system; pv /usr/freebsd-dist/*.txz | tar -xJ)

# Alter registries.conf to indicate that docker.io is a default search registry
sudo sed -ri 's,(.*)(unqualified-search-registries)(.*),\1\2\3\n\2 = ["docker.io"]\n,' /usr/local/etc/containers/registries.conf

# Create a Dockerfile to build a native freebsd image
echo <<-EOF >> Dockerfile
FROM docker.io/dougrabson/freebsd-14-small
ENTRYPOINT ["/bin/sh", "-c"]
CMD ["echo dude"]
EOF

# Build and test it
sudo podman build -t test .
sudo podman run --rm test
sudo podman run --rm test "echo whatever"
