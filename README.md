# Linux Ambient Brightness Control

Automatic screen brightness adjustment for Linux using ambient light sensors or camera, similar to smartphones.

## Features

- **Dual Sensor Support**: Automatically uses ambient light sensor (ALS) if available, falls back to camera
- **Smart Algorithm**: Non-linear brightness mapping optimized for human perception
- **Smooth Transitions**: Prevents jarring brightness changes with exponential smoothing
- **Configurable**: Adjust sensitivity, update rate, and brightness limits
- **Lightweight**: Runs as a systemd service with minimal resource usage
- **Secure**: Includes udev rules for proper permission management

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

- `opencv-python` (optional, only needed for camera mode)
- `numpy` (optional, only needed for camera mode)

## Installation

### Quick Install

```bash
sudo ./install.sh
```

This will:
- Install Python dependencies
- Copy files to system directories
- Set up udev rules for brightness control
- Install systemd service

### Manual Installation

1. Install Python dependencies (if using camera mode):
```bash
sudo apt install python3-opencv  # Debian/Ubuntu
# or
sudo dnf install python3-opencv  # Fedora
# or
pip3 install opencv-python numpy
```

2. Copy the main script:
```bash
sudo cp ambient_brightness.py /usr/local/bin/
sudo chmod +x /usr/local/bin/ambient_brightness.py
```

3. Create config directory and copy example config:
```bash
sudo mkdir -p /etc/ambient-brightness
sudo cp config.conf.example /etc/ambient-brightness/config.conf
```

4. Set up udev rules (to avoid needing sudo):
```bash
sudo cp 90-backlight.rules /etc/udev/rules.d/  # If you create this file
# Or create manually:
sudo tee /etc/udev/rules.d/90-backlight.rules << 'EOF'
ACTION=="add", SUBSYSTEM=="backlight", KERNEL=="*", RUN+="/bin/chgrp video /sys/class/backlight/%k/brightness"
ACTION=="add", SUBSYSTEM=="backlight", KERNEL=="*", RUN+="/bin/chmod g+w /sys/class/backlight/%k/brightness"
EOF

sudo udevadm control --reload-rules
sudo udevadm trigger --subsystem-match=backlight
```

5. Install systemd service:
```bash
sudo cp ambient-brightness.service /etc/systemd/system/
sudo systemctl daemon-reload
```

## Usage

### Start the Service

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

### Stop the Service

```bash
sudo systemctl stop ambient-brightness
```

## Configuration

Edit `/etc/ambient-brightness/config.conf`:

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

Adjust `smoothing_factor` in config:
- Faster response: increase to 0.5-0.8
- Slower/smoother: decrease to 0.1-0.2

### Camera Not Working

```bash
# Test camera access
python3 -c "import cv2; print(cv2.VideoCapture(0).isOpened())"

# Check camera device
ls -la /dev/video*
```

## Uninstallation

```bash
sudo ./uninstall.sh
```

This will stop the service, remove installed files, and optionally remove configuration.

## Architecture

```
┌─────────────────────────────────────────┐
│         AmbientBrightnessService        │
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
