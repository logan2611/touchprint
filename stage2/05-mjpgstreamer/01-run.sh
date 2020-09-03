#!/usr/bin/env bash
set -e

install -m 644 files/mjpg-streamer.service ${ROOTFS_DIR}/etc/systemd/system/mjpg-streamer.service
install -m 755 files/start-mjpg ${ROOTFS_DIR}/usr/local/bin/start-mjpg
mkdir -p ${ROOTFS_DIR}/usr/local/etc/mjpg-server/
install -m 755 files/config.sh ${ROOTFS_DIR}/usr/local/etc/mjpg-server/

if [[ ! -f ${ROOTFS_DIR}/usr/local/bin/mjpeg-server ]]; then
  # Do some semi janky cross compilation since Golang won't let me set GOBIN when cross compiling (gogl plz fix)
  GOPATH=/tmp/go GOARCH=arm64 go get github.com/blueimp/mjpeg-server
  cp /tmp/go/bin/linux_arm64/mjpeg-server ${ROOTFS_DIR}/usr/local/bin/mjpeg-server
  rm -rf /tmp/go
fi
