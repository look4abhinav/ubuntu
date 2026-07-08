#!/bin/bash

# FZF (Fuzzy Finder) installation and update script
# Installs or updates the fzf binary from the official repository.
#
# Only the binary is installed here (--bin). fzf's key bindings and completion
# are wired up by the stowed ~/.zshrc via the cached `fzf --zsh` output, so we
# deliberately do NOT let the installer edit shell rc files (dotfiles stay the
# single source of truth). ~/.fzf/bin is already on PATH via ~/.zshrc.

set -e

FZF_DIR="$HOME/.fzf"

# Check if fzf is already installed
if [ -d "$FZF_DIR" ]; then
    # Update existing installation
    echo "FZF already installed. Updating..."
    cd "$FZF_DIR" || exit 1
    git pull
else
    # Fresh installation
    echo "Installing FZF..."
    git clone --depth 1 https://github.com/junegunn/fzf.git "$FZF_DIR"
fi

# Install/update the binary only (no rc-file modifications)
"$FZF_DIR/install" --bin

echo "FZF installed to $FZF_DIR/bin/fzf"