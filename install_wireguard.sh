#!/bin/bash
set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; BOLD='\033[1m'; NC='\033[0m'

log()   { echo -e "${BLUE}[INFO]${NC}  $*"; }
ok()    { echo -e "${GREEN}[OK]${NC}    $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
fail()  { echo -e "${RED}[ERROR]${NC} $*"; exit 1; }

echo -e "${BOLD}"
echo "  ╔══════════════════════════════════════╗"
echo "  ║    WireGuard Installer — macOS M4    ║"
echo "  ╚══════════════════════════════════════╝"
echo -e "${NC}"

ARCH=$(uname -m)
[[ "$ARCH" == "arm64" ]] || warn "Expected arm64, got: $ARCH"
log "Architecture: $ARCH"
log "macOS: $(sw_vers -productVersion)"

if command -v brew &>/dev/null; then
    ok "Homebrew already installed: $(brew --version | head -1)"
else
    log "Installing Homebrew..."
    NONINTERACTIVE=1 /bin/bash -c \
        "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv)"
    for PROFILE in "$HOME/.zprofile" "$HOME/.bash_profile"; do
        grep -qxF 'eval "$(/opt/homebrew/bin/brew shellenv)"' "$PROFILE" 2>/dev/null || \
            echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "$PROFILE"
    done
    ok "Homebrew installed."
fi

eval "$(/opt/homebrew/bin/brew shellenv)" 2>/dev/null || true

if brew list wireguard-tools &>/dev/null; then
    ok "wireguard-tools already installed."
else
    log "Installing wireguard-tools..."
    brew install wireguard-tools
    ok "wireguard-tools installed."
fi

echo ""
log "Verifying..."
WG_PATH=$(command -v wg || echo "")
[[ -n "$WG_PATH" ]] && ok "wg: $(wg --version)" || fail "wg not found"
[[ -n "$(command -v wg-quick || echo '')" ]] && ok "wg-quick found" || warn "wg-quick not in PATH"

echo ""
echo -e "${GREEN}${BOLD}✓ WireGuard installation complete!${NC}"
