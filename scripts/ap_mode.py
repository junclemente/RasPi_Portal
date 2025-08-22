#!/usr/bin/env python3
import subprocess


def start_ap_mode():
    """Start AP mode by enabling hostapd + dnsmasq."""
    subprocess.run(["systemctl", "start", "hostapd"], check=False)
    subprocess.run(["systemctl", "start", "dnsmasq"], check=False)


if __name__ == "__main__":
    start_ap_mode()
