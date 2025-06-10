# CFWheels TestUI Docker Integration

This document provides an overview of the Docker integration for the CFWheels TestUI application.

## Architecture

The TestUI application is containerized for easy deployment and consistent behavior across environments. The primary components are:

1. **TestUI Container**: A Vue.js application served by NGINX, providing the user interface for test management.
2. **CFML Engine Containers**: Lucee and Adobe ColdFusion containers that execute the CFWheels test suite.
3. **Database Containers**: Various database containers (MySQL, PostgreSQL, SQL Server) for testing database interactions.

## Container Structure

### TestUI Container

- **Base Image**: `nginx:stable-alpine`
- **Ports**: 80 (internal), 3000 (mapped to host)
- **Volumes**: Docker socket mounted (read-only) for container management
- **Extra Hosts**: `host.docker.internal` for accessing host services

### Integration Points

The TestUI container communicates with the following services:

1. **Docker API**: For container management through the Docker socket
2. **CFML Engines**: For executing tests through HTTP APIs
3. **Host Services**: Through host.docker.internal hostname

## Implementation Details

### Docker Socket Access

The TestUI container needs access to the Docker socket to manage engine and database containers:

- The Docker socket is mounted in read-only mode: `/var/run/docker.sock:/var/run/docker.sock:ro`
- The entrypoint script detects the Docker socket group and configures permissions
- NGINX proxies Docker API requests to the Unix socket

### CFML Engine Communication

The TestUI communicates with CFML engines via HTTP:

- NGINX proxies requests to host machine ports where engines are running
- Each engine has a dedicated proxy location in the NGINX configuration
- Example URL format: `http://localhost:3000/api/lucee6/wheels/testbox?format=json`

### Host Network Access

The TestUI container uses `host.docker.internal` to access services on the host:

- This hostname is automatically configured via the `extra_hosts` setting
- The entrypoint script validates connectivity to host ports

## Configuration Options

The TestUI container behavior can be controlled through environment variables:

- `NODE_ENV`: Set to 'production' for production mode
- `VITE_API_BASE`: Base URL for API requests (default: '/api')
- `VITE_MOCK_API`: Whether to use mock API (default: 'false' in production)

## Security Considerations

- Docker socket is mounted read-only
- NGINX runs as a non-root user
- Only necessary API endpoints are exposed
- No sensitive data is stored in the container

## Deployment Instructions

### Basic Deployment

```bash
# From the project root
docker-compose --profile ui up -d
```

### Production Deployment

For a production deployment, additional security measures should be taken:

1. Configure a reverse proxy in front of the TestUI container
2. Set up proper authentication
3. Consider using a Docker API authorization plugin

## Troubleshooting

### Container Cannot Access Host Services

If the container cannot reach host services:

1. Verify that the `extra_hosts` configuration is correct
2. Check if the host services are running and accessible
3. Check firewall or network settings that might block communication

### Docker API Connectivity Issues

If the container cannot access the Docker API:

1. Check if the Docker socket is properly mounted
2. Verify permissions on the Docker socket
3. Check if the NGINX user has the correct group membership

## Further Reading

- [NGINX Configuration](/Users/peter/projects/cfwheels/docker/testui-new/nginx.conf)
- [Docker Entrypoint Script](/Users/peter/projects/cfwheels/docker/testui-new/docker-entrypoint.sh)
- [Docker Service Implementation](/Users/peter/projects/cfwheels/docker/testui-new/src/services/docker.service.ts)