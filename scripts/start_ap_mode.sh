#!/bin/bash
set -e

echo = "Starting Access Point Mode..." 

# set static ip for wlan0
setup_ip() {
    echo "Setting static IP for wlan0..."
    sudo ip link set wlan0 down
    sudo ip addr flush dev wlan0
    sudo ip addr add 192.168.4.1/24 dev wlan0
    sudo ip link set wlan0 up
}

# start dnsmasq
start_dnsmasq() {
    echo "Starting dnsmasq..." 
    sudo systemctl restart dnsmasq
}

# start hostapd
start_hostapd() {
    echo "Starting hostapd..."
    sudo systemctl restart hostapd
}

# start Flask portal
start_portal() {
    echo "Starting captive portal..."
    cd /home/pi/raspi_portal/webportal
    nohup python3 app.py > /dev/null 2>&1 &
}

main() {
    setup_ip
    start_dnsmasq
    start_hostapd
    start_portal
    echo "Access Point is now active!"
}

# --- Start Flask Captive Portal App ---
echo "Starting Flask app..."
LOG_DIR="/home/pi/raspi_portal/logs"
APP_PATH="/home/pi/raspi_portal/web_portal/app.py"
PORT=8080

mkdir -p "$LOG_DIR"
nohup /usr/bin/python3 "$APP_PATH" --port=$PORT >> "$LOG_DIR/app.log" 2>&1 &
