#!/bin/bash

# FZF (Fuzzy Finder) installation and update script
# Installs or updates fzf to the latest version from the official repository

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

# Run the installer
"$FZF_DIR/install"