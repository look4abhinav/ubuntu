#!/usr/bin/env bash

# ==========================================
# bat + Catppuccin themes installation
# Ubuntu ships bat as `batcat`. Installs it and the Catppuccin themes so the
# stowed ~/.config/bat/config works out of the box. Exposes `bat` on PATH.
# ==========================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib.sh
source "$SCRIPT_DIR/../lib.sh"

BAT_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/bat"
THEMES_DIR="$BAT_DIR/themes"

log_section "bat Installation"

apt_install bat

# Expose `bat` on PATH (~/.local/bin is already on PATH via .zshrc)
mkdir -p "$LOCAL_BIN"
if ! cmd_exists bat && cmd_exists batcat; then
	ln -sf "$(command -v batcat)" "$LOCAL_BIN/bat"
	log_info "Symlinked batcat -> $LOCAL_BIN/bat"
else
	log_info "bat already on PATH ($(command -v bat || command -v batcat))"
fi

# Install Catppuccin themes
mkdir -p "$THEMES_DIR"
if [ ! -d "$THEMES_DIR/catppuccin" ]; then
	log_info "Cloning Catppuccin bat themes..."
	git clone --depth 1 https://github.com/catppuccin/bat.git "$THEMES_DIR/catppuccin"
else
	log_info "Catppuccin themes already present; updating..."
	git -C "$THEMES_DIR/catppuccin" pull --rebase >/dev/null 2>&1 || true
fi

find "$THEMES_DIR/catppuccin/themes" -name '*.tmTheme' -exec cp -f {} "$THEMES_DIR/" \;

log_info "Building bat cache..."
batcat cache --build

if batcat --list-themes 2>/dev/null | grep -q "Catppuccin Mocha"; then
	log_success "bat installed: $(batcat --version) (Catppuccin Mocha theme available)"
else
	log_warning "Catppuccin Mocha theme not found after cache build"
fi
