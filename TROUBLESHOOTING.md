# Troubleshooting Guide

This guide helps you diagnose and fix common issues with Ambient Brightness Control.

## Table of Contents

1. [Duplicate System Tray Icons](#duplicate-system-tray-icons)
2. [Service Won't Start (Exit Code 203)](#service-wont-start-exit-code-203)
3. [Service Fails Immediately After Starting](#service-fails-immediately-after-starting)
4. [Permission Denied Errors](#permission-denied-errors)
5. [No Ambient Light Sensor Detected](#no-ambient-light-sensor-detected)

---

## Duplicate System Tray Icons

### Symptoms

You see two (or more) identical system tray icons for Ambient Brightness Control.

### Cause

This happens when the tray application is started from multiple locations:
1. **System-wide autostart file** at `/etc/xdg/autostart/ambient-brightness-tray.desktop`
2. **User-level autostart file** at `~/.config/autostart/ambient-brightness-tray.desktop`

This typically occurs when:
- You installed both a system-wide package (.deb) AND ran the user-level install script
- A previous installation wasn't fully cleaned up before reinstalling
- Old installation files remain from a different installation method

### Solution

**Quick Fix (Recommended):**
```bash
cd /path/to/linux-ambient
./fix-duplicate-tray.sh
```

This script will:
- Detect all autostart files (system-wide and user-level)
- Identify conflicts
- Offer to remove duplicates
- Restart a single tray instance

**Manual Fix:**

1. Check for duplicate files:
```bash
ls -l /etc/xdg/autostart/ambient-brightness-tray.desktop 2>/dev/null
ls -l ~/.config/autostart/ambient-brightness-tray.desktop 2>/dev/null
```

2. Remove the system-wide file (recommended to keep user-level only):
```bash
sudo rm /etc/xdg/autostart/ambient-brightness-tray.desktop
```

3. Kill existing tray instances:
```bash
pkill -f "ambient-brightness-gui --tray"
```

4. Log out and log back in, or manually start the tray:
```bash
ambient-brightness-gui --tray &
```

### Prevention

The latest version includes a singleton check that prevents multiple instances from starting. To update your installation:
```bash
cd /path/to/linux-ambient
git pull
./install.sh
```

After updating, the tray desktop file will automatically prevent duplicate instances even if multiple autostart files exist.

### Verification

After applying the fix:
```bash
# Check for running instances (should show only 1)
pgrep -fa "ambient-brightness-gui --tray"

# Should show only one process
```

---

## Service Won't Start (Exit Code 203)

### Symptoms

When trying to start the service with `systemctl --user start ambient-brightness`, you see:
```
● ambient-brightness.service - Ambient Brightness Control Service
   Loaded: loaded
   Active: failed (Result: exit-code)
  Process: ExitCode=203
```

### Cause

Exit code 203 (EXEC) means systemd cannot execute the program. This typically happens when:
- The executable file doesn't exist at the expected location
- The file is not executable (missing execute permissions)
- The file path is incorrect

### Solution

**Option 1: Run the fix script (Recommended)**
```bash
cd /path/to/linux-ambient
./fix-service-installation.sh
```

This script will:
- Check if the executable exists
- Install it if missing
- Set proper permissions
- Verify the installation

**Option 2: Run the full installation**
```bash
cd /path/to/linux-ambient
./install.sh
```

**Option 3: Manual fix**
```bash
# Create the bin directory if it doesn't exist
mkdir -p ~/.local/bin

# Copy the script
cp ambient_brightness.py ~/.local/bin/

# Make it executable
chmod +x ~/.local/bin/ambient_brightness.py

# Reload systemd
systemctl --user daemon-reload

# Try starting again
systemctl --user start ambient-brightness
```

### Verification

After applying the fix, verify the installation:
```bash
# Check if file exists and is executable
ls -l ~/.local/bin/ambient_brightness.py

# Should show: -rwxr-xr-x ... ambient_brightness.py
#                ^  ^  ^
#                |  |  |
#                executable by owner, group, others

# Check the service logs
journalctl --user -u ambient-brightness -n 20
```

---

## Service Fails Immediately After Starting

### Symptoms

The service starts but immediately fails with error messages in the logs.

### Diagnosis

Check the logs:
```bash
journalctl --user -u ambient-brightness -n 50 --no-pager
```

### Common Causes and Solutions

**Python Dependencies Missing**
```
ModuleNotFoundError: No module named 'cv2'
```

Solution:
```bash
pip3 install --user opencv-python numpy
# OR use system packages:
sudo apt-get install python3-opencv python3-numpy
```

**Config File Issues**
```
Error reading config file
```

Solution:
```bash
# Recreate default config
mkdir -p ~/.config/ambient-brightness
cp config.conf.example ~/.config/ambient-brightness/config.conf
```

---

## Permission Denied Errors

### Symptoms

```
Permission denied: '/sys/class/backlight/*/brightness'
```

### Cause

Your user doesn't have permission to control the backlight device.

### Solution

**Option 1: Add yourself to the video group**
```bash
sudo usermod -aG video $USER
```

Then log out and log back in for changes to take effect.

**Option 2: Set up udev rules**
```bash
sudo bash -c 'cat > /etc/udev/rules.d/90-backlight.rules << "EOF"
# Allow users in video group to control backlight
ACTION=="add", SUBSYSTEM=="backlight", KERNEL=="*", RUN+="/bin/chgrp video /sys/class/backlight/%k/brightness"
ACTION=="add", SUBSYSTEM=="backlight", KERNEL=="*", RUN+="/bin/chmod g+w /sys/class/backlight/%k/brightness"
EOF'

sudo udevadm control --reload-rules
sudo udevadm trigger --subsystem-match=backlight
```

---

## No Ambient Light Sensor Detected

### Symptoms

```
WARNING - No ambient light sensor detected
WARNING - Camera fallback is disabled
```

### Diagnosis

Check if your system has an ambient light sensor:
```bash
ls /sys/bus/iio/devices/
```

Look for devices with names like `iio:device*`. Check their names:
```bash
cat /sys/bus/iio/devices/iio:device*/name
```

### Solutions

**If you have a sensor but it's not detected:**
1. Check if it's a supported sensor (acpi-als, als, isl29*)
2. Ensure the IIO subsystem is enabled in your kernel

**If you don't have a sensor:**
Enable camera fallback in the config file:
```bash
nano ~/.config/ambient-brightness/config.conf
```

Set:
```
enable_camera=true
```

---

## Getting More Help

If you're still experiencing issues:

1. **Check the service status:**
   ```bash
   systemctl --user status ambient-brightness
   ```

2. **View detailed logs:**
   ```bash
   journalctl --user -u ambient-brightness -f
   ```

3. **Try running manually for debugging:**
   ```bash
   ~/.local/bin/ambient_brightness.py
   ```
   (Press Ctrl+C to stop)

4. **Report an issue:**
   Visit: https://github.com/jjermany/linux-ambient/issues

   Include:
   - Your Linux distribution and version
   - Output of `systemctl --user status ambient-brightness`
   - Output of `journalctl --user -u ambient-brightness -n 50`
   - Output of `ls -l ~/.local/bin/ambient_brightness.py`
