#!/bin/bash -e

install -m 644 files/mjpg-streamer.service ${ROOTFS_DIR}/etc/systemd/system/mjpg-streamer.service
install -m 755 files/start-mjpg ${ROOTFS_DIR}/usr/local/bin/start-mjpg

on_chroot << EOF
# If mjpg is already installed, skip this (for debugging)
if ! which mjpg_streamer; then
  cd /tmp
  # Making sure that this directory doesn't exist
  rm -rf /tmp/mjpg-streamer
  git clone https://github.com/jacksonliam/mjpg-streamer/
  cd mjpg-streamer/mjpg-streamer-experimental/
  make
  make install
  cd /
  # Cleanup
  rm -rf /tmp/mjpg-streamer
  # Create needed folder
  mkdir -p /var/www/mjpg
  # Permissions
  chown octoprint:octoprint /var/www/mjpg
fi
EOF
 
