#!/usr/bin/env bash

# ==========================================
# Dotfiles Setup via GNU Stow
# Copies the repo's dotfiles/ directory to ~/dotfiles (only when missing) and
# symlinks them from there. Existing ~/dotfiles is never overwritten, so
# re-running setup leaves user-managed dotfiles untouched. Stowing is
# idempotent and re-run to repair any previously failed links.
# ==========================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib.sh
source "$SCRIPT_DIR/../lib.sh"

DOTFILES_SRC="$SCRIPT_DIR/../dotfiles"
DOTFILES_DIR="$HOME/dotfiles"

log_section "Dotfiles Setup via GNU Stow"

# 1) Ensure dependencies
log_info "Ensuring git and stow are installed..."
apt_install git stow

# 2) Place the dotfiles at ~/dotfiles (only if not already present)
if [ -d "$DOTFILES_DIR" ]; then
	log_info "Dotfiles already present at $DOTFILES_DIR; leaving them untouched (manage updates manually)"
elif [ ! -d "$DOTFILES_SRC" ]; then
	die "dotfiles source not found: $DOTFILES_SRC"
else
	log_info "Copying dotfiles to $DOTFILES_DIR..."
	cp -r "$DOTFILES_SRC" "$DOTFILES_DIR"
	log_success "Dotfiles placed at $DOTFILES_DIR"
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

# 4) Stow the dotfiles (treat the dotfiles directory as the package)
log_info "Stowing dotfiles from $DOTFILES_DIR to $HOME..."
if stow -d "$DOTFILES_DIR" -t "$HOME" .; then
	log_success "Dotfiles stowed successfully"
else
	die "Failed to stow dotfiles. Resolve conflicts in ~ and re-run 'stow -d $DOTFILES_DIR -t $HOME .'"
fi
