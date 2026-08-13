#!/usr/bin/env bash

# ==========================================
# zsh installer for Debian/Ubuntu
# - Installs zsh if missing
# - Ensures zsh is listed in /etc/shells
# - Only calls chsh when zsh is not already the login shell
# ==========================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib.sh
source "$SCRIPT_DIR/../lib.sh"

log_section "Zsh Installation"

# 1) Install zsh if missing
if cmd_exists zsh; then
	log_info "zsh is already installed: $(zsh --version 2>/dev/null | head -n1)"
else
	log_info "Installing zsh..."
	apt_install zsh
	log_info "Installed: $(zsh --version 2>/dev/null | head -n1)"
fi

ZSH_PATH="$(command -v zsh || true)"
if [ -z "$ZSH_PATH" ]; then
	die "zsh binary not found after install"
fi
log_info "zsh binary: $ZSH_PATH"

# 2) Ensure zsh appears in /etc/shells so chsh accepts it
if ! grep -Fxq "$ZSH_PATH" /etc/shells; then
	log_info "Adding $ZSH_PATH to /etc/shells"
	echo "$ZSH_PATH" | sudo tee -a /etc/shells >/dev/null
else
	log_info "$ZSH_PATH already listed in /etc/shells"
fi

# 3) Switch the default shell only if needed
CURRENT_SHELL="$(getent passwd "$USER" | cut -d: -f7 || true)"
if [ "$CURRENT_SHELL" = "$ZSH_PATH" ]; then
	log_info "zsh is already the default shell for $USER"
else
	log_info "Switching default shell to $ZSH_PATH for $USER"
	if sudo chsh -s "$ZSH_PATH" "$USER"; then
		log_success "Default shell changed to $ZSH_PATH (log out/in to take effect)"
	else
		log_warning "Could not change shell automatically. Run: sudo chsh -s $ZSH_PATH $USER"
	fi
fi

log_success "Zsh setup complete"
