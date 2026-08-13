#!/usr/bin/env bash

# ==========================================
# Shared helpers for the Ubuntu setup scripts
# Sourced by setup.sh and every tool in tools/
# ==========================================

# Color codes for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1" >&2; }
log_success() { echo -e "${GREEN}✓${NC} $1"; }
log_section() { echo -e "\n${BLUE}== $1 ==${NC}"; }

# Refuse to run as root: dotfiles and user tools belong to the normal user,
# and sudo is requested explicitly where privileged access is required.
if [ "$EUID" -eq 0 ]; then
	log_error "Do not run as root; run as your normal user (sudo is used where needed)."
	exit 1
fi

# Check if a command exists
cmd_exists() { command -v "$1" >/dev/null 2>&1; }

# Exit with an error message
die() {
	log_error "$1"
	exit 1
}

# User-local bin dir, used by installers that place binaries outside apt
# (read by the scripts that source this library, hence the SC2034 disable)
# shellcheck disable=SC2034
readonly LOCAL_BIN="$HOME/.local/bin"

verify_tool() {
	local name="$1"
	if cmd_exists "$name"; then
		log_success "$name: $($name --version 2>&1 | head -n1)"
	else
		log_warning "$name: NOT FOUND"
	fi
}

# Marker file so `apt-get update` runs at most once per setup run (30m TTL),
# even though every tool script is executed as its own process.
APT_UPDATE_FLAG="${XDG_CACHE_HOME:-$HOME/.cache}/ubuntu-setup/apt-updated"

apt_update() {
	if [[ -f "$APT_UPDATE_FLAG" ]] && [[ $(($(date +%s) - $(stat -c %Y "$APT_UPDATE_FLAG"))) -lt 1800 ]]; then
		return 0
	fi
	sudo apt-get update -y
	mkdir -p "$(dirname "$APT_UPDATE_FLAG")"
	touch "$APT_UPDATE_FLAG"
}

apt_install() {
	apt_update
	sudo apt-get install -y "$@"
}
