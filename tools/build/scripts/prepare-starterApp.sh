#!/bin/bash
set -e

# Prepare script for Wheels Starter App (ForgeBox publishing)
# This script prepares the directory structure without creating ZIP files
# Usage: ./prepare-starterApp.sh <version> <branch> <build_number> <is_prerelease>

VERSION=$1

echo "Preparing Wheels Starter App v${VERSION} for ForgeBox publishing"

# Setup directories
BUILD_DIR="build-wheels-starterApp"

# Cleanup and create directories
rm -rf "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}"
echo "Current Working Directory"
pwd
echo "Contents of current directory"
ls -la

# Create build label file
BUILD_LABEL="wheels-starter-app-${VERSION}-$(date +%Y%m%d%H%M%S)"
echo "Built on $(date)" > "${BUILD_DIR}/${BUILD_LABEL}"

# Copy Starter App files
echo "Copying Starter App files..."
cp -r examples/starter-app/* "${BUILD_DIR}/"

# Check Copied files
echo "These files were copied"
ls -la "${BUILD_DIR}/"

echo "Wheels Starter App prepared for ForgeBox publishing!"
echo "Directory: ${BUILD_DIR}/"