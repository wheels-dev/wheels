#!/bin/bash
set -e

# Prepare script for Wheels Base Template (ForgeBox publishing)
# This script prepares the directory structure without creating ZIP files
# Usage: ./prepare-base.sh <version> <branch> <build_number> <is_prerelease>

VERSION=$1
BRANCH=$2
BUILD_NUMBER=$3
IS_PRERELEASE=$4

echo "Preparing Wheels Base Template v${VERSION} for ForgeBox publishing"

# Setup directories
BUILD_DIR="build-wheels-base"

# Cleanup and create directories
rm -rf "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}"
echo "Current Working Directory"
pwd
echo "Contents of current directory"
ls -la

# Create build label file
BUILD_LABEL="wheels-base-template-${VERSION}-$(date +%Y%m%d%H%M%S)"
echo "Built on $(date)" > "${BUILD_DIR}/${BUILD_LABEL}"

# Copy base template files
echo "Copying base template files..."
cp -r templates/base/src/app "${BUILD_DIR}/"
cp -r templates/base/src/config "${BUILD_DIR}/"
cp -r templates/base/src/db "${BUILD_DIR}/"
cp -r templates/base/src/plugins "${BUILD_DIR}/"
cp -r templates/base/src/public "${BUILD_DIR}/"
cp -r templates/base/src/tests "${BUILD_DIR}/"
cp -r templates/base/src/vendor "${BUILD_DIR}/"

# Copy AI documentation files
echo "Copying AI documentation..."
cp -r .ai "${BUILD_DIR}/"
cp templates/base/src/CLAUDE.md "${BUILD_DIR}/"
cp templates/base/src/AGENTS.md "${BUILD_DIR}/"
cp -r .claude "${BUILD_DIR}/"
cp -r .opencode "${BUILD_DIR}/"

# Copy Apache License how are you?
cp LICENSE "${BUILD_DIR}/"

# Copy VS Code snippets
echo "Copying VS Code snippets..."
mkdir -p "${BUILD_DIR}/.vscode"
cp .vscode/wheels.code-snippets "${BUILD_DIR}/.vscode/"
cp .vscode/wheels-test.code-snippets "${BUILD_DIR}/.vscode/"

# Copy template files, overwriting defaults
cp tools/build/base/.gitignore "${BUILD_DIR}/.gitignore"
cp tools/build/base/box.json "${BUILD_DIR}/box.json"
cp tools/build/base/README.md "${BUILD_DIR}/README.md"
cp tools/build/base/server.json "${BUILD_DIR}/server.json"
cp tools/build/base/config/app.cfm "${BUILD_DIR}/config/app.cfm"
cp tools/build/base/config/settings.cfm "${BUILD_DIR}/config/settings.cfm"

# Copy .env file
cp .env "${BUILD_DIR}/.env"

# Replace version placeholders
echo "Replacing version placeholders..."
find "${BUILD_DIR}" -type f \( -name "*.json" -o -name "*.md" -o -name "*.cfm" -o -name "*.cfc" \) | while read file; do
    sed -i.bak "s/@build\.version@/${VERSION}/g" "$file" && rm "${file}.bak"
    sed -i.bak "s/\${VERSION_NUMBER}/${VERSION}/g" "$file" && rm "${file}.bak"
done

# Handle build number based on release type
if [ "${IS_PRERELEASE}" = "true" ]; then
    # PreRelease: use build number as-is
    find "${BUILD_DIR}" -type f \( -name "*.json" -o -name "*.md" -o -name "*.cfm" -o -name "*.cfc" \) | while read file; do
        sed -i.bak "s/@build\.number@/${BUILD_NUMBER}/g" "$file" && rm "${file}.bak"
    done
elif [ "${BRANCH}" = "develop" ]; then
    # Snapshot: replace +@build.number@ with -snapshot
    find "${BUILD_DIR}" -type f \( -name "*.json" -o -name "*.md" -o -name "*.cfm" -o -name "*.cfc" \) | while read file; do
        sed -i.bak "s/+@build\.number@/-snapshot/g" "$file" && rm "${file}.bak"
    done
else
    # Regular release: use build number as-is
    find "${BUILD_DIR}" -type f \( -name "*.json" -o -name "*.md" -o -name "*.cfm" -o -name "*.cfc" \) | while read file; do
        sed -i.bak "s/@build\.number@/${BUILD_NUMBER}/g" "$file" && rm "${file}.bak"
    done
fi

echo "Wheels Base Template prepared for ForgeBox publishing!"
echo "Directory: ${BUILD_DIR}/"
cd "${BUILD_DIR}/"
pwd
