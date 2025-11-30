#!/bin/bash
# Verify Ambient Brightness Control installation
# This script checks if all components are properly installed

set -e

echo "========================================="
echo "Ambient Brightness Installation Checker"
echo "========================================="
echo ""

ERRORS=0
WARNINGS=0

# Check 1: Main executable
echo "Checking main executable..."
if [ -f ~/.local/bin/ambient_brightness.py ]; then
    if [ -x ~/.local/bin/ambient_brightness.py ]; then
        echo "✅ Main script installed and executable"
    else
        echo "❌ Main script found but not executable"
        echo "   Fix: chmod +x ~/.local/bin/ambient_brightness.py"
        ERRORS=$((ERRORS + 1))
    fi
else
    echo "❌ Main script not found at ~/.local/bin/ambient_brightness.py"
    echo "   Fix: Run ./install.sh or ./fix-service-installation.sh"
    ERRORS=$((ERRORS + 1))
fi
echo ""

# Check 2: GUI executable
echo "Checking GUI application..."
if [ -f ~/.local/bin/ambient-brightness-gui ]; then
    if [ -x ~/.local/bin/ambient-brightness-gui ]; then
        echo "✅ GUI application installed and executable"
    else
        echo "⚠️  GUI application found but not executable"
        echo "   Fix: chmod +x ~/.local/bin/ambient-brightness-gui"
        WARNINGS=$((WARNINGS + 1))
    fi
else
    echo "⚠️  GUI application not found"
    echo "   Fix: Run ./install.sh"
    WARNINGS=$((WARNINGS + 1))
fi
echo ""

# Check 3: Configuration
echo "Checking configuration..."
if [ -f ~/.config/ambient-brightness/config.conf ]; then
    echo "✅ Configuration file exists"
else
    echo "⚠️  Configuration file not found"
    echo "   The application will create one with defaults on first run"
    WARNINGS=$((WARNINGS + 1))
fi
echo ""

# Check 4: systemd service
echo "Checking systemd service..."
SYSTEMD_OK=false
if command -v systemctl >/dev/null 2>&1; then
    if systemctl --user list-units >/dev/null 2>&1; then
        SYSTEMD_OK=true

        if [ -f ~/.config/systemd/user/ambient-brightness.service ]; then
            echo "✅ Service file installed"

            # Check if systemd knows about it
            if systemctl --user list-unit-files | grep -q ambient-brightness.service; then
                echo "✅ Service recognized by systemd"

                # Check service status
                if systemctl --user is-active --quiet ambient-brightness; then
                    echo "✅ Service is running"
                elif systemctl --user is-enabled --quiet ambient-brightness; then
                    echo "⚠️  Service is enabled but not running"
                    echo "   Start with: systemctl --user start ambient-brightness"
                    WARNINGS=$((WARNINGS + 1))
                else
                    echo "ℹ️  Service is installed but not enabled"
                    echo "   Enable with: systemctl --user enable ambient-brightness"
                fi
            else
                echo "⚠️  Service file exists but not recognized by systemd"
                echo "   Fix: systemctl --user daemon-reload"
                WARNINGS=$((WARNINGS + 1))
            fi
        else
            echo "❌ Service file not found at ~/.config/systemd/user/ambient-brightness.service"
            echo "   Fix: Run ./install.sh or ./fix-service-installation.sh"
            ERRORS=$((ERRORS + 1))
        fi
    else
        echo "⚠️  systemd user session not responding"
        echo "   The GUI can still run the service in standalone mode"
        WARNINGS=$((WARNINGS + 1))
    fi
else
    echo "ℹ️  systemd not available"
    echo "   The GUI will run the service in standalone mode"
fi
echo ""

# Check 5: Desktop entries
echo "Checking desktop integration..."
if [ -f ~/.local/share/applications/ambient-brightness-settings.desktop ]; then
    echo "✅ Application menu entry installed"
else
    echo "⚠️  Application menu entry not found"
    WARNINGS=$((WARNINGS + 1))
fi

if [ -f ~/.config/autostart/ambient-brightness-tray.desktop ]; then
    echo "✅ Autostart entry installed"
else
    echo "⚠️  Autostart entry not found"
    WARNINGS=$((WARNINGS + 1))
fi
echo ""

# Check 6: PATH
echo "Checking PATH..."
if [[ ":$PATH:" == *":$HOME/.local/bin:"* ]]; then
    echo "✅ ~/.local/bin is in PATH"
else
    echo "⚠️  ~/.local/bin is not in PATH"
    echo "   Add to ~/.bashrc or ~/.profile:"
    echo "   export PATH=\"\$HOME/.local/bin:\$PATH\""
    WARNINGS=$((WARNINGS + 1))
fi
echo ""

# Check 7: Python dependencies
echo "Checking Python dependencies..."
PYTHON_OK=true

if python3 -c "import cv2" 2>/dev/null; then
    echo "✅ OpenCV (cv2) installed"
else
    echo "⚠️  OpenCV not found"
    echo "   Install: pip3 install --user opencv-python"
    echo "   Or: sudo apt-get install python3-opencv"
    WARNINGS=$((WARNINGS + 1))
    PYTHON_OK=false
fi

if python3 -c "import numpy" 2>/dev/null; then
    echo "✅ NumPy installed"
else
    echo "⚠️  NumPy not found"
    echo "   Install: pip3 install --user numpy"
    echo "   Or: sudo apt-get install python3-numpy"
    WARNINGS=$((WARNINGS + 1))
    PYTHON_OK=false
fi

if python3 -c "import gi; gi.require_version('Gtk', '3.0')" 2>/dev/null; then
    echo "✅ GTK3 bindings installed"
else
    echo "⚠️  GTK3 bindings not found (GUI won't work)"
    echo "   Install: sudo apt-get install python3-gi gir1.2-gtk-3.0"
    WARNINGS=$((WARNINGS + 1))
fi
echo ""

# Check 8: Permissions
echo "Checking backlight permissions..."
BACKLIGHT_DEVICES=$(find /sys/class/backlight -maxdepth 1 -mindepth 1 2>/dev/null || true)
if [ -n "$BACKLIGHT_DEVICES" ]; then
    CAN_WRITE=false
    for device in $BACKLIGHT_DEVICES; do
        if [ -w "$device/brightness" ]; then
            CAN_WRITE=true
            echo "✅ Can write to $device/brightness"
            break
        fi
    done

    if [ "$CAN_WRITE" = false ]; then
        echo "⚠️  Cannot write to backlight devices"
        echo "   You may need to:"
        echo "   1. Add yourself to the video group: sudo usermod -aG video \$USER"
        echo "   2. Set up udev rules (see install.sh output)"
        echo "   3. Log out and log back in"
        WARNINGS=$((WARNINGS + 1))
    fi
else
    echo "ℹ️  No backlight devices found"
    echo "   This may be normal for desktop systems"
fi
echo ""

# Summary
echo "========================================="
echo "Summary"
echo "========================================="
echo ""

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo "🎉 Perfect! Everything is installed correctly."
    echo ""
    if [ "$SYSTEMD_OK" = true ]; then
        echo "You can now:"
        echo "  • Start the service: systemctl --user start ambient-brightness"
        echo "  • Enable at boot: systemctl --user enable ambient-brightness"
        echo "  • Use the GUI: ambient-brightness-gui"
    else
        echo "You can now:"
        echo "  • Use the GUI: ambient-brightness-gui"
        echo "  • The GUI will manage the service for you"
    fi
elif [ $ERRORS -eq 0 ]; then
    echo "✅ Installation is functional with $WARNINGS warning(s)."
    echo ""
    echo "The application should work, but you may want to address the warnings above."
else
    echo "❌ Found $ERRORS error(s) and $WARNINGS warning(s)."
    echo ""
    echo "Please fix the errors above before using the application."
    echo ""
    echo "Quick fix: Run ./install.sh or ./fix-service-installation.sh"
fi
echo ""

exit $ERRORS
