#!/bin/bash
# Comprehensive uninstallation script for Ambient Brightness Control
# Handles both user-level and system-level installations

echo "========================================="
echo "Ambient Brightness Uninstaller"
echo "========================================="
echo ""

FOUND_USER_INSTALL=false
FOUND_SYSTEM_INSTALL=false

# Check for user-level installation
if [ -f ~/.local/bin/ambient_brightness.py ] || \
   [ -f ~/.config/systemd/user/ambient-brightness.service ] || \
   [ -f ~/.local/share/applications/ambient-brightness-settings.desktop ]; then
    FOUND_USER_INSTALL=true
fi

# Check for system-level installation
if [ -f /usr/local/bin/ambient_brightness.py ] || \
   [ -f /etc/systemd/system/ambient-brightness.service ] || \
   [ -f /usr/share/applications/ambient-brightness-settings.desktop ]; then
    FOUND_SYSTEM_INSTALL=true
fi

if ! $FOUND_USER_INSTALL && ! $FOUND_SYSTEM_INSTALL; then
    echo "No installation found."
    echo ""
    echo "Checked locations:"
    echo "  User: ~/.local/bin, ~/.config/systemd/user, ~/.local/share/applications"
    echo "  System: /usr/local/bin, /etc/systemd/system, /usr/share/applications"
    echo ""
    exit 0
fi

echo "Found installations:"
if $FOUND_USER_INSTALL; then
    echo "  ✓ User-level installation"
fi
if $FOUND_SYSTEM_INSTALL; then
    echo "  ✓ System-level installation (requires sudo to remove)"
fi
echo ""

# Uninstall user-level installation
if $FOUND_USER_INSTALL; then
    echo "Removing user-level installation..."
    echo ""

    # Stop and disable the user service
    if systemctl --user is-active --quiet ambient-brightness 2>/dev/null; then
        echo "Stopping user service..."
        systemctl --user stop ambient-brightness 2>/dev/null || true
    fi

    if systemctl --user is-enabled --quiet ambient-brightness 2>/dev/null; then
        echo "Disabling user service..."
        systemctl --user disable ambient-brightness 2>/dev/null || true
    fi

    # Remove user service file
    if [ -f ~/.config/systemd/user/ambient-brightness.service ]; then
        echo "Removing systemd service file..."
        rm -f ~/.config/systemd/user/ambient-brightness.service
        systemctl --user daemon-reload 2>/dev/null || true
    fi

    # Remove scripts
    if [ -f ~/.local/bin/ambient_brightness.py ] || [ -f ~/.local/bin/ambient-brightness-gui ]; then
        echo "Removing scripts..."
        rm -f ~/.local/bin/ambient_brightness.py
        rm -f ~/.local/bin/ambient-brightness-gui
    fi

    # Remove desktop entries
    if [ -f ~/.local/share/applications/ambient-brightness-settings.desktop ] || \
       [ -f ~/.config/autostart/ambient-brightness-tray.desktop ]; then
        echo "Removing desktop entries..."
        rm -f ~/.local/share/applications/ambient-brightness-settings.desktop
        rm -f ~/.config/autostart/ambient-brightness-tray.desktop
        update-desktop-database ~/.local/share/applications/ 2>/dev/null || true
    fi

    echo "✓ User-level installation removed"
    echo ""
fi

# Uninstall system-level installation
if $FOUND_SYSTEM_INSTALL; then
    if [ "$EUID" -ne 0 ]; then
        echo "System-level installation detected but not running as root."
        echo "To remove system-level installation, run:"
        echo "  sudo $0"
        echo ""
        echo "Or use:"
        echo "  sudo make uninstall"
        echo ""
    else
        echo "Removing system-level installation..."
        echo ""

        # Stop and disable the system service
        if systemctl is-active --quiet ambient-brightness 2>/dev/null; then
            echo "Stopping system service..."
            systemctl stop ambient-brightness 2>/dev/null || true
        fi

        if systemctl is-enabled --quiet ambient-brightness 2>/dev/null; then
            echo "Disabling system service..."
            systemctl disable ambient-brightness 2>/dev/null || true
        fi

        # Remove system service file
        if [ -f /etc/systemd/system/ambient-brightness.service ]; then
            echo "Removing systemd service file..."
            rm -f /etc/systemd/system/ambient-brightness.service
            systemctl daemon-reload 2>/dev/null || true
        fi

        # Remove scripts
        if [ -f /usr/local/bin/ambient_brightness.py ] || [ -f /usr/local/bin/ambient-brightness-gui ]; then
            echo "Removing scripts..."
            rm -f /usr/local/bin/ambient_brightness.py
            rm -f /usr/local/bin/ambient-brightness-gui
        fi

        # Remove desktop entries
        if [ -f /usr/share/applications/ambient-brightness-settings.desktop ] || \
           [ -f /etc/xdg/autostart/ambient-brightness-tray.desktop ]; then
            echo "Removing desktop entries..."
            rm -f /usr/share/applications/ambient-brightness-settings.desktop
            rm -f /etc/xdg/autostart/ambient-brightness-tray.desktop
            update-desktop-database /usr/share/applications/ 2>/dev/null || true
        fi

        # Remove udev rules
        if [ -f /etc/udev/rules.d/90-backlight.rules ]; then
            echo "Removing udev rules..."
            rm -f /etc/udev/rules.d/90-backlight.rules
            udevadm control --reload-rules 2>/dev/null || true
        fi

        # Remove system config
        if [ -d /etc/ambient-brightness ]; then
            echo "Removing system configuration..."
            rm -rf /etc/ambient-brightness
        fi

        echo "✓ System-level installation removed"
        echo ""
    fi
fi

# Ask about user configuration
if [ -d ~/.config/ambient-brightness ]; then
    echo ""
    read -p "Remove user configuration files from ~/.config/ambient-brightness? [y/N] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf ~/.config/ambient-brightness
        echo "✓ User configuration removed."
    else
        echo "ℹ User configuration kept at ~/.config/ambient-brightness/"
    fi
fi

echo ""
echo "========================================="
echo "Uninstallation complete!"
echo "========================================="
echo ""

if $FOUND_SYSTEM_INSTALL && [ "$EUID" -ne 0 ]; then
    echo "Note: System-level files require sudo to remove."
    echo "      Run: sudo $0"
    echo ""
fi
