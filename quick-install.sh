#!/bin/bash
# Quick installation script for Ambient Brightness Control
# Can be run directly from the web:
# curl -fsSL https://raw.githubusercontent.com/jjermany/linux-ambient/main/quick-install.sh | bash

set -e

REPO_URL="https://github.com/jjermany/linux-ambient"
BRANCH="main"
TMP_DIR="/tmp/ambient-brightness-install-$$"

echo "========================================="
echo "Ambient Brightness Control - Quick Install"
echo "========================================="
echo ""

# Check for required commands
if ! command -v git &> /dev/null; then
    echo "Error: git is not installed. Please install it first:"
    echo "  Ubuntu/Debian: sudo apt-get install git"
    echo "  Fedora: sudo dnf install git"
    echo "  Arch: sudo pacman -S git"
    exit 1
fi

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
