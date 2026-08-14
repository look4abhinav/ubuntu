#!/usr/bin/env bash

# ==========================================
# Neovim + formatters installation
# Supports x86_64 and aarch64 (ARM)
# - Neovim: latest stable tarball -> /opt/nvim-linux
# - Formatters: stylua, taplo, yamlfmt, shfmt -> ~/.local/bin
# - shellcheck: via apt
# - tree-sitter CLI -> /usr/local/bin (required by nvim-treesitter to build
#   parsers) + a C compiler (build-essential) for `tree-sitter build`
# ruff is installed by tools/uv.sh (single source of truth).
# ==========================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib.sh
source "$SCRIPT_DIR/../lib.sh"

ARCH="$(uname -m)"

# Resolve the latest release asset URL for a repo, matching a filename pattern.
# Returns an empty string (and exit 0) when no asset matches, so a missing
# release never trips `set -e` in the caller.
get_download_url() {
	local repo="$1"
	local pattern="$2"
	curl -fsSL "https://api.github.com/repos/$repo/releases/latest" 2>/dev/null |
		grep -oP '"browser_download_url": "\K(.*)(?=")' |
		grep -i "$pattern" |
		head -n 1 ||
		true
}

# Install a single binary from a GitHub release asset into ~/.local/bin
# Usage: install_formatter <repo> <asset-pattern> <binary-name>
install_formatter() {
	local repo="$1" pattern="$2" binary="$3"
	local url
	url="$(get_download_url "$repo" "$pattern")"
	if [ -z "$url" ]; then
		log_warning "Could not resolve latest $binary release for $ARCH; skipping"
		return 0
	fi
	local tmp
	tmp="$(mktemp -d)"
	curl -Ls "$url" -o "$tmp/asset"
	case "$url" in
	*.zip) unzip -q -o "$tmp/asset" -d "$tmp" ;;
	*.tar.gz) tar -xzf "$tmp/asset" -C "$tmp" ;;
	*.gz) gunzip -c "$tmp/asset" >"$tmp/$binary" ;;
	*) mv "$tmp/asset" "$tmp/$binary" ;;
	esac
	mv "$tmp/$binary" "$LOCAL_BIN/$binary"
	chmod u+x "$LOCAL_BIN/$binary"
	rm -rf "$tmp"
	log_success "$binary installed"
}

log_section "Neovim Installation"

# 1) Dependencies (build-essential provides the C compiler that
#    `tree-sitter build` uses to compile nvim-treesitter parsers)
apt_install unzip ripgrep shellcheck build-essential

# 2) Architecture-specific settings
case "$ARCH" in
x86_64)
	NVIM_URL="https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz"
	NVIM_EXTRACT_FOLDER="nvim-linux-x86_64"
	STYLUA_PATTERN="linux-x86_64.zip"
	TAPLO_PATTERN="linux-x86_64.gz"
	YAMLFMT_PATTERN="Linux_x86_64.tar.gz"
	SHFMT_PATTERN="linux_amd64"
	TS_ASSET="tree-sitter-linux-x64.gz"
	;;
aarch64)
	NVIM_URL="https://github.com/neovim/neovim/releases/latest/download/nvim-linux-arm64.tar.gz"
	NVIM_EXTRACT_FOLDER="nvim-linux-arm64"
	STYLUA_PATTERN="linux-aarch64.zip"
	TAPLO_PATTERN="linux-aarch64.gz"
	YAMLFMT_PATTERN="Linux_arm64.tar.gz"
	SHFMT_PATTERN="linux_arm64"
	TS_ASSET="tree-sitter-linux-arm64.gz"
	;;
*) die "Unsupported architecture: $ARCH" ;;
esac

# 3) Neovim
log_info "Downloading Neovim stable..."
TMP="$(mktemp -d)"
curl -L "$NVIM_URL" -o "$TMP/nvim.tar.gz"

INSTALL_DIR_NVIM="/opt/nvim-linux"
if [ -d "$INSTALL_DIR_NVIM" ]; then
	sudo rm -rf "$INSTALL_DIR_NVIM"
fi

sudo tar -C /opt -xzf "$TMP/nvim.tar.gz"
if [ -d "/opt/$NVIM_EXTRACT_FOLDER" ]; then
	sudo mv "/opt/$NVIM_EXTRACT_FOLDER" "$INSTALL_DIR_NVIM"
fi
sudo chown -R "$USER:$USER" "$INSTALL_DIR_NVIM"
sudo chmod -R u+rwx "$INSTALL_DIR_NVIM"
rm -rf "$TMP"

export PATH="$INSTALL_DIR_NVIM/bin:$PATH"
log_success "Neovim installed: $(nvim --version | head -n1)"

# 4) sudo nvim: link root's config dir to the user's so plugins/settings load.
# NOTE: this means user-controlled Lua runs when `sudo nvim` is used. Safe on a
# single-user box, but review before enabling on a shared/multi-user server.
NVIM_CONFIG_DIR="$HOME/.config/nvim"
if [ -d "$NVIM_CONFIG_DIR" ]; then
	sudo mkdir -p /root/.config
	if [ -e /root/.config/nvim ] && [ ! -L /root/.config/nvim ]; then
		log_warning "/root/.config/nvim is a real directory; not overwriting"
	else
		sudo ln -sfn "$NVIM_CONFIG_DIR" /root/.config/nvim
		log_info "Linked /root/.config/nvim -> $NVIM_CONFIG_DIR"
	fi
else
	log_warning "$NVIM_CONFIG_DIR not found; stow dotfiles first for sudo nvim support"
fi

# 5) Formatters
log_section "Formatters"
mkdir -p "$LOCAL_BIN"
export PATH="$LOCAL_BIN:$PATH"

install_formatter "JohnnyMorganz/StyLua" "$STYLUA_PATTERN" "stylua"
install_formatter "tamasfe/taplo" "$TAPLO_PATTERN" "taplo"
install_formatter "google/yamlfmt" "$YAMLFMT_PATTERN" "yamlfmt"
install_formatter "mvdan/sh" "$SHFMT_PATTERN" "shfmt"

# 6) tree-sitter CLI (nvim-treesitter needs it to generate/build parsers)
#    Pin v0.25.10: the v0.26.x prebuilt binaries require glibc 2.39, which
#    breaks Ubuntu 20.04/22.04 (glibc 2.31/2.35). v0.25.x is the newest line
#    that runs there and still emits ABI-15 parsers for Neovim 0.10+.
log_section "tree-sitter CLI"
TS_VERSION="v0.25.10"
TMP="$(mktemp -d)"
curl -Ls "https://github.com/tree-sitter/tree-sitter/releases/download/$TS_VERSION/$TS_ASSET" -o "$TMP/tree-sitter.gz"
gunzip -f "$TMP/tree-sitter.gz"
sudo mv "$TMP/tree-sitter" /usr/local/bin/tree-sitter
sudo chmod +x /usr/local/bin/tree-sitter
rm -rf "$TMP"
hash -r 2>/dev/null || true
log_success "tree-sitter installed: $(tree-sitter --version | head -n1)"

# 7) Verification
log_section "Verification"
verify_tool nvim
verify_tool rg
verify_tool shellcheck
verify_tool stylua
verify_tool taplo
verify_tool yamlfmt
verify_tool shfmt
verify_tool tree-sitter
