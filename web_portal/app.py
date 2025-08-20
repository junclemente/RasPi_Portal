from flask import Flask, render_template, request, redirect
import subprocess

app = Flask(__name__)


@app.route("/", methods=["GET", "POST"])
def index():
    if request.method == "POST":
        ssid = request.form["ssid"]
        password = request.form["password"]

        # append to wpa_supplicant.conf
        with open("/etc/wpa_supplicant/wpa_supplicant.conf", "a") as f:
            f.write(
                f"""
                    network={{
                    ssid="{ssid}"
                    psk="{password}"
                    }}
                    """
            )

        # reboot to connect to wifi
        subprocess.run(["sudo", "reboot"])
        return "Rebooting and attempting to connect..."

    return render_template("index.html")


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=80)
