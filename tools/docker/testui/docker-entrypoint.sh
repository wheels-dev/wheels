#!/bin/sh
set -e

#-----------------------------------------------------
# Docker Socket Configuration for API Access
#-----------------------------------------------------
echo "🔍 Checking Docker socket access..."

# Check if the Docker socket exists
if [ ! -e /var/run/docker.sock ]; then
  echo "⚠️ Warning: Docker socket not found at /var/run/docker.sock"
  echo "🔄 API calls to Docker will not work. Container management features will be disabled."
  export VITE_MOCK_API=true
else
  # Get the group ID of the docker socket
  SOCKET_GID=$(stat -c '%g' /var/run/docker.sock 2>/dev/null || stat -f '%g' /var/run/docker.sock 2>/dev/null)

  if [ -z "$SOCKET_GID" ]; then
    echo "⚠️ Warning: Could not determine docker socket group ID. Docker API access may not work."
    export VITE_MOCK_API=true
  else
    echo "🔄 Setting up Docker socket access (GID: $SOCKET_GID)..."
    
    # Special handling for root group (GID 0)
    if [ "$SOCKET_GID" -eq 0 ]; then
      echo "🔄 Docker socket is owned by root group"
      
      # Just add nginx to the root group
      echo "🔄 Adding nginx user to root group"
      adduser nginx root || echo "Could not add nginx to root group, might already be a member"
    else
      # Check if the docker group already exists with correct GID
      if getent group docker >/dev/null && [ $(getent group docker | cut -d: -f3) -eq $SOCKET_GID ]; then
        echo "✅ Docker group already exists with correct GID"
      else
        # Remove docker group if it exists but with wrong GID
        if getent group docker >/dev/null; then
          echo "🔄 Removing existing docker group with incorrect GID"
          delgroup docker || echo "Could not delete docker group"
        fi
        
        # Create docker group with the socket GID
        echo "🔄 Creating docker group with GID: $SOCKET_GID"
        addgroup -g $SOCKET_GID docker || echo "Could not create docker group"
      fi
      
      # Add nginx user to the docker group
      echo "🔄 Adding nginx user to docker group"
      adduser nginx docker || echo "Could not add nginx to docker group"
    fi
    
    # Check if socket is writable before trying to change permissions
    if touch /var/run/docker.sock 2>/dev/null; then
      echo "🔄 Setting proper permissions for /var/run/docker.sock"
      chmod 660 /var/run/docker.sock || echo "Could not change socket permissions"
    else
      echo "ℹ️ Docker socket is mounted read-only, skipping permission change"
    fi
    
    # Verify that we can access the Docker socket
    echo "🔍 Testing Docker socket access..."
    if curl --unix-socket /var/run/docker.sock http://localhost/version >/dev/null 2>&1; then
      echo "✅ Docker socket access test successful"
      export VITE_MOCK_API=false
    else
      echo "⚠️ Docker socket access test failed. Container management may not work correctly."
      echo "ℹ️ Will fall back to mock data for container management."
      export VITE_MOCK_API=true
    fi
  fi
fi

#-----------------------------------------------------
# Host Connectivity Check for Engine/DB Access
#-----------------------------------------------------
echo "🔍 Checking host connectivity for CFML engine access..."

# Test if we can reach the host
if ping -c 1 host.docker.internal >/dev/null 2>&1; then
  echo "✅ Host connectivity check successful"

  # Test connectivity to engine ports
  for ENGINE_PORT in 60005 60006 62018 62021 62023; do
    if nc -z host.docker.internal $ENGINE_PORT >/dev/null 2>&1; then
      echo "✅ Engine port $ENGINE_PORT is reachable"
    else
      echo "ℹ️ Engine port $ENGINE_PORT is not reachable (this is normal if the engine is not running)"
    fi
  done
else
  echo "⚠️ Cannot reach host.docker.internal. Engine API access will not work."
  echo "ℹ️ This could be due to Docker networking configuration issues."
fi

#-----------------------------------------------------
# NGINX Configuration
#-----------------------------------------------------

# Verify NGINX configuration
echo "🔍 Verifying NGINX configuration..."
nginx -t || { echo "❌ NGINX configuration test failed"; exit 1; }

# Start nginx
echo "🚀 Starting NGINX server..."
exec nginx -g "daemon off;"