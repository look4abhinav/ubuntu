#!/bin/bash

# ==========================================
# Neovim & Formatters Automation Installer
# Supports: x86_64 and aarch64 (ARM)
# ==========================================

set -e

# 1. Global Architecture Check
ARCH=$(uname -m)
echo "Detected architecture: $ARCH"

# ==========================================
# PART 1: NEOVIM INSTALLATION
# ==========================================
echo "------------------------------------------"
echo "Starting Neovim Installation..."
echo "------------------------------------------"

# Install Dependencies
if sudo apt install unzip -y; then
    echo "Dependencies Installed."
else
    echo "Unable to install dependencies"
fi

# Define Neovim download URL based on architecture
if [ "$ARCH" == "x86_64" ]; then
    NVIM_URL="https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz"
    NVIM_EXTRACT_FOLDER="nvim-linux-x86_64"
elif [ "$ARCH" == "aarch64" ]; then
    NVIM_URL="https://github.com/neovim/neovim/releases/latest/download/nvim-linux-arm64.tar.gz"
    NVIM_EXTRACT_FOLDER="nvim-linux-arm64"
else
    echo "Error: Unsupported architecture $ARCH"
    exit 1
fi

TEMP_DIR=$(mktemp -d)

echo "Downloading Neovim stable..."
curl -L "$NVIM_URL" -o "$TEMP_DIR/nvim.tar.gz"

INSTALL_DIR_NVIM="/opt/nvim-linux"

echo "Removing previous Neovim installations..."
if [ -d "$INSTALL_DIR_NVIM" ]; then
    sudo rm -rf "$INSTALL_DIR_NVIM"
fi

echo "Extracting to /opt..."
sudo tar -C /opt -xzf "$TEMP_DIR/nvim.tar.gz"

# Normalize folder name to /opt/nvim-linux
if [ -d "/opt/$NVIM_EXTRACT_FOLDER" ]; then
    sudo mv "/opt/$NVIM_EXTRACT_FOLDER" "$INSTALL_DIR_NVIM"
fi

# Fix permissions: ensure current user owns the installation
sudo chown -R "$USER:$USER" "$INSTALL_DIR_NVIM"
sudo chmod -R u+rwx "$INSTALL_DIR_NVIM"

echo "Cleaning up Neovim temp files..."
rm -rf "$TEMP_DIR"

# Configure PATH for Neovim
BIN_PATH="$INSTALL_DIR_NVIM/bin"
CONFIG_FILES=("$HOME/.bashrc" "$HOME/.zshrc")

for CONFIG_FILE in "${CONFIG_FILES[@]}"; do
    if [ -f "$CONFIG_FILE" ]; then
        if grep -q "$BIN_PATH" "$CONFIG_FILE"; then
            echo "  [SKIP] Neovim path already in $CONFIG_FILE"
        else
            echo "  [UPDATE] Adding Neovim path to $CONFIG_FILE"
            echo "" >> "$CONFIG_FILE"
            echo "# Neovim Path" >> "$CONFIG_FILE"
            echo "export PATH=\"\$PATH:$BIN_PATH\"" >> "$CONFIG_FILE"
        fi
    fi
done

# Add to current shell's PATH immediately
export PATH="$BIN_PATH:$PATH"

echo "Neovim installed successfully."

# ==========================================
# PART 2: FORMATTERS INSTALLATION
# ==========================================
echo "------------------------------------------"
echo "Starting Formatter Installation..."
echo "------------------------------------------"

# Directory where we will install the binaries
LOCAL_BIN="$HOME/.local/bin"
mkdir -p "$LOCAL_BIN"
export PATH="$LOCAL_BIN:$PATH"

# Determine Formatter Filename Patterns based on Arch
if [ "$ARCH" == "x86_64" ]; then
    STYLUA_PATTERN="linux-x86_64.zip"
    TAPLO_PATTERN="linux-x86_64.gz"
    YAMLFMT_PATTERN="Linux_x86_64.tar.gz"
elif [ "$ARCH" == "aarch64" ]; then
    STYLUA_PATTERN="linux-aarch64.zip"
    TAPLO_PATTERN="linux-aarch64.gz"
    YAMLFMT_PATTERN="Linux_arm64.tar.gz"
fi

echo "Using patterns for $ARCH:"
echo "  StyLua:  $STYLUA_PATTERN"
echo "  Taplo:   $TAPLO_PATTERN"
echo "  Yamlfmt: $YAMLFMT_PATTERN"

# Helper function to get download URL
get_download_url() {
    local repo=$1
    local pattern=$2
    
    # We use -i in grep for case-insensitive matching
    local url=$(curl -s "https://api.github.com/repos/$repo/releases/latest" | \
        grep -oP '"browser_download_url": "\K(.*)(?=")' | \
        grep -i "$pattern" | head -n 1)
    
    echo "$url"
}

TEMP_DIR=$(mktemp -d)

# 1. Ruff (Python)
echo "[1/4] Installing Ruff..."
if command -v uv &> /dev/null; then
    uv tool install ruff --force
else
    echo "  'uv' not found, installing via pip..."
    pip install ruff --break-system-packages
fi

# 2. StyLua (Lua)
echo "[2/4] Installing StyLua..."
STYLUA_URL=$(get_download_url "JohnnyMorganz/StyLua" "$STYLUA_PATTERN")

if [ -z "$STYLUA_URL" ]; then
    echo "  ERROR: Could not find StyLua URL for $ARCH."
else
    curl -L -s "$STYLUA_URL" -o "$TEMP_DIR/stylua.zip"
    unzip -q -o "$TEMP_DIR/stylua.zip" -d "$TEMP_DIR"
    mv "$TEMP_DIR/stylua" "$LOCAL_BIN/stylua"
    chmod u+x "$LOCAL_BIN/stylua"
    chown "$USER:$USER" "$LOCAL_BIN/stylua"
    echo "  Success."
fi

# 3. Taplo (TOML)
echo "[3/4] Installing Taplo..."
TAPLO_URL=$(get_download_url "tamasfe/taplo" "$TAPLO_PATTERN")

if [ -z "$TAPLO_URL" ]; then
    echo "  ERROR: Could not find Taplo URL for $ARCH."
else
    curl -L -s "$TAPLO_URL" -o "$TEMP_DIR/taplo.gz"
    gunzip -f "$TEMP_DIR/taplo.gz"
    mv "$TEMP_DIR/taplo" "$LOCAL_BIN/taplo"
    chmod u+x "$LOCAL_BIN/taplo"
    chown "$USER:$USER" "$LOCAL_BIN/taplo"
    echo "  Success."
fi

# 4. Yamlfmt (YAML)
echo "[4/4] Installing Yamlfmt..."
YAMLFMT_URL=$(get_download_url "google/yamlfmt" "$YAMLFMT_PATTERN")

if [ -z "$YAMLFMT_URL" ]; then
    echo "  ERROR: Could not find Yamlfmt URL for $ARCH."
else
    curl -L -s "$YAMLFMT_URL" -o "$TEMP_DIR/yamlfmt.tar.gz"
    tar -xzf "$TEMP_DIR/yamlfmt.tar.gz" -C "$TEMP_DIR"
    mv "$TEMP_DIR/yamlfmt" "$LOCAL_BIN/yamlfmt"
    chmod u+x "$LOCAL_BIN/yamlfmt"
    chown "$USER:$USER" "$LOCAL_BIN/yamlfmt"
    echo "  Success."
fi

rm -rf "$TEMP_DIR"

# ==========================================
# VERIFICATION
# ==========================================
echo "------------------------------------------"
echo "VERIFICATION REPORT"
echo "------------------------------------------"

verify_tool() {
    local name=$1
    if command -v "$name" &> /dev/null; then
        local version=$($name --version 2>&1 | head -n 1)
        echo -e "✅  $name:\tFOUND ($version)"
    else
        echo -e "❌  $name:\tNOT FOUND"
    fi
}

# Ensure both paths are in current shell for verification
export PATH="$BIN_PATH:$LOCAL_BIN:$PATH"

verify_tool "nvim"
verify_tool "ruff"
verify_tool "stylua"
verify_tool "taplo"
verify_tool "yamlfmt"

echo "------------------------------------------"
echo "Note: If binaries are found but not executable, ensure paths are in your PATH."
echo "Added paths:"
echo "  - $BIN_PATH (Neovim)"
echo "  - $LOCAL_BIN (Formatters)"
echo "You may need to run: source ~/.bashrc (or ~/.zshrc)"
echo "=========================================="