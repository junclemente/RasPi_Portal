#!/bin/bash
set -euo pipefail

echo "Starting raspi-wifi-ap setup..."

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AP_MODE_DIR="$REPO_ROOT/ap_mode"
SYSTEMD_DIR="$REPO_ROOT/systemd"
SCRIPTS_DIR="$REPO_ROOT/scripts"

BIN_DIR="/usr/local/bin"
SYSTEMD_DEST="/etc/systemd/system"

install_dependencies() {
  echo "Installing required packages..."
  export DEBIAN_FRONTEND=noninteractive
  sudo apt-get update -y
  sudo apt-get install -y --option=Dpkg::Options::="--force-confold" \
    hostapd dnsmasq python3 python3-flask dhcpcd5 iw
}

stop_services() {
  echo "Stopping hostapd and dnsmasq..."
  sudo systemctl stop hostapd || true
  sudo systemctl stop dnsmasq || true
  sudo systemctl stop web_portal || true

  echo "Disabling NetworkManager (if present)..."
  sudo systemctl stop NetworkManager || true
  sudo systemctl disable NetworkManager || true
}

copy_configs() {
  echo "Copying configuration files..."
  sudo mkdir -p /etc/hostapd
  sudo cp "$AP_MODE_DIR/hostapd.conf" /etc/hostapd/hostapd.conf
  sudo cp "$AP_MODE_DIR/dnsmasq.conf" /etc/dnsmasq.conf
  sudo cp "$AP_MODE_DIR/dhcpcd.conf" /etc/dhcpcd.conf

  # Ensure captive-portal DNS redirect is present (idempotent)
  if ! grep -q '^address=/#/192\.168\.4\.1$' /etc/dnsmasq.conf; then
    echo "address=/#/192.168.4.1" | sudo tee -a /etc/dnsmasq.conf >/dev/null
  fi

  echo "Restarting dhcpcd to apply static IP config..."
  sudo systemctl restart dhcpcd
}

configure_hostapd() {
  echo "Setting hostapd default config file..."
  if grep -q '^#\?DAEMON_CONF=' /etc/default/hostapd 2>/dev/null; then
    sudo sed -i 's|^#\?DAEMON_CONF=.*|DAEMON_CONF="/etc/hostapd/hostapd.conf"|' /etc/default/hostapd
  else
    echo 'DAEMON_CONF="/etc/hostapd/hostapd.conf"' | sudo tee -a /etc/default/hostapd >/dev/null
  fi
}

install_scripts() {
  echo "Installing helper scripts to $BIN_DIR ..."
  sudo install -m 755 "$SCRIPTS_DIR/ap_mode.py"      "$BIN_DIR/ap_mode.py"
  sudo install -m 755 "$SCRIPTS_DIR/wifi_check.py"   "$BIN_DIR/wifi_check.py"
  sudo install -m 755 "$SCRIPTS_DIR/wifi_watchdog.py" "$BIN_DIR/wifi_watchdog.py"
  sudo install -m 755 "$SCRIPTS_DIR/run_portal.py"   "$BIN_DIR/run_portal.py"
  # make sure uninstall is executable for convenience
  [ -f "$REPO_ROOT/uninstall.sh" ] && chmod +x "$REPO_ROOT/uninstall.sh" || true
}

setup_services() {
  echo "Installing and enabling systemd services..."
  # AP + checks (your existing two)
  sudo install -m 644 "$SYSTEMD_DIR/ap_mode.service"        "$SYSTEMD_DEST/ap_mode.service"
  sudo install -m 644 "$SYSTEMD_DIR/wifi_check.service"     "$SYSTEMD_DEST/wifi_check.service"
  sudo install -m 644 "$SYSTEMD_DIR/wifi_watchdog.service"  "$SYSTEMD_DEST/wifi_watchdog.service"
  # NEW: web portal
  sudo install -m 644 "$SYSTEMD_DIR/web_portal.service"     "$SYSTEMD_DEST/web_portal.service"

  sudo systemctl daemon-reload

  sudo systemctl enable ap_mode.service
  sudo systemctl enable wifi_check.service
  sudo systemctl enable wifi_watchdog.service
  sudo systemctl enable web_portal.service

  # Start/Restart services
  sudo systemctl restart ap_mode.service || echo "Could not start ap_mode.service"
  sudo systemctl restart dnsmasq || true
  sudo systemctl restart web_portal.service || echo "Could not start web_portal.service"
}

main() {
  install_dependencies
  stop_services
  copy_configs
  configure_hostapd
  install_scripts
  setup_services
  echo "✅ Setup complete."
  echo "• AP + DNS redirect installed"
  echo "• Web portal running on http://192.168.4.1"
  echo "• Watchdog will restore AP if Wi‑Fi join fails"
}

main
