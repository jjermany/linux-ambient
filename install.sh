#!/bin/bash
# Installation script for Ambient Brightness Control

set -e

echo "Installing Ambient Brightness Control..."

# Check for root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root (sudo)"
    exit 1
fi

# Install Python dependencies
echo "Installing Python dependencies..."
pip3 install opencv-python numpy 2>/dev/null || echo "Note: OpenCV installation may require system packages. Install python3-opencv via your package manager if needed."

# Copy main script
echo "Installing main script..."
cp ambient_brightness.py /usr/local/bin/
chmod +x /usr/local/bin/ambient_brightness.py

# Create config directory
echo "Setting up configuration..."
mkdir -p /etc/ambient-brightness

# Copy example config if it doesn't exist
if [ ! -f /etc/ambient-brightness/config.conf ]; then
    cp config.conf.example /etc/ambient-brightness/config.conf
    echo "Created default configuration at /etc/ambient-brightness/config.conf"
else
    echo "Configuration file already exists, skipping..."
fi

# Setup udev rules for brightness control without sudo
echo "Setting up udev rules..."
cat > /etc/udev/rules.d/90-backlight.rules << 'EOF'
# Allow users in video group to control backlight
ACTION=="add", SUBSYSTEM=="backlight", KERNEL=="*", RUN+="/bin/chgrp video /sys/class/backlight/%k/brightness"
ACTION=="add", SUBSYSTEM=="backlight", KERNEL=="*", RUN+="/bin/chmod g+w /sys/class/backlight/%k/brightness"
EOF

# Reload udev rules
udevadm control --reload-rules
udevadm trigger --subsystem-match=backlight

# Install systemd service
echo "Installing systemd service..."
cp ambient-brightness.service /etc/systemd/system/
systemctl daemon-reload

echo ""
echo "Installation complete!"
echo ""
echo "To start the service:"
echo "  sudo systemctl start ambient-brightness"
echo ""
echo "To enable at boot:"
echo "  sudo systemctl enable ambient-brightness"
echo ""
echo "To check status:"
echo "  sudo systemctl status ambient-brightness"
echo ""
echo "To view logs:"
echo "  sudo journalctl -u ambient-brightness -f"
echo ""
echo "Configuration file: /etc/ambient-brightness/config.conf"
