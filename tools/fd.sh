#!/usr/bin/env bash

# ==========================================
# fd installation
# Ubuntu ships fd as the `fd-find` package (binary `fdfind`).
# Symlink it to `fd` on PATH via ~/.local/bin so it matches the Arch layout.
# ==========================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib.sh
source "$SCRIPT_DIR/../lib.sh"

log_section "fd Installation"

apt_install fd-find

mkdir -p "$LOCAL_BIN"

if ! cmd_exists fd && cmd_exists fdfind; then
	ln -sf "$(command -v fdfind)" "$LOCAL_BIN/fd"
	log_success "Symlinked fdfind -> $LOCAL_BIN/fd"
else
	log_info "fd already on PATH ($(command -v fd || command -v fdfind))"
fi

# ~/.local/bin isn't on the script's PATH yet; add it so the check below works
export PATH="$LOCAL_BIN:$PATH"

if cmd_exists fd; then
	log_success "fd installed: $(fd --version 2>/dev/null | head -n1)"
else
	die "fd not found on PATH after installation"
fi
