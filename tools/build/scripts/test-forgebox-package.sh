#!/bin/bash

# Script to test ForgeBox packaging locally without publishing
# This helps diagnose issues with empty packages

set -e

# Function to test package creation
test_package() {
    local PACKAGE_NAME=$1
    local PACKAGE_DIR=$2
    
    echo "=========================================="
    echo "Testing package: $PACKAGE_NAME"
    echo "Directory: $PACKAGE_DIR"
    echo "=========================================="
    
    # Check if directory exists
    if [ ! -d "$PACKAGE_DIR" ]; then
        echo "ERROR: Directory $PACKAGE_DIR does not exist!"
        return 1
    fi
    
    # Check if box.json exists
    if [ ! -f "$PACKAGE_DIR/box.json" ]; then
        echo "ERROR: box.json not found in $PACKAGE_DIR!"
        return 1
    fi
    
    # Change to the package directory
    cd "$PACKAGE_DIR"
    
    # Display box.json
    echo "box.json contents:"
    cat box.json | jq '.' || cat box.json
    echo ""
    
    # Check for problematic directives
    echo "Checking for problematic directives..."
    if grep -q '"directory"' box.json; then
        echo "  ⚠️  Found 'directory' directive in box.json"
    fi
    if grep -q '"package"' box.json; then
        echo "  ⚠️  Found 'package' directive in box.json"
    fi
    
    # Count files
    echo ""
    echo "Package contents:"
    local FILE_COUNT=$(find . -type f -not -path "./.git/*" | wc -l)
    local DIR_COUNT=$(find . -type d -not -path "./.git/*" | wc -l)
    echo "  Total files: $FILE_COUNT"
    echo "  Total directories: $DIR_COUNT"
    
    # Show directory structure
    echo ""
    echo "Directory structure (first 3 levels):"
    find . -type d -not -path "./.git/*" | head -20 | sort
    
    # Show sample files
    echo ""
    echo "Sample files:"
    find . -type f -not -path "./.git/*" | head -20 | sort
    
    # Test package creation with CommandBox
    echo ""
    echo "Testing CommandBox package creation..."
    
    # Create a test package without publishing
    local TEST_ZIP="${PACKAGE_NAME//[[:space:]]/-}-test.zip"
    echo "Creating test package: $TEST_ZIP"
    
    # Use box package command to create the ZIP
    box package set name="test-$PACKAGE_NAME"
    box package build --zip="$TEST_ZIP"
    
    if [ -f "$TEST_ZIP" ]; then
        echo "✓ Test package created successfully"
        
        # Check ZIP contents
        echo ""
        echo "ZIP file contents (first 30 files):"
        unzip -l "$TEST_ZIP" | head -35
        
        # Count files in ZIP
        local ZIP_FILE_COUNT=$(unzip -l "$TEST_ZIP" | grep -v "Archive:" | grep -v "Length" | grep -v "--------" | wc -l)
        echo ""
        echo "Files in ZIP: $ZIP_FILE_COUNT"
        
        # Clean up test ZIP
        rm -f "$TEST_ZIP"
    else
        echo "✗ Failed to create test package"
    fi
    
    # Return to original directory
    cd - > /dev/null
    
    echo ""
    echo "=========================================="
    echo ""
}

# Main script
main() {
    # Get the root directory (three levels up from tools/build/scripts)
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    ROOT_DIR="$(cd "$SCRIPT_DIR/../../.." && pwd)"
    
    echo "Testing ForgeBox packaging from: $ROOT_DIR"
    echo ""
    
    # Check if CommandBox is installed
    if ! command -v box &> /dev/null; then
        echo "ERROR: CommandBox is not installed!"
        echo "Please install CommandBox first: https://www.ortussolutions.com/products/commandbox"
        exit 1
    fi
    
    # Test each package
    test_package "Wheels Base Template" "$ROOT_DIR/build-wheels-base"
    test_package "Wheels Core" "$ROOT_DIR/build-wheels-core/wheels"
    test_package "Wheels CLI" "$ROOT_DIR/build-wheels-cli/wheels-cli"
    
    echo "Package testing complete!"
}

# Execute main function
main "$@"