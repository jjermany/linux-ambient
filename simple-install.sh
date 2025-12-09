#!/bin/bash
# Simple Installer for Ambient Brightness Control
# User-level installation (no system-wide files)

set -e

echo "========================================="
echo "SIMPLE INSTALL"
echo "Ambient Brightness Control"
echo "========================================="
echo ""
echo "This will install to your home directory:"
echo "  ~/.local/bin/           (executables)"
echo "  ~/.config/              (config & service)"
echo ""
echo "Sudo is only needed for:"
echo "  - Installing GTK3 system packages (python3-gi, etc.)"
echo "  - Setting up backlight permissions (udev rules)"
echo "  - Adding you to the video group"
echo ""

# Check if we're in the right directory
if [ ! -f "ambient_brightness.py" ] || [ ! -f "ambient_brightness_gui.py" ]; then
    echo "ERROR: Please run this script from the linux-ambient directory"
    echo "  cd linux-ambient"
    echo "  ./simple-install.sh"
    exit 1
fi

echo ""
echo "Step 1: Installing system dependencies..."
echo "----------------------------------------"

# Detect package manager and install GTK dependencies
if command -v apt-get >/dev/null 2>&1; then
    echo "Detected Debian/Ubuntu system"
    echo "Installing GTK3 dependencies (requires sudo)..."
    sudo apt-get update
    sudo apt-get install -y python3-gi gir1.2-gtk-3.0 gir1.2-appindicator3-0.1
elif command -v dnf >/dev/null 2>&1; then
    echo "Detected Fedora system"
    echo "Installing GTK3 dependencies (requires sudo)..."
    sudo dnf install -y python3-gobject gtk3 libappindicator-gtk3
elif command -v pacman >/dev/null 2>&1; then
    echo "Detected Arch system"
    echo "Installing GTK3 dependencies (requires sudo)..."
    sudo pacman -S --noconfirm python-gobject gtk3 libappindicator-gtk3
else
    echo "⚠ Could not detect package manager"
    echo "  Please install GTK3 dependencies manually:"
    echo "  - python3-gi / python-gobject"
    echo "  - gtk3"
    echo "  - libappindicator-gtk3 / gir1.2-appindicator3-0.1"
    read -p "Continue anyway? [y/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Install optional Python dependencies (camera support)
echo ""
echo "Installing optional Python dependencies (for camera mode)..."
pip3 install --user opencv-python numpy 2>/dev/null || \
    echo "⚠ Could not install opencv-python and numpy. Camera mode will not work."

echo ""
echo "Step 2: Creating user directories..."
echo "----------------------------------------"

mkdir -p ~/.local/bin
mkdir -p ~/.config/ambient-brightness
mkdir -p ~/.config/systemd/user
mkdir -p ~/.local/share/applications
mkdir -p ~/.config/autostart

echo "✓ Directories created"

echo ""
echo "Step 3: Installing executables..."
echo "----------------------------------------"

cp ambient_brightness.py ~/.local/bin/
chmod +x ~/.local/bin/ambient_brightness.py
echo "✓ Installed ambient_brightness.py"

cp ambient_brightness_gui.py ~/.local/bin/ambient-brightness-gui
chmod +x ~/.local/bin/ambient-brightness-gui
echo "✓ Installed ambient-brightness-gui"

echo ""
echo "Step 4: Installing configuration..."
echo "----------------------------------------"

if [ ! -f ~/.config/ambient-brightness/config.conf ]; then
    if [ -f config.conf.example ]; then
        cp config.conf.example ~/.config/ambient-brightness/config.conf
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
    fi
    echo "✓ Created default configuration"
else
    echo "✓ Configuration already exists (keeping it)"
fi

echo ""
echo "Step 5: Installing systemd user service..."
echo "----------------------------------------"

if command -v systemctl >/dev/null 2>&1 && systemctl --user list-units >/dev/null 2>&1; then
    if [ -f ambient-brightness.service ]; then
        cp ambient-brightness.service ~/.config/systemd/user/
        systemctl --user daemon-reload
        echo "✓ systemd user service installed"
    else
        # Create a simple service file if it doesn't exist
        cat > ~/.config/systemd/user/ambient-brightness.service << 'EOF'
[Unit]
Description=Ambient Brightness Control Service
After=graphical-session.target

[Service]
Type=simple
ExecStart=%h/.local/bin/ambient_brightness.py
Restart=on-failure
RestartSec=5

[Install]
WantedBy=default.target
EOF
        systemctl --user daemon-reload
        echo "✓ Created and installed systemd user service"
    fi
else
    echo "⚠ systemd not available - service will run in standalone mode"
fi

echo ""
echo "Step 6: Installing desktop entries..."
echo "----------------------------------------"

# Create settings desktop entry if it doesn't exist
if [ -f ambient-brightness-settings.desktop ]; then
    cp ambient-brightness-settings.desktop ~/.local/share/applications/
else
    cat > ~/.local/share/applications/ambient-brightness-settings.desktop << 'EOF'
[Desktop Entry]
Name=Ambient Brightness Settings
Comment=Configure automatic screen brightness control
Exec=ambient-brightness-gui
Icon=preferences-desktop-display
Terminal=false
Type=Application
Categories=Settings;GTK;
EOF
fi
echo "✓ Installed settings desktop entry"

# Create tray desktop entry if it doesn't exist
if [ -f ambient-brightness-tray.desktop ]; then
    cp ambient-brightness-tray.desktop ~/.config/autostart/
else
    cat > ~/.config/autostart/ambient-brightness-tray.desktop << 'EOF'
[Desktop Entry]
Type=Application
Name=Ambient Brightness Tray
Comment=System tray indicator for ambient brightness control
Exec=ambient-brightness-gui --tray
Icon=preferences-desktop-display
Terminal=false
Categories=Settings;
X-GNOME-Autostart-enabled=true
EOF
fi
echo "✓ Installed tray autostart entry"

update-desktop-database ~/.local/share/applications/ 2>/dev/null || true

echo ""
echo "Step 7: Setting up backlight permissions..."
echo "----------------------------------------"

echo "This requires sudo to:"
echo "  1. Create udev rules for backlight access"
echo "  2. Add you to the 'video' group"
echo ""

# Setup udev rules
sudo bash -c 'cat > /etc/udev/rules.d/90-backlight.rules << "EOF"
# Allow users in video group to control backlight
ACTION=="add", SUBSYSTEM=="backlight", KERNEL=="*", RUN+="/bin/chgrp video /sys/class/backlight/%k/brightness"
ACTION=="add", SUBSYSTEM=="backlight", KERNEL=="*", RUN+="/bin/chmod g+w /sys/class/backlight/%k/brightness"
EOF'

sudo udevadm control --reload-rules
sudo udevadm trigger --subsystem-match=backlight
echo "✓ Udev rules installed"

# Add user to video group
if ! groups | grep -q video; then
    sudo usermod -aG video "$USER"
    echo "✓ Added to video group"
    echo ""
    echo "⚠ IMPORTANT: You must log out and log back in for group changes to take effect!"
else
    echo "✓ Already in video group"
fi

# Check if ~/.local/bin is in PATH
echo ""
echo "Step 8: Checking PATH..."
echo "----------------------------------------"

if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    echo "⚠ ~/.local/bin is not in your PATH"
    echo ""
    echo "Add this line to your ~/.bashrc or ~/.profile:"
    echo "  export PATH=\"\$HOME/.local/bin:\$PATH\""
    echo ""
    echo "Then run: source ~/.bashrc"
else
    echo "✓ ~/.local/bin is in PATH"
fi

echo ""
echo "========================================="
echo "INSTALLATION COMPLETE!"
echo "========================================="
echo ""
echo "✓ Ambient Brightness Control is now installed!"
echo ""

# Track if we need to log out
NEED_LOGOUT=false
if ! groups | grep -q video; then
    NEED_LOGOUT=true
fi

echo "Quick Start (RIGHT NOW):"
echo "  1. Run: ambient-brightness-gui"
echo "  2. Click 'Start Service' in the GUI"
echo ""
echo "System Tray Icon:"
echo "  • Will auto-start on next login"
if $NEED_LOGOUT; then
    echo "  • To start it now: Log out and back in first (for video group)"
else
    echo "  • To start it now: ambient-brightness-gui --tray &"
fi
echo ""

if command -v systemctl >/dev/null 2>&1 && systemctl --user list-units >/dev/null 2>&1; then
    echo "Or use systemd commands:"
    echo "  systemctl --user start ambient-brightness    (start service)"
    echo "  systemctl --user enable ambient-brightness   (auto-start at login)"
    echo "  systemctl --user status ambient-brightness   (check status)"
    echo ""
fi

if $NEED_LOGOUT; then
    echo "========================================="
    echo "⚠  ACTION REQUIRED"
    echo "========================================="
    echo ""
    echo "You were added to the 'video' group."
    echo ""
    echo "LOG OUT and LOG BACK IN for this to take effect."
    echo "(You do NOT need to restart your PC - just log out)"
    echo ""
    echo "After logging back in:"
    echo "  • The system tray icon will appear automatically"
    echo "  • The service will have permission to control brightness"
    echo ""
fi

echo "Configuration file: ~/.config/ambient-brightness/config.conf"
echo "To uninstall: ./complete-uninstall.sh"
echo ""
