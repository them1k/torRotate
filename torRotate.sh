#!/bin/bash

cat << "EOF"


 _____         ______      _        _   _____ 
|_   _|        | ___ \    | |      | | |____ |
  | | ___  _ __| |_/ /___ | |_ __ _| |_    / /
  | |/ _ \| '__|    // _ \| __/ _` | __|   \ \
  | | (_) | |  | |\ \ (_) | || (_| | |_.___/ /
  \_/\___/|_|  \_| \_\___/ \__\__,_|\__\____/ 
                                              
  -- [TorRotat3] Tor IP automatic rotator --
                                  @themik
  
EOF

#Config
HOST="127.0.0.1"
PORT="9051"
SOCKS_PORT="9050"
PASSWORD="" #If ControlPort authentication is enabled (/etc/tor/torrc), put the plain password here
INTERVAL=10  #Time in seconds between IP changes
LOGFILE="/var/log/tor-ip-rotation.log"
CHECK_URL="https://api.ipify.org"

#Function help
show_help() {
  echo "Usage: $0 [OPTIONS]"
  echo ""
  echo "Options:"
  echo "  -i SECONDS     Set the interval between IP rotations (default: 10)"
  echo "  -p PASSWORD    Set the ControlPort password if authentication is enabled"
  echo "  -p PATH         Set the path where logs will be saved (default: /var/log/tor-ip-rotation.log)"
  echo "  -h                 Display this help message and exit"
  echo ""
  echo "Example:"
  echo "  $0 -i 20 -p 'mysecret' -l /tmp/rotations.log"
}

#Parse parameters
while [[ "$#" -gt 0 ]]; do
  case $1 in
    -i) INTERVAL="$2"; shift ;;
    -p) PASSWORD="$2"; shift ;;
    -l)  LOGFILE="$2"; shift ;;
    -h) show_help; exit 0 ;;
    *) echo "Unknown parameter passed: $1"; exit 1 ;;
  esac
  shift
done

#Send SIGNAL NEWNYM to tor
send_newnym() {
  {
    echo "AUTHENTICATE \"$PASSWORD\"";
    echo "SIGNAL NEWNYM";
    echo "QUIT";
  } | nc $HOST $PORT > /dev/null
}

#Retrieve current Tor IP
get_current_ip() {
  torsocks curl -s --max-time 10 $CHECK_URL
}

#Verify that Tor service is active and listening on SOCKS_PORT
check_tor_status() {
  pgrep -x tor > /dev/null
  TOR_PROC=$?
  ss -lntp 2>/dev/null | grep -q ":$SOCKS_PORT"
  SOCKS_OPEN=$?

  if [[ $TOR_PROC -ne 0 || $SOCKS_OPEN -ne 0 ]]; then
    echo "[x] ERROR: The Tor service is not active or 9050/tcp port is not open."
    echo "[x] Exiting"
    exit 1
  fi
}

#Main Loop
echo "[+] Starting IP rotation via Tor..."
echo "[+] Log file: $LOGFILE"

LAST_IP=""

while true; do
  check_tor_status

  send_newnym
  sleep 3 #Time for new circuit establishment, not the INTERVAL time
  CURRENT_IP=$(get_current_ip)
  TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

  if [ "$CURRENT_IP" != "$LAST_IP" ] && [ -n "$CURRENT_IP" ]; then
    echo "[+] $TIMESTAMP - IP changed: $CURRENT_IP"
    echo "$TIMESTAMP - $CURRENT_IP" >> "$LOGFILE"
    LAST_IP="$CURRENT_IP"
  else
    echo "[-] $TIMESTAMP - IP didn't change or not detected."
  fi

  sleep $INTERVAL
done
