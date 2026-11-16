#!/usr/bin/env bash
# monitor_mode_modern.sh - Put interface into monitor mode (modern style)
# Last Edited by Charles Duoto on November 16, 2026
# Uses ip + iw. Still calls airmon-ng check kill because it is the most reliable
# way to stop NetworkManager/wpa_supplicant from interfering.
#
# Usage:
#   sudo ./monitor_mode_modern.sh wlan0

set -euo pipefail

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 <interface>"
    echo "Example: $0 wlan0"
    exit 1
fi

IFACE="$1"

if ! ip link show "$IFACE" &>/dev/null; then
    echo "[-] Interface $IFACE not found"
    exit 1
fi

echo "[*] Bringing $IFACE down..."
ip link set "$IFACE" down

echo "[*] Killing interfering processes (airmon-ng check kill)..."
airmon-ng check kill

echo "[*] Setting $IFACE to monitor mode..."
iw dev "$IFACE" set type monitor

echo "[*] Bringing $IFACE up..."
ip link set "$IFACE" up

echo "[*] Current mode:"
iw dev "$IFACE" info | grep -E "type|ssid" || true

echo "[+] Done. Interface should now be in monitor mode."
echo "    To return to managed mode later:"
echo "    ip link set $IFACE down && iw dev $IFACE set type managed && ip link set $IFACE up"
