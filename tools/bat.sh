#!/usr/bin/env bash

# ==========================================
# bat + Catppuccin themes installation
# Installs bat (Ubuntu ships it as `batcat`) and the Catppuccin themes so that
# the stowed ~/.config/bat/config (which sets --theme="Catppuccin Mocha") works
# out of the box. Also exposes `bat` on PATH via ~/.local/bin.
# ==========================================

set -euo pipefail

BAT_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/bat"
THEMES_DIR="$BAT_DIR/themes"

echo "=== bat installer: starting ==="

# 1) Install bat from apt (Ubuntu packages the binary as `batcat`)
echo "Updating package lists..."
sudo apt-get update -y
echo "Installing bat..."
sudo apt-get install -y bat

# 2) Expose `bat` on PATH (~/.local/bin is already on PATH via the zshrc)
LOCAL_BIN="$HOME/.local/bin"
mkdir -p "$LOCAL_BIN"
if ! command -v bat >/dev/null 2>&1 && command -v batcat >/dev/null 2>&1; then
    ln -sf "$(command -v batcat)" "$LOCAL_BIN/bat"
    echo "Symlinked batcat -> $LOCAL_BIN/bat"
else
    echo "bat already on PATH ($(command -v bat || echo batcat))"
fi

# 3) Install Catppuccin themes
mkdir -p "$THEMES_DIR"
if [ ! -d "$THEMES_DIR/catppuccin" ]; then
    echo "Cloning Catppuccin bat themes..."
    git clone --depth 1 https://github.com/catppuccin/bat.git "$THEMES_DIR/catppuccin"
else
    echo "Catppuccin themes already present; updating..."
    git -C "$THEMES_DIR/catppuccin" pull --rebase >/dev/null 2>&1 || true
fi

# Copy the .tmTheme files directly into bat's themes dir (flat layout)
find "$THEMES_DIR/catppuccin/themes" -name '*.tmTheme' -exec cp -f {} "$THEMES_DIR/" \;

# 4) Build the bat cache so the themes are picked up
echo "Building bat cache..."
batcat cache --build

# 5) Verify
if batcat --list-themes 2>/dev/null | grep -q "Catppuccin Mocha"; then
    echo "✅  Catppuccin Mocha theme available"
else
    echo "⚠️  Catppuccin Mocha theme not found after cache build"
fi

echo "=== bat installer: finished ($(batcat --version)) ==="