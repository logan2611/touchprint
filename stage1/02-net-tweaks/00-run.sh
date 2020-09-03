#!/usr/bin/env bash
set -e

echo "${TARGET_HOSTNAME}" > "${ROOTFS_DIR}/etc/hostname"
echo "127.0.1.1		${TARGET_HOSTNAME}" >> "${ROOTFS_DIR}/etc/hosts"

ln -sf /dev/null "${ROOTFS_DIR}/etc/systemd/network/99-default.link"
