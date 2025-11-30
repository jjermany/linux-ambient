#!/bin/bash
# Installation script for Ambient Brightness Control

set -e

echo "Installing Ambient Brightness Control..."

# Install Python dependencies
echo "Installing Python dependencies..."
pip3 install --user opencv-python numpy 2>/dev/null || echo "Note: OpenCV installation may require system packages. Install python3-opencv via your package manager if needed."

# Install GTK dependencies for GUI (requires root)
echo "Checking GUI dependencies..."
echo "If GTK3 dependencies are missing, please install them:"
echo "  Ubuntu/Debian: sudo apt-get install python3-gi gir1.2-gtk-3.0 gir1.2-appindicator3-0.1"
echo "  Fedora: sudo dnf install python3-gobject gtk3 libappindicator-gtk3"
echo "  Arch: sudo pacman -S python-gobject gtk3 libappindicator-gtk3"

# Create user directories
echo "Setting up user directories..."
mkdir -p ~/.local/bin
mkdir -p ~/.config/ambient-brightness
mkdir -p ~/.config/systemd/user
mkdir -p ~/.local/share/applications
mkdir -p ~/.config/autostart

# Copy main script
echo "Installing main script..."
cp ambient_brightness.py ~/.local/bin/
chmod +x ~/.local/bin/ambient_brightness.py

# Copy GUI script
echo "Installing GUI application..."
cp ambient_brightness_gui.py ~/.local/bin/ambient-brightness-gui
chmod +x ~/.local/bin/ambient-brightness-gui

# Create default config if it doesn't exist
if [ ! -f ~/.config/ambient-brightness/config.conf ]; then
    if [ -f config.conf.example ]; then
        cp config.conf.example ~/.config/ambient-brightness/config.conf
        echo "Created default configuration at ~/.config/ambient-brightness/config.conf"
    else
        cat > ~/.config/ambient-brightness/config.conf << 'EOF'
# Ambient Brightness Control Configuration

# Enable camera as fallback sensor (true/false)
enable_camera=true

# Smoothing factor for brightness changes (0.1-1.0)
# Higher = faster response, Lower = smoother transitions
smoothing_factor=0.3

# Update interval in seconds (0.5-5.0)
update_interval=2.0

# Brightness limits (percentage)
min_brightness=10
max_brightness=100
EOF
        echo "Created default configuration at ~/.config/ambient-brightness/config.conf"
    fi
else
    echo "Configuration file already exists, skipping..."
fi

# Install systemd user service (if available)
echo "Installing systemd user service..."
if command -v systemctl >/dev/null 2>&1 && systemctl --user is-system-running >/dev/null 2>&1; then
    if [ -f ambient-brightness.service ]; then
        cp ambient-brightness.service ~/.config/systemd/user/
        systemctl --user daemon-reload
        # Verify installation
        if [ -f ~/.config/systemd/user/ambient-brightness.service ]; then
            echo "✅ systemd user service installed successfully"
        else
            echo "❌ Failed to install service file to ~/.config/systemd/user/"
            echo "  Run ./fix-service-installation.sh to fix this issue"
        fi
    else
        echo "❌ Service file not found in repository"
        echo "  Run ./fix-service-installation.sh to create and install it"
    fi
else
    echo "⚠ systemd not available - service will run in standalone mode"
    echo "  Use the GUI application to start/stop the service"
fi

# Install desktop entries
echo "Installing desktop entries..."
cp ambient-brightness-settings.desktop ~/.local/share/applications/
cp ambient-brightness-tray.desktop ~/.config/autostart/
update-desktop-database ~/.local/share/applications/ 2>/dev/null || true

# Setup udev rules for brightness control without sudo (requires root)
echo ""
echo "Setting up udev rules (requires sudo)..."
if [ "$EUID" -eq 0 ]; then
    if [ -d /etc/udev/rules.d ]; then
        cat > /etc/udev/rules.d/90-backlight.rules << 'EOF'
# Allow users in video group to control backlight
ACTION=="add", SUBSYSTEM=="backlight", KERNEL=="*", RUN+="/bin/chgrp video /sys/class/backlight/%k/brightness"
ACTION=="add", SUBSYSTEM=="backlight", KERNEL=="*", RUN+="/bin/chmod g+w /sys/class/backlight/%k/brightness"
EOF
        # Reload udev rules
        if command -v udevadm >/dev/null 2>&1; then
            udevadm control --reload-rules
            udevadm trigger --subsystem-match=backlight
        fi
        echo "udev rules installed successfully!"
    else
        echo "⚠ /etc/udev/rules.d not found - skipping udev rules"
    fi
else
    echo "Run the following commands with sudo to set up backlight permissions:"
    echo ""
    echo "sudo bash -c 'cat > /etc/udev/rules.d/90-backlight.rules << \"EOF\""
    echo "# Allow users in video group to control backlight"
    echo "ACTION==\"add\", SUBSYSTEM==\"backlight\", KERNEL==\"*\", RUN+=\"/bin/chgrp video /sys/class/backlight/%k/brightness\""
    echo "ACTION==\"add\", SUBSYSTEM==\"backlight\", KERNEL==\"*\", RUN+=\"/bin/chmod g+w /sys/class/backlight/%k/brightness\""
    echo "EOF"
    echo "'"
    echo ""
    echo "sudo udevadm control --reload-rules"
    echo "sudo udevadm trigger --subsystem-match=backlight"
    echo ""
    echo "Then add yourself to the video group:"
    echo "sudo usermod -aG video \$USER"
    echo "(logout and login for group changes to take effect)"
fi

# Ensure user is in video group
if ! groups | grep -q video; then
    echo ""
    echo "Adding current user to video group (requires sudo)..."
    if [ "$EUID" -eq 0 ]; then
        usermod -aG video "$SUDO_USER"
        echo "Added to video group. Please logout and login for changes to take effect."
    else
        echo "Run: sudo usermod -aG video \$USER"
        echo "Then logout and login for group changes to take effect."
    fi
fi

# Ensure ~/.local/bin is in PATH
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    echo ""
    echo "⚠ WARNING: ~/.local/bin is not in your PATH"
    echo "Add this line to your ~/.bashrc or ~/.profile:"
    echo "  export PATH=\"\$HOME/.local/bin:\$PATH\""
    echo ""
fi

echo ""
echo "Installation complete!"
echo ""
echo "✅ NO PASSWORD PROMPTS NEEDED for normal operation!"
echo ""
echo "GUI Application (RECOMMENDED):"
echo "  - Open 'Ambient Brightness Settings' from your application menu"
echo "  - Or run: ambient-brightness-gui"
echo "  - Use the GUI to start/stop the service and adjust settings"
echo "  - System tray indicator will start automatically on next login"
echo ""

if command -v systemctl >/dev/null 2>&1 && systemctl --user is-system-running >/dev/null 2>&1; then
    echo "Command Line (systemd mode):"
    echo "  To start the service:"
    echo "    systemctl --user start ambient-brightness"
    echo "  To enable at boot:"
    echo "    systemctl --user enable ambient-brightness"
    echo "  To check status:"
    echo "    systemctl --user status ambient-brightness"
    echo "  To view logs:"
    echo "    journalctl --user -u ambient-brightness -f"
else
    echo "Command Line (standalone mode):"
    echo "  To start the service manually:"
    echo "    ~/.local/bin/ambient_brightness.py &"
    echo "  Note: Use the GUI application for easier service management"
fi

echo ""
echo "Configuration: ~/.config/ambient-brightness/config.conf (or use GUI)"
echo ""
