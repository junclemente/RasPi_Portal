#!/usr/bin/env python3
import subprocess
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent
SETUP_SH = REPO_ROOT / "setup.sh"


def main():
    if not SETUP_SH.exists():
        print(f"❌ {SETUP_SH} not found.")
        return

    print(f"🚀 Running {SETUP_SH} ...")
    try:
        subprocess.run(["sudo", str(SETUP_SH)], check=True)
        print("✅ Install finished")
    except subprocess.CalledProcessError as e:
        print(f"❌ Install failed with exit code {e.returncode}")


if __name__ == "__main__":
    main()
