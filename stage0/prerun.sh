#!/usr/bin/env bash
set -e

if [ ! -d "${ROOTFS_DIR}" ]; then
  bootstrap ${RELEASE} "${ROOTFS_DIR}" http://deb.debian.org/debian/
fi
