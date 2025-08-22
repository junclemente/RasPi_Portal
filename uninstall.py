#!/usr/bin/env python3
import subprocess
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent
UNINSTALL_SH = REPO_ROOT / "uninstall.sh"


def main():
    if not UNINSTALL_SH.exists():
        print(f"❌ {UNINSTALL_SH} not found.")
        return
    print(f"🧹 Running {UNINSTALL_SH} ...")
    try:
        subprocess.run(["sudo", str(UNINSTALL_SH)], check=True)
        print("✅ Uninstall finished")
    except subprocess.CalledProcessError as e:
        print(f"❌ Uninstall failed with exit code {e.returncode}")


if __name__ == "__main__":
    main()
