#!/usr/bin/env bash

# ==========================================
# Docker installation (official apt repository)
# Installs Docker Engine + Compose plugin, enables the service,
# and adds the current user to the docker group.
# ==========================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib.sh
source "$SCRIPT_DIR/../lib.sh"

log_section "Docker Installation"

# Remove conflicting legacy packages if present
OLD_PACKAGES=$(dpkg --get-selections docker.io docker-compose docker-compose-v2 docker-doc podman-docker containerd runc 2>/dev/null | cut -f1 | tr '\n' ' ')
if [ -n "${OLD_PACKAGES// /}" ]; then
	log_info "Removing conflicting packages: $OLD_PACKAGES"
	# shellcheck disable=SC2086
	sudo apt-get remove -y $OLD_PACKAGES
fi

# Add Docker's official GPG key
apt_install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository
# shellcheck disable=SC1091
sudo tee /etc/apt/sources.list.d/docker.sources >/dev/null <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Signed-By: /etc/apt/keyrings/docker.asc
EOF

# Fetch the (possibly newly-added) repo index before installing
apt_force_update
apt_install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Enable the service and add the user to the docker group
if sudo systemctl enable --now docker.service; then
	log_success "Docker service enabled and started"
else
	log_warning "Could not enable/start docker.service; check 'systemctl status docker'"
fi

sudo usermod -aG docker "$USER"

log_success "Docker installed: $(docker --version)"
log_warning "Group changes apply after re-login (or run 'newgrp docker')"
