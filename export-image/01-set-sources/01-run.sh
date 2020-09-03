#!/usr/bin/env bash
set -e

on_chroot << EOF
apt-get update
apt-get -y dist-upgrade
apt-get clean
EOF
