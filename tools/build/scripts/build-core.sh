#!/bin/bash
set -e

# Build script for Wheels Core
# This script creates GitHub artifacts (ZIP files) from the directory prepared by prepare-core.sh
# Usage: ./build-core.sh <version> <branch> <build_number> <is_prerelease>

VERSION=$1
BRANCH=$2
BUILD_NUMBER=$3
IS_PRERELEASE=$4

echo "Building Wheels Core v${VERSION} artifacts from prepared directory"

# Setup directories
BUILD_DIR="build-wheels-core"
EXPORT_DIR="artifacts/wheels/${VERSION}"
BE_EXPORT_DIR="artifacts/wheels"

# Verify that prepare-core.sh has been run
if [ ! -d "${BUILD_DIR}/wheels" ]; then
    echo "ERROR: ${BUILD_DIR}/wheels does not exist!"
    echo "Please run prepare-core.sh first to create the build directory."
    exit 1
fi

# Create export directories
mkdir -p "${EXPORT_DIR}"
mkdir -p "${BE_EXPORT_DIR}"

# Create ZIP file
echo "Creating ZIP package from prepared directory..."
cd "${BUILD_DIR}" && zip -r "../${EXPORT_DIR}/wheels-core-${VERSION}.zip" wheels/ && cd ..

# Generate checksums
echo "Generating checksums..."
cd "${EXPORT_DIR}"
md5sum "wheels-core-${VERSION}.zip" > "wheels-core-${VERSION}.md5"
sha512sum "wheels-core-${VERSION}.zip" > "wheels-core-${VERSION}.sha512"
cd - > /dev/null

# Copy bleeding edge version
echo "Creating bleeding edge version..."
mkdir -p "${BE_EXPORT_DIR}"
cp "${EXPORT_DIR}/wheels-core-${VERSION}.zip" "${BE_EXPORT_DIR}/wheels-core-be.zip"

echo "Wheels Core build completed!"