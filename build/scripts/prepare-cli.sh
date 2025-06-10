#!/bin/bash
set -e

# Prepare script for Wheels CLI (ForgeBox publishing)
# This script prepares the directory structure without creating ZIP files
# Usage: ./prepare-cli.sh <version> <branch> <build_number> <is_prerelease>

VERSION=$1
BRANCH=$2
BUILD_NUMBER=$3
IS_PRERELEASE=$4

echo "Preparing Wheels CLI v${VERSION} for ForgeBox publishing"

# Setup directories
BUILD_DIR="build-wheels-cli"

# Cleanup and create directories
rm -rf "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}/wheels-cli"

# Create build label file
BUILD_LABEL="wheels-cli-${VERSION}-$(date +%Y%m%d%H%M%S)"
echo "Built on $(date)" > "${BUILD_DIR}/wheels-cli/${BUILD_LABEL}"

# Copy CLI files, excluding specific directories and files
echo "Copying CLI files..."
rsync -av --exclude='workspace' --exclude='simpletestapp' --exclude='*.log' --exclude='.git' --exclude='.gitignore' cli/ "${BUILD_DIR}/wheels-cli/"

# Copy template files
cp build/cli/box.json "${BUILD_DIR}/wheels-cli/box.json"
cp build/cli/README.md "${BUILD_DIR}/wheels-cli/README.md"

# Remove directory packaging directives that confuse ForgeBox
echo "Adjusting box.json for ForgeBox..."
if command -v jq >/dev/null 2>&1; then
    jq 'del(.directory, .packageDirectory, .createPackageDirectory)' "${BUILD_DIR}/wheels-cli/box.json" > "${BUILD_DIR}/wheels-cli/box.json.tmp" && mv "${BUILD_DIR}/wheels-cli/box.json.tmp" "${BUILD_DIR}/wheels-cli/box.json"
else
    # Fallback to sed if jq is not available
    sed -i.bak '/"directory":/d; /"packageDirectory":/d; /"createPackageDirectory":/d' "${BUILD_DIR}/wheels-cli/box.json" && rm "${BUILD_DIR}/wheels-cli/box.json.bak"
fi

# Replace version placeholders
echo "Replacing version placeholders..."
find "${BUILD_DIR}/wheels-cli" -type f \( -name "*.json" -o -name "*.md" -o -name "*.cfm" -o -name "*.cfc" \) | while read file; do
    sed -i.bak "s/@build\.version@/${VERSION}/g" "$file" && rm "${file}.bak"
done

# Handle build number based on release type
if [ "${IS_PRERELEASE}" = "true" ]; then
    # PreRelease: use build number as-is
    find "${BUILD_DIR}/wheels-cli" -type f \( -name "*.json" -o -name "*.md" -o -name "*.cfm" -o -name "*.cfc" \) | while read file; do
        sed -i.bak "s/@build\.number@/${BUILD_NUMBER}/g" "$file" && rm "${file}.bak"
    done
elif [ "${BRANCH}" = "develop" ]; then
    # Snapshot: replace +@build.number@ with -snapshot
    find "${BUILD_DIR}/wheels-cli" -type f \( -name "*.json" -o -name "*.md" -o -name "*.cfm" -o -name "*.cfc" \) | while read file; do
        sed -i.bak "s/+@build\.number@/-snapshot/g" "$file" && rm "${file}.bak"
    done
else
    # Regular release: use build number as-is
    find "${BUILD_DIR}/wheels-cli" -type f \( -name "*.json" -o -name "*.md" -o -name "*.cfm" -o -name "*.cfc" \) | while read file; do
        sed -i.bak "s/@build\.number@/${BUILD_NUMBER}/g" "$file" && rm "${file}.bak"
    done
fi

echo "Wheels CLI prepared for ForgeBox publishing!"
echo "Directory: ${BUILD_DIR}/wheels-cli/"