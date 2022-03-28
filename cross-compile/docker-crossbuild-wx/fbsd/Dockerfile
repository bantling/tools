FROM alpine:latest

# Version of FreeBSD to use
ARG FREEBSD_VERSION

# Install needed packages
# qemu: use qemu to run freebsd
RUN apk update && \
    apk add curl qemu
 
# Grab FreeBSD QEMU image from site
RUN echo "Downloading FreeBSD version $FREEBSD_VERSION"; \
    curl -LO https://download.freebsd.org/releases/VM-IMAGES/$FREEBSD_VERSION-RELEASE/amd64/Latest/FreeBSD-$FREEBSD_VERSION-RELEASE-amd64.qcow2.xz \
    | unxz > FreeBSD-$FREEBSD_VERSION-RELEASE-amd64.qcow2

# Manually execute the following two commands:
# echo 'console="comconsole"' > /boot/loader.conf
# echo 'autoboot_delay="0"' >> /boot/loader.conf
qemu-system-x86_64 \
  -accel kvm \
  -boot c \
  -m 256 \
  -drive file=FreeBSD-13.0-RELEASE-amd64.qcow2,if=none,id=hd \
  -device virtio-blk,drive=hd \
  -netdev user,id=vnet,hostfwd=tcp::5222-:22 \
  -device virtio-net-pci,netdev=vnet

qemu-img create -f qcow2 -b FreeBSD-13.0-RELEASE-amd64.qcow2 -F qcow2 docker-crossbuild-wx.qcow2

# Expand hd
qemu-img resize FreeBSD-13.0-RELEASE-amd64.qcow2 +10G

# Now we can automate usage of qemu
qemu-system-x86_64 \
  -accel kvm \
  -boot c \
  -m 256 \
  -drive file=FreeBSD-13.0-RELEASE-amd64.qcow2,if=none,id=hd \
  -device virtio-blk,drive=hd \
  -netdev user,id=vnet,hostfwd=tcp::5222-:22 \
  -device virtio-net-pci,netdev=vnet \
  -display none \
  -nographic
