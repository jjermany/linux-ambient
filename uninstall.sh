#!/bin/bash
# Uninstallation script for Ambient Brightness Control

set -e

echo "Uninstalling Ambient Brightness Control..."

# Check for root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root (sudo)"
    exit 1
fi

# Stop and disable service
echo "Stopping service..."
systemctl stop ambient-brightness 2>/dev/null || true
systemctl disable ambient-brightness 2>/dev/null || true

# Remove systemd service
echo "Removing systemd service..."
rm -f /etc/systemd/system/ambient-brightness.service
systemctl daemon-reload

# Remove main script
echo "Removing main script..."
rm -f /usr/local/bin/ambient_brightness.py

# Remove GUI application
echo "Removing GUI application..."
rm -f /usr/local/bin/ambient-brightness-gui

# Remove desktop entries
echo "Removing desktop entries..."
rm -f /usr/share/applications/ambient-brightness-settings.desktop
rm -f /etc/xdg/autostart/ambient-brightness-tray.desktop
update-desktop-database /usr/share/applications/ 2>/dev/null || true

# Remove udev rules
echo "Removing udev rules..."
rm -f /etc/udev/rules.d/90-backlight.rules
udevadm control --reload-rules

# Ask about config
read -p "Remove configuration directory /etc/ambient-brightness? (y/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    rm -rf /etc/ambient-brightness
    echo "Configuration removed."
else
    echo "Configuration kept."
fi

echo ""
echo "Uninstallation complete!"
