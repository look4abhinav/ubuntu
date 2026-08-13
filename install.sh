#!/usr/bin/env bash
set -euo pipefail

# Refuse to run as root; setup.sh (and its tools) expect a normal user.
if [ "$EUID" -eq 0 ]; then
	echo "Please do not run as root; run as your normal user." >&2
	exit 1
fi

echo "Bootstrapping Ubuntu Server Setup..."

# Safely create a temporary directory
INSTALL_DIR="$(mktemp -d "${TMPDIR:-/tmp}/ubuntu-setup.XXXXXX")"

# Clean up the temp directory even if the script fails midway
trap 'rm -rf -- "$INSTALL_DIR"' EXIT

if ! command -v git >/dev/null 2>&1; then
	echo "Installing git..."
	sudo apt-get update -y
	sudo apt-get install -y git
fi

echo "Cloning repository into $INSTALL_DIR..."
git clone --depth 1 https://github.com/look4abhinav/ubuntu.git "$INSTALL_DIR"
cd "$INSTALL_DIR"

chmod +x setup.sh
echo "Executing setup.sh..."
./setup.sh

echo "Setup complete! Directory will be cleaned up automatically."
