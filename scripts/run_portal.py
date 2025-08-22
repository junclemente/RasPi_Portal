#!/usr/bin/env python3
"""
Launch RasPi_Portal Flask app on 0.0.0.0:80 without editing app.py.
Assumes WorkingDirectory is set to web_portal/ so `from app import app` works.
"""
from app import (
    app as flask_app,
)  # web_portal/app.py must define `app = Flask(__name__)`

if __name__ == "__main__":
    # No debug, production-ish single-process (good enough for portal)
    flask_app.run(host="0.0.0.0", port=80)
