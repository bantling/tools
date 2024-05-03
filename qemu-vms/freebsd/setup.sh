#!/bin/sh

## Create an empty GPT partition table
gpart create -s gpt vtbd1

## Create boot and zfs partitions
gpart add -t freebsd-boot -l zboot -s 512k vtbd1
gpart add -t freebsd-zfs  -l zroot vtbd1

## Get gpt ids for zboot and zroot labels
zboot_dev="/dev/gptid/`glabel status | grep 'gptid.*vtbd1p1' | awk '{print $1}' | awk -F/ '{print $2}'`"
zroot_dev="/dev/gptid/`glabel status | grep 'gptid.*vtbd1p2' | awk '{print $1}' | awk -F/ '{print $2}'`"

## Create temp moutpoint
mkdir /tmp/zfs

## Create zfs pool
zpool create -m / -R /tmp/zfs zroot $zroot_dev

## Set bootfs property
zpool set bootfs=zroot zroot

## Create swap space
zfs create -V 4G zroot/swap
zfs set org.freebsd:swap=on zroot/swap

## Install base system
cd /tmp/zfs
tar xvJf /usr/freebsd-dist/base.txz
tar xvJf /usr/freebsd-dist/kernel.txz
tar xvJf /usr/freebsd-dist/lib32.txz

## Install boot code
gpart bootcode -b /boot/pmbr -p /boot/gptzfsboot -i 1 vtbd1

## Configure loader.conf settings
echo 'zfs_load="YES"' >> boot/loader.conf
echo 'vfs.root.mountfrom="zfs:zroot"' >> boot/loader.conf

## Configure rc.conf settings
echo 'zfs_enable="YES"' >> etc/rc.conf

## Chroot and set up some stuff
chroot .

## Set timezone to UTC
cp usr/share/zoneinfo/UTC etc/localtime
adjkerntz -a

## Set hostname
hostname freebsd
echo 'hostname="freebsd"' >> etc/rc.conf

sysrc ifconfig_vtnet0="DHCP"
