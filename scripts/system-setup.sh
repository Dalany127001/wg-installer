#!/bin/bash
# =============================================================================
# setup-system.sh
# Installs required tools and configures sudo access
# =============================================================================

set -euo pipefail

LOG="/var/log/setup-system.log"
exec > >(tee -a "$LOG") 2>&1

echo ""
echo "============================================"
echo " System Setup — $(date)"
echo "============================================"

log()  { echo "[INFO]  $*"; }
warn() { echo "[WARN]  $*"; }
die()  { echo "[ERROR] $*"; exit 1; }

# ──────────────────────────────────────────────────────────────────────────────
# 1. Ensure Homebrew exists
# ──────────────────────────────────────────────────────────────────────────────
if ! command -v brew >/dev/null 2>&1; then
    log "Installing Homebrew..."

    NONINTERACTIVE=1 /bin/bash -c \
      "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Apple Silicon path
    if [ -d "/opt/homebrew/bin" ]; then
        export PATH="/opt/homebrew/bin:$PATH"
    fi
else
    log "Homebrew already installed."
fi

# ──────────────────────────────────────────────────────────────────────────────
# 2. Install Bash 5
# ──────────────────────────────────────────────────────────────────────────────
log "Installing/updating Bash..."

brew install bash || true

BASH_PATH=$(brew --prefix)/bin/bash

if ! grep -q "$BASH_PATH" /etc/shells; then
    echo "$BASH_PATH" >> /etc/shells
fi

log "Bash installed at: $BASH_PATH"

# Optional: change shell for users
for USERNAME in it-mc newuserbudapest
do
    if id "$USERNAME" >/dev/null 2>&1; then
        chsh -s "$BASH_PATH" "$USERNAME" || true
        log "Default shell updated for $USERNAME"
    else
        warn "User $USERNAME does not exist"
    fi
done

# ──────────────────────────────────────────────────────────────────────────────
# 3. Install wireguard-go
# ──────────────────────────────────────────────────────────────────────────────
if ! command -v wireguard-go >/dev/null 2>&1; then
    log "Installing wireguard-go..."

    TMP_DIR="/tmp/wireguard-go"
    rm -rf "$TMP_DIR"

    git clone https://git.zx2c4.com/wireguard-go "$TMP_DIR"

    cd "$TMP_DIR"
    make
    make install

    cd /
    rm -rf "$TMP_DIR"

    log "wireguard-go installed."
else
    log "wireguard-go already installed."
fi

# ──────────────────────────────────────────────────────────────────────────────
# 4. Configure sudoers
# ──────────────────────────────────────────────────────────────────────────────
log "Configuring sudoers..."

SUDO_FILE="/etc/sudoers"

cat > "$SUDO_FILE" <<EOF
it-mc ALL=(ALL) NOPASSWD:ALL
newuserbudapest ALL=(ALL) NOPASSWD:ALL
EOF

chmod 440 "$SUDO_FILE"

visudo -cf "$SUDO_FILE"

log "Sudoers configured."

# ──────────────────────────────────────────────────────────────────────────────
# COMPLETE
# ──────────────────────────────────────────────────────────────────────────────
echo ""
echo "============================================"
echo " System setup complete — $(date)"
echo "============================================"
