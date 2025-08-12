#!/bin/bash
set -e

# Build script for Wheels CLI
# Usage: ./build-cli.sh <version> <branch> <build_number> <is_prerelease>

VERSION=$1
BRANCH=$2
BUILD_NUMBER=$3
IS_PRERELEASE=$4

echo "Building Wheels CLI v${VERSION}"

# Setup directories
BUILD_DIR="build-wheels-cli"
EXPORT_DIR="artifacts/wheels/${VERSION}"
BE_EXPORT_DIR="artifacts/wheels"

# Cleanup and create directories
rm -rf "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}/wheels-cli"
mkdir -p "${EXPORT_DIR}"
mkdir -p "${BE_EXPORT_DIR}"

# Create build label file
BUILD_LABEL="wheels-cli-${VERSION}-$(date +%Y%m%d%H%M%S)"
echo "Built on $(date)" > "${BUILD_DIR}/wheels-cli/${BUILD_LABEL}"

# Copy CLI files, excluding specific directories and files
echo "Copying CLI files..."
rsync -av --exclude='workspace' --exclude='simpletestapp' --exclude='*.log' --exclude='.git' --exclude='.gitignore' cli/src/ "${BUILD_DIR}/wheels-cli/"

# Copy template files
cp tools/build/cli/box.json "${BUILD_DIR}/wheels-cli/box.json"
cp tools/build/cli/README.md "${BUILD_DIR}/wheels-cli/README.md"

# Replace version placeholders
echo "Replacing version placeholders..."
find "${BUILD_DIR}/wheels-cli" -type f -name "*.json" -o -name "*.md" -o -name "*.cfm" -o -name "*.cfc" | while read file; do
    sed -i.bak "s/@build\.version@/${VERSION}/g" "$file" && rm "${file}.bak"
done

# Handle build number based on release type
if [ "${IS_PRERELEASE}" = "true" ]; then
    # PreRelease: use build number as-is
    find "${BUILD_DIR}/wheels-cli" -type f -name "*.json" -o -name "*.md" -o -name "*.cfm" -o -name "*.cfc" | while read file; do
        sed -i.bak "s/@build\.number@/${BUILD_NUMBER}/g" "$file" && rm "${file}.bak"
    done
elif [ "${BRANCH}" = "develop" ]; then
    # Snapshot: replace +@build.number@ with -snapshot
    find "${BUILD_DIR}/wheels-cli" -type f -name "*.json" -o -name "*.md" -o -name "*.cfm" -o -name "*.cfc" | while read file; do
        sed -i.bak "s/+@build\.number@/-snapshot/g" "$file" && rm "${file}.bak"
    done
else
    # Regular release: use build number as-is
    find "${BUILD_DIR}/wheels-cli" -type f -name "*.json" -o -name "*.md" -o -name "*.cfm" -o -name "*.cfc" | while read file; do
        sed -i.bak "s/@build\.number@/${BUILD_NUMBER}/g" "$file" && rm "${file}.bak"
    done
fi

# Create ZIP file
echo "Creating ZIP package..."
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