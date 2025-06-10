#!/bin/bash
set -e

# Build script for Wheels Base Template
# Usage: ./build-base.sh <version> <branch> <build_number> <is_prerelease>

VERSION=$1
BRANCH=$2
BUILD_NUMBER=$3
IS_PRERELEASE=$4

echo "Building Wheels Base Template v${VERSION}"

# Setup directories
BUILD_DIR="build-wheels-base"
EXPORT_DIR="artifacts/build-wheels-base/${VERSION}"
BE_EXPORT_DIR="artifacts/build-wheels-base"

# Cleanup and create directories
rm -rf "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}"
mkdir -p "${EXPORT_DIR}"
mkdir -p "${BE_EXPORT_DIR}"

# Create build label file
BUILD_LABEL="wheels-base-template-${VERSION}-$(date +%Y%m%d%H%M%S)"
echo "Built on $(date)" > "${BUILD_DIR}/${BUILD_LABEL}"

# Copy base template files
echo "Copying base template files..."
cp -r app "${BUILD_DIR}/"
cp -r public "${BUILD_DIR}/"
cp -r tests "${BUILD_DIR}/"

# Copy vendor directory from build/base if it exists
if [ -d "build/base/vendor" ]; then
    cp -r build/base/vendor "${BUILD_DIR}/"
fi

# Copy template files, overwriting defaults
cp build/base/box.json "${BUILD_DIR}/box.json"
cp build/base/README.md "${BUILD_DIR}/README.md"
cp build/base/server.json "${BUILD_DIR}/server.json"
cp build/base/app/config/app.cfm "${BUILD_DIR}/app/config/app.cfm"
cp build/base/app/config/settings.cfm "${BUILD_DIR}/app/config/settings.cfm"

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
