#!/bin/bash
set -e

echo "[WiFi Check] Waiting for system to settle..."
sleep 10

echo "[WiFi Check] Checking for internet connectivity..."
if ping -c 1 -W 3 8.8.8.8 > /dev/null 2>&1; then
    echo "[WiFi Check] Internet is available. No action needed."
else
    echo "[WiFi Check] No internet connection detected. Switching to AP mode..."
    /home/pi/Raspi_Portal/scripts/start_ap_mode.sh
fi
