#!/usr/bin/env bash
# mac_changer_ifconfig.sh - MAC changer using ifconfig (course style)
# Usage:
#   ./mac_changer_ifconfig.sh <interface> [new_mac]
# Examples:
#   ./mac_changer_ifconfig.sh wlan0
#   ./mac_changer_ifconfig.sh wlan0 00:11:22:33:44:55

set -euo pipefail

if [[ $# -lt 1 || $# -gt 2 ]]; then
    echo "Usage: $0 <interface> [mac_address]"
    echo "  If no MAC is given, a random locally-administered address is generated."
    exit 1
fi

IFACE="$1"
NEW_MAC="${2:-}"

# Basic interface check
if ! ifconfig "$IFACE" &>/dev/null; then
    echo "[-] Interface $IFACE not found"
    exit 1
fi

# Generate a random MAC if none supplied (locally administered, unicast)
if [[ -z "$NEW_MAC" ]]; then
    # First octet: 02, 06, 0A, 0E (locally administered, unicast)
    FIRST=$(printf '%02X' $(( (RANDOM % 4) * 4 + 2 )))
    REST=$(openssl rand -hex 5 | sed 's/\(..\)/\1:/g; s/:$//')
    NEW_MAC="${FIRST}:${REST}"
    echo "[*] Generated random MAC: $NEW_MAC"
fi

# Validate rough MAC format
if ! [[ "$NEW_MAC" =~ ^([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}$ ]]; then
    echo "[-] Invalid MAC format: $NEW_MAC"
    exit 1
fi

echo "[*] Current MAC for $IFACE:"
ifconfig "$IFACE" | grep -oE 'ether ([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}' | awk '{print $2}' || \
ifconfig "$IFACE" | grep -oE 'HWaddr ([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}' | awk '{print $2}' || true

echo "[*] Bringing $IFACE down..."
ifconfig "$IFACE" down

echo "[*] Setting MAC to $NEW_MAC..."
ifconfig "$IFACE" hw ether "$NEW_MAC"

echo "[*] Bringing $IFACE up..."
ifconfig "$IFACE" up

echo "[*] New MAC for $IFACE:"
ifconfig "$IFACE" | grep -oE 'ether ([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}' | awk '{print $2}' || \
ifconfig "$IFACE" | grep -oE 'HWaddr ([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}' | awk '{print $2}' || true

echo "[+] Done."
