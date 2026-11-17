#!/usr/bin/env bash
# net_discover.sh
# Last Edited by Charles Duoto on November 17, 2026
# Simple network discovery using netdiscover (course style).
# Detects your IP and offers a Class C (/24) scan.
# Pure bash. Authorized lab environments only.
#
# Usage:
#   sudo ./net_discover.sh

set -euo pipefail

echo "[*] Detecting local IP address..."

# Try common methods to get the primary IP
MY_IP=$(ip -4 route get 1.1.1.1 2>/dev/null | grep -oP 'src \K[0-9.]+' || true)
if [[ -z "$MY_IP" ]]; then
    MY_IP=$(hostname -I 2>/dev/null | awk '{print $1}' || true)
fi
if [[ -z "$MY_IP" ]]; then
    MY_IP=$(ifconfig 2>/dev/null | grep -oE 'inet (addr:)?[0-9.]+' | grep -v '127.0.0.1' | head -1 | awk '{print $2}' | cut -d: -f2 || true)
fi

if [[ -z "$MY_IP" ]]; then
    read -rp "Could not detect IP. Enter your IP address: " MY_IP
else
    echo "[*] Detected IP: $MY_IP"
    read -rp "Use this IP? [Y/n]: " CONFIRM
    if [[ "$CONFIRM" =~ ^[Nn] ]]; then
        read -rp "Enter IP address: " MY_IP
    fi
fi

# Build the /24 range
RANGE=$(echo "$MY_IP" | cut -d. -f1-3).0/24

echo
echo "[*] Suggested Class C range: $RANGE"
read -rp "Scan this range with netdiscover? [Y/n]: " DO_SCAN

if [[ ! "$DO_SCAN" =~ ^[Nn] ]]; then
    echo "[*] Running: netdiscover -r $RANGE"
    echo "[*] Press Ctrl+C to stop."
    netdiscover -r "$RANGE"
else
    echo "[*] Skipped."
fi

echo
read -rp "Also run a quick nmap ping scan on the same range? [y/N]: " DO_NMAP
if [[ "$DO_NMAP" =~ ^[Yy] ]]; then
    echo "[*] Running: nmap -sn $RANGE"
    nmap -sn "$RANGE"
fi

echo "[+] Done."
