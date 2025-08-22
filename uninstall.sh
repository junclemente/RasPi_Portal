#!/bin/bash
set -euo pipefail

# Uninstalls raspi-wifi-ap bits installed by setup.sh
# Usage:
#   sudo ./uninstall.sh [--purge-configs] [--purge-packages] [--yes] [--dry-run]

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="/usr/local/bin"
SYSTEMD_DEST="/etc/systemd/system"

SERVICES=(ap_mode.service wifi_check.service wifi_watchdog.service)
BIN_FILES=(ap_mode.py wifi_check.py wifi_watchdog.py start_ap_mode.sh wifi_check.sh)
AP_CONF_FILES=(/etc/hostapd/hostapd.conf /etc/dnsmasq.conf /etc/dhcpcd.conf)

PURGE_CONFIGS=false
PURGE_PACKAGES=false
ASSUME_YES=false
DRY_RUN=false

log() { echo -e "$@"; }
run() { $DRY_RUN && echo "[dry-run] $* " || eval "$@"; }

confirm() {
  $ASSUME_YES && return 0
  read -r -p "$1 [y/N]: " ans
  [[ "${ans:-N}" =~ ^[Yy]$ ]]
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --purge-configs) PURGE_CONFIGS=true ;;
      --purge-packages) PURGE_PACKAGES=true ;;
      --yes|-y) ASSUME_YES=true ;;
      --dry-run) DRY_RUN=true ;;
      *) log "Unknown arg: $1"; exit 2 ;;
    esac
    shift
  done
}

require_root() {
  if [[ $EUID -ne 0 ]]; then
    log "❌ Please run as root: sudo $0 $*"
    exit 1
  fi
}

stop_disable_services() {
  log "🛑 Stopping and disabling systemd services..."
  for svc in "${SERVICES[@]}"; do
    run "systemctl stop $svc || true"
    run "systemctl disable $svc || true"
  done
}

remove_units() {
  log "🧹 Removing unit files from $SYSTEMD_DEST ..."
  for svc in "${SERVICES[@]}"; do
    if [[ -f "$SYSTEMD_DEST/$svc" ]]; then
      run "rm -f '$SYSTEMD_DEST/$svc'"
    fi
  done
  run "systemctl daemon-reload"
}

remove_bins() {
  log "🧹 Removing helper scripts from $BIN_DIR ..."
  for f in "${BIN_FILES[@]}"; do
    if [[ -f "$BIN_DIR/$f" ]]; then
      run "rm -f '$BIN_DIR/$f'"
    fi
  done
}

restore_hostapd_default() {
  local file="/etc/default/hostapd"
  if [[ -f "$file" ]]; then
    # Comment out DAEMON_CONF= line we may have added/modified
    log "♻️  Restoring $file DAEMON_CONF (commenting out if present)..."
    run "sed -i 's|^DAEMON_CONF=.*|#DAEMON_CONF=\"/etc/hostapd/hostapd.conf\"|' '$file' || true"
  fi
}

purge_configs() {
  $PURGE_CONFIGS || return 0
  if confirm "⚠️  Remove AP/Wi‑Fi config files? This may affect your network setup."; then
    for cfg in "${AP_CONF_FILES[@]}"; do
      if [[ -f "$cfg" ]]; then
        log "🗑️  Removing $cfg"
        run "rm -f '$cfg'"
      fi
    done
  else
    log "Skipped purging configs."
  fi
}

purge_packages() {
  $PURGE_PACKAGES || return 0
  if confirm "⚠️  Remove packages hostapd, dnsmasq, dhcpcd5, python3-flask, iw?"; then
    run "apt-get remove -y hostapd dnsmasq dhcpcd5 python3-flask iw || true"
    run "apt-get autoremove -y || true"
  else
    log "Skipped package removal."
  fi
}

summary() {
  log "✅ Uninstall complete."
  $DRY_RUN && log "Note: this was a dry-run; no changes were made."
}

main() {
  parse_args "$@"
  require_root
  stop_disable_services
  remove_units
  remove_bins
  restore_hostapd_default
  purge_configs
  purge_packages
  summary
}

main "$@"
