📡 RasPi_Portal

⚠️ Work in Progress
This project is still under active development. Not all features are implemented yet. Expect bugs, missing components, and changes.

Automatic Wi-Fi Access Point Mode for Raspberry Pi

This project turns your Raspberry Pi into a Wi-Fi hotspot with a configuration portal when no known Wi-Fi network is available.

Features

Auto-detect internet connection

Start fallback hotspot (AP mode)

Captive portal for Wi-Fi config

Auto-reconnect and reboot

Watchdog service: fall back to AP if Wi-Fi join fails

Structure

```pgsql
raspi-wifi-ap/
├── ap_mode/       # Configs for hostapd + dnsmasq
├── web_portal/    # Flask app and HTML portal
├── scripts/       # Python helpers (AP start, Wi-Fi check, watchdog)
├── systemd/       # Systemd unit definitions
├── setup.sh       # One-command installer (called by install.py)
├── install.py     # Python wrapper for setup.sh
├── uninstall.sh   # Safe uninstaller
└── uninstall.py   # Python wrapper for uninstall.sh
```

🚀 Install

Clone this repo onto your Raspberry Pi and run:

```bash
git clone https://github.com/<your-user>/<your-repo>.git
cd <your-repo>
python3 install.py
```

This will:

install required packages (hostapd, dnsmasq, dhcpcd5, python3-flask, iw),

copy AP config files into /etc/,

configure hostapd default path,

install helper scripts into /usr/local/bin/,

install & enable systemd services (ap_mode, wifi_check, wifi_watchdog).

✅ After installation:

If no known Wi-Fi is found → the Pi starts AP mode (PiKaraoke-Setup).

Connect and enter credentials → the Pi reboots and tries to join your Wi-Fi.

If Wi-Fi fails → the watchdog service restores AP mode automatically.

🗑️ Uninstall

To remove services and scripts:

```bash
python3 uninstall.py
```

By default this will stop/disable services and remove installed helper scripts.

Advanced cleanup

```bash
sudo ./uninstall.sh --purge-configs --purge-packages --yes
```

--purge-configs → remove /etc/hostapd/hostapd.conf, /etc/dnsmasq.conf, /etc/dhcpcd.conf

--purge-packages → remove packages (hostapd, dnsmasq, dhcpcd5, python3-flask, iw)

--yes → skip interactive confirmation

--dry-run → preview actions without changes

🔄 Connection Flow

```less
[Boot]
   ↓
[Wi-Fi Available?]───Yes──▶ [Join LAN normally]
        │
        No
        ↓
 [Start AP Mode] ("PiKaraoke-Setup")
        ↓
 [User opens portal]
        ↓
 [Enter SSID + Password]
        ↓
 [Save → Reboot → Retry Wi-Fi]
        │
        └─▶ [Fail to connect?] → [Return to AP mode]
```

License

MIT (see LICENSE)
