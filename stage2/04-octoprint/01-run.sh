#!/bin/bash -e

install -m 644 files/octoprint.service ${ROOTFS_DIR}/etc/systemd/system/octoprint.service

install -m 644 files/nginx.conf ${ROOTFS_DIR}/etc/nginx/nginx.conf
echo -e "listen 443;" > ${ROOTFS_DIR}/etc/nginx/listen.conf

on_chroot << EOF
# Package enables this when installed, won't start until first-time is run due to missing SSL certs
systemctl disable nginx 
# If OctoPrint already exists, skip this (for debugging)
if [[ ! -f /srv/octoprint/bin/octoprint ]]; then
  cd /srv/ || exit 1
  virtualenv octoprint || exit 1
  source octoprint/bin/activate || exit 1
  pip install pip --upgrade 
  pip install octoprint || exit 1
  # Fix permissions
  chown -R octoprint:octoprint /srv/octoprint
fi
# Enable the reverse proxy
systemctl enable nginx
EOF
