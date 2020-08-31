#!/usr/local/bin/bash

qemu-system-x86_64 \
    -nographic \
    -serial telnet:localhost:3333,server,nodelay \
    -netdev user,id=net0 -device virtio-net,netdev=net0 \
    -hda install.fs \
    -hdb /dev/rsd1c \
    -m 512 \
    -no-reboot
