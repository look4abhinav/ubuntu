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
if command -v stow &> /dev/null; then
    STOW_VERSION=$(stow --version | head -n 1)
    echo -e "${GREEN}✅  GNU Stow found: $STOW_VERSION${NC}"
else
    echo -e "${YELLOW}⚠️  GNU Stow not found. Installing...${NC}"
    if sudo apt update && sudo apt install stow -y; then
        STOW_VERSION=$(stow --version | head -n 1)
        echo -e "${GREEN}✅  GNU Stow installed: $STOW_VERSION${NC}"
    else
        echo -e "${RED}❌  Failed to install GNU Stow${NC}"
        exit 1
    fi
fi

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

declare -a CONFLICTS
cd "$DOTFILES_DIR"

for package in */; do
    package="${package%/}"
    
    # Skip files that start with a dot (hidden files)
    if [[ "$package" == .* ]]; then
        continue
    fi
    
    # Check for conflicts in the package directory
    while IFS= read -r -d '' file; do
        # Get the relative path from the package directory
        rel_path="${file#$DOTFILES_DIR/$package/}"
        
        # The target path in home directory
        target_path="$HOME_DIR/$rel_path"
        
        # Check if file exists and is not a symlink already
        if [ -e "$target_path" ] && [ ! -L "$target_path" ]; then
            CONFLICTS+=("$rel_path")
        fi
    done < <(find "$DOTFILES_DIR/$package" -type f -print0)
done

# Display conflicts and create backup if necessary
if [ ${#CONFLICTS[@]} -gt 0 ]; then
    echo -e "${YELLOW}⚠️  Found ${#CONFLICTS[@]} existing file(s) that will be backed up:${NC}"
    for conflict in "${CONFLICTS[@]}"; do
        echo -e "    ${YELLOW}→ $conflict${NC}"
    done
    
    echo -e "\n${YELLOW}Creating backup directory: $BACKUP_DIR${NC}"
    mkdir -p "$BACKUP_DIR"
    
    # Backup conflicting files
    for conflict in "${CONFLICTS[@]}"; do
        target_path="$HOME_DIR/$conflict"
        if [ -e "$target_path" ]; then
            # Create directory structure in backup
            backup_path="$BACKUP_DIR/$conflict"
            mkdir -p "$(dirname "$backup_path")"
            
            # Backup the existing file
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

# Count symlinks created
SYMLINK_COUNT=$(find "$HOME_DIR" -type l -newer /proc -o -type l 2>/dev/null | wc -l)
echo -e "${GREEN}✅  Dotfiles installation completed${NC}"

if [ ${#CONFLICTS[@]} -gt 0 ]; then
    echo -e "\n${YELLOW}📦  Backup Information:${NC}"
    echo -e "    Backup location: ${YELLOW}$BACKUP_DIR${NC}"
    echo -e "    Backed up files: ${#CONFLICTS[@]}"
    echo -e "    To restore backups: ${YELLOW}mv $BACKUP_DIR/* ~/${NC}"
fi

# ==========================================
# SUMMARY
# ==========================================
echo -e "\n${BLUE}========================================${NC}"
echo -e "${GREEN}✅  Installation Complete!${NC}"
echo -e "${BLUE}========================================${NC}"
echo -e "Dotfiles directory: ${YELLOW}$DOTFILES_DIR${NC}"
echo -e "Target directory:   ${YELLOW}$HOME_DIR${NC}"

if [ ${#CONFLICTS[@]} -gt 0 ]; then
    echo -e "Backup directory:   ${YELLOW}$BACKUP_DIR${NC}"
fi
echo -e "${BLUE}========================================${NC}\n"
