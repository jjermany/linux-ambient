#!/bin/bash
# Fix missing systemd service file installation
# This script ensures the ambient-brightness.service file is properly installed

set -e

echo "Ambient Brightness Service Installation Fix"
echo "============================================"
echo ""

# Get the script directory (where the repository is)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVICE_FILE="$SCRIPT_DIR/ambient-brightness.service"
USER_SERVICE_DIR="$HOME/.config/systemd/user"
TARGET_SERVICE_FILE="$USER_SERVICE_DIR/ambient-brightness.service"

# Check if systemd is available
if ! command -v systemctl >/dev/null 2>&1; then
    echo "❌ systemctl command not found"
    echo "   This system doesn't appear to have systemd installed."
    echo "   The service will run in standalone mode via the GUI."
    exit 1
fi

if ! systemctl --user is-system-running >/dev/null 2>&1; then
    echo "❌ systemd user session is not running"
    echo "   The service will run in standalone mode via the GUI."
    exit 1
fi

echo "✅ systemd is available"
echo ""

# Create user systemd directory if it doesn't exist
if [ ! -d "$USER_SERVICE_DIR" ]; then
    echo "Creating systemd user directory: $USER_SERVICE_DIR"
    mkdir -p "$USER_SERVICE_DIR"
fi

# Check if service file exists in repository
if [ ! -f "$SERVICE_FILE" ]; then
    echo "❌ Service file not found in repository: $SERVICE_FILE"
    echo "   Creating service file from template..."

    cat > "$SERVICE_FILE" << 'EOF'
[Unit]
Description=Ambient Brightness Control Service
Documentation=https://github.com/jjermany/linux-ambient

[Service]
Type=simple
ExecStart=%h/.local/bin/ambient_brightness.py
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=default.target
EOF
    echo "✅ Created service file template"
fi

# Copy service file to user systemd directory
echo "Installing service file to: $TARGET_SERVICE_FILE"
cp "$SERVICE_FILE" "$TARGET_SERVICE_FILE"
echo "✅ Service file installed"
echo ""

# Reload systemd daemon
echo "Reloading systemd user daemon..."
systemctl --user daemon-reload
echo "✅ systemd daemon reloaded"
echo ""

# Check if main script is installed
MAIN_SCRIPT="$HOME/.local/bin/ambient_brightness.py"
if [ ! -f "$MAIN_SCRIPT" ]; then
    echo "⚠️  WARNING: Main script not found at: $MAIN_SCRIPT"
    echo "   You may need to run the full installation:"
    echo "   ./install.sh"
    echo ""
else
    echo "✅ Main script found at: $MAIN_SCRIPT"
    echo ""
fi

# Display service status
echo "Checking service status..."
if systemctl --user is-active --quiet ambient-brightness; then
    echo "✅ Service is currently running"
    systemctl --user status ambient-brightness --no-pager || true
elif systemctl --user is-enabled --quiet ambient-brightness; then
    echo "⚠️  Service is enabled but not running"
    echo "   Start it with: systemctl --user start ambient-brightness"
else
    echo "ℹ️  Service is installed but not enabled"
    echo ""
    echo "To start the service:"
    echo "  systemctl --user start ambient-brightness"
    echo ""
    echo "To enable at boot:"
    echo "  systemctl --user enable ambient-brightness"
fi

echo ""
echo "============================================"
echo "Service installation fixed successfully!"
echo ""
echo "Next steps:"
echo "  1. Start the service:"
echo "     systemctl --user start ambient-brightness"
echo ""
echo "  2. Enable at boot (optional):"
echo "     systemctl --user enable ambient-brightness"
echo ""
echo "  3. Check logs:"
echo "     journalctl --user -u ambient-brightness -f"
echo ""
echo "Or use the GUI application:"
echo "  ambient-brightness-gui"
echo ""
