#!/bin/bash

# ==========================================
# Zoxide Installation Script
# ==========================================

set -euo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
if [ -f "$SCRIPT_DIR/../lib/utils.sh" ]; then
    source "$SCRIPT_DIR/../lib/utils.sh"
else
    echo "Error: lib/utils.sh not found."
    exit 1
fi

log_section "Zoxide Installation"

if command_exists "zoxide"; then
    log_info "Zoxide is already installed: $(zoxide --version)"
    exit 0
fi

log_info "Installing Zoxide..."
ensure_dependency "curl"

# Download and run installer
curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash

# Add to shell config
CONFIG_FILES=("$HOME/.bashrc" "$HOME/.zshrc")
for rc in "${CONFIG_FILES[@]}"; do
    if [ -f "$rc" ]; then
        if ! grep -q "zoxide init" "$rc"; then
            log_info "Adding zoxide init to $rc"
            if [[ "$rc" == *zshrc ]]; then
                echo 'eval "$(zoxide init zsh)"' >> "$rc"
            else
                echo 'eval "$(zoxide init bash)"' >> "$rc"
            fi
        fi
    fi
done

log_success "Zoxide setup complete."
