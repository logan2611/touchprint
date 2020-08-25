change_password () {
  local PASSWORD="$(dialog --title "Change Password" --nocancel --insecure --passwordbox "Enter new password for user \"pi\"" 10 50 3>&1 1>&2 2>&3)"
  # If the password field was left blank, exit
  if [[ $? -ne 0 ]] || [[ $PASSWORD == "" ]]; then return 1; fi
  # If the password is raspberry, tell the user he is an idiot
  if [[ "$PASSWORD" == "raspberry" ]]; then
    dialog --title "Change Password" --nocancel --msgbox "That password sucks. Please use a different one :)" 10 50
    change_password
    return 0
  fi
  if [[ "$(dialog --nocancel --insecure --passwordbox "Confirm new password for user \"pi\"" 10 50 3>&1 1>&2 2>&3)" == "$PASSWORD" ]]; then
    if [[ $? != 0 ]]; then return 1; fi 
    echo -e "pi:$PASSWORD" | chpasswd
  else
    dialog --title "Change Password" --nocancel --msgbox "Passwords did not match!" 10 50
    change_password
    return 0
  fi
  unset PASSWORD
}

service_toggle () {
  # Toggle the checkboxes if the service is active or not
  local SERVICE_MENU=$(dialog --separate-output --nocancel --title "Select services" --checklist "Enable/disable services" 0 0 0 \
    "1" "OctoPrint" $(if [[ -f /etc/systemd/system/multi-user.target.wants/octoprint.service ]]; then echo "ON"; else echo "OFF"; fi) \
    "2" "MJPG-Streamer" $(if [[ -f /etc/systemd/system/multi-user.target.wants/mjpg-streamer.service ]]; then echo "ON"; else echo "OFF"; fi) \
    "3" "GUI" $(if [[ $(systemctl get-default) == "graphical.target" ]]; then echo "ON"; else echo "OFF"; fi) \
    "4" "SSH" $(if [[ -f /etc/systemd/system/multi-user.target.wants/ssh.service ]]; then echo "ON"; else echo "OFF"; fi) 3>&1 1>&2 2>&3)

  SERVICE_MENU=($SERVICE_MENU)

  local ENABLE_OCTO=false
  local ENABLE_MJPG=false
  local ENABLE_GUI=false
  local ENABLE_SSH=false

  for i in "${SERVICE_MENU[@]}"; do
    case $i in
      "1") ENABLE_OCTO=true ;;
      "2") ENABLE_MJPG=true ;;
      "3") ENABLE_GUI=true ;;
      "4") ENABLE_SSH=true ;;
    esac
  done

  if [[ $ENABLE_OCTO == true ]]; then
    systemctl enable octoprint
  else
    systemctl disable octoprint
  fi

  if [[ $ENABLE_MJPG == true ]]; then
    systemctl enable mjpg-streamer
    raspi-config nonint do_camera 0 # Counter intuitively enables the camera  
  else
    systemctl disable mjpg-streamer
    raspi-config nonint do_camera 1 # Disables the camera
  fi

  if [[ $ENABLE_GUI == true ]]; then
    systemctl set-default graphical.target 
  else
    systemctl set-default multi-user.target  
  fi

  if [[ $ENABLE_SSH == true ]]; then
    systemctl enable ssh 
  else
    systemctl disable ssh
  fi

<< 'EOF'
  for ((i = 0; i <= 3; i++)); do
    for n in "${SERVICE_MENU[@]}"; do
      if [[ $i == $n ]]; then
        case $i in
          "1") systemctl enable octoprint ;;
          "2") systemctl set-default graphical.target ;;
          "3") systemctl enable ssh ;;
        esac
        break
      fi
    done
    case $i in
      "1") systemctl disable octoprint ;;
      "2") systemctl set-default graphical.target ;;
      "3") systemctl disable ssh ;;
    esac
  done
EOF
}

screen_timeout () {
  local TIMEOUT=$(dialog --nocancel --title "Screen Timeout" --inputbox "Input your desired screen timeout in seconds.\nEnter \"off\" to disable the screen timeout.\n\nAdding a screen timeout can reduce screen burn in.\n\nDefault: off" 12 60 "off" 3>&1 1>&2 2>&3) 
  
  [[ "$TIMEOUT" == "" ]] && return 0

  cat > /home/kiosk/.xtimeout << EOF
    xset s ${TIMEOUT}
    xset -dpms 
EOF
}

nginx_config () {
  local LISTEN=""
  
  # Grab the variable from the nginx conf if it exists, otherwise use default
  if [[ -f /etc/nginx/listen.conf ]]; then
    LISTEN=$(awk '/listen/{gsub(";",""); print $2}' /etc/nginx/listen.conf) 
  else
    LISTEN="443"
  fi
  
  LISTEN=$(dialog --title "Nginx Config" --nocancel --inputbox "Configure what port and IP Nginx should listen on.\nTo listen on all IPs, just enter the port.\nDefault: 443" 11 50 "$LISTEN" 3>&1 1>&2 2>&3)

  [[ "$LISTEN" == "" ]] && return 0

  # Write new value to nginx
  echo "listen $LISTEN;" > /etc/nginx/listen.conf
}
  
video_select () {
  # In the unlikely event that there are no video devices, don't continue
  if ! ls /dev/video* 2>&1 >/dev/null; then
    dialog --title "Error" --msgbox "No video devices detected!" 10 50
    return 1
  fi

  # Grab config values
  source /usr/local/etc/mjpg-server/config.sh 

  # Grab all video devices
  local DEVICES=($(ls /dev/video*))
  
  local DEVICELIST=""

  # Generate a menu from said video devices
  for ((i = 0; i < ${#DEVICES[@]}; i++)); do
    if [[ "$VIDEO_DEVICE" == ${DEVICES[$i]} ]]; then
      DEVICELIST+="${DEVICES[$i]} $i ON "
    else
      DEVICELIST+="${DEVICES[$i]} $i OFF "
    fi
  done

  local DEVICE_MENU=$(dialog --title "MJPG Config" --nocancel --radiolist "Choose which video device you wish to use for MJPG-Streamer" 10 50 0 $DEVICELIST 3>&1 1>&2 2>&3)
  
  [[ "$DEVICE_MENU" == "" ]] && return 0
 
  # Write selected value to config file 
  echo -e "VIDEO_DEVICE=$DEVICE_MENU\nVIDEO_SIZE=$VIDEO_SIZE\nFRAMERATE=$FRAMERATE" > /usr/local/etc/mjpg-server/config.sh 
}

video_config () {
  # Include config values
  source /usr/local/etc/mjpg-server/config.sh

  # Set video device to a resonable default if it isn't set for some reason
  if [[ "$VIDEO_DEVICE" == "" ]]; then
    VIDEO_DEVICE="/dev/video0"
  fi  

  local VIDEOCONFIG_MENU=$(dialog --nocancel --title "MJPG Config" --form "Choose desired camera resolution and framerate." 10 50 0\
    "Resolution: " 1 1 "$VIDEO_SIZE" 1 13 10 0 \
    "Framerate: " 2 1 "$FRAMERATE" 2 12 3 0 3>&1 1>&2 2>&3)
  VIDEOCONFIG_MENU=($VIDEOCONFIG_MENU)

  if [[ "$VIDEOCONFIG_MENU[0]" == "" ]] || [[ "$VIDEOCONFIG_MENU[1]" == "" ]]; then
    dialog --title "Error" --msgbox "Invalid input!" 10 50
    video_config
    return 0
  fi

  # Write values to config file 
  echo -e "VIDEO_DEVICE=$VIDEO_DEVICE\nVIDEO_SIZE=${VIDEOCONFIG_MENU[0]}\nFRAMERATE=${VIDEOCONFIG_MENU[1]}" > /usr/local/etc/mjpg-server/config.sh 
}
