#!/bin/bash

echo "=== Rebuilding TestUI (Without API Server) ==="
echo ""

# Get project directory
PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$PROJECT_DIR"

# Stop any running API containers
echo "1. Stopping any API containers..."
docker rm -f cfwheels-test-suite-testui-api-1 2>/dev/null || true

# Stop UI containers
echo "2. Stopping UI containers..."
docker compose --profile ui down

# Rebuild testui only
echo "3. Rebuilding TestUI..."
docker compose build testui

# Start UI service only
echo "4. Starting TestUI..."
docker compose up -d testui

# Wait for service
echo "5. Waiting for TestUI to start..."
sleep 5

# Check status
echo "6. Container status:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep testui || echo "TestUI not found"

echo ""
echo "=== Setup Complete ==="
echo ""
echo "The TestUI is now running at http://localhost:3000"
echo ""
echo "When you click on a stopped engine or database, it will show the Docker command"
echo "to start it and copy it to your clipboard."
echo ""
echo "Example commands:"
echo "  docker compose up -d lucee5"
echo "  docker compose up -d mysql"
echo "  docker compose up -d postgres"
echo ""
echo "To start all engines: docker compose --profile lucee up -d"
echo "To start all databases: docker compose --profile db up -d"