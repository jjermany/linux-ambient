#!/bin/bash
# Complete Uninstaller for Ambient Brightness Control
# This script removes EVERYTHING from ALL possible installation locations

set -e

echo "========================================="
echo "COMPLETE UNINSTALL"
echo "Ambient Brightness Control"
echo "========================================="
echo ""
echo "This will remove ALL instances of Ambient Brightness from:"
echo "  - User directories (~/.local/, ~/.config/)"
echo "  - System directories (/usr/local/, /usr/, /etc/)"
echo "  - All running processes"
echo ""
read -p "Continue? [y/N] " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 0
fi
echo ""

# Track what we need sudo for
NEED_SUDO=false

# Check if we need sudo for system files
if [ -f /usr/local/bin/ambient_brightness.py ] || \
   [ -f /usr/local/bin/ambient-brightness-gui ] || \
   [ -f /usr/bin/ambient_brightness.py ] || \
   [ -f /usr/bin/ambient-brightness-gui ] || \
   [ -f /etc/systemd/system/ambient-brightness.service ] || \
   [ -f /lib/systemd/system/ambient-brightness.service ] || \
   [ -f /usr/share/applications/ambient-brightness-settings.desktop ] || \
   [ -f /etc/xdg/autostart/ambient-brightness-tray.desktop ] || \
   [ -f /etc/udev/rules.d/90-backlight.rules ] || \
   [ -d /etc/ambient-brightness ]; then
    NEED_SUDO=true
fi

# Function to run command with or without sudo
run_cmd() {
    if [ "$EUID" -eq 0 ]; then
        "$@"
    else
        if $NEED_SUDO; then
            sudo "$@"
        else
            "$@"
        fi
    fi
}

echo "Step 1: Stopping all running instances..."
echo "----------------------------------------"

# Kill any running processes
pkill -f ambient_brightness.py 2>/dev/null && echo "✓ Killed ambient_brightness.py processes" || echo "  No ambient_brightness.py processes running"
pkill -f ambient-brightness-gui 2>/dev/null && echo "✓ Killed ambient-brightness-gui processes" || echo "  No ambient-brightness-gui processes running"

# Stop systemd services (both user and system)
if command -v systemctl >/dev/null 2>&1; then
    # User service
    if systemctl --user is-active --quiet ambient-brightness 2>/dev/null; then
        systemctl --user stop ambient-brightness 2>/dev/null && echo "✓ Stopped user service"
    fi
    if systemctl --user is-enabled --quiet ambient-brightness 2>/dev/null; then
        systemctl --user disable ambient-brightness 2>/dev/null && echo "✓ Disabled user service"
    fi

    # System service
    if systemctl is-active --quiet ambient-brightness 2>/dev/null; then
        run_cmd systemctl stop ambient-brightness 2>/dev/null && echo "✓ Stopped system service"
    fi
    if systemctl is-enabled --quiet ambient-brightness 2>/dev/null; then
        run_cmd systemctl disable ambient-brightness 2>/dev/null && echo "✓ Disabled system service"
    fi
fi

echo ""
echo "Step 2: Removing executables..."
echo "----------------------------------------"

# Remove from user directories
if [ -f ~/.local/bin/ambient_brightness.py ]; then
    rm -f ~/.local/bin/ambient_brightness.py && echo "✓ Removed ~/.local/bin/ambient_brightness.py"
fi
if [ -f ~/.local/bin/ambient-brightness-gui ]; then
    rm -f ~/.local/bin/ambient-brightness-gui && echo "✓ Removed ~/.local/bin/ambient-brightness-gui"
fi

# Remove from system directories
for path in /usr/local/bin/ambient_brightness.py \
            /usr/local/bin/ambient-brightness-gui \
            /usr/bin/ambient_brightness.py \
            /usr/bin/ambient-brightness-gui; do
    if [ -f "$path" ]; then
        run_cmd rm -f "$path" && echo "✓ Removed $path"
    fi
done

echo ""
echo "Step 3: Removing systemd services..."
echo "----------------------------------------"

# Remove user service
if [ -f ~/.config/systemd/user/ambient-brightness.service ]; then
    rm -f ~/.config/systemd/user/ambient-brightness.service && echo "✓ Removed user systemd service"
    systemctl --user daemon-reload 2>/dev/null
fi

# Remove system services
for path in /etc/systemd/system/ambient-brightness.service \
            /lib/systemd/system/ambient-brightness.service; do
    if [ -f "$path" ]; then
        run_cmd rm -f "$path" && echo "✓ Removed $path"
        run_cmd systemctl daemon-reload 2>/dev/null || true
    fi
done

echo ""
echo "Step 4: Removing desktop files..."
echo "----------------------------------------"

# Remove user desktop files
if [ -f ~/.local/share/applications/ambient-brightness-settings.desktop ]; then
    rm -f ~/.local/share/applications/ambient-brightness-settings.desktop && echo "✓ Removed user desktop entry"
    update-desktop-database ~/.local/share/applications/ 2>/dev/null || true
fi

if [ -f ~/.config/autostart/ambient-brightness-tray.desktop ]; then
    rm -f ~/.config/autostart/ambient-brightness-tray.desktop && echo "✓ Removed user autostart entry"
fi

# Remove system desktop files
for path in /usr/share/applications/ambient-brightness-settings.desktop \
            /etc/xdg/autostart/ambient-brightness-tray.desktop; do
    if [ -f "$path" ]; then
        run_cmd rm -f "$path" && echo "✓ Removed $path"
    fi
done

if [ -f /usr/share/applications/ambient-brightness-settings.desktop ]; then
    run_cmd update-desktop-database /usr/share/applications/ 2>/dev/null || true
fi

echo ""
echo "Step 5: Removing udev rules..."
echo "----------------------------------------"

if [ -f /etc/udev/rules.d/90-backlight.rules ]; then
    run_cmd rm -f /etc/udev/rules.d/90-backlight.rules && echo "✓ Removed udev rules"
    run_cmd udevadm control --reload-rules 2>/dev/null || true
else
    echo "  No udev rules found"
fi

echo ""
echo "Step 6: Configuration files..."
echo "----------------------------------------"

# Always show user config status
if [ -d ~/.config/ambient-brightness ]; then
    echo "User configuration found at ~/.config/ambient-brightness/"
    read -p "Remove user configuration? [y/N] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf ~/.config/ambient-brightness && echo "✓ Removed user configuration"
    else
        echo "  Kept user configuration"
    fi
else
    echo "  No user configuration found"
fi

# Remove system config if exists
if [ -d /etc/ambient-brightness ]; then
    run_cmd rm -rf /etc/ambient-brightness && echo "✓ Removed system configuration"
fi

echo ""
echo "========================================="
echo "COMPLETE UNINSTALL FINISHED"
echo "========================================="
echo ""
echo "All instances of Ambient Brightness have been removed."
echo ""

# Check if anything remains
REMAINS=false
for path in ~/.local/bin/ambient*.py \
            ~/.local/bin/ambient-brightness-gui \
            ~/.config/systemd/user/ambient-brightness.service \
            ~/.local/share/applications/ambient-brightness*.desktop \
            ~/.config/autostart/ambient-brightness*.desktop \
            /usr/local/bin/ambient*.py \
            /usr/local/bin/ambient-brightness-gui \
            /usr/bin/ambient*.py \
            /usr/bin/ambient-brightness-gui \
            /etc/systemd/system/ambient-brightness.service \
            /lib/systemd/system/ambient-brightness.service \
            /usr/share/applications/ambient-brightness*.desktop \
            /etc/xdg/autostart/ambient-brightness*.desktop \
            /etc/udev/rules.d/90-backlight.rules; do
    if [ -f "$path" ] || [ -L "$path" ]; then
        if ! $REMAINS; then
            echo "⚠ Warning: Some files may remain:"
            REMAINS=true
        fi
        echo "  $path"
    fi
done

if ! $REMAINS; then
    echo "✓ All files successfully removed!"
fi

echo ""
