#!/usr/bin/env bash

# ==========================================
# eza installation (official gierens repository)
# ==========================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib.sh
source "$SCRIPT_DIR/../lib.sh"

GPG_KEY_FILE="/etc/apt/keyrings/gierens.gpg"
REPO_LIST_FILE="/etc/apt/sources.list.d/gierens.list"
GPG_KEY_URL="https://raw.githubusercontent.com/eza-community/eza/main/deb.asc"
REPO_URL="deb [signed-by=$GPG_KEY_FILE] http://deb.gierens.de stable main"

log_section "eza Installation"

apt_install gpg curl

# Add GPG key if missing
sudo mkdir -p /etc/apt/keyrings
if [ -f "$GPG_KEY_FILE" ]; then
	log_info "GPG key already present; skipping download"
elif curl -fsSL "$GPG_KEY_URL" | sudo gpg --dearmor -o "$GPG_KEY_FILE"; then
	log_success "GPG key installed"
else
	die "Failed to install eza GPG key"
fi

# Add repository source if missing
if [ -f "$REPO_LIST_FILE" ]; then
	if grep -q "deb.gierens.de" "$REPO_LIST_FILE"; then
		log_info "Repository already configured"
	else
		echo "$REPO_URL" | sudo tee "$REPO_LIST_FILE" >/dev/null
	fi
else
	echo "$REPO_URL" | sudo tee "$REPO_LIST_FILE" >/dev/null
	log_success "Repository source added"
fi

sudo chmod 644 "$GPG_KEY_FILE" "$REPO_LIST_FILE"

# Fetch the (possibly newly-added) repo index before installing
apt_force_update
apt_install eza

if cmd_exists eza; then
	log_success "eza installed: $(eza --version | head -n1)"
else
	die "eza not found on PATH after installation"
fi
