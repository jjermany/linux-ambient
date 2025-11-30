#!/bin/bash
# Build Debian package for Ambient Brightness Control

set -e

PACKAGE_NAME="ambient-brightness"
VERSION="1.0.0"
ARCH="all"
BUILD_DIR="build/${PACKAGE_NAME}_${VERSION}_${ARCH}"

echo "========================================="
echo "Building Debian Package"
echo "========================================="
echo ""
echo "Package: $PACKAGE_NAME"
echo "Version: $VERSION"
echo "Architecture: $ARCH"
echo ""

# Clean previous build
if [ -d "build" ]; then
    echo "Cleaning previous build..."
    rm -rf build
fi

# Create package directory structure
echo "Creating package structure..."
mkdir -p "$BUILD_DIR/DEBIAN"
mkdir -p "$BUILD_DIR/usr/bin"
mkdir -p "$BUILD_DIR/usr/share/applications"
mkdir -p "$BUILD_DIR/usr/share/doc/$PACKAGE_NAME"
mkdir -p "$BUILD_DIR/etc/xdg/autostart"
mkdir -p "$BUILD_DIR/lib/systemd/user"

# Copy control files
echo "Copying package metadata..."
cp debian/control "$BUILD_DIR/DEBIAN/"
cp debian/postinst "$BUILD_DIR/DEBIAN/"
cp debian/prerm "$BUILD_DIR/DEBIAN/"
cp debian/postrm "$BUILD_DIR/DEBIAN/"
chmod 755 "$BUILD_DIR/DEBIAN/postinst"
chmod 755 "$BUILD_DIR/DEBIAN/prerm"
chmod 755 "$BUILD_DIR/DEBIAN/postrm"

# Copy application files
echo "Copying application files..."
cp ambient_brightness.py "$BUILD_DIR/usr/bin/"
cp ambient_brightness_gui.py "$BUILD_DIR/usr/bin/ambient-brightness-gui"
chmod 755 "$BUILD_DIR/usr/bin/ambient_brightness.py"
chmod 755 "$BUILD_DIR/usr/bin/ambient-brightness-gui"

# Copy desktop files
echo "Copying desktop entries..."
cp ambient-brightness-settings.desktop "$BUILD_DIR/usr/share/applications/"
cp ambient-brightness-tray.desktop "$BUILD_DIR/etc/xdg/autostart/"

# Copy systemd service (user service)
echo "Copying systemd service..."
cp ambient-brightness.service "$BUILD_DIR/lib/systemd/user/"

# Copy documentation
echo "Copying documentation..."
if [ -f README.md ]; then
    cp README.md "$BUILD_DIR/usr/share/doc/$PACKAGE_NAME/"
fi
if [ -f LICENSE ]; then
    cp LICENSE "$BUILD_DIR/usr/share/doc/$PACKAGE_NAME/"
fi
if [ -f config.conf.example ]; then
    cp config.conf.example "$BUILD_DIR/usr/share/doc/$PACKAGE_NAME/"
fi

# Create changelog
cat > "$BUILD_DIR/usr/share/doc/$PACKAGE_NAME/changelog" << EOF
ambient-brightness (${VERSION}) stable; urgency=low

  * Initial Debian package release
  * Automatic brightness control for Linux
  * GUI application with system tray integration
  * Support for ambient light sensors and camera fallback
  * User systemd service integration

 -- linux-ambient <https://github.com/jjermany/linux-ambient>  $(date -R)
EOF
gzip -9 "$BUILD_DIR/usr/share/doc/$PACKAGE_NAME/changelog"

# Calculate installed size
INSTALLED_SIZE=$(du -sk "$BUILD_DIR" | cut -f1)
echo "Installed-Size: $INSTALLED_SIZE" >> "$BUILD_DIR/DEBIAN/control"

# Build the package
echo ""
echo "Building package..."
dpkg-deb --build "$BUILD_DIR"

# Move to root directory
mv "build/${PACKAGE_NAME}_${VERSION}_${ARCH}.deb" .

echo ""
echo "========================================="
echo "Package built successfully!"
echo "========================================="
echo ""
echo "Package file: ${PACKAGE_NAME}_${VERSION}_${ARCH}.deb"
echo "Size: $(ls -lh ${PACKAGE_NAME}_${VERSION}_${ARCH}.deb | awk '{print $5}')"
echo ""
echo "To install:"
echo "  sudo dpkg -i ${PACKAGE_NAME}_${VERSION}_${ARCH}.deb"
echo "  sudo apt-get install -f  # Install dependencies if needed"
echo ""
echo "Or double-click the .deb file in your file manager to install via Software Center"
echo ""
