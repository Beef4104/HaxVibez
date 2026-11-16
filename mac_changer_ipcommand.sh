#!/usr/bin/env bash
# mac_changer.sh - Simple MAC address changer for lab use
# Last Edited by Charles Duoto on November 16, 2026
# Usage:
#   ./mac_changer.sh <interface> [new_mac]
# Examples:
#   ./mac_changer.sh wlan0
#   ./mac_changer.sh wlan0 00:11:22:33:44:55
#   ./mac_changer.sh eth0

set -euo pipefail

if [[ $# -lt 1 || $# -gt 2 ]]; then
    echo "Usage: $0 <interface> [mac_address]"
    echo "  If no MAC is given, a random locally-administered address is generated."
    exit 1
fi

IFACE="$1"
NEW_MAC="${2:-}"

# Basic interface check
if ! ip link show "$IFACE" &>/dev/null; then
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
ip link show "$IFACE" | grep -oP '(?<=link/ether )[^ ]+' || true

echo "[*] Bringing $IFACE down..."
ip link set "$IFACE" down

echo "[*] Setting MAC to $NEW_MAC..."
ip link set "$IFACE" address "$NEW_MAC"

echo "[*] Bringing $IFACE up..."
ip link set "$IFACE" up

echo "[*] New MAC for $IFACE:"
ip link show "$IFACE" | grep -oP '(?<=link/ether )[^ ]+'

echo "[+] Done."
