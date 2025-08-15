#!/bin/bash
set -e

echo "📦 Setting up raspi-wifi-ap..."

# 1. Install packages
sudo apt-get update
sudo apt-get install -y hostapd dnsmasq python3-flask

# 2. Stop services before config
sudo systemctl stop hostapd
sudo systemctl stop dnsmasq

# 3. Copy configs (you’ll update these later)
sudo cp ap_mode/hostapd.conf /etc/hostapd/hostapd.conf
sudo cp ap_mode/dnsmasq.conf /etc/dnsmasq.conf

# 4. Enable hostapd
sudo sed -i 's|#DAEMON_CONF=".*"|DAEMON_CONF="/etc/hostapd/hostapd.conf"|' /etc/default/hostapd

echo "✅ Done. Next: configure AP mode and create portal"
