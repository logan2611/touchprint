#!/usr/bin/env bash
set -e

install -m 644 files/resolv.conf "${ROOTFS_DIR}/etc/"
