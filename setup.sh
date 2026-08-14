#!/usr/bin/env bash

# Master Ubuntu Server Setup Script
# Automates the complete setup of an Ubuntu server from scratch.

set -euo pipefail

# Resolve the script directory and source shared helpers
# (lib.sh also enforces the non-root requirement)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

# Verify we're on Ubuntu/Debian
if [[ ! -f /etc/debian_version ]]; then
	die "This script is designed for Ubuntu/Debian systems only"
fi

# Verify architecture: Neovim (and its formatters/tree-sitter) are installed
# from GitHub releases that only publish x86_64 and aarch64 binaries.
ARCH="$(uname -m)"
if [[ "$ARCH" != "x86_64" && "$ARCH" != "aarch64" ]]; then
	die "Unsupported architecture: $ARCH (supported: x86_64, aarch64)"
fi
log_info "Architecture: $ARCH"

# Tracking arrays
SUCCESSFUL_STEPS=()
FAILED_STEPS=()

record_success() {
	log_success "$1"
	SUCCESSFUL_STEPS+=("$1")
}
record_failure() {
	log_error "$1 failed"
	FAILED_STEPS+=("$1")
}

log_section "Ubuntu Server Setup Script"
log_info "Script directory: $SCRIPT_DIR"
log_info "Home directory: $HOME"

# Step 1: System Update
log_section "Step 1: System Update"
if apt_update && sudo apt-get upgrade -y; then
	record_success "System update"
else
	record_failure "System update"
fi

# Step 2: Setup Zsh
log_section "Step 2: Zsh"
if bash "$SCRIPT_DIR/tools/zsh.sh"; then
	record_success "Zsh setup"
else
	record_failure "Zsh setup"
fi

# Step 3: Stow dotfiles (cloned to ~/dotfiles, never pulled on re-runs)
log_section "Step 3: Dotfiles"
if bash "$SCRIPT_DIR/tools/stow.sh"; then
	record_success "Dotfiles setup"
else
	record_failure "Dotfiles setup"
fi

# Step 4: Install remaining tools
log_section "Step 4: Additional Tools"
tools=("bat" "docker" "eza" "fd" "fzf" "neovim" "tmux" "uv" "zoxide")

for tool in "${tools[@]}"; do
	log_info "Installing $tool..."
	if bash "$SCRIPT_DIR/tools/$tool.sh"; then
		record_success "$tool"
	else
		record_failure "$tool"
	fi
done

# Summary Report
log_section "Setup Summary"
echo -e "\n${GREEN}Successful Steps (${#SUCCESSFUL_STEPS[@]}):${NC}"
for step in "${SUCCESSFUL_STEPS[@]}"; do
	echo -e "  ${GREEN}✓${NC} $step"
done

if [ ${#FAILED_STEPS[@]} -gt 0 ]; then
	echo -e "\n${RED}Failed Steps (${#FAILED_STEPS[@]}):${NC}"
	for step in "${FAILED_STEPS[@]}"; do
		echo -e "  ${RED}✗${NC} $step"
	done
fi

echo ""
if [ ${#FAILED_STEPS[@]} -eq 0 ]; then
	log_success "All steps completed successfully!"
else
	log_warning "${#FAILED_STEPS[@]} step(s) failed. Please review the errors above."
fi

echo ""
log_info "Next steps:"
echo "  1. Log out and back in (or run 'newgrp docker') to apply group changes"
echo "  2. Start a new shell session to use the new Zsh configuration"
echo "  3. Verify tools: zsh docker nvim tmux fzf eza fd zoxide uv bat rg"
echo ""
log_info "Enjoy your newly configured Ubuntu server!"
