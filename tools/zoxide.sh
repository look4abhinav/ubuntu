#!/usr/bin/env bash

# ==========================================
# zoxide installation
# Uses the official installer (installs to ~/.local/bin, no rc edits).
# Shell integration is wired up by the stowed .zshrc.
# ==========================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib.sh
source "$SCRIPT_DIR/../lib.sh"

log_section "zoxide Installation"

curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh

export PATH="$HOME/.local/bin:$PATH"
if cmd_exists zoxide; then
	log_success "zoxide installed: $(zoxide --version)"
else
	die "zoxide not found on PATH after installation"
fi
