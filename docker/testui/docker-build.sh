#!/bin/bash
# Script to build and run the new TestUI in Docker

# Set to exit on error
set -e

echo "Building Wheels TestUI Docker image..."
cd "$(dirname "$0")"

# Check if this is development or production
if [ "$1" == "dev" ]; then
  echo "Building development image..."
  docker build -t cfwheels-testui-new-dev:latest -f Dockerfile.dev .
  
  echo "Starting development container..."
  docker run --rm -it \
    -p 3001:3000 \
    -v "$(pwd)":/app \
    -v /app/node_modules \
    --add-host=host.docker.internal:host-gateway \
    -e NODE_ENV=development \
    -e VITE_API_BASE=/api \
    -e VITE_MOCK_API=true \
    cfwheels-testui-new-dev:latest
else
  echo "Building production image..."
  docker build -t cfwheels-testui-new:latest .
  
  echo "Starting production container..."
  docker run --rm -it \
    -p 3001:80 \
    --add-host=host.docker.internal:host-gateway \
    cfwheels-testui-new:latest
fi

echo "Container is running. Press Ctrl+C to stop."