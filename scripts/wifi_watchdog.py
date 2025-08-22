#!/usr/bin/env python3
import subprocess, time


def wifi_connected():
    try:
        out = subprocess.check_output(["iw", "dev", "wlan0", "link"], text=True)
        return "Connected to" in out
    except Exception:
        return False


def start_ap_mode():
    subprocess.run(["systemctl", "start", "dnsmasq"], check=False)
    subprocess.run(["systemctl", "start", "hostapd"], check=False)


if __name__ == "__main__":
    deadline = time.time() + 45  # wait up to 45s
    while time.time() < deadline:
        if wifi_connected():
            exit(0)
        time.sleep(3)

    # Not connected → fall back to AP
    start_ap_mode()
