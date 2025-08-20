# 📡 RasPi_Portal

> ⚠️ **Work in Progress**  
> This project is still under active development. Not all features are implemented yet. Expect bugs, missing components, and changes.

**Automatic Wi-Fi Access Point Mode for Raspberry Pi**

This project turns your Raspberry Pi into a Wi-Fi hotspot with a configuration portal when no known Wi-Fi network is available.

## Features

- Auto-detect internet connection
- Start fallback hotspot (AP mode)
- Captive portal for Wi-Fi config
- Auto-reconnect and reboot

## Structure

raspi-wifi-ap/
├── ap_mode/ # Configs for hostapd + dnsmasq
├── web_portal/ # Flask app and HTML portal
├── scripts/ # Wi-Fi check and AP start scripts
├── systemd/ # Autostart services
├── setup.sh # One-command installer

## License

MIT (see LICENSE)
