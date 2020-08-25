#!/bin/bash -e

install -d "${ROOTFS_DIR}/etc/systemd/system/getty@tty1.service.d"
install -m 644 files/noclear.conf "${ROOTFS_DIR}/etc/systemd/system/getty@tty1.service.d/noclear.conf"
install -v -m 644 files/fstab "${ROOTFS_DIR}/etc/fstab"
install -m 755 files/.xprofile "${ROOTFS_DIR}/etc/skel/.xprofile"
install -m 755 files/.browser.sh "${ROOTFS_DIR}/etc/skel/.browser.sh"
install -m 644 files/.dialogrc "${ROOTFS_DIR}/etc/skel/.dialogrc"
install -m 644 files/.dialogrc "${ROOTFS_DIR}/root/.dialogrc"
mkdir -p "${ROOTFS_DIR}/etc/skel/.config/openbox"
install -m 644 files/autostart "${ROOTFS_DIR}/etc/skel/.config/openbox/autostart"
install -m 644 files/menu.xml "${ROOTFS_DIR}/etc/skel/.config/openbox/menu.xml"

on_chroot << EOF
if ! id -u ${FIRST_USER_NAME} >/dev/null 2>&1; then
	adduser --disabled-password --gecos "" ${FIRST_USER_NAME}
fi
if ! id -u octoprint >/dev/null 2>&1; then
  adduser --system --shell /usr/sbin/nologin --group --disabled-password --gecos "" octoprint
fi
if ! id -u kiosk >/dev/null 2>&1; then
	adduser --disabled-password --shell /usr/sbin/nologin --gecos "" kiosk 
fi
echo "${FIRST_USER_NAME}:${FIRST_USER_PASS}" | chpasswd
echo "kiosk:$(cat /dev/urandom | tr -dc _A-Z-a-z-0-9 | head -c40)" | chpasswd 
echo "root:$(cat /dev/urandom | tr -dc _A-Z-a-z-0-9 | head -c40)" | chpasswd
EOF
