#!/bin/bash

#
# Build Script for Wheels macOS Swift Installer
#
# This script compiles the Swift GUI installer into a native macOS app
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=========================================================================${NC}"
echo -e "${GREEN}Wheels macOS Installer - Swift Build Script${NC}"
echo -e "${GREEN}=========================================================================${NC}"
echo ""

# Check if Swift is available
if ! command -v swiftc &> /dev/null; then
    echo -e "${RED}ERROR: Swift compiler (swiftc) not found!${NC}"
    echo ""
    echo "Please install Xcode Command Line Tools:"
    echo "  xcode-select --install"
    echo ""
    exit 1
fi

echo -e "${GREEN}✓${NC} Swift compiler found: $(swiftc --version | head -n 1)"

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# Check if Swift source exists
if [[ ! -f "WheelsInstallerApp.swift" ]]; then
    echo -e "${RED}ERROR: WheelsInstallerApp.swift not found!${NC}"
    exit 1
fi

echo -e "${GREEN}✓${NC} Swift source found"

# Check if install script exists
if [[ ! -f "install-wheels" ]]; then
    echo -e "${RED}ERROR: install-wheels not found!${NC}"
    exit 1
fi

# Make install script executable
chmod +x install-wheels

echo -e "${GREEN}✓${NC} Install script found"

# Check if Info.plist exists
if [[ ! -f "Info.plist" ]]; then
    echo -e "${RED}ERROR: Info.plist not found!${NC}"
    exit 1
fi

echo -e "${GREEN}✓${NC} Info.plist found"

# Clean previous build
if [[ -d "installer" ]]; then
    echo "Cleaning previous build..."
    rm -rf installer
fi

mkdir -p installer

# Build the app
echo ""
echo "Building WheelsInstaller.app..."
echo ""

# Compile Swift code
echo "→ Compiling Swift code..."
swiftc -o installer/wheels-installer \
    -target x86_64-apple-macosx10.13 \
    -sdk "$(xcrun --show-sdk-path)" \
    -F "$(xcrun --show-sdk-path)/System/Library/Frameworks" \
    WheelsInstallerApp.swift

if [[ ! -f "installer/wheels-installer" ]]; then
    echo -e "${RED}ERROR: Compilation failed!${NC}"
    exit 1
fi

echo -e "${GREEN}✓${NC} Compilation successful"

# Create app bundle structure
echo "→ Creating app bundle..."
mkdir -p "installer/wheels-installer.app/Contents/MacOS"
mkdir -p "installer/wheels-installer.app/Contents/Resources"

# Copy executable
cp installer/wheels-installer "installer/wheels-installer.app/Contents/MacOS/"
chmod +x "installer/wheels-installer.app/Contents/MacOS/wheels-installer"

# Copy Info.plist
cp Info.plist "installer/wheels-installer.app/Contents/"

# Copy icon if available
ICON_PATH="assets/wheels_logo.icns"
if [[ -f "$ICON_PATH" ]]; then
    cp "$ICON_PATH" "installer/wheels-installer.app/Contents/Resources/wheels_logo.icns"
    echo -e "${GREEN}✓${NC} Icon copied"
else
    echo -e "${YELLOW}⚠${NC}  Icon not found (app will use default icon)"
fi

# Copy install script to Resources
cp install-wheels "installer/wheels-installer.app/Contents/Resources/install-wheels.sh"
chmod +x "installer/wheels-installer.app/Contents/Resources/install-wheels.sh"

echo -e "${GREEN}✓${NC} App bundle created"

# Clean up temporary executable
rm -f installer/wheels-installer

# Code sign (if available)
if command -v codesign &> /dev/null; then
    echo "→ Code signing (ad-hoc)..."
    codesign --force --deep --sign - "installer/wheels-installer.app" 2>/dev/null || echo -e "${YELLOW}⚠${NC}  Code signing skipped"
fi

echo ""
echo -e "${GREEN}=========================================================================${NC}"
echo -e "${GREEN}SUCCESS: Build completed!${NC}"
echo -e "${GREEN}=========================================================================${NC}"
echo ""
echo "Application built at:"
echo "  $(pwd)/installer/wheels-installer.app"
echo ""
echo "You can now:"
echo "  1. Test the app: open installer/wheels-installer.app"
echo "  2. Create DMG: ./create-dmg.sh"
echo ""
