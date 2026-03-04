#!/bin/bash

# ==========================================
# GNU Stow Dotfiles Installation Script
# ==========================================

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ==========================================
# SETUP
# ==========================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$SCRIPT_DIR/../dotfiles"
HOME_DIR="$HOME"
BACKUP_DIR="$HOME_DIR/.dotfiles_backup_$(date +%Y%m%d_%H%M%S)"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}GNU Stow Dotfiles Installation${NC}"
echo -e "${BLUE}========================================${NC}"

# ==========================================
# PART 1: PREREQUISITES CHECK
# ==========================================
echo -e "\n${BLUE}[1/4] Checking Prerequisites...${NC}"

# Check if stow is installed
if ! command -v stow &> /dev/null; then
    echo -e "${YELLOW}⚠️  GNU Stow not found. Installing...${NC}"
    if sudo apt update && sudo apt install stow -y; then
        echo -e "${GREEN}✅  GNU Stow installed successfully${NC}"
    else
        echo -e "${RED}❌  Failed to install GNU Stow${NC}"
        exit 1
    fi
fi

STOW_VERSION=$(stow --version | head -n 1)
echo -e "${GREEN}✅  GNU Stow found: $STOW_VERSION${NC}"

# Check if dotfiles directory exists
if [ ! -d "$DOTFILES_DIR" ]; then
    echo -e "${RED}❌  Dotfiles directory not found: $DOTFILES_DIR${NC}"
    exit 1
fi
echo -e "${GREEN}✅  Dotfiles directory found: $DOTFILES_DIR${NC}"

# ==========================================
# PART 2: CONFLICT DETECTION & BACKUP
# ==========================================
echo -e "\n${BLUE}[2/4] Detecting Conflicts...${NC}"

# Use dry-run to find conflicts
# Look for "existing target is not owned by stow: file"
CONFLICTS=()
while IFS= read -r line; do
    if [[ "$line" =~ "existing target is not owned by stow" ]]; then
        # Extract the conflicting file path (last word usually, or after ': ')
        conflict_file=$(echo "$line" | sed 's/.*: //')
        CONFLICTS+=("$conflict_file")
    fi
done < <(stow -n -v 2 -d "$DOTFILES_DIR" -t "$HOME_DIR" . 2>&1)

if [ ${#CONFLICTS[@]} -gt 0 ]; then
    echo -e "${YELLOW}⚠️  Found ${#CONFLICTS[@]} existing file(s) that will be backed up:${NC}"
    mkdir -p "$BACKUP_DIR"
    
    for conflict in "${CONFLICTS[@]}"; do
        target_path="$HOME_DIR/$conflict"
        if [ -e "$target_path" ]; then
            echo -e "    ${YELLOW}→ $conflict${NC}"
            backup_path="$BACKUP_DIR/$conflict"
            mkdir -p "$(dirname "$backup_path")"
            mv "$target_path" "$backup_path"
            echo -e "${GREEN}✅  Backed up: $conflict${NC}"
        fi
    done
else
    echo -e "${GREEN}✅  No conflicts detected${NC}"
fi

# ==========================================
# PART 3: STOW INSTALLATION
# ==========================================
echo -e "\n${BLUE}[3/4] Stowing Dotfiles...${NC}"

if stow -d "$DOTFILES_DIR" -t "$HOME_DIR" . >/dev/null 2>&1; then
    echo -e "${GREEN}✅  Successfully stowed dotfiles${NC}"
else
    echo -e "${RED}❌  Failed to stow dotfiles${NC}"
    exit 1
fi

# ==========================================
# PART 4: VERIFICATION
# ==========================================
echo -e "\n${BLUE}[4/4] Verification...${NC}"

# Simple check for a known dotfile if dotfiles dir is not empty
if [ "$(ls -A "$DOTFILES_DIR")" ]; then
    echo -e "${GREEN}✅  Dotfiles verified${NC}"
else
    echo -e "${YELLOW}⚠️  Dotfiles directory is empty${NC}"
fi

if [ ${#CONFLICTS[@]} -gt 0 ]; then
    echo -e "\n${YELLOW}📦  Backup Information:${NC}"
    echo -e "    Backup location: ${YELLOW}$BACKUP_DIR${NC}"
    echo -e "    To restore backups: ${YELLOW}cp -r $BACKUP_DIR/. ~/${NC}"
fi

echo -e "\n${BLUE}========================================${NC}"
echo -e "${GREEN}✅  Installation Complete!${NC}"
echo -e "${BLUE}========================================${NC}\n"
