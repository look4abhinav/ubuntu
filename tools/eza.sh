#!/bin/bash

# ==========================================
# Eza Installation Script
# A modern replacement for ls
# Repository: https://github.com/eza-community/eza
# ==========================================

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Setup variables
GPG_KEY_FILE="/etc/apt/keyrings/gierens.gpg"
REPO_LIST_FILE="/etc/apt/sources.list.d/gierens.list"
GPG_KEY_URL="https://raw.githubusercontent.com/eza-community/eza/main/deb.asc"
REPO_URL="deb [signed-by=$GPG_KEY_FILE] http://deb.gierens.de stable main"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Eza Installation${NC}"
echo -e "${BLUE}========================================${NC}"

# ==========================================
# PART 1: INSTALL PREREQUISITES
# ==========================================
echo -e "\n${BLUE}[1/4] Installing Prerequisites...${NC}"

echo "Updating package lists..."
if sudo apt update > /dev/null 2>&1; then
    echo -e "${GREEN}✅  Package lists updated${NC}"
else
    echo -e "${RED}❌  Failed to update package lists${NC}"
    exit 1
fi

echo "Installing gpg..."
if sudo apt install -y gpg > /dev/null 2>&1; then
    echo -e "${GREEN}✅  GPG installed${NC}"
else
    echo -e "${RED}❌  Failed to install gpg${NC}"
    exit 1
fi

# ==========================================
# PART 2: SETUP GPG KEY & REPOSITORY
# ==========================================
echo -e "\n${BLUE}[2/4] Setting Up Repository...${NC}"

# Create keyrings directory if it doesn't exist
sudo mkdir -p /etc/apt/keyrings
echo "Created keyrings directory"

# Check if GPG key already exists
if [ -f "$GPG_KEY_FILE" ]; then
    echo -e "${YELLOW}⚠️  GPG key already exists at $GPG_KEY_FILE${NC}"
    echo -e "${YELLOW}⚠️  Skipping key download and overwrite${NC}"
else
    echo "Downloading GPG key from eza community..."
    if wget -qO- "$GPG_KEY_URL" | sudo gpg --dearmor -o "$GPG_KEY_FILE"; then
        echo -e "${GREEN}✅  GPG key installed${NC}"
    else
        echo -e "${RED}❌  Failed to download or install GPG key${NC}"
        exit 1
    fi
fi

# Check if repository source already exists
if [ -f "$REPO_LIST_FILE" ]; then
    echo -e "${YELLOW}⚠️  Repository source already exists at $REPO_LIST_FILE${NC}"
    echo -e "${YELLOW}⚠️  Verifying it contains correct configuration...${NC}"
    
    if grep -q "deb.gierens.de" "$REPO_LIST_FILE"; then
        echo -e "${GREEN}✅  Repository configuration is correct${NC}"
    else
        echo -e "${YELLOW}⚠️  Repository configuration appears incorrect, updating...${NC}"
        echo "$REPO_URL" | sudo tee "$REPO_LIST_FILE" > /dev/null
    fi
else
    echo "Adding eza repository source..."
    if echo "$REPO_URL" | sudo tee "$REPO_LIST_FILE" > /dev/null; then
        echo -e "${GREEN}✅  Repository source added${NC}"
    else
        echo -e "${RED}❌  Failed to add repository source${NC}"
        exit 1
    fi
fi

# Set appropriate permissions for repository files
echo "Setting repository file permissions..."
if sudo chmod 644 "$GPG_KEY_FILE" "$REPO_LIST_FILE"; then
    echo -e "${GREEN}✅  Permissions set correctly${NC}"
else
    echo -e "${RED}❌  Failed to set permissions${NC}"
    exit 1
fi

# ==========================================
# PART 3: INSTALL EZA
# ==========================================
echo -e "\n${BLUE}[3/4] Installing Eza...${NC}"

echo "Updating package cache..."
if sudo apt update > /dev/null 2>&1; then
    echo -e "${GREEN}✅  Package cache updated${NC}"
else
    echo -e "${RED}❌  Failed to update package cache${NC}"
    exit 1
fi

echo "Installing eza..."
if sudo apt install -y eza > /dev/null 2>&1; then
    echo -e "${GREEN}✅  Eza installed successfully${NC}"
else
    echo -e "${RED}❌  Failed to install eza${NC}"
    exit 1
fi

# ==========================================
# PART 4: VERIFICATION
# ==========================================
echo -e "\n${BLUE}[4/4] Verification...${NC}"

if command -v eza &> /dev/null; then
    EZA_PATH=$(which eza)
    EZA_VERSION=$(eza --version)
    echo -e "${GREEN}✅  Eza found at: $EZA_PATH${NC}"
    echo -e "${GREEN}✅  $EZA_VERSION${NC}"
else
    echo -e "${RED}❌  Eza not found in PATH${NC}"
    exit 1
fi

# ==========================================
# SUMMARY
# ==========================================
echo -e "\n${BLUE}========================================${NC}"
echo -e "${GREEN}✅  Installation Complete!${NC}"
echo -e "${BLUE}========================================${NC}"
echo -e "Eza version: $(eza --version)"
echo -e "Installation path: $(which eza)"
echo -e "GPG key: $GPG_KEY_FILE"
echo -e "Repository: $REPO_LIST_FILE"
echo -e "${BLUE}========================================${NC}\n"
