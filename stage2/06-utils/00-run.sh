#!/usr/bin/env bash
set -e

mkdir -p "${ROOTFS_DIR}/usr/local/bin/"
install -m 755 files/octo-config "${ROOTFS_DIR}/usr/local/bin/octo-config"
install -m 755 files/first-time.sh "${ROOTFS_DIR}/etc/profile.d/first-time.sh"
install -m 755 files/octo-lib.sh "${ROOTFS_DIR}/usr/local/lib/octo-lib.sh"

# Autologin on first boot
mkdir -p ${ROOTFS_DIR}/etc/systemd/system/getty@tty1.service.d/ 
cat > ${ROOTFS_DIR}/etc/systemd/system/getty@tty1.service.d/override.conf << 'EOF'
[Service]
ExecStart=
ExecStart=-/usr/sbin/agetty --autologin root --noclear %I $TERM
EOF

# Don't boot to a GUI
on_chroot << EOF
systemctl set-default multi-user.target
EOF
