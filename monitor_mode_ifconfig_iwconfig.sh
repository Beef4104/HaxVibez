#!/usr/bin/env bash
# monitor_mode_course.sh - Put interface into monitor mode (course style)
# Last Edited by Charles Duoto on November 16, 2026
# Uses ifconfig + iwconfig as taught in the course.
#
# Usage:
#   sudo ./monitor_mode_course.sh wlan0

set -euo pipefail

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 <interface>"
    echo "Example: $0 wlan0"
    exit 1
fi

IFACE="$1"

if ! ifconfig "$IFACE" &>/dev/null; then
    echo "[-] Interface $IFACE not found"
    exit 1
fi

echo "[*] Bringing $IFACE down..."
ifconfig "$IFACE" down

echo "[*] Killing interfering processes (airmon-ng check kill)..."
airmon-ng check kill

echo "[*] Setting $IFACE to monitor mode..."
iwconfig "$IFACE" mode monitor

echo "[*] Bringing $IFACE up..."
ifconfig "$IFACE" up

echo "[*] Current mode:"
iwconfig "$IFACE" | grep -E "Mode|ESSID" || true

echo "[+] Done. Interface should now be in monitor mode."
echo "    To return to managed mode later:"
echo "    ifconfig $IFACE down && iwconfig $IFACE mode managed && ifconfig $IFACE up"
