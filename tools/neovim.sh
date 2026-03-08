#!/bin/bash

# ==========================================
# Neovim & Formatters Installer
# ==========================================

set -euo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
if [ -f "$SCRIPT_DIR/../lib/utils.sh" ]; then
    source "$SCRIPT_DIR/../lib/utils.sh"
else
    echo "Error: lib/utils.sh not found."
    exit 1
fi

log_section "Neovim Installation"

check_sudo
ensure_dependency "curl"
ensure_dependency "tar"
ensure_dependency "unzip"
ensure_dependency "gzip"

ARCH=$(uname -m)
log_info "Detected architecture: $ARCH"

# Determine URL and Folder Name
if [ "$ARCH" == "x86_64" ]; then
    NVIM_URL="https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz"
    # GitHub release tarballs unpack to nvim-linux-x86_64
    EXTRACTED_DIR="nvim-linux-x86_64"
elif [ "$ARCH" == "aarch64" ]; then
    NVIM_URL="https://github.com/neovim/neovim/releases/latest/download/nvim-linux-arm64.tar.gz"
    EXTRACTED_DIR="nvim-linux-arm64"
else
    log_error "Unsupported architecture: $ARCH"
    exit 1
fi

INSTALL_DIR="/opt/nvim"

if command_exists "nvim"; then
    log_info "Neovim is already installed: $(nvim --version | head -n 1)"
    # Optional: Logic to update
else
    log_info "Downloading Neovim..."
    TEMP_DIR=$(mktemp -d)
    curl -L "$NVIM_URL" -o "$TEMP_DIR/nvim.tar.gz"
    
    log_info "Installing to $INSTALL_DIR..."
    # Remove old install
    if [ -d "$INSTALL_DIR" ]; then
        sudo rm -rf "$INSTALL_DIR"
    fi
    
    sudo tar -C /opt -xzf "$TEMP_DIR/nvim.tar.gz"
    
    # Rename extracted dir to generic /opt/nvim
    if [ -d "/opt/$EXTRACTED_DIR" ]; then
        sudo mv "/opt/$EXTRACTED_DIR" "$INSTALL_DIR"
    fi
    
    rm -rf "$TEMP_DIR"
    
    # Symlink
    if [ ! -L "/usr/local/bin/nvim" ]; then
        sudo ln -s "$INSTALL_DIR/bin/nvim" "/usr/local/bin/nvim"
    fi
    
    log_success "Neovim installed."
fi

# Formatters
log_section "Formatters Installation"
LOCAL_BIN="$HOME/.local/bin"
mkdir -p "$LOCAL_BIN"
export PATH="$LOCAL_BIN:$PATH"

install_from_github() {
    local repo=$1
    local pattern=$2
    local binary_name=$3
    local type=$4 # zip, tar, gzip
    
    log_info "Installing $binary_name from $repo..."
    
    # Get download URL
    local url
    url=$(curl -s "https://api.github.com/repos/$repo/releases/latest" | \
        grep -oP '"browser_download_url": "\K(.*)(?=")' | \
        grep -i "$pattern" | head -n 1)
        
    if [ -z "$url" ]; then
        log_warn "Could not find release for $binary_name ($pattern)"
        return
    fi
    
    TEMP_DIR=$(mktemp -d)
    local file="$TEMP_DIR/download"
    curl -L -s "$url" -o "$file"
    
    case "$type" in
        "zip")
            unzip -q -o "$file" -d "$TEMP_DIR"
            mv "$TEMP_DIR/$binary_name" "$LOCAL_BIN/$binary_name"
            ;;
        "tar")
            tar -xzf "$file" -C "$TEMP_DIR"
            # Find the binary (might be in subdir)
            find "$TEMP_DIR" -type f -name "$binary_name" -exec mv {} "$LOCAL_BIN/$binary_name" \;
            ;;
        "gzip")
            gunzip -f "$file"
            mv "$TEMP_DIR/download" "$LOCAL_BIN/$binary_name"
            ;;
    esac
    
    chmod +x "$LOCAL_BIN/$binary_name"
    rm -rf "$TEMP_DIR"
    log_success "$binary_name installed."
}

# Determine patterns
if [ "$ARCH" == "x86_64" ]; then
    install_from_github "JohnnyMorganz/StyLua" "linux-x86_64.zip" "stylua" "zip"
    install_from_github "tamasfe/taplo" "linux-x86_64.gz" "taplo" "gzip"
    install_from_github "google/yamlfmt" "Linux_x86_64.tar.gz" "yamlfmt" "tar"
elif [ "$ARCH" == "aarch64" ]; then
    install_from_github "JohnnyMorganz/StyLua" "linux-aarch64.zip" "stylua" "zip"
    install_from_github "tamasfe/taplo" "linux-aarch64.gz" "taplo" "gzip"
    install_from_github "google/yamlfmt" "Linux_arm64.tar.gz" "yamlfmt" "tar"
fi

# Ruff (Python)
log_info "Installing Ruff..."
if command_exists "uv"; then
    uv tool install ruff --force || log_warn "uv tool install failed"
else
    ensure_dependency "pip" # or python3-pip
    # check for pip break system packages
    pip install ruff --break-system-packages || pip install ruff || log_warn "pip install ruff failed"
fi

log_success "Neovim & Formatters setup complete."
