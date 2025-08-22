#!/usr/bin/env python3
import subprocess
from pathlib import Path
import os

REPO_ROOT = Path(__file__).resolve().parent
INSTALL_SH = REPO_ROOT / "install.sh"


def main():
    if not INSTALL_SH.exists():
        print(f"❌ {INSTALL_SH} not found.")
        return

    # Ensure it's executable
    if not os.access(INSTALL_SH, os.X_OK):
        print(f"ℹ️  Making {INSTALL_SH} executable...")
        INSTALL_SH.chmod(0o755)

    print(f"🚀 Running {INSTALL_SH} ...")
    try:
        subprocess.run(["sudo", "bash", str(INSTALL_SH)], check=True)
        print("✅ Install finished")
    except subprocess.CalledProcessError as e:
        print(f"❌ Install failed with exit code {e.returncode}")


if __name__ == "__main__":
    main()
