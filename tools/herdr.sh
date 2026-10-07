#!/usr/bin/env bash

# ==========================================
# herdr installation
# Uses the official installer (installs to ~/.local/bin, no rc edits).
# Shell integration is wired up by the stowed .zshrc.
# ==========================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib.sh
source "$SCRIPT_DIR/../lib.sh"

log_section "herdr Installation"

curl -fsSL --max-time 120 https://herdr.dev/install.sh | sh

export PATH="$HOME/.local/bin:$PATH"
if cmd_exists herdr; then
	log_success "herdr installed: $(herdr --version 2>&1 | head -n1)"
else
	die "herdr not found on PATH after installation"
fi
