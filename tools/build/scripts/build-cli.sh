#!/bin/bash
set -e

# Build script for Wheels CLI
# This script creates GitHub artifacts (ZIP files) from the directory prepared by prepare-cli.sh
# Usage: ./build-cli.sh <version> <branch> <build_number> <is_prerelease>

VERSION=$1
BRANCH=$2
BUILD_NUMBER=$3
IS_PRERELEASE=$4

echo "Building Wheels CLI v${VERSION} artifacts from prepared directory"

# Setup directories
BUILD_DIR="build-wheels-cli"
EXPORT_DIR="artifacts/wheels/${VERSION}"
BE_EXPORT_DIR="artifacts/wheels"

# Verify that prepare-cli.sh has been run
if [ ! -d "${BUILD_DIR}/wheels-cli" ]; then
    echo "ERROR: ${BUILD_DIR}/wheels-cli does not exist!"
    echo "Please run prepare-cli.sh first to create the build directory."
    exit 1
fi

# Create export directories
mkdir -p "${EXPORT_DIR}"
mkdir -p "${BE_EXPORT_DIR}"

# Create ZIP file
echo "Creating ZIP package from prepared directory..."
cd "${BUILD_DIR}" && zip -r "../${EXPORT_DIR}/wheels-cli-${VERSION}.zip" wheels-cli/ && cd ..

# Generate checksums
echo "Generating checksums..."
cd "${EXPORT_DIR}"
md5sum "wheels-cli-${VERSION}.zip" > "wheels-cli-${VERSION}.md5"
sha512sum "wheels-cli-${VERSION}.zip" > "wheels-cli-${VERSION}.sha512"
cd - > /dev/null

# Copy bleeding edge version
echo "Creating bleeding edge version..."
mkdir -p "${BE_EXPORT_DIR}"
cp "${EXPORT_DIR}/wheels-cli-${VERSION}.zip" "${BE_EXPORT_DIR}/wheels-cli-be.zip"

echo "Wheels CLI build completed!"