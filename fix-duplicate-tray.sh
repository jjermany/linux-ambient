#!/bin/bash
# Fix duplicate system tray icons for Ambient Brightness

echo "========================================="
echo "Ambient Brightness - Fix Duplicate Tray Icons"
echo "========================================="
echo ""

# Kill any running tray instances
echo "Stopping any running tray instances..."
pkill -f "ambient-brightness-gui --tray" 2>/dev/null || true
sleep 1

# Check for system-wide autostart file
FOUND_SYSTEM_AUTOSTART=false
if [ -f /etc/xdg/autostart/ambient-brightness-tray.desktop ]; then
    FOUND_SYSTEM_AUTOSTART=true
    echo "✓ Found system-wide autostart file: /etc/xdg/autostart/ambient-brightness-tray.desktop"
fi

# Check for user autostart file
FOUND_USER_AUTOSTART=false
if [ -f ~/.config/autostart/ambient-brightness-tray.desktop ]; then
    FOUND_USER_AUTOSTART=true
    echo "✓ Found user-level autostart file: ~/.config/autostart/ambient-brightness-tray.desktop"
fi

# Check for duplicate in applications directory (shouldn't be there)
FOUND_IN_APPS=false
if [ -f ~/.local/share/applications/ambient-brightness-tray.desktop ]; then
    FOUND_IN_APPS=true
    echo "✓ Found tray file in applications directory (incorrect location)"
fi

echo ""

# If both system and user files exist, we have a conflict
if $FOUND_SYSTEM_AUTOSTART && $FOUND_USER_AUTOSTART; then
    echo "❌ DUPLICATE DETECTED: Both system-wide and user-level autostart files exist!"
    echo ""
    echo "This will cause two tray icons to appear."
    echo ""
    echo "Recommended solution: Remove the system-wide file and use user-level only."
    echo ""

    if [ "$EUID" -eq 0 ]; then
        read -p "Remove system-wide autostart file? [Y/n] " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Nn]$ ]]; then
            rm -f /etc/xdg/autostart/ambient-brightness-tray.desktop
            echo "✓ Removed system-wide autostart file"
        fi
    else
        echo "To remove the system-wide file, run:"
        echo "  sudo rm /etc/xdg/autostart/ambient-brightness-tray.desktop"
        echo ""
        echo "Or run this script with sudo:"
        echo "  sudo $0"
    fi
elif $FOUND_SYSTEM_AUTOSTART; then
    echo "ℹ Only system-wide autostart file found (this is okay, but user-level is recommended)"
elif $FOUND_USER_AUTOSTART; then
    echo "✓ Only user-level autostart file found (correct configuration)"
else
    echo "⚠️  No autostart files found. Installation may be incomplete."
    echo "  Run: ./install.sh"
fi

# Remove tray file from applications if it's there
if $FOUND_IN_APPS; then
    echo ""
    echo "Removing tray file from incorrect location..."
    rm -f ~/.local/share/applications/ambient-brightness-tray.desktop
    echo "✓ Removed tray file from applications directory"
fi

echo ""
echo "========================================="
echo "Fix Complete"
echo "========================================="
echo ""

# Restart the tray if we have an autostart file
if $FOUND_USER_AUTOSTART || $FOUND_SYSTEM_AUTOSTART; then
    echo "Starting tray indicator..."
    nohup ambient-brightness-gui --tray >/dev/null 2>&1 &
    sleep 1

    # Check if it started successfully
    if pgrep -f "ambient-brightness-gui --tray" > /dev/null; then
        echo "✓ Tray indicator started successfully"
    else
        echo "⚠️  Could not start tray indicator. Check installation."
    fi
fi

echo ""
