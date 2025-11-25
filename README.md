# Linux Ambient Brightness Control

Automatic screen brightness adjustment for Linux using ambient light sensors or camera, similar to smartphones.

## Quick Start

```bash
# One-line install
curl -fsSL https://raw.githubusercontent.com/jjermany/linux-ambient/main/quick-install.sh | sudo bash

# Then open the GUI
ambient-brightness-gui
```

That's it! The GUI will guide you through starting and configuring the service.

## Features

- **Graphical User Interface**: Full-featured GTK3 GUI with real-time monitoring and easy configuration
- **System Tray Integration**: Quick access indicator with service control
- **Dual Sensor Support**: Automatically uses ambient light sensor (ALS) if available, falls back to camera
- **Smart Algorithm**: Non-linear brightness mapping optimized for human perception
- **Smooth Transitions**: Prevents jarring brightness changes with exponential smoothing
- **Highly Configurable**: Adjust sensitivity, update rate, and brightness limits via GUI or config file
- **Service Management**: Start/stop/restart service and view logs directly from GUI
- **Lightweight**: Runs as a systemd service with minimal resource usage
- **Secure**: Includes udev rules and PolicyKit integration for proper permission management

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
- Root access for installation

### Python Dependencies

- `python3-gi` / `PyGObject` (required for GUI)
- `gtk3` / `gir1.2-gtk-3.0` (required for GUI)
- `libappindicator-gtk3` / `gir1.2-appindicator3-0.1` (required for system tray)
- `opencv-python` (optional, only needed for camera mode)
- `numpy` (optional, only needed for camera mode)

## Installation

Choose one of the following installation methods:

### Method 1: One-Liner Install (Easiest)

Download and install automatically with a single command:

```bash
curl -fsSL https://raw.githubusercontent.com/jjermany/linux-ambient/main/quick-install.sh | sudo bash
```

Or with wget:

```bash
wget -qO- https://raw.githubusercontent.com/jjermany/linux-ambient/main/quick-install.sh | sudo bash
```

This will automatically:
- Clone the repository
- Install all dependencies
- Set up the service
- Install the GUI application
- Clean up temporary files

### Method 2: Standard Make Install (Recommended for Developers)

If you've cloned or downloaded the repository:

```bash
git clone https://github.com/jjermany/linux-ambient.git
cd linux-ambient
sudo make install
```

The Makefile supports standard targets:
- `make help` - Show available targets
- `make install` - Install everything
- `make uninstall` - Remove everything
- `make install-deps` - Install dependencies only

### Method 3: Using Install Script

After cloning/downloading the repository:

```bash
cd linux-ambient
sudo ./install.sh
```

This script will:
- Install Python and GTK dependencies
- Copy scripts to `/usr/local/bin/`
- Set up configuration in `/etc/ambient-brightness/`
- Create udev rules for brightness control
- Install systemd service
- Add GUI desktop entries

### Method 4: Manual Installation

For complete control over the installation process:

1. **Install dependencies**:
```bash
# Debian/Ubuntu
sudo apt install python3-gi gir1.2-gtk-3.0 gir1.2-appindicator3-0.1 python3-opencv python3-numpy

# Fedora
sudo dnf install python3-gobject gtk3 libappindicator-gtk3 python3-opencv python3-numpy

# Arch Linux
sudo pacman -S python-gobject gtk3 libappindicator-gtk3 python-opencv python-numpy
```

2. **Copy scripts**:
```bash
sudo cp ambient_brightness.py /usr/local/bin/
sudo cp ambient_brightness_gui.py /usr/local/bin/ambient-brightness-gui
sudo chmod +x /usr/local/bin/ambient_brightness.py
sudo chmod +x /usr/local/bin/ambient-brightness-gui
```

3. **Create configuration**:
```bash
sudo mkdir -p /etc/ambient-brightness
sudo cp config.conf.example /etc/ambient-brightness/config.conf
```

4. **Set up udev rules**:
```bash
sudo tee /etc/udev/rules.d/90-backlight.rules << 'EOF'
ACTION=="add", SUBSYSTEM=="backlight", KERNEL=="*", RUN+="/bin/chgrp video /sys/class/backlight/%k/brightness"
ACTION=="add", SUBSYSTEM=="backlight", KERNEL=="*", RUN+="/bin/chmod g+w /sys/class/backlight/%k/brightness"
EOF

sudo udevadm control --reload-rules
sudo udevadm trigger --subsystem-match=backlight
```

5. **Install systemd service**:
```bash
sudo cp ambient-brightness.service /etc/systemd/system/
sudo systemctl daemon-reload
```

6. **Install desktop entries**:
```bash
sudo cp ambient-brightness-settings.desktop /usr/share/applications/
sudo cp ambient-brightness-tray.desktop /etc/xdg/autostart/
sudo update-desktop-database /usr/share/applications/
```

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

You can also manage the service via command line:

#### Start the Service

```bash
sudo systemctl start ambient-brightness
```

### Enable at Boot

```bash
sudo systemctl enable ambient-brightness
```

### Check Status

```bash
sudo systemctl status ambient-brightness
```

### View Logs

```bash
# Follow live logs
sudo journalctl -u ambient-brightness -f

# View recent logs
sudo journalctl -u ambient-brightness -n 50
```

#### Stop the Service

```bash
sudo systemctl stop ambient-brightness
```

## Configuration

### Via GUI (Recommended)

Use the Settings tab in the GUI application to adjust all configuration options with real-time preview:

1. Open `ambient-brightness-gui`
2. Go to the "Settings" tab
3. Adjust sliders and checkboxes
4. Click "Save Settings"
5. Restart the service from the "Service" tab

### Via Config File

Alternatively, edit `/etc/ambient-brightness/config.conf`:

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
sudo systemctl restart ambient-brightness
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
sudo python3 ambient_brightness.py
```

## Troubleshooting

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

```bash
# Check detailed error logs
sudo journalctl -u ambient-brightness -xe

# Verify Python script is executable
ls -l /usr/local/bin/ambient_brightness.py

# Test script manually
sudo /usr/local/bin/ambient_brightness.py
```

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

If you get permission errors when saving settings:
- The GUI uses PolicyKit (pkexec) to save with elevated privileges
- Ensure PolicyKit is installed and running
- Check `/etc/ambient-brightness/` directory permissions

### Camera Not Working

```bash
# Test camera access
python3 -c "import cv2; print(cv2.VideoCapture(0).isOpened())"

# Check camera device
ls -la /dev/video*
```

## Uninstallation

### Using Make (Recommended)

```bash
cd linux-ambient
sudo make uninstall
```

### Using Uninstall Script

```bash
cd linux-ambient
sudo ./uninstall.sh
```

Both methods will:
- Stop and disable the service
- Remove all installed files
- Remove desktop entries
- Ask before removing configuration

To completely remove including configuration:
```bash
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
│  (3 Tabs)   │  │  (systemd)  │   │
└──────┬──────┘  └──────┬──────┘   │
       │                 │          │
       │          ┌──────▼──────┐   │
       │          │   Config    │   │
       │          │  Manager    │   │
       │          │  (pkexec)   │   │
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
