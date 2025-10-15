#!/bin/bash

#
# Create DMG for Wheels macOS Installer
#
# This script creates a distributable DMG file containing the installer app
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}=========================================================================${NC}"
echo -e "${GREEN}Wheels Installer for macOS - DMG Creator${NC}"
echo -e "${GREEN}=========================================================================${NC}"
echo ""

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# Configuration
APP_NAME="wheels-installer"
DMG_NAME="wheels-installer"
VERSION="1.0.0"

# Check if app exists
if [[ ! -d "installer/wheels-installer.app" ]]; then
    echo -e "${RED}ERROR: wheels-installer.app not found in installer directory!${NC}"
    echo ""
    echo "Please build the app first:"
    echo "  ./build-swift.sh"
    exit 1
fi

echo -e "${GREEN}✓${NC} wheels-installer.app found"

# Create DMG directory
mkdir -p dmg-temp
rm -rf dmg-temp/*

# Copy app to DMG temp directory
echo "Copying wheels-installer.app to DMG staging area..."
cp -R "installer/wheels-installer.app" "dmg-temp/wheels-installer.app"

# Create README for DMG
cat > dmg-temp/README.txt << 'EOF'
Wheels Installer for macOS
===========================

Welcome to the Wheels Application Installer for macOS!

Installation:
1. Double-click wheels-installer.app to start the installation wizard
2. Follow the on-screen instructions
3. The installer will download and install CommandBox and Wheels CLI
4. Your new Wheels application will be created and ready to use!

Requirements:
- macOS 10.13 (High Sierra) or later
- Java 17 or higher (will be auto-installed via Homebrew if not present)
- Internet connection for downloads
- ~1GB free disk space (for CommandBox, Wheels CLI, and application)

Support:
- Documentation: https://wheels.dev
- Guides: https://wheels.dev/guides
- GitHub: https://github.com/wheels-dev/wheels
- Issues: https://github.com/wheels-dev/wheels/issues

Enjoy building with Wheels!
EOF

echo -e "${GREEN}✓${NC} README created"

# Remove existing DMG if it exists
if [[ -f "installer/${DMG_NAME}.dmg" ]]; then
    echo "Removing existing DMG..."
    rm "installer/${DMG_NAME}.dmg"
fi

# Create DMG
echo ""
echo "Creating DMG..."
echo ""

if command -v create-dmg &> /dev/null; then
    # If create-dmg is installed, use it for a nicer DMG
    create-dmg \
        --volname "${APP_NAME}" \
        --window-pos 200 120 \
        --window-size 600 400 \
        --icon-size 100 \
        --app-drop-link 450 150 \
        "installer/${DMG_NAME}.dmg" \
        "dmg-temp/"
else
    # Fallback to hdiutil (built into macOS)
    echo -e "${YELLOW}Note: Using hdiutil (basic DMG). For better DMG, install create-dmg:${NC}"
    echo -e "${YELLOW}  brew install create-dmg${NC}"
    echo ""

    hdiutil create -volname "${APP_NAME}" \
        -srcfolder "dmg-temp" \
        -ov -format UDZO \
        "installer/${DMG_NAME}.dmg"
fi

# Cleanup
echo ""
echo "Cleaning up..."
rm -rf dmg-temp

# Success
echo ""
echo -e "${GREEN}=========================================================================${NC}"
echo -e "${GREEN}SUCCESS: DMG created!${NC}"
echo -e "${GREEN}=========================================================================${NC}"
echo ""
echo "DMG file created at:"
echo "  $(pwd)/installer/${DMG_NAME}.dmg"
echo ""
echo "Size: $(du -h "installer/${DMG_NAME}.dmg" | cut -f1)"
echo ""
echo "You can now distribute this DMG file to users!"
echo ""
