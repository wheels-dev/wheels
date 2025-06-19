#!/bin/bash
set -e

# Prepare script for Wheels Core (ForgeBox publishing)
# This script prepares the directory structure without creating ZIP files
# Usage: ./prepare-core.sh <version> <branch> <build_number> <is_prerelease>

VERSION=$1
BRANCH=$2
BUILD_NUMBER=$3
IS_PRERELEASE=$4

echo "Preparing Wheels Core v${VERSION} for ForgeBox publishing"

# Setup directories
BUILD_DIR="build-wheels-core"

# Cleanup and create directories
rm -rf "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}/wheels"

# Create build label file
BUILD_LABEL="wheels-core-${VERSION}-$(date +%Y%m%d%H%M%S)"
echo "Built on $(date)" > "${BUILD_DIR}/wheels/${BUILD_LABEL}"

# Copy core files
echo "Copying core files..."
cp -r vendor/wheels/* "${BUILD_DIR}/wheels/"

# Copy template files
cp build/core/box.json "${BUILD_DIR}/wheels/box.json"
cp build/core/README.md "${BUILD_DIR}/wheels/README.md"

# Update box.json for ForgeBox publishing
echo "Adjusting box.json for ForgeBox..."
if command -v jq >/dev/null 2>&1; then
    # Update directory settings for proper packaging
    # Set directory to empty string so ForgeBox packages all files in current directory
    jq '.directory = "" | del(.packageDirectory) | .createPackageDirectory = false' "${BUILD_DIR}/wheels/box.json" > "${BUILD_DIR}/wheels/box.json.tmp" && mv "${BUILD_DIR}/wheels/box.json.tmp" "${BUILD_DIR}/wheels/box.json"
else
    # Fallback to sed if jq is not available
    sed -i.bak 's/"directory"[[:space:]]*:[[:space:]]*"[^"]*"/"directory":""/' "${BUILD_DIR}/wheels/box.json"
    sed -i.bak 's/"createPackageDirectory"[[:space:]]*:[[:space:]]*true/"createPackageDirectory":false/' "${BUILD_DIR}/wheels/box.json"
    sed -i.bak '/"packageDirectory":/d' "${BUILD_DIR}/wheels/box.json"
    rm -f "${BUILD_DIR}/wheels/box.json.bak"
fi

# Replace version placeholders
echo "Replacing version placeholders..."
find "${BUILD_DIR}/wheels" -type f \( -name "*.json" -o -name "*.md" -o -name "*.cfm" -o -name "*.cfc" \) | while read file; do
    sed -i.bak "s/@build\.version@/${VERSION}/g" "$file" && rm "${file}.bak"
done

# Handle build number based on release type
if [ "${IS_PRERELEASE}" = "true" ]; then
    # PreRelease: use build number as-is
    find "${BUILD_DIR}/wheels" -type f \( -name "*.json" -o -name "*.md" -o -name "*.cfm" -o -name "*.cfc" \) | while read file; do
        sed -i.bak "s/@build\.number@/${BUILD_NUMBER}/g" "$file" && rm "${file}.bak"
    done
elif [ "${BRANCH}" = "develop" ]; then
    # Snapshot: replace +@build.number@ with -snapshot
    find "${BUILD_DIR}/wheels" -type f \( -name "*.json" -o -name "*.md" -o -name "*.cfm" -o -name "*.cfc" \) | while read file; do
        sed -i.bak "s/+@build\.number@/-snapshot/g" "$file" && rm "${file}.bak"
    done
else
    # Regular release: use build number as-is
    find "${BUILD_DIR}/wheels" -type f \( -name "*.json" -o -name "*.md" -o -name "*.cfm" -o -name "*.cfc" \) | while read file; do
        sed -i.bak "s/@build\.number@/${BUILD_NUMBER}/g" "$file" && rm "${file}.bak"
    done
fi

echo "Wheels Core prepared for ForgeBox publishing!"
echo "Directory: ${BUILD_DIR}/wheels/"