#!/bin/bash

# ==========================================
# UV (Python Environment Manager) Installer
# Astral: https://astral.sh/uv
# Supports: x86_64 and aarch64 (ARM)
# ==========================================

set -e

# ==========================================
# PART 1: PREREQUISITES & CLEANUP
# ==========================================
echo "------------------------------------------"
echo "UV Installation & Setup"
echo "------------------------------------------"

echo "[1/4] Checking for existing UV installations..."

# List of UV-related binaries to check
UV_BINARIES=("uv" "uvx" "uvw")
FOUND_INSTALLATIONS=()

for binary in "${UV_BINARIES[@]}"; do
    if command -v "$binary" &> /dev/null; then
        FOUND_INSTALLATIONS+=("$binary")
        echo "  Found existing: $binary"
    fi
done

# If existing installations found, uninstall them
if [ ${#FOUND_INSTALLATIONS[@]} -gt 0 ]; then
    echo ""
    echo "⚠️  Found ${#FOUND_INSTALLATIONS[@]} existing UV installation(s)."
    echo "Removing previous UV installations..."
    
    # Try to uninstall via the installer script
    if [ -f "$HOME/.cargo/bin/uv" ]; then
        echo "  Removing from ~/.cargo/bin..."
        rm -f "$HOME/.cargo/bin/uv"
    fi
    
    # Check if uv was installed via pip
    if pip list 2>/dev/null | grep -q "^uv "; then
        echo "  Removing UV installed via pip..."
        pip uninstall uv -y 2>/dev/null || true
    fi
    
    # Clean up any other installations
    for binary in "${UV_BINARIES[@]}"; do
        if command -v "$binary" &> /dev/null; then
            BINARY_PATH=$(command -v "$binary")
            echo "  Removing: $BINARY_PATH"
            rm -f "$BINARY_PATH" || sudo rm -f "$BINARY_PATH" || true
        fi
    done
    
    echo "  Cleanup completed."
fi

# ==========================================
# PART 2: UV INSTALLATION
# ==========================================
echo ""
echo "[2/4] Installing UV..."

# Download and run the official installer
if curl -LsSf https://astral.sh/uv/install.sh | sh; then
    echo "✅  UV installation script executed successfully."
else
    echo "❌  Failed to run UV installation script."
    exit 1
fi

# Determine installation directory based on shell
UV_INSTALL_DIR="$HOME/.cargo/bin"

# Add to current shell's PATH immediately
export PATH="$UV_INSTALL_DIR:$PATH"

# Configure PATH for UV in shell config files
CONFIG_FILES=("$HOME/.bashrc" "$HOME/.zshrc")

for CONFIG_FILE in "${CONFIG_FILES[@]}"; do
    if [ -f "$CONFIG_FILE" ]; then
        if grep -q "$UV_INSTALL_DIR" "$CONFIG_FILE"; then
            echo "  [SKIP] UV path already in $CONFIG_FILE"
        else
            echo "  [UPDATE] Adding UV path to $CONFIG_FILE"
            echo "" >> "$CONFIG_FILE"
            echo "# UV (Astral Python Package Manager)" >> "$CONFIG_FILE"
            echo "export PATH=\"\$PATH:$UV_INSTALL_DIR\"" >> "$CONFIG_FILE"
        fi
    fi
done

echo "✅  UV installed successfully."

# ==========================================
# PART 3: UV TOOLS INSTALLATION
# ==========================================
echo ""
echo "[3/4] Installing UV Tools..."

# Verify uv command is available
if command -v uv &> /dev/null; then
    
    # Install tools
    echo "  Installing 'ty' tool..."
    if uv tool install ty@latest; then
        echo "  ✅  ty installed"
    else
        echo "  ⚠️  Failed to install ty (optional)"
    fi
    
    echo "  Installing 'ruff' tool..."
    if uv tool install ruff@latest; then
        echo "  ✅  ruff installed"
    else
        echo "  ⚠️  Failed to install ruff (optional)"
    fi
    
else
    echo "  ❌  UV binary not found in PATH. Installation may have failed."
    exit 1
fi

# ==========================================
# PART 4: VERIFICATION
# ==========================================
echo ""
echo "[4/4] Verification Report"
echo "------------------------------------------"

verify_tool() {
    local name=$1
    if command -v "$name" &> /dev/null; then
        local version=$($name --version 2>&1 | head -n 1)
        echo "✅  $name: FOUND ($version)"
    else
        echo "❌  $name: NOT FOUND"
    fi
}

# Ensure UV path is in current shell for verification
export PATH="$UV_INSTALL_DIR:$PATH"

verify_tool "uv"
verify_tool "uvx"
verify_tool "ty"
verify_tool "ruff"

echo "------------------------------------------"
echo ""
echo "Installation Summary:"
echo "  Installation directory: $UV_INSTALL_DIR"
echo "  PATH updated in: ~/.bashrc, ~/.zshrc"
echo ""
echo "Note: If binaries are not found, run:"
echo "  source ~/.bashrc (or ~/.zshrc)"
echo "=========================================="
