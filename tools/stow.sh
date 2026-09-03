#!/usr/bin/env bash

# ==========================================
# Dotfiles Setup via GNU Stow
# Clones the dotfiles repo (look4abhinav/ubuntu-dotfiles) into ~/dotfiles and
# symlinks them into $HOME with GNU Stow. The dotfiles live in their own repo,
# so the setup repo -- which may be cloned to a temp dir and deleted afterwards
# -- never becomes the source of truth for the symlinks.
# ==========================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib.sh
source "$SCRIPT_DIR/../lib.sh"

DOTFILES_REPO="https://github.com/look4abhinav/ubuntu-dotfiles.git"
DOTFILES_DIR="$HOME/dotfiles"

log_section "Dotfiles Setup via GNU Stow"

# 1) Ensure dependencies
log_info "Ensuring git and stow are installed..."
apt_install git stow

# 2) Ensure the dotfiles repo is checked out at ~/dotfiles
if [ -d "$DOTFILES_DIR/.git" ]; then
	# Already a git repo. If it's ours, refresh it; otherwise leave it alone.
	if git -C "$DOTFILES_DIR" remote get-url origin 2>/dev/null | grep -q "ubuntu-dotfiles"; then
		log_info "Updating existing dotfiles at $DOTFILES_DIR..."
		git -C "$DOTFILES_DIR" pull --ff-only
	else
		log_warning "$DOTFILES_DIR is an unrelated git repo; leaving it untouched"
	fi
elif [ -e "$DOTFILES_DIR" ]; then
	log_warning "$DOTFILES_DIR already exists and is not a git repo; leaving it untouched"
else
	log_info "Cloning dotfiles into $DOTFILES_DIR..."
	git clone --depth 1 "$DOTFILES_REPO" "$DOTFILES_DIR"
	log_success "Dotfiles cloned to $DOTFILES_DIR"
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
#    Pre-create top-level directories (e.g. ~/.config) so stow "folds" into
#    them as real directories with symlinked leaves, rather than symlinking the
#    whole directory (which would shadow other apps' configs). Skip .git so no
#    empty ~/.git is created in $HOME.
while IFS= read -r dir; do
	mkdir -p "$HOME/$dir"
done < <(find "$DOTFILES_DIR" -mindepth 1 -maxdepth 1 -type d ! -name '.git' -exec basename {} \;)

log_info "Stowing dotfiles from $DOTFILES_DIR to $HOME..."
if stow -d "$DOTFILES_DIR" -t "$HOME" .; then
	log_success "Dotfiles stowed successfully"
else
	die "Failed to stow dotfiles. Resolve conflicts in ~ and re-run 'stow -d $DOTFILES_DIR -t $HOME .'"
fi
