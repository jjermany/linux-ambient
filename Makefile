.PHONY: install uninstall help check-root install-deps install-scripts install-service install-gui clean

PREFIX ?= /usr/local
BINDIR = $(PREFIX)/bin
SYSTEMD_DIR = /etc/systemd/system
CONFIG_DIR = /etc/ambient-brightness
UDEV_DIR = /etc/udev/rules.d
DESKTOP_DIR = /usr/share/applications
AUTOSTART_DIR = /etc/xdg/autostart

help:
	@echo "Ambient Brightness Control - Installation"
	@echo ""
	@echo "Usage:"
	@echo "  make install      - Install everything (requires sudo)"
	@echo "  make uninstall    - Remove everything (requires sudo)"
	@echo "  make install-deps - Install system dependencies only"
	@echo "  make check-root   - Check if running as root"
	@echo ""
	@echo "Quick install:"
	@echo "  sudo make install"

check-root:
	@if [ "$$(id -u)" -ne 0 ]; then \
		echo "Error: This target must be run as root (use sudo)"; \
		exit 1; \
	fi

install-deps: check-root
	@echo "Installing dependencies..."
	@apt-get install -y python3-gi gir1.2-gtk-3.0 gir1.2-appindicator3-0.1 2>/dev/null || \
	dnf install -y python3-gobject gtk3 libappindicator-gtk3 2>/dev/null || \
	pacman -S --noconfirm python-gobject gtk3 libappindicator-gtk3 2>/dev/null || \
	echo "Note: Please install GTK3 dependencies via your package manager"
	@pip3 install opencv-python numpy 2>/dev/null || \
	echo "Note: Install python3-opencv python3-numpy via your package manager if needed"

install-scripts: check-root
	@echo "Installing scripts..."
	@install -m 755 ambient_brightness.py $(BINDIR)/ambient_brightness.py
	@install -m 755 ambient_brightness_gui.py $(BINDIR)/ambient-brightness-gui
	@echo "Scripts installed to $(BINDIR)"

install-config: check-root
	@echo "Installing configuration..."
	@mkdir -p $(CONFIG_DIR)
	@if [ ! -f $(CONFIG_DIR)/config.conf ]; then \
		install -m 644 config.conf.example $(CONFIG_DIR)/config.conf; \
		echo "Created default configuration at $(CONFIG_DIR)/config.conf"; \
	else \
		echo "Configuration already exists, skipping..."; \
	fi

install-udev: check-root
	@echo "Setting up udev rules..."
	@if [ -d $(UDEV_DIR) ]; then \
		echo '# Allow users in video group to control backlight' > $(UDEV_DIR)/90-backlight.rules; \
		echo 'ACTION=="add", SUBSYSTEM=="backlight", KERNEL=="*", RUN+="/bin/chgrp video /sys/class/backlight/%k/brightness"' >> $(UDEV_DIR)/90-backlight.rules; \
		echo 'ACTION=="add", SUBSYSTEM=="backlight", KERNEL=="*", RUN+="/bin/chmod g+w /sys/class/backlight/%k/brightness"' >> $(UDEV_DIR)/90-backlight.rules; \
		udevadm control --reload-rules 2>/dev/null || true; \
		udevadm trigger --subsystem-match=backlight 2>/dev/null || true; \
		echo "Udev rules installed"; \
	else \
		echo "⚠ udev rules directory not found - skipping udev rules"; \
		echo "  You may need to run the service with appropriate permissions"; \
	fi

install-service: check-root
	@echo "Checking for systemd..."
	@if systemctl --version >/dev/null 2>&1 && [ -d /run/systemd/system ]; then \
		echo "Installing systemd service..."; \
		install -m 644 ambient-brightness.service $(SYSTEMD_DIR)/ambient-brightness.service; \
		systemctl daemon-reload; \
		echo "Systemd service installed"; \
	else \
		echo "⚠ systemd not available - service will run in standalone mode"; \
		echo "  Use the GUI application to start/stop the service"; \
	fi

install-gui: check-root
	@echo "Installing desktop entries..."
	@if [ -d $(DESKTOP_DIR) ]; then \
		install -m 644 ambient-brightness-settings.desktop $(DESKTOP_DIR)/ambient-brightness-settings.desktop; \
		echo "Desktop entry installed to $(DESKTOP_DIR)"; \
	else \
		echo "⚠ Desktop directory not found - skipping desktop entry"; \
	fi
	@if [ -d $(AUTOSTART_DIR) ]; then \
		install -m 644 ambient-brightness-tray.desktop $(AUTOSTART_DIR)/ambient-brightness-tray.desktop; \
		echo "Autostart entry installed to $(AUTOSTART_DIR)"; \
	else \
		echo "⚠ Autostart directory not found - skipping autostart entry"; \
	fi
	@update-desktop-database $(DESKTOP_DIR) 2>/dev/null || true
	@echo "Desktop entries installation complete"

install: check-root install-deps install-scripts install-config install-udev install-service install-gui
	@echo ""
	@echo "========================================="
	@echo "Installation complete!"
	@echo "========================================="
	@echo ""
	@echo "GUI Application (RECOMMENDED):"
	@echo "  - Open 'Ambient Brightness Settings' from your application menu"
	@echo "  - Or run: ambient-brightness-gui"
	@echo "  - Use the GUI to start/stop the service and adjust settings"
	@echo "  - System tray indicator will start automatically on next login"
	@echo ""
	@if systemctl --version >/dev/null 2>&1 && [ -d /run/systemd/system ]; then \
		echo "Command Line (systemd mode):"; \
		echo "  Start the service:"; \
		echo "    sudo systemctl start ambient-brightness"; \
		echo ""; \
		echo "  Enable at boot:"; \
		echo "    sudo systemctl enable ambient-brightness"; \
		echo ""; \
	else \
		echo "Command Line (standalone mode):"; \
		echo "  The GUI application provides the easiest way to manage the service"; \
		echo "  Or run manually: $(BINDIR)/ambient_brightness.py &"; \
		echo ""; \
	fi
	@echo "Configuration: $(CONFIG_DIR)/config.conf (or use GUI)"
	@echo ""

uninstall: check-root
	@echo "Uninstalling Ambient Brightness Control..."
	@if systemctl --version >/dev/null 2>&1 && [ -d /run/systemd/system ]; then \
		systemctl stop ambient-brightness 2>/dev/null || true; \
		systemctl disable ambient-brightness 2>/dev/null || true; \
		rm -f $(SYSTEMD_DIR)/ambient-brightness.service; \
		systemctl daemon-reload; \
	fi
	@rm -f $(BINDIR)/ambient_brightness.py
	@rm -f $(BINDIR)/ambient-brightness-gui
	@rm -f $(DESKTOP_DIR)/ambient-brightness-settings.desktop
	@rm -f $(AUTOSTART_DIR)/ambient-brightness-tray.desktop
	@update-desktop-database $(DESKTOP_DIR) 2>/dev/null || true
	@rm -f $(UDEV_DIR)/90-backlight.rules
	@udevadm control --reload-rules 2>/dev/null || true
	@echo ""
	@echo "Uninstallation complete!"
	@echo "Configuration files remain at $(CONFIG_DIR)"
	@echo "To remove config: sudo rm -rf $(CONFIG_DIR)"

clean:
	@echo "Removing temporary files..."
	@find . -type f -name "*.pyc" -delete
	@find . -type d -name "__pycache__" -delete
	@echo "Clean complete"
