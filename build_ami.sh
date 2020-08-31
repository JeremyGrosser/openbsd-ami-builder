#!/usr/local/bin/bash
set -x

TARGET=/dev/rsd1c

if [ ! -f install.fs ]; then
	ftp -o install.fs https://cdn.openbsd.org/pub/OpenBSD/6.7/amd64/install67.fs
fi
if [ ! -f bsd.rd ]; then
	ftp https://cdn.openbsd.org/pub/OpenBSD/6.7/amd64/bsd.rd
fi

cp disktab /etc/disktab

rdsetroot -x bsd.rd disk.fs
vnconfig vnd1 disk.fs
mkdir disk
mount /dev/vnd1a disk
cp auto_install.conf disk/
umount disk
vnconfig -u vnd1
rm -rf disk
rdsetroot bsd.rd disk.fs
rm disk.fs

# 512MB
dd if=/dev/zero of=new.fs bs=512 count=1048600
vnconfig vnd2 new.fs
fdisk -yi -b 960 -f /usr/mdec/mbr vnd2
disklabel -w vnd2 install512
newfs -m 0 -o space -S 512 -s 1048512 /dev/rvnd2a
mkdir new
mount /dev/vnd2a new

vnconfig vnd0 install.fs
mkdir install
mount /dev/vnd0a install

cp -r install/{6.7,boot,etc,bsd} new/
cp bsd.rd new/
cp boot.conf new/etc/
tar czvf new/6.7/amd64/site67.tgz -C site .
installboot -v -r new vnd2 /usr/mdec/biosboot new/boot

umount install
vnconfig -u vnd0
rm -rf install

umount new
vnconfig -u vnd2
rm -rf new

qemu-system-x86_64 \
    -nographic \
    -serial mon:stdio \
    -netdev user,id=net0 -device virtio-net,netdev=net0 \
    -hda new.fs \
    -hdb ${TARGET} \
    -m 512 \
    -no-reboot
