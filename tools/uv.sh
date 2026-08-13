#!/usr/bin/env bash

# ==========================================
# uv (Python environment manager) installer
# Uses the official installer with UV_NO_MODIFY_PATH=1 so shell rc files are
# never touched (dotfiles remain the single source of truth). Also installs
# `ty` and `ruff` as uv tools.
# ==========================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib.sh
source "$SCRIPT_DIR/../lib.sh"

log_section "uv Installation"

# 1) Remove any legacy pip-installed uv to avoid PATH conflicts
if pip list 2>/dev/null | grep -q "^uv "; then
	log_info "Removing pip-installed uv..."
	pip uninstall uv -y 2>/dev/null || true
fi

# 2) Install uv without letting it modify shell profiles
log_info "Installing uv..."
if ! curl -LsSf https://astral.sh/uv/install.sh | UV_NO_MODIFY_PATH=1 sh; then
	die "Failed to install uv"
fi

# uv installs to ~/.local/bin; add it to this session's PATH for verification
export PATH="$LOCAL_BIN:$PATH"

# 3) Install uv tools
log_info "Installing uv tools (ty, ruff)..."
cmd_exists uv || die "uv binary not found on PATH after installation"
uv tool install ty || log_warning "Failed to install ty (optional)"
uv tool install ruff || log_warning "Failed to install ruff (optional)"

# 4) Verification
verify_tool uv
verify_tool uvx
verify_tool ty
verify_tool ruff

log_info "uv and tools installed to ~/.local/bin (PATH managed by dotfiles)"
