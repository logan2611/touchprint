#!/bin/bash -e

#echo -n -e "NODM_USER=${FIRST_USER_NAME}\nNODM_XSESSION=/home/${FIRST_USER_NAME}/.xprofile" > ${ROOTFS_DIR}/etc/nodm.conf

cat > ${ROOTFS_DIR}/etc/default/nodm << EOF
# nodm configuration

# Set NODM_ENABLED to something different than 'false' to enable nodm
NODM_ENABLED=true

# User to autologin for
NODM_USER=${FIRST_USER_NAME}

# First vt to try when looking for free VTs
NODM_FIRST_VT=7

# X session
NODM_XSESSION=/home/${FIRST_USER_NAME}/.xprofile

# Options for nodm itself
NODM_OPTIONS=

# Options for the X server.
#
# Format: [/usr/bin/<Xserver>] [:<disp>] <Xserver-options>
#
# The Xserver executable and the display name can be omitted, but should
# be placed in front, if nodm's defaults shall be overridden.
NODM_X_OPTIONS='-nolisten tcp'

# If an X session will run for less than this time in seconds, nodm will wait an
# increasing bit of time before restarting the session.
NODM_MIN_SESSION_TIME=60

# Timeout (in seconds) to wait for X to be ready to accept connections. If X is
# not ready before this timeout, it is killed and restarted.
NODM_X_TIMEOUT=300
EOF 

# Probably not needed
on_chroot << EOF
update-alternatives --install /usr/bin/x-www-browser \
  x-www-browser /usr/bin/surf 86
update-alternatives --install /usr/bin/gnome-www-browser \
  gnome-www-browser /usr/bin/surf 86
EOF
