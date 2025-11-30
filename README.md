# Linux Ambient Brightness Control

Automatic screen brightness adjustment for Linux using ambient light sensors or camera, similar to smartphones.

## Quick Start

```bash
# One-line install
curl -fsSL https://raw.githubusercontent.com/jjermany/linux-ambient/main/quick-install.sh | bash

# Then open the GUI
ambient-brightness-gui
```

That's it! **No password prompts needed** for normal operation. The GUI will guide you through starting and configuring the service.

## Features

- **Graphical User Interface**: Full-featured GTK3 GUI with real-time monitoring and easy configuration
- **System Tray Integration**: Quick access indicator with service control
- **Dual Sensor Support**: Automatically uses ambient light sensor (ALS) if available, falls back to camera
- **Smart Algorithm**: Non-linear brightness mapping optimized for human perception
- **Smooth Transitions**: Prevents jarring brightness changes with exponential smoothing
- **Highly Configurable**: Adjust sensitivity, update rate, and brightness limits via GUI or config file
- **Service Management**: Start/stop/restart service and view logs directly from GUI
- **Lightweight**: Runs as a user systemd service with minimal resource usage
- **No Password Prompts**: User-level installation and operation, no root access needed after setup

## How It Works

1. **Sensor Detection**: On startup, the service detects available light sensors:
   - First checks for ambient light sensors via IIO subsystem (`/sys/bus/iio/devices/`)
   - Falls back to camera-based detection if no ALS is found

2. **Light Measurement**:
   - **ALS Mode**: Reads illuminance in lux and maps logarithmically (0-50000 lux range)
   - **Camera Mode**: Analyzes frame brightness using OpenCV

3. **Brightness Mapping**: Uses non-linear mapping optimized for different lighting conditions:
   - Dark (0-20%): Higher relative brightness for visibility
   - Medium (20-60%): Balanced brightness scaling
   - Bright (60-100%): Maximum brightness for outdoor visibility

4. **Smooth Adjustment**: Applies exponential smoothing to prevent flickering

## Requirements

- Linux kernel with:
  - IIO subsystem (for ALS) or working webcam (for camera mode)
  - Backlight control (`/sys/class/backlight/`)
- Python 3.6+
- One-time sudo access for udev rules setup (backlight permissions)

### Python Dependencies

- `python3-gi` / `PyGObject` (required for GUI)
- `gtk3` / `gir1.2-gtk-3.0` (required for GUI)
- `libappindicator-gtk3` / `gir1.2-appindicator3-0.1` (required for system tray)
- `opencv-python` (optional, only needed for camera mode)
- `numpy` (optional, only needed for camera mode)

## Installation

Choose one of the following installation methods:

### Method 1: Debian Package (Recommended for Linux Mint/Ubuntu/Debian)

**NEW!** Install via .deb package for the easiest installation and uninstallation:

1. **Download the latest .deb package** from the [Releases page](https://github.com/jjermany/linux-ambient/releases)

2. **Install by double-clicking** the .deb file in your file manager, or via command line:
   ```bash
   sudo dpkg -i ambient-brightness_1.0.0_all.deb
   sudo apt-get install -f  # Install dependencies if needed
   ```

3. **Add your user to the video group**:
   ```bash
   sudo usermod -aG video $USER
   # Log out and back in for group changes to take effect
   ```

4. **Open the GUI** from your application menu or run `ambient-brightness-gui`

**Benefits:**
- ✅ Shows up in Linux Mint/Ubuntu Software Manager
- ✅ Easy uninstallation via package manager (right-click → Uninstall)
- ✅ Automatic dependency management
- ✅ Proper integration with system package database

**To build the .deb package yourself:**
```bash
git clone https://github.com/jjermany/linux-ambient.git
cd linux-ambient
./build-deb.sh
```

### Method 2: One-Liner Install

Download and install automatically with a single command:

```bash
curl -fsSL https://raw.githubusercontent.com/jjermany/linux-ambient/main/quick-install.sh | bash
```

Or with wget:

```bash
wget -qO- https://raw.githubusercontent.com/jjermany/linux-ambient/main/quick-install.sh | bash
```

**Requires sudo.** The installer will:
- Clone the repository
- Install system dependencies
- Install scripts to system directories
- Set up systemd service
- Install the GUI application
- Configure udev rules for backlight permissions
- Clean up temporary files

### Method 3: Using Makefile (Recommended for Developers)

After cloning/downloading the repository:

```bash
git clone https://github.com/jjermany/linux-ambient.git
cd linux-ambient
sudo make install
```

This will:
- Install system dependencies
- Copy scripts to `/usr/local/bin/`
- Set up system configuration
- Install systemd service
- Add GUI desktop entries
- Set up udev rules for backlight permissions

### Method 4: Manual Installation

For complete control over the installation process:

1. **Install system dependencies** (one-time, requires sudo):
```bash
# Debian/Ubuntu
sudo apt install python3-gi gir1.2-gtk-3.0 gir1.2-appindicator3-0.1

# Fedora
sudo dnf install python3-gobject gtk3 libappindicator-gtk3

# Arch Linux
sudo pacman -S python-gobject gtk3 libappindicator-gtk3
```

2. **Install Python dependencies** (no sudo needed):
```bash
pip3 install --user opencv-python numpy
```

3. **Copy scripts to user directory**:
```bash
mkdir -p ~/.local/bin
cp ambient_brightness.py ~/.local/bin/
cp ambient_brightness_gui.py ~/.local/bin/ambient-brightness-gui
chmod +x ~/.local/bin/ambient_brightness.py
chmod +x ~/.local/bin/ambient-brightness-gui
```

4. **Create user configuration**:
```bash
mkdir -p ~/.config/ambient-brightness
cp config.conf.example ~/.config/ambient-brightness/config.conf
```

5. **Set up udev rules** (one-time, requires sudo):
```bash
sudo tee /etc/udev/rules.d/90-backlight.rules << 'EOF'
ACTION=="add", SUBSYSTEM=="backlight", KERNEL=="*", RUN+="/bin/chgrp video /sys/class/backlight/%k/brightness"
ACTION=="add", SUBSYSTEM=="backlight", KERNEL=="*", RUN+="/bin/chmod g+w /sys/class/backlight/%k/brightness"
EOF

sudo udevadm control --reload-rules
sudo udevadm trigger --subsystem-match=backlight
sudo usermod -aG video $USER  # Add yourself to video group
# Log out and back in for group changes to take effect
```

6. **Install user systemd service**:
```bash
mkdir -p ~/.config/systemd/user
cp ambient-brightness.service ~/.config/systemd/user/
systemctl --user daemon-reload
```

7. **Install desktop entries**:
```bash
mkdir -p ~/.local/share/applications ~/.config/autostart
cp ambient-brightness-settings.desktop ~/.local/share/applications/
cp ambient-brightness-tray.desktop ~/.config/autostart/
update-desktop-database ~/.local/share/applications/ 2>/dev/null || true
```

### Verifying Installation

After installation, verify everything is set up correctly:

```bash
./verify-installation.sh
```

This will check:
- ✅ Main executable installed and executable
- ✅ GUI application installed
- ✅ Configuration file exists
- ✅ systemd service properly configured
- ✅ Desktop entries installed
- ✅ Python dependencies available
- ✅ Backlight permissions configured

**If verification fails**, the script will provide specific commands to fix each issue.

### Troubleshooting Installation

If you encounter issues:

1. **Service fails to start (exit code 203)**:
   ```bash
   # Run the fix script
   ./fix-service-installation.sh
   ```
   This automatically installs missing components and verifies the installation.

2. **"systemd user session not running"**:
   - This is usually fine - the GUI will run the service in standalone mode
   - The service will still work, just managed differently

3. **Permission errors**:
   ```bash
   # Add yourself to the video group
   sudo usermod -aG video $USER
   # Log out and log back in for changes to take effect
   ```

4. **For detailed troubleshooting**, see [TROUBLESHOOTING.md](TROUBLESHOOTING.md)

## Usage

### GUI Application (Recommended)

After installation, you can manage the service using the graphical interface:

#### Opening the Settings GUI

1. **From Application Menu**: Search for "Ambient Brightness Settings" in your application launcher
2. **From Command Line**: Run `ambient-brightness-gui`
3. **System Tray**: Click the brightness indicator icon in your system tray (auto-starts on login)

#### GUI Features

**Status Tab**:
- View service status (running/stopped, enabled/disabled)
- Real-time sensor readings with progress bars
- Current ambient light level and screen brightness
- Hardware information (backlight device)

**Settings Tab**:
- Enable/disable camera fallback sensor
- Adjust smoothing factor (how fast brightness changes)
- Set update interval (how often to check sensor)
- Configure minimum and maximum brightness limits
- All settings adjustable via intuitive sliders

**Service Tab**:
- Start/stop/restart the service with one click
- Enable/disable automatic startup at boot
- View recent service logs
- Refresh logs in real-time

#### System Tray Indicator

The system tray indicator provides quick access:
- Shows current service status
- Quick start/stop service
- Open settings window
- Automatically starts on login

To manually start the tray indicator:
```bash
ambient-brightness-gui --tray
```

To disable auto-start:
```bash
rm ~/.config/autostart/ambient-brightness-tray.desktop
```

### Command Line Usage

#### With systemd (Default)

If systemd is available, you can manage the service via command line (**no sudo needed!**):

```bash
# Start the service
systemctl --user start ambient-brightness

# Enable at boot
systemctl --user enable ambient-brightness

# Check status
systemctl --user status ambient-brightness

# View logs
journalctl --user -u ambient-brightness -f

# Stop the service
systemctl --user stop ambient-brightness
```

#### Standalone Mode (Non-systemd Environments)

If systemd is not available, the service automatically runs in standalone mode. The GUI will detect this and provide appropriate controls. You can also manage it manually:

```bash
# Start the service manually
~/.local/bin/ambient_brightness.py &

# Check if running
ps aux | grep ambient_brightness

# Stop the service (kill the process)
pkill -f ambient_brightness.py
```

**Note**: It's recommended to use the GUI application for easier service management in standalone mode. The GUI handles process management, logging, and autostart configuration automatically.

## Configuration

### Via GUI (Recommended)

Use the Settings tab in the GUI application to adjust all configuration options with real-time preview:

1. Open `ambient-brightness-gui`
2. Go to the "Settings" tab
3. Adjust sliders and checkboxes
4. Click "Save Settings"
5. Restart the service from the "Service" tab

### Via Config File

Alternatively, edit `~/.config/ambient-brightness/config.conf`:

```ini
# Enable camera as fallback (true/false)
enable_camera=true

# Smoothing factor (0.0-1.0)
# Higher = faster response, Lower = smoother transitions
smoothing_factor=0.3

# Update interval in seconds
update_interval=2.0

# Minimum brightness percentage (1-100)
min_brightness=10

# Maximum brightness percentage (1-100)
max_brightness=100
```

After changing configuration, restart the service:
```bash
systemctl --user restart ambient-brightness
```

## Testing

### Check for Ambient Light Sensor

```bash
# List IIO devices
ls -la /sys/bus/iio/devices/

# Check for illuminance sensors
find /sys/bus/iio/devices/ -name "*illuminance*"
```

### Check Backlight Device

```bash
# List backlight devices
ls -la /sys/class/backlight/

# Check current brightness
cat /sys/class/backlight/*/brightness

# Check max brightness
cat /sys/class/backlight/*/max_brightness
```

### Manual Test Run

```bash
# Run in foreground with debug output
~/.local/bin/ambient_brightness.py
```

## Troubleshooting

### Service Fails to Start with "Unit not found" Errors

If you see errors like:
```
Failed to start ambient-brightness.service: Unit ambient-brightness.service not found.
```

This usually means you're trying to manage a user service when it was installed system-wide, or vice versa. The installation method determines where the service is installed:

- **System-wide installation** (via `sudo make install` or quick-install): Uses `sudo systemctl` (no `--user`)
- **User installation** (via `install.sh` without sudo): Uses `systemctl --user`

**Solution - Complete Cleanup and Reinstall:**

1. **Run the cleanup script** to remove all versions:
```bash
cd linux-ambient
chmod +x cleanup-old-install.sh
./cleanup-old-install.sh
```

2. **Reinstall with the latest version**:
```bash
# Pull latest fixes
git pull

# For system-wide installation (recommended):
sudo make install

# Then manage with:
sudo systemctl start ambient-brightness
sudo systemctl enable ambient-brightness

# OR for user installation:
./install.sh

# Then manage with:
systemctl --user start ambient-brightness
systemctl --user enable ambient-brightness
```

3. **Use the GUI (easiest)**:
```bash
ambient-brightness-gui
```
The GUI automatically detects your installation type and uses the correct commands.

### No Sensor Detected

If you see "No sensors available":
- **For ALS**: Check if your laptop has an ambient light sensor (common in MacBooks, ThinkPads, and high-end laptops)
- **For Camera**: Install OpenCV: `sudo apt install python3-opencv` or `pip3 install opencv-python`

### Permission Denied for Brightness Control

If you get permission errors:
1. Ensure udev rules are installed (see Installation)
2. Add your user to the `video` group: `sudo usermod -a -G video $USER`
3. Log out and back in
4. Or run the service with systemd (which runs as root)

### Service Won't Start

**If using systemd:**
```bash
# Check detailed error logs
journalctl --user -u ambient-brightness -xe

# Verify systemd service file exists
ls -l ~/.config/systemd/user/ambient-brightness.service

# Reload systemd
systemctl --user daemon-reload
```

**If service file is missing:**

If you see errors like "No such file or directory" for the service file or "-- No entries --" in the logs, the service file wasn't properly installed. Run the fix script:

```bash
cd linux-ambient
./fix-service-installation.sh
```

This will:
- Create the systemd user directory if missing
- Copy or recreate the service file
- Reload the systemd daemon
- Verify the installation

After running the fix script, try starting the service again:
```bash
systemctl --user start ambient-brightness
```

**If systemd is not available:**
The service will automatically run in standalone mode. Use the GUI application to start the service, or:

```bash
# Verify Python script is executable
ls -l ~/.local/bin/ambient_brightness.py

# Test script manually
~/.local/bin/ambient_brightness.py

# Check logs in standalone mode
cat ~/.config/ambient-brightness/service.log
```

**Common issues:**
- Missing hardware: The service requires either an ambient light sensor or a camera, plus a backlight device
- Permission issues: Ensure you're in the `video` group for backlight control
- GTK dependencies: Make sure GTK3 libraries are installed for the GUI

### Brightness Changes Too Fast/Slow

Use the GUI Settings tab to adjust the smoothing factor slider, or edit config:
- Faster response: increase to 0.5-0.8
- Slower/smoother: decrease to 0.1-0.2

### GUI Won't Start

If the GUI application fails to launch:

```bash
# Check if GTK3 dependencies are installed
dpkg -l | grep python3-gi  # Debian/Ubuntu
rpm -qa | grep python3-gobject  # Fedora

# Install missing dependencies
sudo apt install python3-gi gir1.2-gtk-3.0 gir1.2-appindicator3-0.1  # Debian/Ubuntu
sudo dnf install python3-gobject gtk3 libappindicator-gtk3  # Fedora
```

### Settings Won't Save

If settings fail to save:
- Check that `~/.config/ambient-brightness/` directory exists and is writable
- Ensure you have write permissions to your home directory
- Check available disk space

### Camera Not Working

```bash
# Test camera access
python3 -c "import cv2; print(cv2.VideoCapture(0).isOpened())"

# Check camera device
ls -la /dev/video*
```

## Uninstallation

The uninstallation method depends on how you installed:

### If installed via Debian Package

**Easiest method - Use the package manager:**

1. **Via GUI**: Right-click on "Ambient Brightness Settings" in your application menu → Uninstall
2. **Via Software Manager**: Open Software Manager, search for "ambient-brightness", click Uninstall
3. **Via command line**:
   ```bash
   sudo apt remove ambient-brightness
   # Or to remove config files too:
   sudo apt purge ambient-brightness
   ```

✅ This will cleanly remove all installed files and show up properly in your package manager!

### If installed via script or Makefile

**Option 1: Using the uninstall script (recommended)**

The improved uninstall script automatically detects both user-level and system-level installations:

```bash
cd linux-ambient
./uninstall.sh
```

For system-level installations (installed with `sudo make install`):
```bash
sudo ./uninstall.sh
# Or use:
sudo make uninstall
```

**Option 2: Manual removal (user-level installation)**

```bash
# Stop and disable the service
systemctl --user stop ambient-brightness
systemctl --user disable ambient-brightness

# Remove installed files
rm -f ~/.local/bin/ambient_brightness.py
rm -f ~/.local/bin/ambient-brightness-gui
rm -f ~/.config/systemd/user/ambient-brightness.service
rm -f ~/.local/share/applications/ambient-brightness-settings.desktop
rm -f ~/.config/autostart/ambient-brightness-tray.desktop

# Reload systemd
systemctl --user daemon-reload

# Optional: Remove configuration and data
rm -rf ~/.config/ambient-brightness
```

**Option 3: Manual removal (system-level installation)**

```bash
# Stop and disable the service
sudo systemctl stop ambient-brightness
sudo systemctl disable ambient-brightness

# Remove installed files
sudo rm -f /usr/local/bin/ambient_brightness.py
sudo rm -f /usr/local/bin/ambient-brightness-gui
sudo rm -f /etc/systemd/system/ambient-brightness.service
sudo rm -f /usr/share/applications/ambient-brightness-settings.desktop
sudo rm -f /etc/xdg/autostart/ambient-brightness-tray.desktop
sudo rm -f /etc/udev/rules.d/90-backlight.rules

# Reload systemd and udev
sudo systemctl daemon-reload
sudo udevadm control --reload-rules

# Optional: Remove system configuration
sudo rm -rf /etc/ambient-brightness
```

## Architecture

### Service Architecture

```
┌─────────────────────────────────────────┐
│         AmbientBrightnessService        │
│              (Background)               │
└────────────────┬────────────────────────┘
                 │
        ┌────────┴────────┐
        │                 │
┌───────▼───────┐  ┌──────▼──────┐
│ SensorReader  │  │  Brightness │
│   - ALSSensor │  │  Controller │
│   - Camera    │  │             │
└───────┬───────┘  └──────┬──────┘
        │                 │
        └────────┬────────┘
                 │
        ┌────────▼────────┐
        │   Brightness    │
        │    Adapter      │
        │  (Algorithm)    │
        └─────────────────┘
```

### GUI Architecture

```
┌────────────────────────────────────────────┐
│        Ambient Brightness GUI              │
│         (GTK3 Application)                 │
└──────┬──────────────┬──────────────────────┘
       │              │
       │              └──────────────┐
       │                             │
┌──────▼──────┐  ┌──────▼──────┐   │
│   Settings  │  │   Service   │   │
│   Window    │  │   Control   │   │
│  (3 Tabs)   │  │  (systemd   │   │
│             │  │    --user)  │   │
└──────┬──────┘  └──────┬──────┘   │
       │                 │          │
       │          ┌──────▼──────┐   │
       │          │   Config    │   │
       │          │  Manager    │   │
       │          │  (~/.config)│   │
       │          └─────────────┘   │
       │                            │
┌──────▼────────────────────────────▼───┐
│        System Tray Indicator          │
│         (AppIndicator3)               │
└───────────────────────────────────────┘
```

## Supported Hardware

### Tested Devices
- Laptops with IIO-based ambient light sensors
- ThinkPad series (X1, T, P series with ALS)
- MacBooks (when running Linux)
- Dell XPS series
- Any Linux laptop with webcam (fallback mode)

### Requirements
- `/sys/class/backlight/` support (standard on modern Linux)
- Either:
  - IIO ambient light sensor (`/sys/bus/iio/devices/`)
  - Webcam accessible via `/dev/video*`

## Contributing

Contributions welcome! Please feel free to submit issues or pull requests.

## License

See LICENSE file for details.

## Acknowledgments

Inspired by automatic brightness control in macOS and smartphones.
