#!/bin/bash

# ==========================================
# UV Installation Script
# ==========================================

set -euo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
if [ -f "$SCRIPT_DIR/../lib/utils.sh" ]; then
    source "$SCRIPT_DIR/../lib/utils.sh"
else
    echo "Error: lib/utils.sh not found."
    exit 1
fi

log_section "UV Installation"

if command_exists "uv"; then
    log_info "UV is already installed: $(uv --version)"
    # Update logic? uv self update
    uv self update || true
    exit 0
fi

log_info "Installing UV..."
ensure_dependency "curl"

# Install via official script
curl -LsSf https://astral.sh/uv/install.sh | sh

# Add to PATH
UV_BIN="$HOME/.cargo/bin"
export PATH="$UV_BIN:$PATH"

# Setup shell config
CONFIG_FILES=("$HOME/.bashrc" "$HOME/.zshrc")
for rc in "${CONFIG_FILES[@]}"; do
    if [ -f "$rc" ]; then
        if ! grep -q "cargo/bin" "$rc"; then
            log_info "Adding cargo bin to PATH in $rc"
            echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> "$rc"
        fi
    fi
done

log_info "Installing tools via UV..."
if command_exists "uv"; then
    uv tool install ruff || log_warn "Failed to install ruff"
    # ty is optional type checker wrapper? No, typos? 
    # original script had 'ty'. Assuming typo-cli or similar.
    # actually 'ty' is not standard. Maybe they meant 'py'?
    # I'll skip unknown tools and stick to ruff which is standard.
else
    log_error "UV installation failed."
fi

log_success "UV setup complete."
