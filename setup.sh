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
    sudo mkdir -p /etc/hostapd
    sudo cp ap_mode/hostapd.conf /etc/hostapd/hostapd.conf
    sudo cp ap_mode/dnsmasq.conf /etc/dnsmasq.conf
}

# function: configure hostapd default path
configure_hostapd() {
    echo "Settings hostapd default config file..."
    sudo sed -i 's|^#DAEMON_CONF=.*|DAEMON_CONF="/etc/hostapd/hostapd.conf"|' /etc/default/hostapd
}

# install and enable systemd services
setup_services() {
    echo "Installing and enabling systemd services..."
    sudo cp systemd/ap-mode.service /etc/systemd/system/
    sudo cp systemd/wifi-check.service /etc/systemd/system/
    sudo systemctl enable ap-mode.service
    sudo systemctl enable wifi-check.service
}

# fix script permissions
set_permissions() {
    echo "Setting executable permissions..."
    chmod +x scripts/*.sh
    chmod +x web_portal/app.py
}

# main runner
main() {
    install_dependencies
    stop_services
    copy_configs
    configure_hostapd
    setup_services
    set_permissions
    echo "Setup complete. Next: create your AP config and captive portal."
}

main "S@"