#!/bin/bash
# Standalone Ambient Brightness Removal Script
# Can be run from anywhere - no repository needed!

echo "========================================="
echo "Ambient Brightness Complete Removal"
echo "========================================="
echo ""
echo "This will search for and remove all ambient-brightness installations."
echo ""

FOUND_ANYTHING=false

# Check and remove USER installation
echo "Checking for user-level installation..."
if [ -f ~/.local/bin/ambient_brightness.py ] || \
   [ -f ~/.local/bin/ambient-brightness-gui ] || \
   [ -f ~/.config/systemd/user/ambient-brightness.service ] || \
   [ -f ~/.local/share/applications/ambient-brightness-settings.desktop ] || \
   [ -f ~/.config/autostart/ambient-brightness-tray.desktop ]; then

    FOUND_ANYTHING=true
    echo "✓ Found user-level installation"
    echo ""

    # Stop service
    if systemctl --user is-active --quiet ambient-brightness 2>/dev/null; then
        echo "  Stopping user service..."
        systemctl --user stop ambient-brightness 2>/dev/null || true
    fi

    if systemctl --user is-enabled --quiet ambient-brightness 2>/dev/null; then
        echo "  Disabling user service..."
        systemctl --user disable ambient-brightness 2>/dev/null || true
    fi

    # Remove files
    echo "  Removing user files..."
    rm -f ~/.local/bin/ambient_brightness.py
    rm -f ~/.local/bin/ambient-brightness-gui
    rm -f ~/.config/systemd/user/ambient-brightness.service
    rm -f ~/.local/share/applications/ambient-brightness-settings.desktop
    rm -f ~/.config/autostart/ambient-brightness-tray.desktop

    # Reload systemd
    systemctl --user daemon-reload 2>/dev/null || true

    # Update desktop database
    update-desktop-database ~/.local/share/applications/ 2>/dev/null || true

    echo "  ✓ User-level installation removed"
    echo ""
fi

# Check and remove SYSTEM installation
echo "Checking for system-level installation..."
if [ -f /usr/local/bin/ambient_brightness.py ] || \
   [ -f /usr/local/bin/ambient-brightness-gui ] || \
   [ -f /usr/bin/ambient_brightness.py ] || \
   [ -f /usr/bin/ambient-brightness-gui ] || \
   [ -f /etc/systemd/system/ambient-brightness.service ] || \
   [ -f /usr/share/applications/ambient-brightness-settings.desktop ] || \
   [ -f /etc/xdg/autostart/ambient-brightness-tray.desktop ]; then

    FOUND_ANYTHING=true
    echo "✓ Found system-level installation"

    if [ "$EUID" -ne 0 ]; then
        echo ""
        echo "ERROR: System-level installation requires sudo to remove."
        echo "Please run: sudo $0"
        echo ""
        exit 1
    fi

    echo ""

    # Stop service
    if systemctl is-active --quiet ambient-brightness 2>/dev/null; then
        echo "  Stopping system service..."
        systemctl stop ambient-brightness 2>/dev/null || true
    fi

    if systemctl is-enabled --quiet ambient-brightness 2>/dev/null; then
        echo "  Disabling system service..."
        systemctl disable ambient-brightness 2>/dev/null || true
    fi

    # Remove files
    echo "  Removing system files..."
    rm -f /usr/local/bin/ambient_brightness.py
    rm -f /usr/local/bin/ambient-brightness-gui
    rm -f /usr/bin/ambient_brightness.py
    rm -f /usr/bin/ambient-brightness-gui
    rm -f /etc/systemd/system/ambient-brightness.service
    rm -f /usr/share/applications/ambient-brightness-settings.desktop
    rm -f /etc/xdg/autostart/ambient-brightness-tray.desktop
    rm -f /etc/udev/rules.d/90-backlight.rules
    rm -rf /etc/ambient-brightness

    # Reload systemd
    systemctl daemon-reload 2>/dev/null || true

    # Reload udev
    udevadm control --reload-rules 2>/dev/null || true

    # Update desktop database
    update-desktop-database /usr/share/applications/ 2>/dev/null || true

    echo "  ✓ System-level installation removed"
    echo ""
fi

# Check for Debian package installation
echo "Checking for Debian package installation..."
if dpkg -l | grep -q "^ii.*ambient-brightness" 2>/dev/null; then
    FOUND_ANYTHING=true
    echo "✓ Found Debian package installation"
    echo ""

    if [ "$EUID" -ne 0 ]; then
        echo "ERROR: Debian package requires sudo to remove."
        echo "Please run: sudo apt remove ambient-brightness"
        echo "Or run: sudo $0"
        echo ""
        exit 1
    fi

    echo "  Removing Debian package..."
    apt-get remove -y ambient-brightness
    echo "  ✓ Debian package removed"
    echo ""
fi

# Handle configuration
if [ -d ~/.config/ambient-brightness ]; then
    FOUND_ANYTHING=true
    echo ""
    echo "Configuration directory found: ~/.config/ambient-brightness"
    read -p "Remove configuration files? [y/N] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf ~/.config/ambient-brightness
        echo "✓ Configuration removed"
    else
        echo "ℹ Configuration kept at ~/.config/ambient-brightness/"
    fi
fi

echo ""
echo "========================================="
if [ "$FOUND_ANYTHING" = true ]; then
    echo "Removal complete!"
else
    echo "No ambient-brightness installation found!"
    echo ""
    echo "Checked locations:"
    echo "  • ~/.local/bin/"
    echo "  • ~/.config/systemd/user/"
    echo "  • /usr/local/bin/"
    echo "  • /usr/bin/"
    echo "  • /etc/systemd/system/"
    echo "  • Debian package database"
fi
echo "========================================="
echo ""
