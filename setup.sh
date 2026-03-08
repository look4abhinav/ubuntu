#!/bin/bash

# ==========================================
# Master Ubuntu Server Setup Script
# Automates complete server setup from scratch
# ==========================================

set -euo pipefail

# Determine script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/lib/utils.sh"

log_section "Ubuntu Server Setup"

# Check for sudo privileges
check_sudo

# Ensure basic dependencies
log_info "Ensuring basic dependencies..."
ensure_dependency "curl"
ensure_dependency "git"
ensure_dependency "build-essential"

# Update System
log_section "System Update"
apt_update
if [ "${SKIP_UPGRADE:-false}" != "true" ]; then
    log_info "Upgrading packages..."
    sudo apt-get upgrade -y
else
    log_info "Skipping system upgrade (SKIP_UPGRADE=true)."
fi
log_success "System updated."

# Install Stow
log_section "Dotfiles Setup"
ensure_dependency "stow"

if [ -f "$SCRIPT_DIR/tools/stow.sh" ]; then
    log_info "Delegating dotfiles setup to tools/stow.sh..."
    # We will let the tool loop handle it, or run it explicitly here if order matters.
    # The tool loop runs everything alphabetically. S... comes after D (docker), E (eza)...
    # Dotfiles (stow) usually should be done early if shell configs depend on them.
    # Zsh setup is last (Z).
    # So alphabetical is mostly fine, but let's run stow explicitly here for clarity and then skip it in loop?
    # Actually, simpler to just let the loop run it.
    log_info "Stow setup will run with other tools."
else
    log_warn "tools/stow.sh not found. Skipping dotfiles setup."
fi

# Run Tool Scripts
log_section "Installing Tools"

# Define tool order (optional, but good for dependencies)
# If stow.sh is in tools/, it will run.
# We should ensure stow runs early if other tools depend on it, but usually they don't.
# Zsh setup might be good to run last or explicitly.

# Find all executable scripts in tools/
TOOL_SCRIPTS=("$SCRIPT_DIR/tools/"*.sh)

if [ ${#TOOL_SCRIPTS[@]} -eq 0 ]; then
    log_warn "No tool scripts found in tools/."
else
    for script in "${TOOL_SCRIPTS[@]}"; do
        if [ -x "$script" ]; then
            script_name=$(basename "$script")
            
            # Skip stow.sh here if we want to run it separately or if we handled it above.
            # But since we removed the inline stow logic, we let it run here.
            
            log_info "Running $script_name..."
            if "$script"; then
                log_success "$script_name completed."
            else
                log_error "$script_name failed."
            fi
        else
            log_warn "Skipping non-executable script: $(basename "$script")"
        fi
    done
fi

log_section "Setup Complete!"
log_info "Please restart your shell or log out/in for changes to take effect."
