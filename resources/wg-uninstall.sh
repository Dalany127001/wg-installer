#!/bin/bash
# =============================================================================
# wg-uninstall.sh — cleanly removes WireGuard/Tunnelblick zero-touch install
# Run as root: sudo bash wg-uninstall.sh
# =============================================================================
set -euo pipefail

[ "$(id -u)" = "0" ] || exec sudo bash "$0" "$@"

echo "============================================"
echo " WireGuard/Tunnelblick Uninstaller — $(date)"
echo "============================================"

PLIST="/Library/LaunchDaemons/com.company.wireguard.plist"
TBLK="/Library/Application Support/Tunnelblick/Shared/wg0.tblk"
TB_APP="/Applications/Tunnelblick.app"
TB_PREFS="/Library/Preferences/net.tunnelblick.tunnelblick.plist"

# ── Stop tunnel ───────────────────────────────────────────────────────────────
echo "[INFO] Unloading LaunchDaemon…"
launchctl bootout system "$PLIST" 2>/dev/null || true
[ -f "$PLIST" ] && rm -f "$PLIST" && echo "[INFO] LaunchDaemon removed."

# Give tunnel a moment to come down
sleep 2

# ── Remove config ─────────────────────────────────────────────────────────────
if [ -d "$TBLK" ]; then
  read -r -p "Remove VPN config? [y/N] " R
  [[ "$R" =~ ^[Yy]$ ]] && rm -rf "$TBLK" && echo "[INFO] Config removed."
fi

# ── Remove Tunnelblick ────────────────────────────────────────────────────────
if [ -d "$TB_APP" ]; then
  read -r -p "Remove Tunnelblick.app? [y/N] " R
  if [[ "$R" =~ ^[Yy]$ ]]; then
    rm -rf "$TB_APP"
    rm -f  "$TB_PREFS"
    echo "[INFO] Tunnelblick removed."
  fi
fi

echo ""
echo "[INFO] Uninstall complete."
