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
    local MARK_STABLE=$6

    echo "=========================================="
    echo "Publishing $PACKAGE_NAME to ForgeBox"
    echo "Directory: $PACKAGE_DIR"
    echo "Mark as Stable: $MARK_STABLE"
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

    # Note: ForgeBox automatically determines version stability based on semver rules
    # Versions with pre-release identifiers (-rc, -beta, -SNAPSHOT) are never "stable"
    # Only versions without pre-release identifiers (e.g., 3.0.0) are marked as stable/current
    if [ "$MARK_STABLE" == "true" ]; then
        echo "Note: MARK_STABLE parameter is set, but ForgeBox automatically determines"
        echo "      version stability based on semantic versioning rules:"
        echo "      - Versions like '3.0.0-rc.1' are pre-release (not default)"
        echo "      - Versions like '3.0.0' are stable (default for installation)"
        echo "      - Pre-release versions must be explicitly specified when installing"
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
        echo "Usage: $0 <forgebox_user> <forgebox_pass> [force] [mark_stable]"
        echo ""
        echo "Arguments:"
        echo "  forgebox_user  - ForgeBox username"
        echo "  forgebox_pass  - ForgeBox password"
        echo "  force          - Force publish (true/false, default: false)"
        echo "  mark_stable    - Mark version as stable/current (true/false, default: false)"
        echo ""
        echo "Examples:"
        echo "  $0 myuser mypass                    # Basic publish"
        echo "  $0 myuser mypass true               # Force publish"
        echo "  $0 myuser mypass true true          # Force publish and mark stable"
        exit 1
    fi

    FORGEBOX_USER=$1
    FORGEBOX_PASS=$2
    FORCE=${3:-false}
    MARK_STABLE=${4:-false}

    # Get the root directory (three levels up from tools/build/scripts)
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    ROOT_DIR="$(cd "$SCRIPT_DIR/../../.." && pwd)"

    echo "=========================================="
    echo "ForgeBox Publishing Configuration"
    echo "=========================================="
    echo "Publishing packages from: $ROOT_DIR"
    echo "Force publish: $FORCE"
    echo "Mark as stable: $MARK_STABLE"
    echo ""

    # Publish Wheels Base Template
    publish_package "Wheels Base Template" "$ROOT_DIR/build-wheels-base" "$FORGEBOX_USER" "$FORGEBOX_PASS" "$FORCE" "$MARK_STABLE"

    # Publish Wheels Core
    publish_package "Wheels Core" "$ROOT_DIR/build-wheels-core/wheels" "$FORGEBOX_USER" "$FORGEBOX_PASS" "$FORCE" "$MARK_STABLE"

    # Publish Wheels CLI
    publish_package "Wheels CLI" "$ROOT_DIR/build-wheels-cli/wheels-cli" "$FORGEBOX_USER" "$FORGEBOX_PASS" "$FORCE" "$MARK_STABLE"

    # Publish Wheels Starter App
    publish_package "Wheels Starter App" "$ROOT_DIR/build-wheels-starterApp" "$FORGEBOX_USER" "$FORGEBOX_PASS" "$FORCE" "$MARK_STABLE"

    # Log out of ForgeBox
    echo "Logging out of ForgeBox..."
    box forgebox logout

    echo "=========================================="
    echo "All packages published successfully!"
    echo "=========================================="
}

# Execute main function
main "$@"