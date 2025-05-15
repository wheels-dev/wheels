#!/bin/sh
set -e

echo "Testing Docker socket access directly..."

# Try to list Docker containers using curl to the socket
echo "Querying Docker API for containers..."
curl -s --unix-socket /var/run/docker.sock http://localhost/containers/json?all=true | head -n 20

echo "\n\nTesting Docker socket permissions..."
ls -la /var/run/docker.sock

echo "\n\nTesting NGINX configuration..."
cat /etc/nginx/conf.d/default.conf

echo "\n\nTesting Docker group membership..."
id nginx

echo "\n\nDone testing."