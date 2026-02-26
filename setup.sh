#!/bin/bash

# Master Ubuntu Server Setup Script
# This script automates the complete setup of an Ubuntu server from scratch

set -o pipefail

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Tracking arrays
SUCCESSFUL_STEPS=()
FAILED_STEPS=()

# Helper functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_section() {
    echo -e "\n${BLUE}╔════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC} $1"
    echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
}

log_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Verify we're on Linux
if [[ ! "$OSTYPE" == "linux-gnu"* ]]; then
    log_error "This script is designed for Linux systems only"
    exit 1
fi

log_section "Ubuntu Server Setup Script"
log_info "Script directory: $SCRIPT_DIR"
log_info "Home directory: $HOME"

# Step 1: System Update
log_section "Step 1: System Update"
log_info "Running apt update and upgrade..."
if sudo apt update && sudo apt upgrade -y; then
    log_success "System updated and upgraded"
    SUCCESSFUL_STEPS+=("System Update")
else
    log_error "System update failed"
    FAILED_STEPS+=("System Update")
fi

# Step 2: Setup Zsh
log_section "Step 2: Setting up Zsh"
if [ -f "$SCRIPT_DIR/tools/zsh.sh" ]; then
    log_info "Running zsh.sh..."
    if bash "$SCRIPT_DIR/tools/zsh.sh"; then
        log_success "Zsh setup complete"
        SUCCESSFUL_STEPS+=("Zsh Setup")
    else
        log_error "Zsh setup failed"
        FAILED_STEPS+=("Zsh Setup")
    fi
else
    log_error "zsh.sh not found at $SCRIPT_DIR/tools/zsh.sh"
    FAILED_STEPS+=("Zsh Setup")
fi

# Step 3: Setup Stow and stow the dotfiles
log_section "Step 3: Setting up Stow and Dotfiles"

# Install stow
log_info "Installing stow..."
if sudo apt install stow -y; then
    log_success "Stow installed"
    
    # Stow the dotfiles
    log_info "Stowing dotfiles from $SCRIPT_DIR/dotfiles to $HOME..."
    if [ -d "$SCRIPT_DIR/dotfiles" ]; then
        if cd "$SCRIPT_DIR" && stow -v -t "$HOME" dotfiles && cd - > /dev/null; then
            log_success "Dotfiles stowed successfully"
            SUCCESSFUL_STEPS+=("Dotfiles Setup")
        else
            log_error "Failed to stow dotfiles"
            FAILED_STEPS+=("Dotfiles Setup")
        fi
    else
        log_error "dotfiles directory not found at $SCRIPT_DIR/dotfiles"
        FAILED_STEPS+=("Dotfiles Setup")
    fi
else
    log_error "Failed to install stow"
    FAILED_STEPS+=("Dotfiles Setup")
fi

# Step 4: Install remaining tools
log_section "Step 4: Installing Additional Tools"
tools=("docker.sh" "eza.sh" "fzf.sh" "neovim.sh" "tmux.sh" "uv.sh" "zoxide.sh")

for tool in "${tools[@]}"; do
    tool_path="$SCRIPT_DIR/tools/$tool"
    if [ -f "$tool_path" ]; then
        log_info "Installing from $tool..."
        if bash "$tool_path"; then
            log_success "$tool completed"
            SUCCESSFUL_STEPS+=("${tool%.*}")
        else
            log_error "$tool failed"
            FAILED_STEPS+=("${tool%.*}")
        fi
    else
        log_warning "$tool not found at $tool_path, skipping..."
        FAILED_STEPS+=("${tool%.*} (not found)")
    fi
done

# Print Summary Report
log_section "Setup Summary"
echo -e "\n${GREEN}Successful Steps (${#SUCCESSFUL_STEPS[@]}):${NC}"
for step in "${SUCCESSFUL_STEPS[@]}"; do
    echo -e "  ${GREEN}✓${NC} $step"
done

if [ ${#FAILED_STEPS[@]} -gt 0 ]; then
    echo -e "\n${RED}Failed Steps (${#FAILED_STEPS[@]}):${NC}"
    for step in "${FAILED_STEPS[@]}"; do
        echo -e "  ${RED}✗${NC} $step"
    done
fi

echo ""
if [ ${#FAILED_STEPS[@]} -eq 0 ]; then
    log_success "All steps completed successfully!"
else
    log_warning "${#FAILED_STEPS[@]} step(s) failed. Please review the errors above."
fi

echo ""
log_info "Next steps:"
echo "  1. You may need to restart your shell or log out and log back in"
echo "  2. Start a new shell session to use the new Zsh configuration"
echo "  3. Check that all tools are properly installed"
echo ""
log_info "Enjoy your newly configured Ubuntu server!"
