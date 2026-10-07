#!/usr/bin/env bash

# Master Ubuntu Server Setup Script
# Automates the complete setup of an Ubuntu server from scratch.

set -euo pipefail

# Resolve the script directory and source shared helpers
# (lib.sh also enforces the non-root requirement and sudo presence)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

usage() {
	cat <<EOF
Usage: bash setup.sh [options]

Transforms a minimal Ubuntu server into a fully configured dev environment.

Options:
  --only=<list>   Comma-separated steps to run (default: all)
  --skip=<list>   Comma-separated steps to skip
  -h, --help      Show this help and exit

Steps:
  system-update   apt update + upgrade
  zsh             Zsh as default shell
  stow            Clone ubuntu-dotfiles to ~/dotfiles and stow
  bat docker eza fd fzf neovim tmux uv zoxide

Examples:
  bash setup.sh
  bash setup.sh --skip=neovim,docker
  bash setup.sh --only=zsh,stow,fd
EOF
}

# ------------------------------------------
# Argument parsing
# ------------------------------------------
ONLY_STEPS=()
SKIP_STEPS=()

while [ $# -gt 0 ]; do
	case "$1" in
	--only)
		IFS=',' read -ra ONLY_STEPS <<<"${2:-}"
		shift 2
		;;
	--only=*)
		IFS=',' read -ra ONLY_STEPS <<<"${1#*=}"
		shift
		;;
	--skip)
		IFS=',' read -ra SKIP_STEPS <<<"${2:-}"
		shift 2
		;;
	--skip=*)
		IFS=',' read -ra SKIP_STEPS <<<"${1#*=}"
		shift
		;;
	-h | --help)
		usage
		exit 0
		;;
	*)
		log_error "Unknown option: $1"
		echo ""
		usage
		exit 1
		;;
	esac
done

ALL_STEPS=("system-update" "zsh" "stow" "bat" "docker" "eza" "fd" "fzf" "neovim" "tmux" "uv" "zoxide")

# Validate requested steps against the known set
validate_steps() {
	local step found
	for step in "$@"; do
		found=0
		for known in "${ALL_STEPS[@]}"; do
			if [ "$step" = "$known" ]; then
				found=1
				break
			fi
		done
		if [ "$found" -eq 0 ]; then
			log_error "Unknown step: '$step' (valid: ${ALL_STEPS[*]})"
			exit 1
		fi
	done
}
validate_steps "${ONLY_STEPS[@]}"
validate_steps "${SKIP_STEPS[@]}"

# Compute the final step list: --only selects (in canonical order),
# then --skip removes.
STEPS=()
for step in "${ALL_STEPS[@]}"; do
	if [ "${#ONLY_STEPS[@]}" -gt 0 ]; then
		selected=0
		for want in "${ONLY_STEPS[@]}"; do
			if [ "$step" = "$want" ]; then
				selected=1
				break
			fi
		done
		if [ "$selected" -eq 0 ]; then
			continue
		fi
	fi
	skipped=0
	for skip in "${SKIP_STEPS[@]}"; do
		if [ "$step" = "$skip" ]; then
			skipped=1
			break
		fi
	done
	if [ "$skipped" -eq 0 ]; then
		STEPS+=("$step")
	fi
done

if [ "${#STEPS[@]}" -eq 0 ]; then
	die "Nothing to do: the step list is empty after applying --only/--skip"
fi

# ------------------------------------------
# Single-run lock: two overlapping runs would fight over the apt lock,
# stow symlinks, and git checkouts.
# ------------------------------------------
if cmd_exists flock; then
	LOCK_FILE="${XDG_RUNTIME_DIR:-/tmp}/ubuntu-setup.lock"
	exec 9>"$LOCK_FILE"
	if ! flock -n 9; then
		die "Another setup run is in progress (lock: $LOCK_FILE)"
	fi
else
	log_warning "flock not available; skipping single-run lock"
fi

# ------------------------------------------
# Preflight checks: fail in seconds instead of 10 minutes into the run
# ------------------------------------------
preflight() {
	# Network reachability (curl is guaranteed when using the one-liner;
	# fall back to DNS-only check when curl is missing)
	if cmd_exists curl; then
		if ! curl -fsSL --max-time 10 -o /dev/null https://github.com; then
			die "Cannot reach github.com; check the server's internet access"
		fi
	else
		if ! getent hosts github.com >/dev/null; then
			die "Cannot resolve github.com; check the server's internet access"
		fi
	fi

	# Disk space: warn under 2 GB free on $HOME (tmux builds from source,
	# Neovim + Docker + tools need room)
	local avail_kb
	avail_kb="$(df -Pk "$HOME" | awk 'NR==2 {print $4}')"
	if [ "$avail_kb" -lt 2097152 ]; then
		log_warning "Only $((avail_kb / 1024)) MB free on $HOME; installs may fail"
	fi
}

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

log_section "Ubuntu Server Setup Script"
log_info "Script directory: $SCRIPT_DIR"
log_info "Home directory: $HOME"
log_info "User: $CURRENT_USER"

log_section "Preflight"
preflight
log_success "Preflight checks passed"

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

REBOOT_REQUIRED=0

# Run each step in order
for step in "${STEPS[@]}"; do
	log_section "Step: $step"
	if [ "$step" = "system-update" ]; then
		if apt_update && sudo "${APT_ENV[@]}" apt-get "${APT_CONF[@]}" upgrade -y; then
			record_success "System update"
		else
			record_failure "System update"
		fi
		# Kernel/library updates may require a reboot; surface it in the summary
		if [ -f /var/run/reboot-required ]; then
			REBOOT_REQUIRED=1
		fi
	elif [ -f "$SCRIPT_DIR/tools/$step.sh" ]; then
		if bash "$SCRIPT_DIR/tools/$step.sh"; then
			record_success "$step"
		else
			record_failure "$step"
		fi
	else
		die "Step '$step' has no script at tools/$step.sh"
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

if [ "$REBOOT_REQUIRED" -eq 1 ]; then
	log_warning "A reboot is required (/var/run/reboot-required exists) -- likely a kernel update"
fi

echo ""
log_info "Next steps:"
echo "  1. Log out and back in (or run 'newgrp docker') to apply group changes"
echo "  2. Start a new shell session to use the new Zsh configuration"
echo "  3. Verify tools: zsh docker nvim tmux fzf eza fd zoxide uv bat rg"
echo ""

# Reflect failures in the exit code so install.sh, CI and cron can detect
# a partial setup instead of assuming success.
if [ ${#FAILED_STEPS[@]} -gt 0 ]; then
	exit 1
fi

log_info "Enjoy your newly configured Ubuntu server!"
