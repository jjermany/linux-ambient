#!/bin/bash
# Comprehensive cleanup script for ambient-brightness
# Removes both user and system-wide installations

echo "=== Ambient Brightness - Complete Cleanup ==="
echo ""

# Function to check and remove
check_remove() {
    if [ -e "$1" ]; then
        echo "Removing: $1"
        rm -f "$1" 2>/dev/null || sudo rm -f "$1" 2>/dev/null
    fi
}

# Stop any running services
echo "Stopping services..."
systemctl --user stop ambient-brightness 2>/dev/null || true
sudo systemctl stop ambient-brightness 2>/dev/null || true

# Disable services
echo "Disabling services..."
systemctl --user disable ambient-brightness 2>/dev/null || true
sudo systemctl disable ambient-brightness 2>/dev/null || true

# Kill any running processes
echo "Stopping any running processes..."
pkill -f ambient_brightness.py 2>/dev/null || true

# Remove system-wide installation (requires sudo)
echo ""
echo "Removing system-wide installation..."
sudo rm -f /usr/local/bin/ambient_brightness.py
sudo rm -f /usr/local/bin/ambient-brightness-gui
sudo rm -f /etc/systemd/system/ambient-brightness.service
sudo rm -f /usr/share/applications/ambient-brightness-settings.desktop
sudo rm -f /etc/xdg/autostart/ambient-brightness-tray.desktop
sudo rm -f /etc/udev/rules.d/90-backlight.rules

# Remove user installation
echo "Removing user installation..."
rm -f ~/.local/bin/ambient_brightness.py
rm -f ~/.local/bin/ambient-brightness-gui
rm -f ~/.config/systemd/user/ambient-brightness.service
rm -f ~/.local/share/applications/ambient-brightness-settings.desktop
rm -f ~/.config/autostart/ambient-brightness-tray.desktop
rm -f ~/.config/autostart/ambient-brightness-service.desktop

# Reload systemd
echo "Reloading systemd..."
systemctl --user daemon-reload 2>/dev/null || true
sudo systemctl daemon-reload 2>/dev/null || true

# Reload udev rules
echo "Reloading udev rules..."
sudo udevadm control --reload-rules 2>/dev/null || true

echo ""
echo "=== Cleanup Complete ==="
echo ""
echo "Configuration files preserved at:"
echo "  - ~/.config/ambient-brightness/"
echo "  - /etc/ambient-brightness/"
echo ""
echo "To remove config files too, run:"
echo "  rm -rf ~/.config/ambient-brightness"
echo "  sudo rm -rf /etc/ambient-brightness"
echo ""
