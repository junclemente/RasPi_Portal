#!/bin/bash
set -e

echo "Starting raspi-wifi-ap setup..."

# function: install system dependencies
install_dependencies() {
    echo "Installing required packages..."
    sudo apt-get update
    sudo apt-get install -y hostapd dnsmasq python3-flask
}

# function: stop conflicting services
stop_services() {
    echo "Stopping hostapd and dnsmasq..."
    sudo systemctl stop hostapd || true
    sudo systemctl stop dnsmasq || true
}

# function: copy default AP configs
copy_configs() {
    echo "Copying configuration files..." 
    sudo cp ap_mode/hostapd.conf /etc/hostapd/hostapd.conf
    sudo cp ap_mode/dnsmasq.conf /etc/dnsmasq.conf
}

# function: configure hostapd default path
configure_hostapd() {
    echo "Settings hostapd default config file..."
    sudo sed -i 's|#DAEMON_CONF=".*"|DAEMON_CONF="/etc/hostapd/hostapd.conf"|' /etc/default/hostapd
}

# main runner
main() {
    install_dependencies
    stop_services
    copy_configs
    configure_hostapd
    echo "Setup complete. Next: create your AP config and captive portal."
}

main "S@"