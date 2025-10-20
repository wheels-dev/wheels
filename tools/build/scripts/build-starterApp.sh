#!/bin/bash
set -e

# Build script for Wheels Starter App
# This script creates GitHub artifacts (ZIP files) from the directory prepared by prepare-starterApp.sh
# Usage: ./build-starterApp.sh <version>

VERSION=$1

echo "Building Wheels Starter App v${VERSION} artifacts from prepared directory"

# Setup directories
BUILD_DIR="build-wheels-starterApp"
EXPORT_DIR="artifacts/wheels/${VERSION}"
BE_EXPORT_DIR="artifacts/wheels"

# Verify that prepare-starterApp.sh has been run
if [ ! -d "${BUILD_DIR}" ]; then
    echo "ERROR: ${BUILD_DIR} does not exist!"
    echo "Please run prepare-starterApp.sh first to create the build directory."
    exit 1
fi

# Create export directories
mkdir -p "${EXPORT_DIR}"
mkdir -p "${BE_EXPORT_DIR}"

# Create ZIP file
echo "Creating ZIP package from prepared directory..."
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
