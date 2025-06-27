#!/bin/bash

# Wheels Docker Test Cleanup Script
# This script cleans up Docker test environments

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default values
KEEP_IMAGES=false
FORCE=false

# Function to display usage
usage() {
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  --keep-images   Don't remove Docker images"
    echo "  --force         Don't prompt for confirmation"
    echo "  -h, --help      Show this help message"
    echo ""
    exit 1
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        --keep-images)
            KEEP_IMAGES=true
            shift
            ;;
        --force)
            FORCE=true
            shift
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo "Unknown option: $1"
            usage
            ;;
    esac
done

# Check if .wheels-test directory exists
if [[ ! -d ".wheels-test" ]]; then
    echo -e "${YELLOW}No test environment found in current directory.${NC}"
    exit 0
fi

# Confirmation prompt
if [[ "$FORCE" != true ]]; then
    echo ""
    echo -e "${YELLOW}This will remove:${NC}"
    echo "  - All test containers"
    echo "  - All test volumes"
    echo "  - The .wheels-test directory"
    if [[ "$KEEP_IMAGES" != true ]]; then
        echo "  - Downloaded Docker images (if not used elsewhere)"
    fi
    echo ""
    read -p "Are you sure you want to clean up? [y/n] " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Cleanup cancelled."
        exit 0
    fi
fi

echo ""
echo -e "${YELLOW}Cleaning up Docker test environment...${NC}"

# Stop and remove containers and volumes
if [[ -f ".wheels-test/docker-compose.yml" ]]; then
    cd .wheels-test
    docker-compose down -v
    cd ..
    echo -e "${GREEN}✓ Containers and volumes removed${NC}"
fi

# Remove images if requested
if [[ "$KEEP_IMAGES" != true && -f ".wheels-test/docker-compose.yml" ]]; then
    # Extract image names from docker-compose.yml
    IMAGES=$(grep -E "^\s*image:" .wheels-test/docker-compose.yml | sed 's/.*image:\s*//' | sort -u)
    
    for IMAGE in $IMAGES; do
        # Skip if it's not a tagged image
        if [[ ! "$IMAGE" == *":"* ]]; then
            continue
        fi
        
        echo "  Removing image: $IMAGE"
        docker rmi "$IMAGE" 2>/dev/null || echo -e "${YELLOW}  Could not remove $IMAGE (may be in use)${NC}"
    done
fi

# Remove .wheels-test directory
if [[ -d ".wheels-test" ]]; then
    rm -rf .wheels-test
    echo -e "${GREEN}✓ .wheels-test directory removed${NC}"
fi

echo ""
echo -e "${GREEN}✓ Docker test environment cleaned up successfully!${NC}"