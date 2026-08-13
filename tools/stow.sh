#!/usr/bin/env bash

# ==========================================
# Dotfiles Setup via GNU Stow
# Clones the shared dotfiles repo to ~/dotfiles and symlinks them.
# The repo is cloned only when missing and never `git pull`ed, so re-running
# setup never mutates user-managed dotfiles. Stowing is idempotent and re-run
# to repair any previously failed links.
# ==========================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib.sh
source "$SCRIPT_DIR/../lib.sh"

DOTFILES_DIR="$HOME/dotfiles"
DOTFILES_REPO="https://github.com/look4abhinav/dotfiles.git"

log_section "Dotfiles Setup via GNU Stow"

# 1) Ensure dependencies
log_info "Ensuring git and stow are installed..."
apt_install git stow

# 2) Clone the repo only if missing; never update an existing checkout
if [ ! -d "$DOTFILES_DIR" ]; then
	log_info "Cloning dotfiles repository..."
	if ! git clone "$DOTFILES_REPO" "$DOTFILES_DIR"; then
		die "Failed to clone dotfiles from $DOTFILES_REPO"
	fi
	log_success "Dotfiles cloned to $DOTFILES_DIR"
else
	log_info "Dotfiles already present at $DOTFILES_DIR (left untouched; manage updates manually)"
fi

# 3) Back up any existing real files that would clash with the stow targets
#    (existing symlinks from a previous stow are left alone, keeping this idempotent)
BACKUP_DIR="$HOME/.dotfiles_backup_$(date +%Y%m%d_%H%M%S)"
BACKUP_FILES=(".zshrc" ".gitconfig" ".p10k.zsh")
backed_up=0

for f in "${BACKUP_FILES[@]}"; do
	if [ -e "$HOME/$f" ] && [ ! -L "$HOME/$f" ]; then
		mkdir -p "$BACKUP_DIR"
		mv "$HOME/$f" "$BACKUP_DIR/$f"
		log_info "Backed up ~/$f -> $BACKUP_DIR/$f"
		backed_up=$((backed_up + 1))
	fi
done

if [ "$backed_up" -gt 0 ]; then
	log_info "Backed up $backed_up file(s) to $BACKUP_DIR"
fi

# 4) Stow the dotfiles (treat the repo root as the package)
log_info "Stowing dotfiles from $DOTFILES_DIR to $HOME..."
if stow -d "$DOTFILES_DIR" -t "$HOME" .; then
	log_success "Dotfiles stowed successfully"
else
	die "Failed to stow dotfiles. Resolve conflicts in ~ and re-run 'stow -d $DOTFILES_DIR -t $HOME .'"
fi
