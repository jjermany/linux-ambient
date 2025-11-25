#!/bin/bash
# Quick installation script for Ambient Brightness Control
# Can be run directly from the web:
# curl -fsSL https://raw.githubusercontent.com/jjermany/linux-ambient/main/quick-install.sh | sudo bash

set -e

REPO_URL="https://github.com/jjermany/linux-ambient"
BRANCH="main"
TMP_DIR="/tmp/ambient-brightness-install"

echo "========================================="
echo "Ambient Brightness Control - Quick Install"
echo "========================================="
echo ""

# Check for root
if [ "$EUID" -ne 0 ]; then
    echo "Error: This script must be run as root (use sudo)"
    exit 1
fi

# Check for required commands
for cmd in git; do
    if ! command -v $cmd &> /dev/null; then
        echo "Installing git..."
        apt-get install -y git 2>/dev/null || \
        dnf install -y git 2>/dev/null || \
        pacman -S --noconfirm git 2>/dev/null || {
            echo "Error: Could not install git. Please install it manually."
            exit 1
        }
    fi
done

# Clean up any previous installation attempts
rm -rf "$TMP_DIR"

# Clone repository
echo "Downloading Ambient Brightness Control..."
git clone --depth 1 --branch "$BRANCH" "$REPO_URL" "$TMP_DIR" || {
    echo "Error: Failed to download repository"
    exit 1
}

# Change to repo directory
cd "$TMP_DIR"

# Run installation
echo ""
echo "Running installation..."
if [ -f "Makefile" ]; then
    make install
else
    ./install.sh
fi

# Clean up
cd /
rm -rf "$TMP_DIR"

echo ""
echo "========================================="
echo "Quick installation complete!"
echo "========================================="
echo ""
echo "Next steps:"
echo "  1. Open 'Ambient Brightness Settings' from your application menu"
echo "  2. Or run: ambient-brightness-gui"
echo "  3. Start the service and configure to your liking"
echo ""
