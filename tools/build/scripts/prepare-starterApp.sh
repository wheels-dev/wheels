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
shopt -s dotglob
cp -r examples/starter-app/* "${BUILD_DIR}/"
shopt -u dotglob

# Ship the framework, as `wheels new` does, so the zip runs with
# `wheels start` and no install step. prepare-core.sh has already built the
# version-stamped framework at the release commit into build-wheels-core/wheels.
CORE_DIR="build-wheels-core/wheels"
if [ ! -f "${CORE_DIR}/box.json" ]; then
    echo "ERROR: ${CORE_DIR} is missing; run prepare-core.sh first" >&2
    exit 1
fi
echo "Copying the framework into vendor/wheels..."
rm -rf "${BUILD_DIR}/vendor/wheels"
mkdir -p "${BUILD_DIR}/vendor"
cp -R "${CORE_DIR}" "${BUILD_DIR}/vendor/wheels"

# Stamp the release version, as prepare-base.sh and prepare-core.sh do. The
# source box.json keeps a fixed placeholder version, so without this every
# release published the starter app to ForgeBox as that version (#3908).
echo "Stamping box.json version ${VERSION}..."
jq --arg version "${VERSION}" '.version = $version' "${BUILD_DIR}/box.json" > "${BUILD_DIR}/box.json.tmp"
mv "${BUILD_DIR}/box.json.tmp" "${BUILD_DIR}/box.json"
if [ "$(jq -r '.version' "${BUILD_DIR}/box.json")" != "${VERSION}" ]; then
    echo "ERROR: could not stamp ${BUILD_DIR}/box.json with version ${VERSION}" >&2
    exit 1
fi

# Apache 2.0 §4(a) requires LICENSE in every distributed artifact and §4(d)
# requires NOTICE to propagate to derivatives.
cp LICENSE "${BUILD_DIR}/"
cp NOTICE "${BUILD_DIR}/"

# Ship the CONSUMER AI doc tier into the starter app root and defensively
# strip maintainer-only paths (defense in depth — see prepare-core.sh and
# ship-consumer-docs.sh).
echo "Shipping consumer AI docs..."
./tools/build/scripts/ship-consumer-docs.sh ship "${BUILD_DIR}"

# Check Copied files
echo "These files were copied"
ls -la "${BUILD_DIR}/"

echo "Wheels Starter App prepared for ForgeBox publishing!"
echo "Directory: ${BUILD_DIR}/"