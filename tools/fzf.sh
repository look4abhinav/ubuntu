#!/usr/bin/env bash

# ==========================================
# fzf installation
# Installs/updates the fzf binary (~/.fzf) without touching shell rc files.
# Key bindings and completions are wired up by the stowed .zshrc.
# ==========================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib.sh
source "$SCRIPT_DIR/../lib.sh"

FZF_DIR="$HOME/.fzf"

log_section "fzf Installation"

if [ -d "$FZF_DIR" ]; then
	log_info "fzf already present; updating..."
	git -C "$FZF_DIR" pull --rebase || true
else
	log_info "Cloning fzf..."
	git clone --depth 1 https://github.com/junegunn/fzf.git "$FZF_DIR"
fi

"$FZF_DIR/install" --bin

log_success "fzf installed: $("$FZF_DIR/bin/fzf" --version)"
