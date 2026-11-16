#!/usr/bin/env bash
# wep_crack.sh
# Last Edited by Charles Duoto on November 16, 2026
# Run aircrack-ng against a WEP capture file.
# Pure bash. Authorized lab environments only (WEP is obsolete).
#
# Usage:
#   ./wep_crack.sh capture.cap
#   ./wep_crack.sh capture.cap 00:11:22:33:44:55   # optional BSSID filter

set -euo pipefail

if [[ $# -lt 1 || $# -gt 2 ]]; then
    echo "Usage: $0 <capture.cap> [bssid]"
    echo "Example: $0 capture_001122334455-01.cap"
    exit 1
fi

CAP="$1"
BSSID="${2:-}"

if [[ ! -f "$CAP" ]]; then
    echo "[-] Capture file not found: $CAP"
    exit 1
fi

echo "[*] Analyzing WEP capture: $CAP"
if [[ -n "$BSSID" ]]; then
    echo "[*] Filtering to BSSID $BSSID"
    aircrack-ng -b "$BSSID" "$CAP"
else
    aircrack-ng "$CAP"
fi

echo "[+] Done."
