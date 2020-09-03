#!/usr/bin/env bash

# This should never happen, no harm in checking though ;)
if [ "$EUID" -ne 0 ]; then 
  echo "This image has not been configured properly. Please file an issue at https://github.com/logan2611/touchprint/issues"
  bash
  exit 1
fi

# Import common functions
source /usr/local/lib/tp-lib.sh

install_package () {
  echo "==========Installing $1==========" >>/home/pi/install.log 
  source /srv/octoprint/bin/activate || return 1
  pip install $1 2>&1 >>/home/pi/install.log || return 1
}

error_install () {
  dialog --title "ERROR" --msgbox "Error installing $1!" 10 50
}

recommended_menu () {
  local RECOMMEND_MENU=$(dialog --nocancel --title "Plugin Manager | Recommended Plugins" --checklist "Check plugins that you wish to install." 0 0 0 \
  "OctoPrint-Dashboard" "Adds a nice dashboard to OctoPrint." ON \
  "ExcludeRegion" "Select regions of the bed where you don't want to print." ON \
  "NavbarTemp" "Shows the temperature of the Pi, extruder(s) and bed in the navigation bar." ON \
  "PrintTimeGenius" "Provides more accurate print time estimates." ON \
  "HeaterTimeout" "Turns off the hotend and bed after a set amount of time." ON \
  "TouchUI" "Makes the UI easier to use on touchscreens. Also adds a virtual keyboard." ON 3>&1 1>&2 2>&3)

  RECOMMEND_MENU=($RECOMMEND_MENU)
   
  for ((i = 0; i < ${#RECOMMEND_MENU[@]}; i++)); do
    echo $(( $i * 100 / ${#RECOMMEND_MENU[@]} )) | dialog --title "Plugin Manager" --gauge "Installing ${RECOMMEND_MENU[$i]}" 10 50
    case ${RECOMMEND_MENU[$i]} in
      "OctoPrint-Dashboard") install_package "https://github.com/StefanCohen/OctoPrint-Dashboard/archive/master.zip" || error_install "OctoPrint-Dashboard"; install_package "https://github.com/OllisGit/OctoPrint-DisplayLayerProgress/releases/latest/download/master.zip" || error_install "OctoPrint-Dashboard";;
      "ExcludeRegion") install_package "https://github.com/bradcfisher/OctoPrint-ExcludeRegionPlugin/archive/master.zip" || error_install "ExcludeRegion";;
      "NavbarTemp") install_package "https://github.com/imrahil/OctoPrint-NavbarTemp/archive/master.zip" || error_install "NavbarTemp";;
      "PrintTimeGenius") install_package "https://github.com/eyal0/OctoPrint-PrintTimeGenius/archive/master.zip" || error_install "PrintTimeGenius";;
      "HeaterTimeout") install_package "https://github.com/google/OctoPrint-HeaterTimeout/archive/master.zip" || error_install "HeaterTimeout";;  
      "TouchUI") install_package "https://github.com/BillyBlaze/OctoPrint-TouchUI/archive/master.zip" || error_install "TouchUI";;
    esac
  done
}

suggested_menu () {
  local SUGGEST_MENU=$(dialog --nocancel --title "Plugin Manager | Suggested Plugins" --checklist "Check plugins that you wish to install.\n\nSome of these may conflict with the recommended plugins." 0 0 0 \
  "Themeify" "Adds theming supports and a few themes to OctoPrint." OFF \
  "Preheat" "Adds a preheat button to preheat the bed and extruder to the temperature set in the selected gcode file." OFF \
  "ConsolidatedTabs" "Allows you to combine several tabs into one larger tab with draggable and resizable panels." OFF \
  "DetailedProgress" "Sends commands to your printer to display current printing progress." OFF 3>&1 1>&2 2>&3)
  
  SUGGEST_MENU=($SUGGEST_MENU)
   
  for ((i = 0; i < ${#SUGGEST_MENU[@]}; i++)); do
    echo $(( $i * 100 / ${#SUGGEST_MENU[@]} )) | dialog --title "Plugin Manager" --gauge "Installing ${SUGGEST_MENU[$i]}" 10 50
    case ${SUGGEST_MENU[$i]} in
      "Themeify") install_package "https://github.com/birkbjo/OctoPrint-Themeify/archive/master.zip" || error_install "Themeify";;
      "Preheat") install_package "https://github.com/marian42/octoprint-preheat/archive/master.zip" || error_install "Preheat";;
      "ConsolidatedTabs") install_package "https://github.com/jneilliii/OctoPrint-ConsolidatedTabs/archive/master.zip" || error_install "ConsolidatedTabs";;
      "DetailedProgress") install_package "https://github.com/tpmullan/OctoPrint-DetailedProgress/archive/master.zip" || error_install "DetailedProgress";;
    esac
  done
}

dialog --title "NOTICE" --nocancel --colors --msgbox "This collection of software is currently in beta, it may contain several bugs. This software is \Zb\Z1NOT\Zn recommended for a production environment." 10 50

# Makes a certificate and key for Nginx HTTPS
openssl req -x509 -nodes -days 36500 -newkey rsa:4096 -subj "/C=/ST=/L=/O=/OU=/CN=*/emailAddress=" -out /etc/ssl/certs/nginx-octoprint.crt -keyout /etc/ssl/private/nginx-octoprint.key

# Force the user to change the pi user's password before the RPi gets botnetted
change_password
# Randomize the root password
echo "root:$(cat /dev/urandom | tr -dc _A-Z-a-z-0-9 | head -c40)" | chpasswd

dialog --title "Network Configuration" --nocancel --msgbox "Setup will now open nmtui, a program to help configure your ethernet/wireless interfaces. Hit Quit when you are done." 10 50
nmtui

# Configure the timezone
dpkg-reconfigure tzdata

# Enable/disable OctoPrint, GUI, MJPG and SSH
service_toggle 

screen_timeout

# If a touchscreen is detected, and the GUI is enabled, ask the user if they want to calibrate it
if ( udevadm info --export-db | grep ID_INPUT_TOUCHSCREEN=1 >/dev/null ) && [[ $(readlink -f /etc/systemd/system/default.target) == "/usr/lib/systemd/system/graphical.target" ]] && dialog --title "Touchscreen Calibration" --defaultno --yesno "Do you wish to calibrate your touchscreen?\nMost touchscreens are calibrated out of the factory, so this is usually not needed." 10 60; then
  startx $(which xinput_calibrator) --no-timeout --output-filename /etc/X11/xorg.conf.d/99-calibration.conf 
fi

# If OctoPrint and the GUI are running locally, ask the user if they want to change the autologin user
if [[ -f /etc/systemd/system/multi-user.target.wants/octoprint.service ]] && [[ $(readlink -f /etc/systemd/system/default.target) == "/usr/lib/systemd/system/graphical.target" ]] && dialog --title "OctoPrint AutoLogin" --yesno "Do you wish to configure the user that the GUI auto logs in as in OctoPrint?\nThis is required if you wish to enable access control in OctoPrint." 10 60; then
  octo_autologin
fi

# If OctoPrint/MJPG Streamer is running locally, ask if the user wants to change the default listening port/IP (optional)
if ( [[ -f /etc/systemd/system/multi-user.target.wants/octoprint.service ]] || [[ -f /etc/systemd/system/multi-user.target.wants/mjpg-streamer.service ]] ) && dialog --title "Nginx Config" --defaultno --yesno "Do you wish to change the default Nginx listening address and/or port?" 10 60; then
  nginx_listen
fi

# If MJPG service is enabled, ask the user to configure Nginx basic auth and the video device
if [[ -f /etc/systemd/system/multi-user.target.wants/mjpg-streamer.service ]]; then
  nginx_auth
  video_select
  video_config
fi

# If OctoPrint is running locally, ask if user wants to preinstall recommended plugins
if [[ -f /etc/systemd/system/multi-user.target.wants/octoprint.service ]] && dialog --title "Plugin Manager" --yesno "Do you wish to preinstall some suggested plugins?" 10 60; then 
  recommended_menu || return 1
  suggested_menu || return 1
  chown -R octoprint:octoprint /srv/octoprint
  chown -R octoprint:octoprint /home/octoprint
fi

# Delete the autologin override and first-time setup utility
rm /etc/systemd/system/getty@tty1.service.d/override.conf 
rm /etc/profile.d/first-time.sh

dialog --title "TouchPrint Config" --colors --msgbox "Congratulations! Your install of TouchPrint has been successfully configured.\n\n\Z1To change these settings later, login to your Raspberry Pi and run \"\Z1\Zbtp-config\Zn\Z1\"." 0 0
dialog --title "TouchPrint Config" --infobox "Rebooting..." 0 0
sleep 1
reboot
