#!/bin/bash

# Grabs the port (and IP) out of the nginx config
LISTEN=$(grep -i listen /etc/nginx/listen.conf | awk '{gsub(";",""); print $2}')

# If the value we just grabbed doesn't contain an IP, prepend localhost
if ! echo $LISTEN | grep ":" 2>&1; then
  ADDRESS="localhost:$LISTEN"
else
  ADDRESS=$LISTEN
fi

# Override the automatically detected address if the user wants to
if [[ -f ~/.overrideurl.sh ]]; then source ~/.overrideurl.sh; fi

# Wait until OctoPrint comes up
while ! curl "$ADDRESS" 2>&1 >/dev/null; do
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
surf -t -F -g -K -n -p "https://$ADDRESS"
