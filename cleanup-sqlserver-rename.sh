#!/bin/bash

echo "=== Cleaning up SQL Server rename from sqlserver_cicd to sqlserver ==="
echo ""

# Stop and remove old sqlserver_cicd container if it exists
echo "1. Removing old sqlserver_cicd container if it exists..."
docker rm -f cfwheels-test-suite-sqlserver_cicd-1 2>/dev/null || true

# Stop UI to reload new configuration
echo "2. Stopping TestUI..."
docker compose stop testui

# Rebuild TestUI with updated service names
echo "3. Rebuilding TestUI..."
docker compose build testui

# Start TestUI
echo "4. Starting TestUI..."
docker compose up -d testui

# Show status
echo ""
echo "5. Current container status:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "(testui|sqlserver)" || echo "No matching containers running"

echo ""
echo "=== Rename Complete ==="
echo ""
echo "SQL Server has been renamed from 'sqlserver_cicd' to 'sqlserver'"
echo ""
echo "To start SQL Server, use:"
echo "  docker compose up -d sqlserver"
echo ""
echo "The TestUI at http://localhost:3000 has been updated to use the new name."