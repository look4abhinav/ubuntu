#!/usr/bin/env bash

# Neat, safe installer for zsh on Debian/Ubuntu
# - Checks if zsh is already installed and skips installation when possible
# - Verifies and adds zsh to /etc/shells if necessary (so `chsh` accepts it)
# - Only calls `chsh` when zsh is not already the user's login shell

set -euo pipefail

echo "=== zsh installer: starting ==="

# 1) Check if zsh is already installed
if command -v zsh >/dev/null 2>&1; then
	echo "zsh is already installed: $(zsh --version 2>/dev/null | head -n1)"
else
	echo "zsh not found — installing via apt"
	echo "Updating apt package index..."
	sudo apt-get update -y
	echo "Installing zsh package..."
	sudo apt-get install -y zsh
	echo "Installation finished: $(zsh --version 2>/dev/null | head -n1 || echo 'unknown')"
fi

# 2) Ensure the zsh binary is present and known
ZSH_PATH="$(command -v zsh || true)"
if [ -z "$ZSH_PATH" ]; then
	echo "ERROR: zsh binary not found after install." >&2
	exit 1
fi

echo "zsh binary: $ZSH_PATH"

# 3) Ensure zsh appears in /etc/shells so chsh will accept it
if ! grep -Fxq "$ZSH_PATH" /etc/shells; then
	echo "Adding $ZSH_PATH to /etc/shells (requires sudo)"
	echo "$ZSH_PATH" | sudo tee -a /etc/shells >/dev/null
else
	echo "$ZSH_PATH already listed in /etc/shells"
fi

# 4) Check current login shell for the invoking user
# Use getent to be robust (works when not running under a login shell)
CURRENT_SHELL="$(getent passwd "$USER" | cut -d: -f7 || echo '')"
if [ "$CURRENT_SHELL" = "$ZSH_PATH" ]; then
	echo "zsh is already the default shell for user $USER ($CURRENT_SHELL). No change needed."
	NEED_RELOGIN=false
else
	echo "Current shell for $USER: $CURRENT_SHELL"
	echo "Switching default shell to $ZSH_PATH for user $USER"
	if chsh -s "$ZSH_PATH" "$USER"; then
		echo "Successfully changed default shell to $ZSH_PATH for $USER"
		NEED_RELOGIN=true
	else
		echo "Warning: failed to change default shell automatically. You can run: chsh -s $ZSH_PATH $USER" >&2
		NEED_RELOGIN=false
	fi
fi

if [ "${NEED_RELOGIN:-false}" = true ]; then
	echo "Please log out and log back in (or reboot) for the shell change to take effect."
else
	echo "No logout required."
fi

echo "=== zsh installer: finished ==="