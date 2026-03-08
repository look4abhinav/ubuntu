#!/bin/bash

# ==========================================
# Docker Installation Script
# ==========================================

set -euo pipefail

# Source utils
# Determine where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# Assuming standard structure: tools/docker.sh -> lib/utils.sh
if [ -f "$SCRIPT_DIR/../lib/utils.sh" ]; then
    source "$SCRIPT_DIR/../lib/utils.sh"
else
    # Fallback if running from root or different structure
    echo "Error: lib/utils.sh not found at $SCRIPT_DIR/../lib/utils.sh"
    exit 1
fi

log_section "Docker Installation"

check_sudo

if command_exists "docker"; then
    log_warn "Docker is already installed: $(docker --version)"
    # For automated setup, we skip re-install unless forced.
    # In interactive mode we might ask.
    # Let's assume non-interactive for now or implement a flag.
    log_info "Skipping installation."
    exit 0
fi

log_info "Removing conflicting packages..."
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do
    sudo apt-get remove -y "$pkg" || true
done

log_info "Setting up repository..."
apt_update
ensure_dependency "ca-certificates"
ensure_dependency "curl"
ensure_dependency "gnupg"

sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

log_info "Installing Docker Engine..."
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

log_info "Adding user to docker group..."
if ! getent group docker >/dev/null; then
    sudo groupadd docker
fi
sudo usermod -aG docker "$USER"

log_success "Docker installed successfully!"
log_info "Note: You may need to log out and back in for group changes to take effect."
