#!/bin/bash
set -e

echo = "Starting Access Point Mode..." 

# set static ip for wlan0
setup_ip() {
    echo "Setting static IP for wlan0..."
    sudo ip link set wlan0 down
    sudo ip addr flush dev wlan0
    sudo ip addr ad 192.168.4.1/24 dev wlan0
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
    cd /home/pi/RasPi_Portal/webportal
    nohup python3 app.py > /dev/null 2>&1 &
}

main() {
    setup_ip
    start_dnsmasq
    start_hostapd
    start_portal
    echo "Access Point is now active!"
}
