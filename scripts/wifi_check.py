#!/usr/bin/env python3
import subprocess
import sys


def wifi_connected():
    """Check if wlan0 is associated with an AP."""
    try:
        out = subprocess.check_output(["iw", "dev", "wlan0", "link"], text=True)
        return "Connected to" in out
    except subprocess.CalledProcessError:
        return False


if __name__ == "__main__":
    if wifi_connected():
        sys.exit(0)
    else:
        sys.exit(1)
