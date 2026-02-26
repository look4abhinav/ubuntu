#!/bin/bash

# ==========================================
# Tmux Installation Script (Source Build)
# Based on: https://tmuxcheatsheet.com/how-to-install-tmux/
# Supports: x86_64 and aarch64 (ARM)
# ==========================================

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# ==========================================
# PART 1: PREREQUISITES & DEPENDENCIES
# ==========================================
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Tmux Installation from Source${NC}"
echo -e "${BLUE}========================================${NC}"

echo -e "\n${BLUE}[1/5] Installing Build Dependencies...${NC}"

echo "Updating package lists..."
if sudo apt-get update -y > /dev/null 2>&1; then
    echo -e "${GREEN}✅  Package lists updated${NC}"
else
    echo -e "${RED}❌  Failed to update package lists${NC}"
    exit 1
fi

echo "Installing dependencies..."
DEPS="libevent-dev ncurses-dev build-essential bison pkg-config curl tar"
if sudo apt-get install -y $DEPS > /dev/null 2>&1; then
    echo -e "${GREEN}✅  Build dependencies installed${NC}"
else
    echo -e "${RED}❌  Failed to install dependencies${NC}"
    exit 1
fi

# ==========================================
# PART 2: DOWNLOAD SOURCE
# ==========================================
echo -e "\n${BLUE}[2/5] Downloading Tmux Source...${NC}"

echo "Fetching latest tmux version..."
TMUX_VERSION=$(curl -s https://api.github.com/repos/tmux/tmux/releases/latest | grep -oP '"tag_name": "\K(.*)(?=")')

if [ -z "$TMUX_VERSION" ]; then
    echo -e "${YELLOW}⚠️  Could not fetch latest version, using fallback 3.5a${NC}"
    TMUX_VERSION="3.5a"
fi

echo -e "${GREEN}✅  Detected version: $TMUX_VERSION${NC}"

TEMP_DIR=$(mktemp -d)
echo "Temporary directory: $TEMP_DIR"

DOWNLOAD_URL="https://github.com/tmux/tmux/releases/download/${TMUX_VERSION}/tmux-${TMUX_VERSION}.tar.gz"

echo "Downloading tmux from GitHub..."
if curl -L "$DOWNLOAD_URL" -o "$TEMP_DIR/tmux.tar.gz" > /dev/null 2>&1; then
    echo -e "${GREEN}✅  Download successful${NC}"
else
    echo -e "${RED}❌  Failed to download tmux${NC}"
    rm -rf "$TEMP_DIR"
    exit 1
fi

# ==========================================
# PART 3: BUILD FROM SOURCE
# ==========================================
echo -e "\n${BLUE}[3/5] Building from Source...${NC}"

echo "Extracting archive..."
if tar -xzf "$TEMP_DIR/tmux.tar.gz" -C "$TEMP_DIR"; then
    echo -e "${GREEN}✅  Archive extracted${NC}"
else
    echo -e "${RED}❌  Failed to extract archive${NC}"
    rm -rf "$TEMP_DIR"
    exit 1
fi

SRC_DIR="$TEMP_DIR/tmux-$TMUX_VERSION"

if [ ! -d "$SRC_DIR" ]; then
    echo -e "${RED}❌  Source directory not found: $SRC_DIR${NC}"
    rm -rf "$TEMP_DIR"
    exit 1
fi

cd "$SRC_DIR"

echo "Running configure..."
if ./configure > /dev/null 2>&1; then
    echo -e "${GREEN}✅  Configure completed${NC}"
else
    echo -e "${RED}❌  Configure failed${NC}"
    cd ~
    rm -rf "$TEMP_DIR"
    exit 1
fi

echo "Compiling (this may take a moment)..."
if make > /dev/null 2>&1; then
    echo -e "${GREEN}✅  Compilation successful${NC}"
else
    echo -e "${RED}❌  Compilation failed${NC}"
    cd ~
    rm -rf "$TEMP_DIR"
    exit 1
fi

echo "Installing to system..."
if sudo make install > /dev/null 2>&1; then
    echo -e "${GREEN}✅  Installation successful${NC}"
else
    echo -e "${RED}❌  Installation failed${NC}"
    cd ~
    rm -rf "$TEMP_DIR"
    exit 1
fi

# Clean up
cd ~
rm -rf "$TEMP_DIR"
echo -e "${GREEN}✅  Cleaned up temporary files${NC}"

# ==========================================
# PART 4: VERIFY INSTALLATION
# ==========================================
echo -e "\n${BLUE}[4/5] Verifying Installation...${NC}"

if command -v tmux &> /dev/null; then
    TMUX_PATH=$(which tmux)
    TMUX_VER=$(tmux -V)
    echo -e "${GREEN}✅  Tmux found at: $TMUX_PATH${NC}"
    echo -e "${GREEN}✅  $TMUX_VER${NC}"
else
    echo -e "${YELLOW}⚠️  Tmux not found in PATH${NC}"
    echo -e "    It was installed to /usr/local/bin"
    echo -e "    Ensure /usr/local/bin is in your PATH"
fi

# ==========================================
# PART 5: INSTALL TPM (TMUX PLUGIN MANAGER)
# ==========================================
echo -e "\n${BLUE}[5/5] Setting up Tmux Plugin Manager...${NC}"

TPM_DIR="$HOME/.config/tmux/plugins/tpm"

if [ -d "$TPM_DIR" ]; then
    echo "Tmux Plugin Manager already installed. Updating..."
    cd "$TPM_DIR"
    if git pull > /dev/null 2>&1; then
        echo -e "${GREEN}✅  Tmux Plugin Manager updated${NC}"
    else
        echo -e "${YELLOW}⚠️  Failed to update TPM${NC}"
    fi
else
    echo "Installing Tmux Plugin Manager..."
    if git clone https://github.com/tmux-plugins/tpm "$TPM_DIR" > /dev/null 2>&1; then
        echo -e "${GREEN}✅  Tmux Plugin Manager installed${NC}"
    else
        echo -e "${YELLOW}⚠️  Failed to install TPM${NC}"
    fi
fi

cd ~

# ==========================================
# SUMMARY
# ==========================================
echo -e "\n${BLUE}========================================${NC}"
echo -e "${GREEN}✅  Installation Complete!${NC}"
echo -e "${BLUE}========================================${NC}"
echo -e "Tmux version: $(tmux -V)"
echo -e "Installation path: $(which tmux)"
echo -e "TPM directory: $TPM_DIR"
echo -e "${BLUE}========================================${NC}\n"
