#!/bin/bash
set -e

# Build script for Wheels Base Template
# This script creates GitHub artifacts (ZIP files) from the directory prepared by prepare-base.sh
# Usage: ./build-base.sh <version> <branch> <build_number> <is_prerelease>

VERSION=$1
BRANCH=$2
BUILD_NUMBER=$3
IS_PRERELEASE=$4

echo "Building Wheels Base Template v${VERSION} artifacts from prepared directory"

# Setup directories
BUILD_DIR="build-wheels-base"
EXPORT_DIR="artifacts/wheels/${VERSION}"
BE_EXPORT_DIR="artifacts/wheels"

# Verify that prepare-base.sh has been run
if [ ! -d "${BUILD_DIR}" ]; then
    echo "ERROR: ${BUILD_DIR} does not exist!"
    echo "Please run prepare-base.sh first to create the build directory."
    exit 1
fi

# Create export directories
mkdir -p "${EXPORT_DIR}"
mkdir -p "${BE_EXPORT_DIR}"

# Create ZIP file
echo "Creating ZIP package from prepared directory..."
cd "${BUILD_DIR}" && zip -r "../${EXPORT_DIR}/wheels-base-template-${VERSION}.zip" ./ && cd ..

# Generate checksums
echo "Generating checksums..."
cd "${EXPORT_DIR}"
md5sum "wheels-base-template-${VERSION}.zip" > "wheels-base-template-${VERSION}.md5"
sha512sum "wheels-base-template-${VERSION}.zip" > "wheels-base-template-${VERSION}.sha512"
cd - > /dev/null

# Copy bleeding edge version
echo "Creating bleeding edge version..."
mkdir -p "${BE_EXPORT_DIR}"
cp "${EXPORT_DIR}/wheels-base-template-${VERSION}.zip" "${BE_EXPORT_DIR}/wheels-base-template-be.zip"

echo "Wheels Base Template build completed!"
