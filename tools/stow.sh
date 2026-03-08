#!/usr/bin/bash

# ==========================================
# GNU Stow Dotfiles Installation Script
# Clones and stows the main dotfiles repo
# ==========================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/utils.sh"

log_section "Dotfiles Setup"

# Configuration
REPO_URL="https://github.com/look4abhinav/dotfiles.git"
DOTFILES_DIR="$HOME/dotfiles"

# Install Stow
if ! command_exists "stow"; then
    log_info "Installing stow..."
    sudo apt update && sudo apt install -y stow
else
    log_info "Stow is already installed."
fi

# Clone/Update Dotfiles Repo
if [ -d "$DOTFILES_DIR" ]; then
    log_info "Updating dotfiles repo..."
    if git -C "$DOTFILES_DIR" pull --rebase; then
        log_success "Dotfiles repo updated."
    else
        log_warn "Failed to update dotfiles repo. You may need to resolve conflicts manually."
    fi
else
    log_info "Cloning dotfiles repo..."
    if git clone "$REPO_URL" "$DOTFILES_DIR"; then
        log_success "Dotfiles repo cloned."
    else
        log_error "Failed to clone dotfiles repo."
        exit 1
    fi
fi

# Run Stow
log_info "Stowing dotfiles..."
# Use --adopt to handle conflicts (overwrites repo with local if exists, or just links)
# We want repo to be the source of truth, so we might want to back up existing first.
# But `stow --adopt` is often easiest for first run, then `git reset --hard` to force repo state.

if stow -d "$DOTFILES_DIR" -t "$HOME" . 2>/dev/null; then
    log_success "Dotfiles stowed successfully."
else
    log_warn "Stow reported conflicts. Using --adopt to resolve..."
    if stow --adopt -d "$DOTFILES_DIR" -t "$HOME" . ; then
        log_success "Dotfiles stowed with --adopt."
        
        # Force the repo state (discard any adopted local changes that conflict)
        log_info "Resetting any adopted local changes to match repo..."
        git -C "$DOTFILES_DIR" reset --hard HEAD
        log_success "Dotfiles synced to repo state."
    else
        log_error "Failed to stow dotfiles."
        exit 1
    fi
fi

log_success "Dotfiles setup complete!"
