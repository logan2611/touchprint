#!/usr/bin/env bash
set -e

mkdir -p ${ROOTFS_DIR}/etc/default
install -m 644 files/nodm ${ROOTFS_DIR}/etc/default/nodm

# Probably not needed
on_chroot << EOF
update-alternatives --install /usr/bin/x-www-browser \
  x-www-browser /usr/bin/surf 86
update-alternatives --install /usr/bin/gnome-www-browser \
  gnome-www-browser /usr/bin/surf 86
EOF
