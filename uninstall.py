#!/usr/bin/env python3
import subprocess
from pathlib import Path
import os

REPO_ROOT = Path(__file__).resolve().parent
UNINSTALL_SH = REPO_ROOT / "uninstall.sh"


def main():
    if not UNINSTALL_SH.exists():
        print(f"❌ {UNINSTALL_SH} not found.")
        return

    # Ensure it's executable
    if not os.access(UNINSTALL_SH, os.X_OK):
        print(f"ℹ️  Making {UNINSTALL_SH} executable...")
        UNINSTALL_SH.chmod(0o755)

    print(f"🧹 Running {UNINSTALL_SH} ...")
    try:
        # Run explicitly through bash, so it works even with shebang issues
        subprocess.run(["sudo", "bash", str(UNINSTALL_SH)], check=True)
        print("✅ Uninstall finished")
    except subprocess.CalledProcessError as e:
        print(f"❌ Uninstall failed with exit code {e.returncode}")


if __name__ == "__main__":
    main()
