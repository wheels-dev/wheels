# Docker Integration Guide for CFWheels TestUI

This document provides instructions for running the new CFWheels TestUI with Docker.

## Prerequisites

- Docker and Docker Compose installed
- Basic understanding of Docker concepts

## Using Docker Compose

The TestUI has been integrated into the main CFWheels `compose.yml` file. You can run it using the following commands:

### Production Mode

To run the TestUI in production mode:

```bash
# From the root CFWheels directory
docker-compose --profile ui up -d
```

This will build and start the TestUI container, making it accessible at http://localhost:3001

### Development Mode

For active development with hot-reloading:

```bash
# From the docker/testui-new directory
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
# From the docker/testui-new directory
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
   docker exec -it cfwheels-testui-new curl host.docker.internal:60005
   ```

### API Proxy Issues

If API requests are not being properly proxied:

1. Check the NGINX configuration in the container:
   ```bash
   docker exec -it cfwheels-testui-new cat /etc/nginx/conf.d/default.conf
   ```

2. Check the NGINX logs:
   ```bash
   docker exec -it cfwheels-testui-new tail -f /var/log/nginx/error.log
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
   docker exec -it cfwheels-testui-new ls -la /var/run/docker.sock
   ```

2. Verify the entrypoint script ran correctly:
   ```bash
   docker logs cfwheels-testui-new
   ```

3. Check NGINX permissions:
   ```bash
   docker exec -it cfwheels-testui-new id nginx
   docker exec -it cfwheels-testui-new ls -la /var/run/docker.sock
   ```

## Security Considerations

The TestUI container needs access to the Docker daemon to manage containers. This is done through a proxy to the Docker socket. In a production environment, you should consider:

1. Using read-only mount of the Docker socket (as configured)
2. Implementing Docker API authentication
3. Running the container with minimal permissions
4. Limiting the container's access to only necessary Docker API endpoints
5. Running the container in a separate network with appropriate access controls

## Contributing

When making changes to the Docker configuration:

1. Test both development and production builds
2. Ensure API proxying works correctly for all required services
3. Update this documentation with any configuration changes