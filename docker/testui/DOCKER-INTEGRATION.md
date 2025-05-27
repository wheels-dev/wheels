# Docker Integration Guide for CFWheels TestUI

This document provides instructions for running the new CFWheels TestUI with Docker.

## Prerequisites

- Docker and Docker Compose installed
- Basic understanding of Docker concepts

## Architecture Overview

The TestUI consists of two services:
- **testui**: The main web interface (Vue.js app served by NGINX)
- **testui-api**: API server for Docker command execution (Node.js/Express)

## Using Docker Compose

The TestUI has been integrated into the main CFWheels `compose.yml` file. You can run it using the following commands:

### Production Mode

To run the TestUI in production mode:

```bash
# From the root CFWheels directory
docker compose --profile ui up -d
```

This will build and start both the TestUI and API containers:
- TestUI accessible at http://localhost:3000
- API server running on http://localhost:3001

### Development Mode

For active development with hot-reloading:

```bash
# From the docker/testui directory
docker-compose -f docker-compose.dev.yml up
```

This will start a development container with volume mounting, making your local changes immediately available in the running container.

## Docker Profiles

The TestUI is part of the following Docker Compose profiles:

- `ui`: Just the new TestUI
- `ui-legacy`: Just the old TestUI
- `all`: All services including both UIs

## Manual Docker Build

You can also build and run the TestUI directly using Docker:

```bash
# From the docker/testui directory
./docker-build.sh       # For production mode
./docker-build.sh dev   # For development mode
```

## Container Configuration

The TestUI container is configured with:

1. **NGINX for Production**: The production container uses NGINX to serve the built static files and proxy API requests to the appropriate services.

2. **Node.js for Development**: The development container runs Node.js with Vite's development server for hot module replacement.

3. **API Proxying**: Both containers are configured to proxy API requests to the appropriate CFML engines and Docker daemon.

4. **Host Access**: The containers use `host.docker.internal` to access services running on the host machine.

## Environment Variables

The following environment variables can be set:

- `VITE_API_BASE`: Base URL for API requests (default: `/api`)
- `VITE_MOCK_API`: Whether to use mock API responses (default: `true` in development, `false` in production)

## Troubleshooting

### Container Cannot Access Host Services

If the container cannot access services on the host machine:

1. Ensure the `extra_hosts` configuration is set correctly in your Docker Compose file:
   ```yaml
   extra_hosts:
     - "host.docker.internal:host-gateway"
   ```

2. Check if the host services are running and accessible from the container:
   ```bash
   docker exec -it cfwheels-testui curl host.docker.internal:60005
   ```

### API Proxy Issues

If API requests are not being properly proxied:

1. Check the NGINX configuration in the container:
   ```bash
   docker exec -it cfwheels-testui cat /etc/nginx/conf.d/default.conf
   ```

2. Check the NGINX logs:
   ```bash
   docker exec -it cfwheels-testui tail -f /var/log/nginx/error.log
   ```

## Docker Socket Integration

The TestUI container now integrates directly with the Docker daemon through the Docker socket:

1. **Socket Mounting**: The Docker socket is mounted into the container:
   ```yaml
   volumes:
     - /var/run/docker.sock:/var/run/docker.sock:ro
   ```

2. **Dynamic Permission Handling**: An entrypoint script automatically handles socket permissions:
   - Detects the Docker socket group ID
   - Creates a matching group in the container
   - Adds the NGINX user to this group
   - Sets appropriate permissions on the socket

3. **NGINX Proxy Configuration**: NGINX is configured to proxy Docker API requests to the Unix socket:
   ```nginx
   location /api/docker/ {
       proxy_pass http://unix:/var/run/docker.sock:/;
       # Additional proxy configurations...
   }
   ```

### Troubleshooting Docker Socket Access

If the TestUI cannot access the Docker socket:

1. Check if the Docker socket is properly mounted:
   ```bash
   docker exec -it cfwheels-testui ls -la /var/run/docker.sock
   ```

2. Verify the entrypoint script ran correctly:
   ```bash
   docker logs cfwheels-testui
   ```

3. Check NGINX permissions:
   ```bash
   docker exec -it cfwheels-testui id nginx
   docker exec -it cfwheels-testui ls -la /var/run/docker.sock
   ```

## Container Management Features

The TestUI provides direct container management capabilities:

### Starting Containers from the UI

1. **Click on stopped engines**: When an engine shows as "Checking..." or is not running, click on it to start
2. **Click on stopped databases**: Similar functionality for database containers
3. **Automatic profile detection**: The system determines the correct Docker Compose profile to use
4. **Real-time feedback**: See container status updates in real-time

### How It Works

1. The TestUI detects container states through the Docker API
2. When you click a stopped service, it sends a request to the API server
3. The API server executes `docker compose --profile <profile> up -d`
4. The UI refreshes to show the new container status

### API Server Endpoints

The testui-api service provides these endpoints:

- `POST /api/compose/start` - Start containers using Docker Compose
  ```json
  {
    "profile": "lucee",
    "service": "lucee5",
    "action": "up -d"
  }
  ```

- `GET /health` - Health check endpoint

## Security Considerations

The TestUI container needs access to the Docker daemon to manage containers. This is done through a combination of Docker socket access and the API server. In a production environment, you should consider:

1. Using read-only mount of the Docker socket where possible
2. The API server has write access to execute Docker commands
3. Running the containers with minimal permissions
4. Limiting the container's access to only necessary Docker API endpoints
5. Running the container in a separate network with appropriate access controls
6. The API server only accepts commands from the testui container

## Troubleshooting API Connectivity

If the testui and testui-api containers cannot communicate:

### 1. Check Container Status

```bash
# Verify both containers are running
docker compose ps | grep testui

# Check container logs
docker compose logs testui-api
docker compose logs testui
```

### 2. Test Network Connectivity

```bash
# Test API from host
curl http://localhost:3001/health

# Test from inside testui container
docker exec -it cfwheels-testui-1 wget -qO- http://testui-api:3001/health

# Test NGINX proxy
curl http://localhost:3000/api/compose/health
```

### 3. Common Issues and Solutions

#### API container not starting
- Check if port 3001 is already in use: `lsof -i :3001`
- Verify the Dockerfile.api builds correctly: `docker compose build testui-api`
- Check API logs: `docker compose logs testui-api`

#### Containers can't communicate
- Ensure both containers are on the same network: `docker network ls`
- Verify container names: `docker compose ps`
- Check NGINX configuration is pointing to correct hostname

#### Path mounting errors when starting containers
If you see "Mounts denied" errors when the API tries to start containers:
- This happens because Docker Compose inside the container references container paths
- The API server uses `-f /cfwheels-test-suite/compose.yml` to specify the compose file
- Make sure the testui-api container has the project mounted: `- ./:/cfwheels-test-suite:ro`
- The COMPOSE_PROJECT_DIRECTORY environment variable helps Docker resolve relative paths

#### NGINX proxy errors
- Verify NGINX config: `docker exec -it cfwheels-testui-1 cat /etc/nginx/conf.d/default.conf | grep testui-api`
- Check NGINX error logs: `docker exec -it cfwheels-testui-1 cat /var/log/nginx/error.log`

### 4. Monitoring Logs

The TestUI now logs to persistent files on the host:

```bash
# Monitor all logs in real-time
cd /path/to/wheels
./docker/testui/monitor-logs.sh

# Or check individual log files
tail -f docker/testui/logs/api/api-server.log
tail -f docker/testui/logs/nginx/error.log
```

Log locations:
- API Server: `docker/testui/logs/api/api-server.log`
- NGINX Access: `docker/testui/logs/nginx/access.log`
- NGINX Error: `docker/testui/logs/nginx/error.log`
- TestUI Access: `docker/testui/logs/nginx/testui-access.log`
- TestUI Error: `docker/testui/logs/nginx/testui-error.log`

### 5. Rebuild and Restart

If issues persist, try a clean rebuild:

```bash
# Stop and remove containers
docker compose --profile ui down

# Remove old log files
rm -rf docker/testui/logs/*

# Rebuild images
docker compose --profile ui build --no-cache

# Start fresh
docker compose --profile ui up -d

# Monitor logs
./docker/testui/monitor-logs.sh
```

## Contributing

When making changes to the Docker configuration:

1. Test both development and production builds
2. Ensure API proxying works correctly for all required services
3. Update this documentation with any configuration changes
4. Verify container-to-container communication works