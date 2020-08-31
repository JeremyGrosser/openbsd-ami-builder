#!/usr/local/bin/bash
set -x

TARGET=/dev/rsd1c

sha256 -c SHA256SUMS
if [ ! $? -eq 0 ]; then
	ftp -o install67.img https://cdn.openbsd.org/pub/OpenBSD/6.7/amd64/install67.fs
	ftp https://cdn.openbsd.org/pub/OpenBSD/6.7/amd64/bsd.rd
	ftp https://cdn.openbsd.org/pub/OpenBSD/6.7/amd64/bsd.mp
fi
sha256 -c SHA256SUMS || exit $?

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
dd if=/dev/zero of=autoinstall.img bs=512 count=1048600
vnconfig vnd2 autoinstall.img
fdisk -yi -b 960 -f /usr/mdec/mbr vnd2
disklabel -w vnd2 install512
newfs -m 0 -o space -S 512 -s 1048512 /dev/rvnd2a
mkdir autoinstall
mount /dev/vnd2a autoinstall

vnconfig vnd0 install67.img
mkdir install
mount /dev/vnd0a install

cp -r install/{6.7,boot,etc,bsd} autoinstall/
cp bsd.rd autoinstall/
cp boot.conf autoinstall/etc/
cp bsd.mp autoinstall/6.7/amd64/bsd.mp
tar czvf autoinstall/6.7/amd64/site67.tgz -C site .
ls -l autoinstall/6.7/amd64/ >autoinstall/6.7/amd64/index.txt
installboot -v -r autoinstall vnd2 /usr/mdec/biosboot autoinstall/boot

umount install
vnconfig -u vnd0
rm -rf install

umount autoinstall
vnconfig -u vnd2
rm -rf autoinstall

qemu-system-x86_64 \
    -nographic \
    -serial mon:stdio \
    -netdev user,id=net0 -device virtio-net,netdev=net0 \
    -hda autoinstall.img \
    -hdb ${TARGET} \
    -m 512 \
    -no-reboot
