import os, shlex, subprocess, tempfile, time
from pathlib import Path
from flask import (
    Flask,
    request,
    render_template_string,
    render_template,
    redirect,
    url_for,
)

app = Flask(__name__)

WPA_PATH = Path("/etc/wpa_supplicant/wpa_supplicant.conf")
COUNTRY = os.environ.get("RPI_COUNTRY", "US")

REBOOT_AFTER_APPLY = True  # simplest reliable v1
AP_SERVICES = ["hostapd", "dnsmasq"]

SUCCESS_PAGE = """
<!doctype html>
<title>PiKaraoke Wi‑Fi</title>
<h2>Wi‑Fi saved ✅</h2>
<p>Your Pi is rebooting to join <b>{{ssid}}</b>. This page will disconnect shortly.</p>
"""

ERROR_PAGE = """
<!doctype html>
<title>PiKaraoke Wi‑Fi</title>
<h2>Something went wrong ❌</h2>
<pre>{{err}}</pre>
"""


def run(cmd):
    # Runs as root if the service runs app.py as root. Otherwise, set up sudoers once.
    return subprocess.run(shlex.split(cmd), capture_output=True, text=True, check=True)


def _dedup_networks(blocks):
    seen = set()
    unique = []
    for b in blocks:
        key = (b.get("ssid"), b.get("psk"))
        if key not in seen:
            seen.add(key)
            unique.append(b)
    return unique


def _render_wpa(conf_header, blocks):
    header = conf_header.strip().splitlines()
    needed = {
        "ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev",
        "update_config=1",
        f"country={COUNTRY}",
    }
    # keep any existing non-empty header lines; add missing required lines
    hdr = [l for l in header if l.strip()]
    for line in needed:
        if not any(line.split("=")[0] == h.split("=")[0] for h in hdr):
            hdr.append(line)

    parts = ["\n".join(hdr), ""]
    for b in blocks:
        lines = [
            "network={",
            f'    ssid="{b["ssid"]}"',
        ]
        # prefer plaintext psk for simplicity; swap to hashed if you want
        lines.append(f'    psk="{b["psk"]}"')
        lines += [
            "    key_mgmt=WPA-PSK",
            "    priority=10",
        ]
        if b.get("scan_ssid"):  # set when user ticks “hidden network”
            lines.append("    scan_ssid=1")
        lines.append("}")
        parts.append("\n".join(lines))
    return "\n\n".join(parts).strip() + "\n"


def _parse_existing_wpa(text):
    # very simple header/network splitter
    header, nets = [], []
    cur = None
    for line in text.splitlines():
        s = line.strip()
        if s.startswith("network={"):
            cur = {}
        elif s == "}" and cur is not None:
            nets.append(cur)
            cur = None
        elif cur is not None:
            if s.startswith("ssid="):
                cur["ssid"] = s.split("=", 1)[1].strip().strip('"')
            elif s.startswith("psk="):
                cur["psk"] = s.split("=", 1)[1].strip().strip('"')
            elif s.startswith("scan_ssid="):
                cur["scan_ssid"] = s.endswith("1")
        else:
            header.append(line)
    return "\n".join(header), nets


def save_wifi(ssid, psk, hidden=False):
    WPA_PATH.parent.mkdir(parents=True, exist_ok=True)
    existing = WPA_PATH.read_text() if WPA_PATH.exists() else ""
    header, blocks = _parse_existing_wpa(existing)
    blocks.append({"ssid": ssid, "psk": psk, "scan_ssid": hidden})
    blocks = _dedup_networks(blocks)
    new_text = _render_wpa(header, blocks)

    # atomic write
    with tempfile.NamedTemporaryFile("w", delete=False) as tmp:
        tmp.write(new_text)
        tmp_path = tmp.name
    os.replace(tmp_path, WPA_PATH)


def apply_wifi_now():
    # stop AP stack so wlan0 can associate
    for svc in AP_SERVICES:
        subprocess.run(["systemctl", "stop", svc], check=False)

    # (v1) reboot is simplest & robust
    if REBOOT_AFTER_APPLY:
        subprocess.Popen(["/sbin/shutdown", "-r", "now"])
        return

    # (alt: no reboot) reconfigure live
    run("systemctl restart dhcpcd")
    run("systemctl restart wpa_supplicant")
    subprocess.run(["wpa_cli", "-i", "wlan0", "reconfigure"], check=False)


@app.post("/configure")
def configure():
    try:
        ssid = request.form["ssid"].strip()
        psk = request.form["password"].strip()
        hidden = request.form.get("hidden", "").lower() in ("1", "true", "on", "yes")

        if not ssid or not psk:
            return (
                render_template_string(
                    ERROR_PAGE, err="SSID and Password are required."
                ),
                400,
            )

        save_wifi(ssid, psk, hidden=hidden)
        apply_wifi_now()
        return render_template_string(SUCCESS_PAGE, ssid=ssid)
    except Exception as e:
        return render_template_string(ERROR_PAGE, err=str(e)), 500


@app.get("/")
def index():
    return render_template("index.html")
