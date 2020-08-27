#!/bin/bash

# Grabs the port (and IP) out of the nginx config
LISTEN=$(awk '/listen/{gsub(";",""); print $2}' /etc/nginx/listen.conf)

# If the value we just grabbed doesn't contain an IP, prepend localhost
if ! echo $LISTEN | grep ":" 2>&1; then
  ADDRESS="https://localhost:$LISTEN"
else
  ADDRESS="https://$LISTEN"
fi

# Override the automatically detected address if the user wants to
if [[ -f ~/.overrideurl.sh ]]; then source ~/.overrideurl.sh; fi

# Wait until Nginx/override comes up
while ! curl -f -k -s -I "$ADDRESS" 2>&1 >/dev/null; do
  sleep 1
done

# Wait until OctoPrint comes up if it is enabled
while [[ -f /etc/systemd/system/multi-user.target.wants/octoprint.service ]] && ! curl -f -s -I "localhost:5000"; do
  sleep 1
done

######
## Opens browser
# -t | Disables strict TLS check
# -F | Fullscreen
# -g | Disable giving away geolocation
# -K | Enable kiosk mode (doesn't seem to do anything?)
# -n | Disable web inspector
# -p | Disable plugins
surf -t -F -g -K -n -p "$ADDRESS"
