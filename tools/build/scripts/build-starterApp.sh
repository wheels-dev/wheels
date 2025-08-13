#!/bin/bash
set -e

# Build script for Wheels Starter App
# Usage: ./build-base.sh <version> <branch> <build_number> <is_prerelease>

VERSION=$1

echo "Building Wheels Starter App v${VERSION}"

# Setup directories
BUILD_DIR="build-wheels-starterApp"
EXPORT_DIR="artifacts/wheels/${VERSION}"
BE_EXPORT_DIR="artifacts/wheels"

# Cleanup and create directories
rm -rf "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}"
mkdir -p "${EXPORT_DIR}"
mkdir -p "${BE_EXPORT_DIR}"

# Create build label file
BUILD_LABEL="wheels-starter-app-${VERSION}-$(date +%Y%m%d%H%M%S)"
echo "Built on $(date)" > "${BUILD_DIR}/${BUILD_LABEL}"

# Copy Starter App files
echo "Copying Starter App files..."
cp -r examples/starter-app "${BUILD_DIR}/"

# Create ZIP file
echo "Creating ZIP package..."
cd "${BUILD_DIR}" && zip -r "../${EXPORT_DIR}/wheels-starter-app-${VERSION}.zip" ./ && cd ..

# Generate checksums
echo "Generating checksums..."
cd "${EXPORT_DIR}"
md5sum "wheels-starter-app-${VERSION}.zip" > "wheels-starter-app-${VERSION}.md5"
sha512sum "wheels-starter-app-${VERSION}.zip" > "wheels-starter-app-${VERSION}.sha512"
cd - > /dev/null

# Copy bleeding edge version
echo "Creating bleeding edge version..."
mkdir -p "${BE_EXPORT_DIR}"
cp "${EXPORT_DIR}/wheels-starter-app-${VERSION}.zip" "${BE_EXPORT_DIR}/wheels-starter-app-be.zip"

echo "Wheels Starter App build completed!"
