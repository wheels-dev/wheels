#!/bin/bash
set -e

# Replace placeholders in server.json if it exists
if [ -f "/wheelsapp/server.json" ]; then
    # Create a backup
    cp /wheelsapp/server.json /wheelsapp/server.json.template
    
    # Replace placeholders
    sed -i 's/|appName|/wheels-test-app/g' /wheelsapp/server.json
    sed -i 's/|cfmlEngine|/lucee@6/g' /wheelsapp/server.json
fi

# Ensure vendor directory exists
mkdir -p /wheelsapp/vendor

# Create symbolic link for wheels core if not exists
if [ ! -e "/wheelsapp/vendor/wheels" ]; then
    ln -sf /wheelsapp/core/src/wheels /wheelsapp/vendor/wheels
fi

# Install dependencies if not already installed
if [ ! -d "/wheelsapp/vendor/wirebox" ] || [ ! -d "/wheelsapp/vendor/testbox" ]; then
    cd /wheelsapp
    box install --force
fi

# Execute the original entrypoint
exec "$@"