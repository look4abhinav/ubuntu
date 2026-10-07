#!/usr/bin/env bash

# ==========================================
# tmux installation (source build, latest stable)
# Builds the latest tmux (>= 3.2 required by the stowed tmux.conf).
# TPM and plugins are bootstrapped by tmux.conf itself, so nothing else
# needs to be installed here.
# ==========================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib.sh
source "$SCRIPT_DIR/../lib.sh"

MIN_VERSION="3.2"

# Temp dir removed on exit (success, failure or interrupt) so failed builds
# never leak half-extracted sources.
TMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMP_ROOT"' EXIT

log_section "tmux Installation"

# Skip the build if a recent-enough tmux is already present
if cmd_exists tmux; then
	current="$(tmux -V | grep -oP '\d+\.\d+' || true)"
	if [[ -n "$current" ]] && [[ "$(printf '%s\n' "$MIN_VERSION" "$current" | sort -V | head -n1)" = "$MIN_VERSION" ]]; then
		log_info "tmux $current already installed (>= $MIN_VERSION); skipping build"
		exit 0
	fi
	log_info "tmux $current is older than $MIN_VERSION; rebuilding..."
fi

apt_install libevent-dev ncurses-dev build-essential bison pkg-config curl tar

log_info "Fetching latest tmux version..."
TMUX_VERSION="$(curl -s --max-time 30 https://api.github.com/repos/tmux/tmux/releases/latest | grep -oP '"tag_name": "\K(.*)(?=")' || true)"
if [ -z "$TMUX_VERSION" ]; then
	log_warning "Could not fetch latest version, using fallback 3.5a"
	TMUX_VERSION="3.5a"
fi
log_info "Detected version: $TMUX_VERSION"

TMP="$TMP_ROOT/build"
curl -fLs --max-time 300 "https://github.com/tmux/tmux/releases/download/${TMUX_VERSION}/tmux-${TMUX_VERSION}.tar.gz" -o "$TMP/tmux.tar.gz"
tar -xzf "$TMP/tmux.tar.gz" -C "$TMP"

SRC_DIR="$TMP/tmux-$TMUX_VERSION"
if [ ! -d "$SRC_DIR" ]; then
	die "Source directory not found: $SRC_DIR"
fi

(
	cd "$SRC_DIR"
	./configure
	make
	sudo make install
)

log_success "tmux installed: $(tmux -V)"
