# Linux Ambient Brightness Control

Automatic screen brightness adjustment for Linux using ambient light sensors or camera, similar to smartphones.

## Quick Start

```bash
# Clone the repository
git clone https://github.com/jjermany/linux-ambient.git
cd linux-ambient

# Run the simple installer
./simple-install.sh

# Then open the GUI
ambient-brightness-gui
```

That's it! The installer will guide you through the setup. Sudo is only needed for GTK packages and backlight permissions.

## Where Files Are Installed

After installation, here's where everything lives:

```
~/.local/bin/
  ├── ambient_brightness.py          (main service)
  └── ambient-brightness-gui         (GUI application)

~/.config/ambient-brightness/
  └── config.conf                    (your settings)

~/.config/systemd/user/
  └── ambient-brightness.service     (systemd service)

~/.local/share/applications/
  └── ambient-brightness-settings.desktop  (app menu entry)

~/.config/autostart/
  └── ambient-brightness-tray.desktop      (system tray)

/etc/udev/rules.d/
  └── 90-backlight.rules             (backlight permissions)
```

**That's it!** Everything is in standard user directories. No scattered files across the system.

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

**Simple, single-method installation:**

```bash
# 1. Clone the repository
git clone https://github.com/jjermany/linux-ambient.git
cd linux-ambient

# 2. Run the installer
./simple-install.sh
```

The installer will:
- ✅ Install GTK3 dependencies (asks for sudo)
- ✅ Install to your home directory (~/.local/bin)
- ✅ Set up user systemd service
- ✅ Create desktop entries and system tray icon
- ✅ Configure backlight permissions (asks for sudo)
- ✅ Add you to the video group (asks for sudo)

**That's it!** No confusing choices, no multiple methods.

### Advanced: System-wide Installation

For system administrators who want to install for all users:

```bash
sudo make install
```

This installs to system directories (/usr/local/bin, /etc/systemd/system) instead of user directories.

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

### Duplicate System Tray Icons

If you see two (or more) tray icons, this means multiple instances are starting from different locations. Quick fix:

```bash
cd linux-ambient
./fix-duplicate-tray.sh
```

This typically happens when:
- Both system-wide and user-level autostart files exist
- Previous installation wasn't fully cleaned up

For detailed troubleshooting, see [TROUBLESHOOTING.md](TROUBLESHOOTING.md#duplicate-system-tray-icons).

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

**To remove EVERYTHING from ALL possible locations:**

```bash
cd linux-ambient
./complete-uninstall.sh
```

This script will:
- ✅ Stop all running processes
- ✅ Remove all user-level files (~/.local/, ~/.config/)
- ✅ Remove all system-level files (/usr/local/, /etc/) - asks for sudo if needed
- ✅ Remove udev rules
- ✅ Ask before removing configuration files
- ✅ Verify everything is gone

**No more confusion about multiple installations!** This script finds and removes everything.

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
