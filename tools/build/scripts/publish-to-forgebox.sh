#!/bin/bash

# Script to publish packages to ForgeBox
# Replaces the pixl8/github-action-box-publish@v4 GitHub action

set -e

# Function to verify package contents before publishing
verify_package_contents() {
    local PACKAGE_DIR=$1
    local PACKAGE_NAME=$2
    
    echo "Verifying package contents for $PACKAGE_NAME..."
    
    # Count files and directories
    local FILE_COUNT=$(find "$PACKAGE_DIR" -type f | wc -l)
    local DIR_COUNT=$(find "$PACKAGE_DIR" -type d | wc -l)
    
    echo "  Files: $FILE_COUNT"
    echo "  Directories: $DIR_COUNT"
    
    # Show first 20 files as sample
    echo "  Sample files:"
    find "$PACKAGE_DIR" -type f | head -20 | sed 's/^/    /'
    
    if [ "$FILE_COUNT" -eq 0 ]; then
        echo "WARNING: No files found in package directory!"
        return 1
    fi
    
    return 0
}

# Function to create a package ZIP manually if needed
create_package_zip() {
    local PACKAGE_DIR=$1
    local PACKAGE_NAME=$2
    local ZIP_NAME=$3
    
    echo "Creating package ZIP manually: $ZIP_NAME"
    
    # Create the ZIP file
    cd "$PACKAGE_DIR"
    zip -r "$ZIP_NAME" . -x "*.git*" -x "*.DS_Store" -x "node_modules/*" -x "workspace/*"
    
    # Show ZIP contents
    echo "ZIP contents:"
    unzip -l "$ZIP_NAME" | head -30
    
    cd - > /dev/null
}

# Function to publish a package to ForgeBox
publish_package() {
    local PACKAGE_NAME=$1
    local PACKAGE_DIR=$2
    local FORGEBOX_USER=$3
    local FORGEBOX_PASS=$4
    local FORCE=$5
    
    echo "=========================================="
    echo "Publishing $PACKAGE_NAME to ForgeBox"
    echo "Directory: $PACKAGE_DIR"
    echo "=========================================="
    
    # Check if directory exists
    if [ ! -d "$PACKAGE_DIR" ]; then
        echo "ERROR: Directory $PACKAGE_DIR does not exist!"
        exit 1
    fi
    
    # Check if box.json exists
    if [ ! -f "$PACKAGE_DIR/box.json" ]; then
        echo "ERROR: box.json not found in $PACKAGE_DIR!"
        exit 1
    fi
    
    # Verify package contents
    if ! verify_package_contents "$PACKAGE_DIR" "$PACKAGE_NAME"; then
        echo "ERROR: Package verification failed!"
        exit 1
    fi
    
    # Change to the package directory
    cd "$PACKAGE_DIR"
    
    # Display box.json for verification
    echo ""
    echo "box.json contents:"
    cat box.json | jq '.'
    echo ""
    
    # Check for directory/package directives in box.json
    if grep -q '"directory"' box.json || grep -q '"package"' box.json; then
        echo "WARNING: box.json contains directory/package directives that might cause issues!"
    fi
    
    # Login to ForgeBox first
    echo "Logging into ForgeBox..."
    box forgebox login username="$FORGEBOX_USER" password="$FORGEBOX_PASS"
    
    if [ $? -ne 0 ]; then
        echo "✗ Failed to login to ForgeBox"
        exit 1
    fi
    echo "✓ Successfully logged into ForgeBox"
    
    # Build the publish command with verbose output
    PUBLISH_CMD="box publish --verbose"
    
    # Add force flag if requested
    if [ "$FORCE" == "true" ]; then
        PUBLISH_CMD="$PUBLISH_CMD --force"
    fi
    
    # Execute the publish command
    echo "Executing: $PUBLISH_CMD"
    $PUBLISH_CMD
    
    # Check if publish was successful
    if [ $? -eq 0 ]; then
        echo "✓ Successfully published $PACKAGE_NAME to ForgeBox"
    else
        echo "✗ Failed to publish $PACKAGE_NAME to ForgeBox"
        # Log out before exiting on error
        box forgebox logout
        exit 1
    fi
    
    # Return to original directory
    cd - > /dev/null
    
    echo ""
}

# Main script
main() {
    # Check if we have the required arguments
    if [ "$#" -lt 2 ]; then
        echo "Usage: $0 <forgebox_user> <forgebox_pass> [force]"
        exit 1
    fi
    
    FORGEBOX_USER=$1
    FORGEBOX_PASS=$2
    FORCE=${3:-false}
    
    # Get the root directory (three levels up from tools/build/scripts)
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    ROOT_DIR="$(cd "$SCRIPT_DIR/../../.." && pwd)"
    
    echo "Publishing packages from: $ROOT_DIR"
    echo ""
    
    # Publish Wheels Base Template
    publish_package "Wheels Base Template" "$ROOT_DIR/build-wheels-base" "$FORGEBOX_USER" "$FORGEBOX_PASS" "$FORCE"
    
    # Publish Wheels Core
    publish_package "Wheels Core" "$ROOT_DIR/build-wheels-core/wheels" "$FORGEBOX_USER" "$FORGEBOX_PASS" "$FORCE"
    
    # Publish Wheels CLI
    publish_package "Wheels CLI" "$ROOT_DIR/build-wheels-cli/wheels-cli" "$FORGEBOX_USER" "$FORGEBOX_PASS" "$FORCE"
    
    publish_package "Wheels Starter App" "$ROOT_DIR/build-wheels-starterApp" "$FORGEBOX_USER" "$FORGEBOX_PASS" "$FORCE"

    # Log out of ForgeBox
    echo "Logging out of ForgeBox..."
    box forgebox logout
    
    echo "=========================================="
    echo "All packages published successfully!"
    echo "=========================================="
}

# Execute main function
main "$@"