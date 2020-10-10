#!/usr/bin/env bash
set -e

install -m 644 files/octoprint.service ${ROOTFS_DIR}/etc/systemd/system/octoprint.service
mkdir -p ${ROOTFS_DIR}/home/octoprint/.octoprint/  
install -m 600 files/config.yaml ${ROOTFS_DIR}/home/octoprint/.octoprint/config.yaml 

install -m 644 files/nginx.conf ${ROOTFS_DIR}/etc/nginx/nginx.conf
echo -e "listen 443;" > ${ROOTFS_DIR}/etc/nginx/listen.conf
touch ${ROOTFS_DIR}/etc/nginx/auth.conf

mkdir -p ${ROOTFS_DIR}/usr/local/bin 
install -m 755 files/restart-octoprint ${ROOTFS_DIR}/usr/local/bin/restart-octoprint

# Yeah I could've used polkit, but this works fine so whatever
mkdir -p ${ROOTFS_DIR}/etc/sudoers.d 
echo "octoprint ALL=NOPASSWD: /sbin/shutdown" > ${ROOTFS_DIR}/etc/sudoers.d/octoprint-shutdown
echo "octoprint ALL=NOPASSWD: /usr/local/bin/restart-octoprint" > ${ROOTFS_DIR}/etc/sudoers.d/octoprint-restart

on_chroot << EOF
# Package enables this when installed, won't start until first-time is run due to missing SSL certs
systemctl disable nginx 

# If OctoPrint already exists, skip this (for debugging)
if [[ ! -f /srv/octoprint/bin/octoprint ]]; then
  python3 -m venv /srv/octoprint || exit 1
  source /srv/octoprint/bin/activate || exit 1
  pip install pip --upgrade 
  pip install octoprint || exit 1
  # Fix permissions
  chown -R octoprint:octoprint /srv/octoprint
  chown -R octoprint:octoprint /home/octoprint
fi
EOF
