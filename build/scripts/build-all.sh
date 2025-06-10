#!/bin/bash
set -e

# Build all Wheels variants
# Usage: ./build-all.sh [version] [branch] [build_number] [is_prerelease]

# Use provided arguments or defaults
VERSION=${1:-$(cat box.json | jq -r '.version')+999}
BRANCH=${2:-develop}
BUILD_NUMBER=${3:-999}
IS_PRERELEASE=${4:-false}

echo "Building all Wheels variants"
echo "Version: ${VERSION}"
echo "Branch: ${BRANCH}"
echo "Build Number: ${BUILD_NUMBER}"
echo "Is PreRelease: ${IS_PRERELEASE}"
echo "----------------------------"

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Make sure all build scripts are executable
chmod +x "${SCRIPT_DIR}"/*.sh

# Build each variant
echo "Building Core..."
"${SCRIPT_DIR}/build-core.sh" "${VERSION}" "${BRANCH}" "${BUILD_NUMBER}" "${IS_PRERELEASE}"

echo ""
echo "Building Base Template..."
"${SCRIPT_DIR}/build-base.sh" "${VERSION}" "${BRANCH}" "${BUILD_NUMBER}" "${IS_PRERELEASE}"

echo ""
echo "Building CLI..."
"${SCRIPT_DIR}/build-cli.sh" "${VERSION}" "${BRANCH}" "${BUILD_NUMBER}" "${IS_PRERELEASE}"

echo ""
echo "All builds completed successfully!"
echo ""
echo "Artifacts are available in:"
echo "  - artifacts/wheels/${VERSION}/"
echo "  - artifacts/wheels/ (bleeding edge versions)"