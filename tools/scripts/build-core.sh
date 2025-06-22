#!/bin/bash
set -e

# Build script for Wheels Core
# Usage: ./build-core.sh <version> <branch> <build_number> <is_prerelease>

VERSION=$1
BRANCH=$2
BUILD_NUMBER=$3
IS_PRERELEASE=$4

echo "Building Wheels Core v${VERSION}"

# Setup directories
BUILD_DIR="build-wheels-core"
EXPORT_DIR="artifacts/wheels/${VERSION}"
BE_EXPORT_DIR="artifacts/wheels"

# Cleanup and create directories
rm -rf "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}/wheels"
mkdir -p "${EXPORT_DIR}"
mkdir -p "${BE_EXPORT_DIR}"

# Create build label file
BUILD_LABEL="wheels-core-${VERSION}-$(date +%Y%m%d%H%M%S)"
echo "Built on $(date)" > "${BUILD_DIR}/wheels/${BUILD_LABEL}"

# Copy core files
echo "Copying core files..."
cp -r vendor/wheels/* "${BUILD_DIR}/wheels/"

# Copy template files
cp build/core/box.json "${BUILD_DIR}/wheels/box.json"
cp build/core/README.md "${BUILD_DIR}/wheels/README.md"

# Replace version placeholders
echo "Replacing version placeholders..."
find "${BUILD_DIR}/wheels" -type f -name "*.json" -o -name "*.md" -o -name "*.cfm" -o -name "*.cfc" | while read file; do
    sed -i.bak "s/@build\.version@/${VERSION}/g" "$file" && rm "${file}.bak"
done

# Handle build number based on release type
if [ "${IS_PRERELEASE}" = "true" ]; then
    # PreRelease: use build number as-is
    find "${BUILD_DIR}/wheels" -type f -name "*.json" -o -name "*.md" -o -name "*.cfm" -o -name "*.cfc" | while read file; do
        sed -i.bak "s/@build\.number@/${BUILD_NUMBER}/g" "$file" && rm "${file}.bak"
    done
elif [ "${BRANCH}" = "develop" ]; then
    # Snapshot: replace +@build.number@ with -snapshot
    find "${BUILD_DIR}/wheels" -type f -name "*.json" -o -name "*.md" -o -name "*.cfm" -o -name "*.cfc" | while read file; do
        sed -i.bak "s/+@build\.number@/-snapshot/g" "$file" && rm "${file}.bak"
    done
else
    # Regular release: use build number as-is
    find "${BUILD_DIR}/wheels" -type f -name "*.json" -o -name "*.md" -o -name "*.cfm" -o -name "*.cfc" | while read file; do
        sed -i.bak "s/@build\.number@/${BUILD_NUMBER}/g" "$file" && rm "${file}.bak"
    done
fi

# Create ZIP file
echo "Creating ZIP package..."
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