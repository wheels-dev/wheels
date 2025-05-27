#!/bin/bash

echo "=== Cleaning up API Server Files ==="
echo ""
echo "This will remove all API server related files since we're no longer using that approach."
echo ""

# List of files to remove
FILES_TO_REMOVE=(
    # API server implementations
    "docker/testui/api-server.js"
    "docker/testui/api-server-v2.js"
    "docker/testui/api-server-final.js"
    "docker/testui/api-server-fixed.js"
    "docker/testui/api-server-host.js"
    "docker/testui/api-server-simple.js"
    "docker/testui/api-server-direct.js"
    "docker/testui/api-server-compose-override.js"
    "docker/testui/api-server-fix-volumes.js"
    "docker/testui/api-server-final-simple.js"
    "docker/testui/api-server-clean.js"
    "docker/testui/api-server-host-paths.js"
    
    # API configuration files
    "docker/testui/api-package.json"
    "docker/testui/Dockerfile.api"
    
    # Test and debugging scripts for API
    "docker/testui/debug-api-container.sh"
    "docker/testui/docker-compose-wrapper.sh"
    "docker/testui/test-connectivity.sh"
    "docker/testui/monitor-logs.sh"
    "docker/testui/run-container-test.sh"
    "docker/testui/fix-and-test.sh"
    "docker/testui/rebuild-and-test.sh"
    "docker/testui/test-lucee5-start.sh"
    "docker/testui/test-container-launch.js"
    
    # Root level fix scripts
    "fix-testui-api.sh"
    "fix-lucee-start.sh"
    "fix-final.sh"
    "restart-api.sh"
    "rebuild-with-host-path.sh"
)

# Change to project root
cd "$(dirname "$0")"

echo "Files to be removed:"
echo "===================="
for file in "${FILES_TO_REMOVE[@]}"; do
    if [ -f "$file" ]; then
        echo "  ✓ $file"
    fi
done

echo ""
read -p "Are you sure you want to remove these files? (y/N) " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    echo "Removing files..."
    for file in "${FILES_TO_REMOVE[@]}"; do
        if [ -f "$file" ]; then
            rm -f "$file"
            echo "  Removed: $file"
        fi
    done
    
    # Also remove any API log directories if they exist
    if [ -d "docker/testui/logs/api" ]; then
        rm -rf "docker/testui/logs/api"
        echo "  Removed: docker/testui/logs/api directory"
    fi
    
    echo ""
    echo "=== Cleanup Complete ==="
    echo ""
    echo "All API server related files have been removed."
    echo "The TestUI now simply shows Docker commands for users to run manually."
else
    echo ""
    echo "Cleanup cancelled."
fi