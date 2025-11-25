#!/usr/bin/env python3
"""
Automatic Brightness Control for Linux
Uses ambient light sensor or camera to adjust screen brightness automatically.
"""

import os
import sys
import time
import glob
import logging
from pathlib import Path
from typing import Optional, Tuple
import signal

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger('ambient-brightness')


class SensorReader:
    """Abstract base for sensor reading"""

    def read_light_level(self) -> Optional[float]:
        """Read ambient light level. Returns value 0-100 or None if unavailable."""
        raise NotImplementedError


class ALSSensor(SensorReader):
    """Ambient Light Sensor via IIO subsystem"""

    def __init__(self):
        self.sensor_path = None
        self.scale = 1.0
        self._detect_sensor()

    def _detect_sensor(self):
        """Detect ambient light sensor in IIO subsystem"""
        iio_devices = Path('/sys/bus/iio/devices')

        if not iio_devices.exists():
            logger.warning("IIO subsystem not found")
            return

        # Look for ambient light sensor
        for device in iio_devices.glob('iio:device*'):
            name_file = device / 'name'
            if name_file.exists():
                name = name_file.read_text().strip()
                logger.debug(f"Found IIO device: {name}")

                # Check for illuminance channel
                illuminance_raw = device / 'in_illuminance_raw'
                illuminance_input = device / 'in_illuminance_input'
                intensity_raw = device / 'in_intensity_both_raw'

                if illuminance_raw.exists() or illuminance_input.exists() or intensity_raw.exists():
                    self.sensor_path = device

                    # Try to get scale
                    scale_file = device / 'in_illuminance_scale'
                    if scale_file.exists():
                        try:
                            self.scale = float(scale_file.read_text().strip())
                        except:
                            self.scale = 1.0

                    logger.info(f"Using ALS: {name} at {device}")
                    return

        logger.warning("No ambient light sensor detected")

    def read_light_level(self) -> Optional[float]:
        """Read light level from ALS (0-100 scale)"""
        if not self.sensor_path:
            return None

        try:
            # Try different possible input files
            for input_file in ['in_illuminance_input', 'in_illuminance_raw', 'in_intensity_both_raw']:
                path = self.sensor_path / input_file
                if path.exists():
                    raw_value = float(path.read_text().strip())
                    # Scale to lux
                    lux = raw_value * self.scale

                    # Convert lux to 0-100 scale (logarithmic mapping)
                    # Typical range: 0-50000 lux
                    # Indoor: 100-1000 lux, Outdoor: 10000-50000+ lux
                    if lux <= 0:
                        return 0

                    # Logarithmic scale: log10(lux+1) / log10(50000) * 100
                    import math
                    normalized = (math.log10(lux + 1) / math.log10(50000)) * 100
                    return min(100, max(0, normalized))

            return None

        except Exception as e:
            logger.error(f"Error reading ALS: {e}")
            return None

    def is_available(self) -> bool:
        return self.sensor_path is not None


class CameraSensor(SensorReader):
    """Camera-based light detection using OpenCV"""

    def __init__(self):
        self.camera = None
        self.available = False
        self._init_camera()

    def _init_camera(self):
        """Initialize camera"""
        try:
            import cv2

            # Try to open default camera
            self.camera = cv2.VideoCapture(0)
            if self.camera.isOpened():
                self.available = True
                logger.info("Camera sensor initialized")
            else:
                logger.warning("Could not open camera")

        except ImportError:
            logger.warning("OpenCV (cv2) not installed. Camera sensor unavailable.")
        except Exception as e:
            logger.error(f"Error initializing camera: {e}")

    def read_light_level(self) -> Optional[float]:
        """Read light level from camera (0-100 scale)"""
        if not self.available or not self.camera:
            return None

        try:
            import cv2
            import numpy as np

            # Capture frame
            ret, frame = self.camera.read()
            if not ret:
                return None

            # Convert to grayscale and calculate mean brightness
            gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
            brightness = np.mean(gray)

            # Normalize to 0-100 (grayscale is 0-255)
            normalized = (brightness / 255.0) * 100

            return normalized

        except Exception as e:
            logger.error(f"Error reading camera: {e}")
            return None

    def is_available(self) -> bool:
        return self.available

    def cleanup(self):
        """Release camera resources"""
        if self.camera:
            self.camera.release()


class BrightnessController:
    """Control screen brightness via /sys/class/backlight"""

    def __init__(self):
        self.backlight_path = None
        self.max_brightness = 100
        self._detect_backlight()

    def _detect_backlight(self):
        """Detect backlight device"""
        backlight_base = Path('/sys/class/backlight')

        if not backlight_base.exists():
            logger.error("Backlight subsystem not found")
            return

        # Find first available backlight device
        devices = list(backlight_base.glob('*'))
        if not devices:
            logger.error("No backlight devices found")
            return

        self.backlight_path = devices[0]

        # Read maximum brightness
        max_file = self.backlight_path / 'max_brightness'
        if max_file.exists():
            self.max_brightness = int(max_file.read_text().strip())

        logger.info(f"Using backlight: {self.backlight_path.name} (max: {self.max_brightness})")

    def get_current_brightness(self) -> Optional[int]:
        """Get current brightness (0-100 scale)"""
        if not self.backlight_path:
            return None

        try:
            brightness_file = self.backlight_path / 'brightness'
            current = int(brightness_file.read_text().strip())
            # Normalize to 0-100
            return int((current / self.max_brightness) * 100)
        except Exception as e:
            logger.error(f"Error reading brightness: {e}")
            return None

    def set_brightness(self, level: int) -> bool:
        """Set brightness (0-100 scale)"""
        if not self.backlight_path:
            return False

        try:
            # Clamp to valid range
            level = max(1, min(100, level))  # Never go to 0 (screen off)

            # Convert to device scale
            device_value = int((level / 100) * self.max_brightness)
            device_value = max(1, device_value)  # Ensure at least 1

            brightness_file = self.backlight_path / 'brightness'
            brightness_file.write_text(str(device_value))

            return True

        except PermissionError:
            logger.error("Permission denied. Run with sudo or add appropriate udev rules.")
            return False
        except Exception as e:
            logger.error(f"Error setting brightness: {e}")
            return False

    def is_available(self) -> bool:
        return self.backlight_path is not None


class BrightnessAdapter:
    """Adaptive brightness controller with smoothing"""

    def __init__(self, config: dict):
        self.config = config
        self.smoothing_factor = config.get('smoothing_factor', 0.3)
        self.update_interval = config.get('update_interval', 2.0)
        self.min_brightness = config.get('min_brightness', 10)
        self.max_brightness = config.get('max_brightness', 100)

        # State
        self.current_target = None
        self.last_sensor_value = None

    def map_light_to_brightness(self, light_level: float) -> int:
        """Map light level (0-100) to brightness (0-100)"""

        # Non-linear mapping: darker environments need relatively higher brightness
        # Light: 0-20 -> Brightness: 10-40
        # Light: 20-60 -> Brightness: 40-75
        # Light: 60-100 -> Brightness: 75-100

        if light_level < 20:
            # Dark environment
            brightness = self.min_brightness + (light_level / 20) * (40 - self.min_brightness)
        elif light_level < 60:
            # Medium light
            brightness = 40 + ((light_level - 20) / 40) * 35
        else:
            # Bright environment
            brightness = 75 + ((light_level - 60) / 40) * 25

        # Clamp to configured range
        brightness = max(self.min_brightness, min(self.max_brightness, brightness))

        return int(brightness)

    def smooth_transition(self, current: int, target: int) -> int:
        """Apply smoothing to avoid sudden changes"""
        if current is None:
            return target

        # Exponential smoothing
        smooth_value = current + self.smoothing_factor * (target - current)

        return int(smooth_value)


class AmbientBrightnessService:
    """Main service orchestrator"""

    def __init__(self, config: dict):
        self.config = config
        self.running = False

        # Initialize components
        self.als_sensor = ALSSensor()
        self.camera_sensor = CameraSensor() if config.get('enable_camera', True) else None
        self.brightness_controller = BrightnessController()
        self.adapter = BrightnessAdapter(config)

        # Select sensor
        self.sensor = None
        if self.als_sensor.is_available():
            self.sensor = self.als_sensor
            logger.info("Using ambient light sensor")
        elif self.camera_sensor and self.camera_sensor.is_available():
            self.sensor = self.camera_sensor
            logger.info("Using camera as fallback sensor")
        else:
            logger.error("No sensors available!")
            sys.exit(1)

        if not self.brightness_controller.is_available():
            logger.error("Brightness control not available!")
            sys.exit(1)

        # Setup signal handlers
        signal.signal(signal.SIGINT, self._signal_handler)
        signal.signal(signal.SIGTERM, self._signal_handler)

    def _signal_handler(self, signum, frame):
        """Handle shutdown signals"""
        logger.info("Received shutdown signal")
        self.stop()

    def run(self):
        """Main service loop"""
        self.running = True
        logger.info("Ambient brightness service started")

        current_brightness = self.brightness_controller.get_current_brightness()

        try:
            while self.running:
                # Read light level
                light_level = self.sensor.read_light_level()

                if light_level is not None:
                    # Map to target brightness
                    target_brightness = self.adapter.map_light_to_brightness(light_level)

                    # Apply smoothing
                    smooth_brightness = self.adapter.smooth_transition(current_brightness, target_brightness)

                    # Update if changed significantly
                    if current_brightness is None or abs(smooth_brightness - current_brightness) >= 1:
                        if self.brightness_controller.set_brightness(smooth_brightness):
                            logger.debug(f"Light: {light_level:.1f}% -> Brightness: {smooth_brightness}%")
                            current_brightness = smooth_brightness

                # Sleep until next update
                time.sleep(self.adapter.update_interval)

        except Exception as e:
            logger.error(f"Error in main loop: {e}", exc_info=True)
        finally:
            self.cleanup()

    def stop(self):
        """Stop the service"""
        self.running = False

    def cleanup(self):
        """Cleanup resources"""
        if self.camera_sensor:
            self.camera_sensor.cleanup()
        logger.info("Service stopped")


def load_config() -> dict:
    """Load configuration"""
    # Default configuration
    config = {
        'enable_camera': True,
        'smoothing_factor': 0.3,
        'update_interval': 2.0,
        'min_brightness': 10,
        'max_brightness': 100,
    }

    # TODO: Load from config file if exists
    config_file = Path('/etc/ambient-brightness/config.conf')
    if config_file.exists():
        # Simple key=value parser
        try:
            for line in config_file.read_text().splitlines():
                line = line.strip()
                if line and not line.startswith('#'):
                    if '=' in line:
                        key, value = line.split('=', 1)
                        key = key.strip()
                        value = value.strip()

                        # Type conversion
                        if key in ['enable_camera']:
                            config[key] = value.lower() in ['true', '1', 'yes']
                        elif key in ['smoothing_factor', 'update_interval']:
                            config[key] = float(value)
                        elif key in ['min_brightness', 'max_brightness']:
                            config[key] = int(value)
        except Exception as e:
            logger.warning(f"Error loading config file: {e}")

    return config


def main():
    """Main entry point"""
    # Check for root/permissions
    if os.geteuid() != 0:
        logger.warning("Not running as root. May need sudo for brightness control.")

    # Load configuration
    config = load_config()

    # Create and run service
    service = AmbientBrightnessService(config)
    service.run()


if __name__ == '__main__':
    main()
