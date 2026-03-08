#!/bin/bash

# ==========================================
# Tmux Installation Script (Source Build)
# ==========================================

set -euo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
if [ -f "$SCRIPT_DIR/../lib/utils.sh" ]; then
    source "$SCRIPT_DIR/../lib/utils.sh"
else
    echo "Error: lib/utils.sh not found."
    exit 1
fi

log_section "Tmux Installation"

check_sudo

# 1. Check current version
if command_exists "tmux"; then
    CURRENT_VER=$(tmux -V | cut -d' ' -f2)
    log_info "Tmux is already installed: $CURRENT_VER"
    # Optional: Compare versions logic
fi

# 2. Dependencies
log_info "Installing build dependencies..."
apt_update
ensure_dependency "libevent-dev"
ensure_dependency "ncurses-dev"
ensure_dependency "build-essential"
ensure_dependency "bison"
ensure_dependency "pkg-config"
ensure_dependency "curl"
ensure_dependency "git"
ensure_dependency "tar"

# 3. Get Version
log_info "Fetching latest tmux version..."
LATEST_TAG=$(curl -s https://api.github.com/repos/tmux/tmux/releases/latest | grep -oP '"tag_name": "\K(.*)(?=")')

if [ -z "$LATEST_TAG" ]; then
    LATEST_TAG="3.4" # Fallback
    log_warn "Could not fetch latest version, using fallback: $LATEST_TAG"
fi

if [ "${CURRENT_VER:-}" == "$LATEST_TAG" ] || [ "${CURRENT_VER:-}" == "tmux $LATEST_TAG" ]; then
    log_info "Tmux is up to date ($LATEST_TAG)."
else
    log_info "Installing Tmux $LATEST_TAG..."
    TEMP_DIR=$(mktemp -d)
    
    # Download
    DOWNLOAD_URL="https://github.com/tmux/tmux/releases/download/${LATEST_TAG}/tmux-${LATEST_TAG}.tar.gz"
    curl -L "$DOWNLOAD_URL" -o "$TEMP_DIR/tmux.tar.gz"
    
    # Extract
    tar -xzf "$TEMP_DIR/tmux.tar.gz" -C "$TEMP_DIR"
    SRC_DIR=$(find "$TEMP_DIR" -maxdepth 1 -type d -name "tmux-*")
    
    cd "$SRC_DIR"
    ./configure
    make
    sudo make install
    
    cd "$SCRIPT_DIR"
    rm -rf "$TEMP_DIR"
    log_success "Tmux installed."
fi

# 4. Install TPM
TPM_DIR="$HOME/.tmux/plugins/tpm"
# OR ~/.config/tmux/plugins/tpm depending on config. Let's use standard.
# The original script used ~/.config/tmux/plugins/tpm.
TPM_DIR="$HOME/.config/tmux/plugins/tpm"

if [ -d "$TPM_DIR" ]; then
    log_info "Updating TPM..."
    git -C "$TPM_DIR" pull
else
    log_info "Installing TPM..."
    git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
fi

log_success "Tmux setup complete."
