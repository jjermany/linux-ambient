#!/bin/bash
# Uninstallation script for Ambient Brightness Control (user-level)

echo "Uninstalling Ambient Brightness Control..."
echo ""

# Stop and disable the user service
echo "Stopping service..."
systemctl --user stop ambient-brightness 2>/dev/null || true
systemctl --user disable ambient-brightness 2>/dev/null || true

# Remove user service file
echo "Removing systemd service..."
rm -f ~/.config/systemd/user/ambient-brightness.service
systemctl --user daemon-reload

# Remove scripts
echo "Removing scripts..."
rm -f ~/.local/bin/ambient_brightness.py
rm -f ~/.local/bin/ambient-brightness-gui

# Remove desktop entries
echo "Removing desktop entries..."
rm -f ~/.local/share/applications/ambient-brightness-settings.desktop
rm -f ~/.config/autostart/ambient-brightness-tray.desktop
update-desktop-database ~/.local/share/applications/ 2>/dev/null || true

# Ask about configuration
echo ""
read -p "Remove configuration files from ~/.config/ambient-brightness? [y/N] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    rm -rf ~/.config/ambient-brightness
    echo "Configuration removed."
else
    echo "Configuration kept at ~/.config/ambient-brightness/"
fi

echo ""
echo "========================================="
echo "Uninstallation complete!"
echo "========================================="
echo ""
echo "Note: System-level udev rules (if installed) were not removed."
echo "To remove them manually (requires sudo):"
echo "  sudo rm -f /etc/udev/rules.d/90-backlight.rules"
echo "  sudo udevadm control --reload-rules"
echo ""
