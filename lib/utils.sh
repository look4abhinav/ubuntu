#!/bin/bash

# ==========================================
# Utility Functions for Ubuntu Setup
# ==========================================

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

log_section() {
    echo -e "\n${BLUE}════════════════════════════════════════${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}════════════════════════════════════════${NC}"
}

# Error Handling
handle_error() {
    log_error "An error occurred on line $1"
    exit 1
}

# Check for Sudo
check_sudo() {
    if [ "$EUID" -eq 0 ]; then
        return 0
    fi

    if ! command -v sudo >/dev/null 2>&1; then
        log_error "This script requires sudo privileges but sudo is not installed."
        exit 1
    fi

    if ! sudo -v; then
        log_error "Sudo authentication failed."
        exit 1
    fi
    
    # Keep sudo alive
    (while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null) &
}

# Command Check
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Ensure Dependency
ensure_dependency() {
    if ! command_exists "$1"; then
        log_info "Installing dependency: $1"
        sudo apt-get install -y "$1"
    fi
}

# Apt Update (with cache check)
apt_update() {
    if [ -z "${APT_UPDATED:-}" ]; then
        log_info "Updating package lists..."
        sudo apt-get update -y
        export APT_UPDATED=true
    fi
}
