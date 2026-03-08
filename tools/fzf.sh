#!/bin/bash

# ==========================================
# FZF Installation Script
# ==========================================

set -euo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
if [ -f "$SCRIPT_DIR/../lib/utils.sh" ]; then
    source "$SCRIPT_DIR/../lib/utils.sh"
else
    echo "Error: lib/utils.sh not found."
    exit 1
fi

log_section "FZF Installation"

check_sudo

if command_exists "fzf"; then
    log_info "FZF is already installed: $(fzf --version)"
    exit 0
fi

log_info "Installing Git if needed..."
ensure_dependency "git"

FZF_DIR="$HOME/.fzf"

if [ -d "$FZF_DIR" ]; then
    log_info "Updating FZF repository..."
    cd "$FZF_DIR"
    git pull
else
    log_info "Cloning FZF repository..."
    git clone --depth 1 https://github.com/junegunn/fzf.git "$FZF_DIR"
fi

log_info "Running FZF installer..."
# --all: Enable all features (fuzzy auto-completion, key bindings)
# --no-update-rc: Don't modify shell rc files (we manage them via dotfiles)
"$FZF_DIR/install" --all --no-update-rc

log_success "FZF installed successfully: $(fzf --version)"
