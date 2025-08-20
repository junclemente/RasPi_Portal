#!/bin/bash
set -e

echo "Starting raspi-wifi-ap setup..."

# function: install system dependencies
install_dependencies() {
    echo "Installing required packages..."

     # Set noninteractive mode to skip config file prompts
    export DEBIAN_FRONTEND=noninteractive
    sudo apt-get install -y --option=Dpkg::Options::="--force-confold" hostapd dnsmasq python3-flask dhcpcd5
}

# function: stop conflicting services
stop_services() {
    echo "Stopping hostapd and dnsmasq..."
    sudo systemctl stop hostapd || true
    sudo systemctl stop dnsmasq || true

    echo "Disable NetworkManager (if running)..."
    sudo systemctl stop NetworkManager || true
    sudo systemctl disable NetworkManager || true 
}

# function: copy default AP configs
copy_configs() {
    echo "Copying configuration files..." 
    sudo mkdir -p /etc/hostapd
    sudo cp ap_mode/hostapd.conf /etc/hostapd/hostapd.conf
    sudo cp ap_mode/dnsmasq.conf /etc/dnsmasq.conf
    sudo cp ap_mode/dhcpcd.conf /etc/dhcpcd.conf

    echo "Restarting dhcpcd to apply static IP config..." 
    sudo systemctl restart dhcpcd
}

# function: configure hostapd default path
configure_hostapd() {
    echo "Settings hostapd default config file..."
    sudo sed -i 's|^#DAEMON_CONF=.*|DAEMON_CONF="/etc/hostapd/hostapd.conf"|' /etc/default/hostapd
}

# install and enable systemd services
setup_services() {
    echo "Installing and enabling systemd services..."
    sudo cp systemd/ap_mode.service /etc/systemd/system/ap_mode.service
    sudo cp systemd/wifi_check.service /etc/systemd/system/wifi_check.service

    sudo systemctl daemon-reload
    sudo systemctl enable ap_mode.service
    sudo systemctl enable wifi_check.service

    # start services immediately
    sudo systemctl restart ap_mode.service || echo "Could not start ap_mode.service"
    sudo systemctl restart wifi_check.service || echo "Could not start wifi_check.service"
}

# fix script permissions
set_permissions() {
    echo "Setting executable permissions..."
    chmod +x scripts/*.sh
    chmod +x scripts/start_ap_mode.sh
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