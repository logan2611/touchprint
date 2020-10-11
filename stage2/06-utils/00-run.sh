#!/usr/bin/env bash
set -e

mkdir -p "${ROOTFS_DIR}/usr/local/bin/"
install -m 755 files/tp-config "${ROOTFS_DIR}/usr/local/bin/tp-config"
install -m 755 files/octo-settings "${ROOTFS_DIR}/usr/local/bin/octo-settings"
install -m 755 files/first-time.sh "${ROOTFS_DIR}/etc/profile.d/first-time.sh"
install -m 755 files/tp-lib.sh "${ROOTFS_DIR}/usr/local/lib/tp-lib.sh"

# Autologin on first boot
mkdir -p ${ROOTFS_DIR}/etc/systemd/system/getty@tty1.service.d/ 
cat > ${ROOTFS_DIR}/etc/systemd/system/getty@tty1.service.d/override.conf << 'EOF'
[Service]
ExecStart=
ExecStart=-/usr/sbin/agetty --skip-login --nonewline --noissue --autologin root --noclear %I $TERM
EOF

on_chroot << EOF
# Install PyYAML
pip3 install pyyaml
# Don't boot to a GUI
systemctl set-default multi-user.target
EOF
