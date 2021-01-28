change_password () {
  if [[ "$1" != "" ]]; then
    if [[ "$1" == "export" ]]; then
      echo "PI_PWD_HASH='$(awk -F ":" '/pi/{print $2}' /etc/shadow)'" >> $2
      return 0;
    elif [[ "$1" == "hash" ]]; then
      usermod -p "$2" pi
      return 0;
    else
      local PASSWORD="$1"
    fi
  else
    local PASSWORD="$(dialog --title "Change Password" $FIRST_TIME --insecure --passwordbox "Enter new password for user \"pi\"" 10 50 3>&1 1>&2 2>&3 || return 0)"
  fi

  # If the password field was left blank and we aren't in the first time setup, exit
  [[ $PASSWORD == "" ]] && [[ $FIRST_TIME == "" ]] && return 0

  # If we are in the first time setup and the password field is blank, make the user restart
  [[ $PASSWORD == "" ]] && ! [[ $FIRST_TIME == "" ]] && change_password
  
  # If the password is raspberry, tell the user he is an idiot
  if [[ "$PASSWORD" == "raspberry" ]]; then
    dialog --title "Change Password" --msgbox "That password sucks. Please use a different one :)" 10 50
    change_password
    return 0
  fi

  if [[ "$(dialog $FIRST_TIME --title "Change Password" --insecure --passwordbox "Confirm new password for user \"pi\"" 10 50 3>&1 1>&2 2>&3 || return 0)" == "$PASSWORD" ]]; then
    echo -e "pi:$PASSWORD" | chpasswd
  else
    dialog --title "Change Password" --colors --msgbox "\Z1\ZbPasswords did not match!" 5 30
    change_password
    return 0
  fi

  unset PASSWORD
}

service_toggle () {
  if [[ "$1" != "" ]]; then
    if [[ "$1" == "export" ]]; then
      echo "SERVICE_TOGGLE=\"$(if [[ -f /etc/systemd/system/multi-user.target.wants/octoprint.service ]]; then echo "true"; else echo "false"; fi) \
$(if [[ -f /etc/systemd/system/multi-user.target.wants/mjpg-streamer.service ]]; then echo "true"; else echo "false"; fi) \
$(if [[ $(systemctl get-default) == "graphical.target" ]]; then echo "true"; else echo "false"; fi) \
$(if [[ -f /etc/systemd/system/multi-user.target.wants/ssh.service ]]; then echo "true"; else echo "false"; fi)\"" >> $2
      return 0
    else
      local ENABLE_OCTO=$1
      local ENABLE_MJPG=$2
      local ENABLE_GUI=$3
      local ENABLE_SSH=$4
    fi
  else
    # Toggle the checkboxes if the service is active or not
    local SERVICE_MENU=$(dialog $FIRST_TIME --title "Select services" --checklist "Enable/disable services" 0 0 0 \
      "1" "OctoPrint" $(if [[ -f /etc/systemd/system/multi-user.target.wants/octoprint.service ]]; then echo "ON"; else echo "OFF"; fi) \
      "2" "MJPG-Streamer" $(if [[ -f /etc/systemd/system/multi-user.target.wants/mjpg-streamer.service ]]; then echo "ON"; else echo "OFF"; fi) \
      "3" "GUI" $(if [[ $(systemctl get-default) == "graphical.target" ]]; then echo "ON"; else echo "OFF"; fi) \
      "4" "SSH" $(if [[ -f /etc/systemd/system/multi-user.target.wants/ssh.service ]]; then echo "ON"; else echo "OFF"; fi) 3>&1 1>&2 2>&3 || return 0)

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
  fi

  # If FIRST_TIME is not empty, this is the first time boot so don't actually start stuff, otherwise use normal behaviour
  if [[ "$FIRST_TIME" != "" ]]; then
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

    if [[ $ENABLE_OCTO == true ]] && [[ $ENABLE_MJPG == true ]]; then
      systemctl enable nginx
    elif [[ $ENABLE_OCTO == false ]] && [[ $ENABLE_MJPG == false ]]; then
      systemctl disable nginx
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
  else
    if [[ $ENABLE_OCTO == true ]]; then
      systemctl enable --now octoprint
    else
      systemctl disable --now octoprint
    fi

    if [[ $ENABLE_MJPG == true ]]; then
      systemctl enable --now mjpg-streamer
      raspi-config nonint do_camera 0 # Counter intuitively enables the camera
      ASK_REBOOT=true
    else
      systemctl disable --now mjpg-streamer
      raspi-config nonint do_camera 1 # Disables the camera
      ASK_REBOOT=true
    fi

    if [[ $ENABLE_OCTO == true ]] && [[ $ENABLE_MJPG == true ]]; then
      systemctl enable --now nginx
    elif [[ $ENABLE_OCTO == false ]] && [[ $ENABLE_MJPG == false ]]; then
      systemctl disable --now nginx
    fi

    if [[ $ENABLE_GUI == true ]]; then
      systemctl set-default graphical.target
      ASK_REBOOT=true
    else
      systemctl set-default multi-user.target
      ASK_REBOOT=true
    fi

    if [[ $ENABLE_SSH == true ]]; then
      systemctl enable --now ssh 
    else
      systemctl disable --now ssh
    fi
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
  if [[ -f /home/kiosk/.xtimeout ]]; then
    local TIMEOUT=$(awk '/xset s [0-9 o O]/{print $3}' /home/kiosk/.xtimeout)
  else
    local TIMEOUT="off"
  fi

  if [[ "$1" != "" ]]; then
    if [[ "$1" == "export" ]]; then
      echo "SCREEN_TIMEOUT=$(awk '/xset s [0-9 o O]/{print $3}' /home/kiosk/.xtimeout)" >> $2
      return 0
    else
      TIMEOUT=$1
    fi
  else
    local TIMEOUT=$(dialog $FIRST_TIME --title "Screen Timeout" --inputbox "Input your desired screen timeout in seconds.\nEnter \"off\" to disable the screen timeout.\n\nAdding a screen timeout can reduce screen burn in.\n\nDefault: off" 12 60 $TIMEOUT 3>&1 1>&2 2>&3 || return 0) 
  fi

  # If timeout is blank, exit before we break everything 
  [[ "$TIMEOUT" == "" ]] && return 0

  cat > /home/kiosk/.xtimeout << EOF
    xset s ${TIMEOUT}
    xset -dpms
    xset s noblank 
EOF

  if [[ $(readlink -f /etc/systemd/system/default.target) == "/usr/lib/systemd/system/graphical.target" ]] && [[ "$FIRST_TIME" == "" ]]; then 
    ASK_REBOOT=true
  fi
}

octo_autologin () {
  local AUTOLOGIN_MENU=$(octo-settings read accessControl autologinAs)

  if [[ "$1" != "" ]]; then
    if [[ "$1" == "export" ]]; then
      echo "OCTO_AUTOLOGIN=$AUTOLOGIN_MENU" >> $2
      return 0
    else
      AUTOLOGIN_MENU=$1
    fi
  else
    AUTOLOGIN_MENU="$(dialog --title "OctoPrint AutoLogin" --inputbox "Enter the username of the user that you want the GUI to autologin as on startup." 10 50 $AUTOLOGIN_MENU 3>&1 1>&2 2>&3 || return 0)"
  fi

  # If the text field is blank, exit before everything (probably doesn't) break 
  [[ "$AUTOLOGIN_MENU" == "" ]] && return 0

  octo-settings write accessControl autologinAs $AUTOLOGIN_MENU
  
  if [[ -f /etc/systemd/system/multi-user.target.wants/octoprint.service ]] && [[ "$FIRST_TIME" == "" ]]; then
    systemctl restart octoprint
    ASK_REBOOT=true
  fi
}

nginx_listen () {
  # Grab the variable from the nginx conf if it exists, otherwise use default
  if [[ -f /etc/nginx/listen.conf ]]; then
    local LISTEN=$(awk '/listen/{gsub(";",""); print $2}' /etc/nginx/listen.conf) 
  else
    local LISTEN="443"
  fi
  
  if [[ "$1" != "" ]]; then
    if [[ "$1" == "export" ]]; then
      echo "NGINX_LISTEN=$LISTEN" >> $2
      return 0
    fi
  else
    LISTEN=$(dialog --title "Nginx Config" --inputbox "Configure what port and IP Nginx should listen on.\nTo listen on all IPs, just enter the port.\nDefault: 443" 11 50 "$LISTEN" 3>&1 1>&2 2>&3 || return 0)
  fi

  [[ "$LISTEN" == "" ]] && return 0

  # Write new value to nginx
  echo "listen $LISTEN ssl;" > /etc/nginx/listen.conf
  
  if [[ -f /etc/systemd/system/multi-user.target.wants/nginx.service ]] && [[ "$FIRST_TIME" == "" ]]; then
    systemctl restart nginx
    ASK_REBOOT=true
  fi
}

nginx_auth () {
  if [[ "$1" != "" ]]; then
    if [[ "$1" == "export" ]] && [[ -f /etc/nginx/.htpasswd ]]; then
      echo "NGINX_AUTH_HASH='$(cat /etc/nginx/.htpasswd)'" >> $2
      return 0
    else
      if [[ "$1" == "hash" ]]; then
        echo -e "satisfy any;\nallow 127.0.0.1;\ndeny all;\nauth_basic \"TouchPrint MJPG Stream\";\nauth_basic_user_file /etc/nginx/.htpasswd;" > /etc/nginx/auth.conf
        echo "$(echo $2 | awk -F ":" '{print $1}'):$(echo $2 | awk -F ":" '{print $2}')" > /etc/nginx/.htpasswd
        return 0;
      else
        local NGINXAUTH_MENU=($1 $2)
      fi
    fi 
  else
    local NGINXAUTH_MENU=$(dialog --colors $FIRST_TIME --insecure --title "Nginx Config" --mixedform "Input desired username and password for the MJPG stream.\n\nLeave both fields blank if you do not want authentication \Zb\Z1(NOT RECOMMENDED)\Zn." 12 60 0\
      "Username: " 1 1 "$(awk -F ":" '{print $1}' /etc/nginx/.htpasswd)" 1 11 10 0 0 \
      "Password: " 2 1 "" 2 11 30 0 1 3>&1 1>&2 2>&3 || return 0)
    NGINXAUTH_MENU=($NGINXAUTH_MENU)
  fi

  # If all the fields are blank, remove the auth stuff and exit
  if [[ "${NGINXAUTH_MENU[*]}" == "" ]]; then
    echo "" > /etc/nginx/auth.conf
    rm /etc/nginx/.htpasswd
    return 0
  fi

  # If only one of them is blank, make the user start over
  if [[ ${NGINXAUTH_MENU[0]} == "" ]] || [[ ${NGINXAUTH_MENU[1]} == "" ]]; then
    dialog --title "Nginx Config" --colors --msgbox "\Z1\ZbInvalid input!" 5 20
    nginx_auth
    return 0
  fi

  # Write the auth config and password file to Nginx
  echo -e "satisfy any;\nallow 127.0.0.1;\ndeny all;\nauth_basic \"TouchPrint MJPG Stream\";\nauth_basic_user_file /etc/nginx/.htpasswd;" > /etc/nginx/auth.conf
  #htpasswd -b -B -c /etc/nginx/.htpasswd ${NGINXAUTH_MENU[0]} ${NGINXAUTH_MENU[1]}
  echo "${NGINXAUTH_MENU[0]}:$(openssl passwd -apr1 ${NGINXAUTH_MENU[1]})" > /etc/nginx/.htpasswd
  unset NGINXAUTH_MENU

  # Set perms so that no one steals our precious password hashes
  chown root:www-data /etc/nginx/.htpasswd
  chmod 640 /etc/nginx/.htpasswd
  
  if [[ -f /etc/systemd/system/multi-user.target.wants/nginx.service ]] && [[ "$FIRST_TIME" == "" ]]; then
    systemctl restart nginx
  fi
}

video_select () {
  # In the extremely unlikely event that there are no video devices, don't continue
  if ! ls /dev/video* 2>&1 >/dev/null; then
    dialog --title "Video Config" --colors --msgbox "\Z1\ZbNo video devices detected!" 5 30
    return 1
  fi

  # Grab config values
  source /usr/local/etc/mjpg-server/config.sh 

  if [[ "$1" != "" ]]; then
    if [[ "$1" == "export" ]]; then
      echo "MJPG_DEVICE=$VIDEO_DEVICE" >> $2 
      return 0
    else
      local DEVICE_MENU="$1"
    fi
  else
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

    local DEVICE_MENU=$(dialog --title "MJPG Config" $FIRST_TIME --radiolist "Choose which video device you wish to use for MJPG-Streamer" 10 50 0 $DEVICELIST 3>&1 1>&2 2>&3 || return 0)
  fi
  
  [[ "$DEVICE_MENU" == "" ]] && return 0
 
  # Write selected value to config file 
  echo -e "VIDEO_DEVICE=$DEVICE_MENU\nVIDEO_SIZE=$VIDEO_SIZE\nFRAMERATE=$FRAMERATE" > /usr/local/etc/mjpg-server/config.sh
  
  if [[ -f /etc/systemd/system/multi-user.target.wants/mjpg-streamer.service ]] && [[ "$FIRST_TIME" == "" ]]; then
    systemctl restart mjpg-streamer
  fi
}

video_config () {
  # Include config values
  source /usr/local/etc/mjpg-server/config.sh

  if [[ "$1" != "" ]]; then
    if [[ "$1" == "export" ]]; then
      echo -e "MJPG_FRAMERATE=$VIDEO_FRAMERATE\nMJPG_SIZE=$VIDEO_SIZE" >> $2
      return 0
    else
      local VIDEOCONFIG_MENU=($1 $2)
    fi
  else
    # Set video device to a resonable default if it isn't set for some reason
    if [[ "$VIDEO_DEVICE" == "" ]]; then
      VIDEO_DEVICE="/dev/video0"
    fi  

    local VIDEOCONFIG_MENU=$(dialog $FIRST_TIME --title "MJPG Config" --form "Choose desired camera resolution and framerate." 10 50 0 \
      "Resolution: " 1 1 "$VIDEO_SIZE" 1 13 10 0 \
      "Framerate: " 2 1 "$VIDEO_FRAMERATE" 2 12 3 0 3>&1 1>&2 2>&3 || return 0)
    VIDEOCONFIG_MENU=($VIDEOCONFIG_MENU)
  fi

  [[ "${VIDEOCONFIG_MENU[@]}" == "" ]] && return 0
  
  # If one of the fields is empty, tell the user to start over
  if [[ "${VIDEOCONFIG_MENU[0]}" == "" ]] || [[ "${VIDEOCONFIG_MENU[1]}" == "" ]]; then
    dialog --title "Error" --msgbox "Invalid input!" 10 50
    video_config
    return 0
  fi

  # Write values to config file 
  echo -e "VIDEO_DEVICE=$VIDEO_DEVICE\nVIDEO_SIZE=${VIDEOCONFIG_MENU[0]}\nVIDEO_FRAMERATE=${VIDEOCONFIG_MENU[1]}" > /usr/local/etc/mjpg-server/config.sh 

  if [[ -f /etc/systemd/system/multi-user.target.wants/mjpg-streamer.service ]] && [[ "$FIRST_TIME" == "" ]]; then
    systemctl restart mjpg-streamer
  fi
}
