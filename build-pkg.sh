#!/bin/bash
# =============================================================================
# build-pkg.sh — builds the WireGuard/Tunnelblick zero-touch .pkg
#
# Usage:
#   bash build-pkg.sh                               # unsigned (testing only)
#   bash build-pkg.sh --sign "Developer ID Installer: Acme (XXXXXXXXXX)"
#
# For a fleet, run once per laptop with its unique wg0.conf:
#   cp /path/to/laptop1.conf payload/wg0.conf && bash build-pkg.sh
#   cp /path/to/laptop2.conf payload/wg0.conf && bash build-pkg.sh
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

PKG_ID="com.company.wireguard-tunnelblick"
PKG_VERSION="1.0.0"
PKG_NAME="WireGuard-ZeroTouch"
OUTPUT_DIR="$SCRIPT_DIR/build"
PAYLOAD_DIR="$SCRIPT_DIR/payload"
SCRIPTS_DIR="$SCRIPT_DIR/scripts"
RESOURCES_DIR="$SCRIPT_DIR/resources"
COMPONENT_PKG="$OUTPUT_DIR/${PKG_NAME}-component.pkg"
FINAL_PKG="$OUTPUT_DIR/${PKG_NAME}-${PKG_VERSION}.pkg"

SIGN_IDENTITY=""
if [[ "${1:-}" == "--sign" && -n "${2:-}" ]]; then
  SIGN_IDENTITY="$2"
fi

mkdir -p "$OUTPUT_DIR"

# ── Validate config has been filled in ────────────────────────────────────────
CONF="$PAYLOAD_DIR/etc/wireguard-payload/wg0.conf"
if grep -q "REPLACE_WITH" "$CONF" || grep -q "YOUR_SERVER" "$CONF" || grep -q "10\.10\.0\.X" "$CONF"; then
  echo ""
  echo "⚠️  ERROR: payload/wg0.conf has not been filled in."
  echo "   Edit it and replace all placeholder values before building."
  echo ""
  exit 1
fi
echo "[build] Config looks filled in ✓"

# ── Script permissions ────────────────────────────────────────────────────────
chmod 755 "$SCRIPTS_DIR/preinstall" "$SCRIPTS_DIR/postinstall"
echo "[build] Script permissions set ✓"

# ── Payload: config goes to staging dir (postinstall reads it from there) ─────
# Install location: /etc/wireguard-tunnelblick/wg0.conf
PAYLOAD_STAGED="$SCRIPT_DIR/_payload_staged/etc/wireguard-payload"
rm -rf "$SCRIPT_DIR/_payload_staged"
mkdir -p "$PAYLOAD_STAGED"
cp "$CONF" "$PAYLOAD_STAGED/wg0.conf"
chmod 600 "$PAYLOAD_STAGED/wg0.conf"

# ── Build component package ───────────────────────────────────────────────────
echo "[build] Building component package…"
pkgbuild \
  --root "$SCRIPT_DIR/_payload_staged" \
  --scripts "$SCRIPTS_DIR" \
  --identifier "$PKG_ID" \
  --version "$PKG_VERSION" \
  --install-location "/" \
  ${SIGN_IDENTITY:+--sign "$SIGN_IDENTITY"} \
  "$COMPONENT_PKG"

rm -rf "$SCRIPT_DIR/_payload_staged"

# ── Distribution XML ──────────────────────────────────────────────────────────
DIST_XML="$OUTPUT_DIR/distribution.xml"
cat > "$DIST_XML" << DISTXML
<?xml version="1.0" encoding="utf-8"?>
<installer-gui-script minSpecVersion="2">
  <title>WireGuard VPN</title>
  <welcome file="welcome.html" mime-type="text/html"/>
  <options customize="never" require-scripts="true" hostArchitectures="arm64"/>
  <volume-check>
    <allowed-os-versions>
      <os-version min="13.0"/>
    </allowed-os-versions>
  </volume-check>
  <pkg-ref id="${PKG_ID}"/>
  <choices-outline>
    <line choice="default">
      <line choice="${PKG_ID}"/>
    </line>
  </choices-outline>
  <choice id="default"/>
  <choice id="${PKG_ID}" visible="false">
    <pkg-ref id="${PKG_ID}"/>
  </choice>
  <pkg-ref id="${PKG_ID}" version="${PKG_VERSION}" onConclusion="none">$(basename "$COMPONENT_PKG")</pkg-ref>
</installer-gui-script>
DISTXML

# ── Welcome screen ────────────────────────────────────────────────────────────
cat > "$RESOURCES_DIR/welcome.html" << 'HTML'
<!DOCTYPE html>
<html>
<head><meta charset="utf-8"/>
<style>
  body { font-family: -apple-system, sans-serif; padding: 20px; font-size: 13px; color: #1d1d1f; }
  h2   { margin-bottom: 8px; }
  ul   { padding-left: 20px; }
  li   { margin: 6px 0; }
  .note { margin-top: 16px; padding: 10px 14px; background: #f5f5f7; border-radius: 8px; font-size: 12px; }
</style>
</head>
<body>
<h2>WireGuard VPN</h2>
<p>This installer will set up your company VPN automatically.</p>
<ul>
  <li>Downloads and installs <strong>Tunnelblick</strong> VPN client</li>
  <li>Installs your unique VPN configuration</li>
  <li>Configures VPN to <strong>connect automatically on every boot</strong></li>
  <li>Works for <strong>all user accounts</strong> on this Mac</li>
</ul>
<div class="note">
  You will be asked for your administrator password once.<br/>
  No other interaction is required — ever.
</div>
</body>
</html>
HTML

# ── Build final product package ───────────────────────────────────────────────
echo "[build] Building final product package…"
productbuild \
  --distribution "$DIST_XML" \
  --resources "$RESOURCES_DIR" \
  --package-path "$OUTPUT_DIR" \
  ${SIGN_IDENTITY:+--sign "$SIGN_IDENTITY"} \
  "$FINAL_PKG"

rm -f "$COMPONENT_PKG" "$DIST_XML"

echo ""
echo "✅ Done!"
echo "   → $FINAL_PKG"
echo ""
if [ -z "$SIGN_IDENTITY" ]; then
  echo "⚠️  Package is unsigned — only works on your own Mac for testing."
  echo "   To distribute to other Macs, sign and notarise:"
  echo ""
  echo "   1. bash build-pkg.sh --sign \"Developer ID Installer: Acme Corp (XXXXXXXXXX)\""
  echo "   2. xcrun notarytool submit \"$FINAL_PKG\" --apple-id you@co.com --team-id XXXXXXXXXX --wait"
  echo "   3. xcrun stapler staple \"$FINAL_PKG\""
  echo ""
fi
