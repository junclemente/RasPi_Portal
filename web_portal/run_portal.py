#!/usr/bin/env python3

# import sys
# from pathlib import Path

# # Add the web_portal folder to the Python path
# project_root = Path(__file__).resolve().parent
# web_portal_path = project_root / "web_portal"
# sys.path.insert(0, str(web_portal_path))

# Import and run the Flask app
from app import app

app.run(host="0.0.0.0", port=80)
