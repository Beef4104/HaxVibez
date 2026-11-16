#!/usr/bin/env bash
# setup_haxvibez.sh
# Last Edited by Charles Duoto on November 16, 2026
# Clones (or updates) https://github.com/Beef4104/HaxVibez
# then makes all .sh scripts executable.
#
# Usage:
#   ./setup_haxvibez.sh              # clones into ./HaxVibez
#   ./setup_haxvibez.sh /opt/hax     # clones into /opt/hax/HaxVibez
#   ./setup_haxvibez.sh --update     # just pull + chmod if already cloned

set -euo pipefail

REPO_URL="https://github.com/Beef4104/HaxVibez.git"
TARGET_DIR="HaxVibez"
BASE_DIR="."

# Parse args
if [[ $# -ge 1 ]]; then
    if [[ "$1" == "--update" || "$1" == "-u" ]]; then
        if [[ ! -d "$TARGET_DIR/.git" ]]; then
            echo "[-] $TARGET_DIR not found. Run without --update first to clone."
            exit 1
        fi
        echo "[*] Updating existing clone..."
        git -C "$TARGET_DIR" pull --ff-only
    else
        BASE_DIR="$1"
        mkdir -p "$BASE_DIR"
        TARGET_DIR="$BASE_DIR/HaxVibez"
    fi
fi

# Clone if needed
if [[ ! -d "$TARGET_DIR/.git" ]]; then
    echo "[*] Cloning $REPO_URL into $TARGET_DIR ..."
    git clone "$REPO_URL" "$TARGET_DIR"
else
    echo "[*] Repo already exists at $TARGET_DIR — skipping clone."
fi

# Make every shell script executable
echo "[*] Setting execute bit on all .sh files..."
find "$TARGET_DIR" -type f -name "*.sh" -exec chmod +x {} \;

echo "[+] Done. Scripts in $TARGET_DIR are ready."
echo "    cd $TARGET_DIR && ls -l *.sh"
