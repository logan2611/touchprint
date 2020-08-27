#!/bin/bash -e

mkdir -p "${ROOTFS_DIR}/home/kiosk"
install -m 755 files/.xprofile "${ROOTFS_DIR}/home/kiosk/.xprofile"
install -m 755 files/.browser.sh "${ROOTFS_DIR}/home/kiosk/.browser.sh"

mkdir -p "${ROOTFS_DIR}/home/kiosk/.config/openbox"
install -m 644 files/autostart "${ROOTFS_DIR}/home/kiosk/.config/openbox/autostart"
install -m 644 files/menu.xml "${ROOTFS_DIR}/home/kiosk/.config/openbox/menu.xml"

