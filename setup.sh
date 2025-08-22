#!/bin/bash
set -euo pipefail

echo "Starting raspi-wifi-ap setup..."

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Paths in repo
AP_MODE_DIR="$REPO_ROOT/ap_mode"
SYSTEMD_DIR="$REPO_ROOT/systemd"
SCRIPTS_DIR="$REPO_ROOT/scripts"
WEB_PORTAL_DIR="$REPO_ROOT/web_portal"

# Install destinations
BIN_DIR="/usr/local/bin"
SYSTEMD_DEST="/etc/systemd/system"

# function: install system dependencies
install_dependencies() {
  echo "Installing required packages..."
  export DEBIAN_FRONTEND=noninteractive
  sudo apt-get update -y
  sudo apt-get install -y --option=Dpkg::Options::="--force-confold" \
    hostapd dnsmasq python3 python3-flask dhcpcd5 iw
}

# function: stop conflicting services
stop_services() {
  echo "Stopping hostapd and dnsmasq..."
  sudo systemctl stop hostapd || true
  sudo systemctl stop dnsmasq || true

  echo "Disabling NetworkManager (if present)..."
  sudo systemctl stop NetworkManager || true
  sudo systemctl disable NetworkManager || true
}

# function: copy default AP configs
copy_configs() {
  echo "Copying configuration files..."
  sudo mkdir -p /etc/hostapd

  sudo cp "$AP_MODE_DIR/hostapd.conf" /etc/hostapd/hostapd.conf
  sudo cp "$AP_MODE_DIR/dnsmasq.conf" /etc/dnsmasq.conf
  sudo cp "$AP_MODE_DIR/dhcpcd.conf" /etc/dhcpcd.conf

  echo "Restarting dhcpcd to apply static IP config..."
  sudo systemctl restart dhcpcd
}

# function: configure hostapd default path
configure_hostapd() {
  echo "Setting hostapd default config file..."
  if grep -q '^#\?DAEMON_CONF=' /etc/default/hostapd 2>/dev/null; then
    sudo sed -i 's|^#\?DAEMON_CONF=.*|DAEMON_CONF="/etc/hostapd/hostapd.conf"|' /etc/default/hostapd
  else
    echo 'DAEMON_CONF="/etc/hostapd/hostapd.conf"' | sudo tee -a /etc/default/hostapd >/dev/null
  fi
}

# function: install helper scripts (Python-first, but compatible with .sh)
install_scripts() {
  echo "Installing helper scripts to $BIN_DIR ..."

  sudo mkdir -p "$BIN_DIR"

  # Python versions (preferred)
  if [ -f "$SCRIPTS_DIR/ap_mode.py" ]; then
    sudo install -m 755 "$SCRIPTS_DIR/ap_mode.py" "$BIN_DIR/ap_mode.py"
  fi
  if [ -f "$SCRIPTS_DIR/wifi_check.py" ]; then
    sudo install -m 755 "$SCRIPTS_DIR/wifi_check.py" "$BIN_DIR/wifi_check.py"
  fi
  if [ -f "$SCRIPTS_DIR/wifi_watchdog.py" ]; then
    sudo install -m 755 "$SCRIPTS_DIR/wifi_watchdog.py" "$BIN_DIR/wifi_watchdog.py"
  fi

  # Legacy shell (if still present, keep working)
  if ls "$SCRIPTS_DIR"/*.sh >/dev/null 2>&1; then
    for f in "$SCRIPTS_DIR"/*.sh; do
      [ -f "$f" ] || continue
      sudo install -m 755 "$f" "$BIN_DIR/$(basename "$f")"
    done
  fi

  # Flask app is run via systemd unit in your project; just ensure it’s executable if needed
  if [ -f "$WEB_PORTAL_DIR/app.py" ]; then
    chmod +x "$WEB_PORTAL_DIR/app.py" || true
  fi
}

# install and enable systemd services (including watchdog)
setup_services() {
  echo "Installing and enabling systemd services..."

  # Core services you already had
  if [ -f "$SYSTEMD_DIR/ap_mode.service" ]; then
    sudo install -m 644 "$SYSTEMD_DIR/ap_mode.service" "$SYSTEMD_DEST/ap_mode.service"
  fi
  if [ -f "$SYSTEMD_DIR/wifi_check.service" ]; then
    sudo install -m 644 "$SYSTEMD_DIR/wifi_check.service" "$SYSTEMD_DEST/wifi_check.service"
  fi

  # New watchdog service
  if [ -f "$SYSTEMD_DIR/wifi_watchdog.service" ]; then
    sudo install -m 644 "$SYSTEMD_DIR/wifi_watchdog.service" "$SYSTEMD_DEST/wifi_watchdog.service"
  fi

  sudo systemctl daemon-reload

  # Enable services if present
  for svc in ap_mode.service wifi_check.service wifi_watchdog.service; do
    if [ -f "$SYSTEMD_DEST/$svc" ]; then
      sudo systemctl enable "$svc"
    fi
  done

  # Start (or restart) services
  [ -f "$SYSTEMD_DEST/ap_mode.service" ] && sudo systemctl restart ap_mode.service || true
  [ -f "$SYSTEMD_DEST/wifi_check.service" ] && sudo systemctl restart wifi_check.service || true
  # Watchdog is oneshot; no need to start now. It runs at boot.
}

# main runner
main() {
  install_dependencies
  stop_services
  copy_configs
  configure_hostapd
  install_scripts
  setup_services
  echo "✅ Setup complete."
  echo "• AP config and services installed"
  echo "• Watchdog will bring AP back on boot if Wi‑Fi fails to associate"
}

main
