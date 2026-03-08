#!/bin/bash

# ==========================================
# Eza Installation Script
# A modern replacement for ls
# ==========================================

set -euo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
if [ -f "$SCRIPT_DIR/../lib/utils.sh" ]; then
    source "$SCRIPT_DIR/../lib/utils.sh"
else
    echo "Error: lib/utils.sh not found."
    exit 1
fi

log_section "Eza Installation"

check_sudo

if command_exists "eza"; then
    log_info "Eza is already installed: $(eza --version)"
    exit 0
fi

log_info "Installing prerequisites..."
apt_update
ensure_dependency "gpg"

# Setup Key and Repo
KEYRING="/etc/apt/keyrings/gierens.gpg"
REPO_FILE="/etc/apt/sources.list.d/gierens.list"

log_info "Setting up GPG key..."
sudo mkdir -p /etc/apt/keyrings
wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor -o "$KEYRING"

log_info "Adding repository..."
echo "deb [signed-by=$KEYRING] http://deb.gierens.de stable main" | sudo tee "$REPO_FILE" > /dev/null
sudo chmod 644 "$KEYRING" "$REPO_FILE"

log_info "Installing eza..."
sudo apt-get update
sudo apt-get install -y eza

log_success "Eza installed successfully: $(eza --version)"
