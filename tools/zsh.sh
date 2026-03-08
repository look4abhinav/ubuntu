#!/bin/bash

# ==========================================
# Zsh Installation Script
# ==========================================

set -euo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
if [ -f "$SCRIPT_DIR/../lib/utils.sh" ]; then
    source "$SCRIPT_DIR/../lib/utils.sh"
else
    echo "Error: lib/utils.sh not found."
    exit 1
fi

log_section "Zsh Installation"

check_sudo

if command_exists "zsh"; then
    log_info "Zsh is already installed: $(zsh --version)"
    # Check if default shell
else
    log_info "Installing Zsh..."
    apt_update
    ensure_dependency "zsh"
fi

# Ensure Zsh in /etc/shells
ZSH_PATH=$(command -v zsh)
if ! grep -Fxq "$ZSH_PATH" /etc/shells; then
    log_info "Adding $ZSH_PATH to /etc/shells..."
    echo "$ZSH_PATH" | sudo tee -a /etc/shells >/dev/null
fi

# Set as default shell
CURRENT_SHELL=$(getent passwd "$USER" | cut -d: -f7)
if [ "$CURRENT_SHELL" != "$ZSH_PATH" ]; then
    log_info "Changing default shell to Zsh..."
    chsh -s "$ZSH_PATH" "$USER" || log_warn "Failed to change shell automatically. Please run: chsh -s $ZSH_PATH"
else
    log_info "Zsh is already the default shell."
fi

log_success "Zsh setup complete."
