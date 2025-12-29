# Wheels Docker Deploy

## Overview

The `wheels docker deploy` command provides a unified interface for deploying Wheels applications using Docker. It supports both local development deployments and remote server deployments with optional Blue/Green deployment strategy for zero-downtime updates.

## Prerequisites

Before using this command, you must first initialize Docker configuration files:

```bash
wheels docker init
```

This will create the necessary `Dockerfile` and `docker-compose.yml` files in your project directory.

## Command Syntax

```bash
wheels docker deploy [OPTIONS]
```

## Parameters

| Parameter | Type | Default | Required | Description |
|-----------|------|---------|----------|-------------|
| `--local` | boolean | `true` (if neither flag set) | No | Deploy to local Docker environment |
| `--remote` | boolean | `false` | No | Deploy to remote server(s) |
| `--servers` | string | `""` | No | Server configuration file (deploy-servers.txt or deploy-servers.json) - **Remote only** |
| `--skipDockerCheck` | boolean | `false` | No | Skip Docker installation check on remote servers - **Remote only** |
| `--blueGreen` | boolean | `false` | No | Enable Blue/Green deployment strategy (zero downtime) - **Remote only** |

## Usage Examples

### Local Deployment

#### Basic Local Deployment

Deploy to local Docker environment:

```bash
wheels docker deploy
# or explicitly
wheels docker deploy --local
```

This will:
- Use `docker-compose.yml` if available, otherwise use `Dockerfile`
- Build and start containers locally

### Remote Deployment

#### Basic Remote Deployment

Deploy to remote servers using default `deploy-servers.txt` or `deploy-servers.json`:

```bash
wheels docker deploy --remote
```

#### Remote Deployment with Custom Server File

```bash
wheels docker deploy --remote --servers=production-servers.txt
```

or with JSON configuration:

```bash
wheels docker deploy --remote --servers=deploy-servers.json
```

#### Remote Deployment with Blue/Green Strategy

Deploy with zero downtime using Blue/Green deployment:

```bash
wheels docker deploy --remote --blueGreen
```

#### Remote Deployment Skipping Docker Check

Skip the automatic Docker installation check (useful if Docker is already installed):

```bash
wheels docker deploy --remote --skipDockerCheck
```

#### Complete Remote Deployment Example

```bash
wheels docker deploy --remote --servers=production-servers.json --blueGreen --skipDockerCheck
```

## Server Configuration

For remote deployments, you need to create a server configuration file.

### Text File Format (deploy-servers.txt)

```text
192.168.1.100 ubuntu 22
production.example.com deploy 22 /var/www/myapp myapp-prod
staging.example.com staginguser 2222 /home/staginguser/app staging-app
```

**Format:** `host username [port] [remoteDir] [imageName]`

- `host`: Server hostname or IP address (required)
- `username`: SSH username (required)
- `port`: SSH port (optional, default: 22)
- `remoteDir`: Remote deployment directory (optional, default: `/home/username/username-app`)
- `imageName`: Docker image name (optional, default: `username-app`)

### JSON File Format (deploy-servers.json)

```json
{
  "servers": [
    {
      "host": "192.168.1.100",
      "user": "ubuntu",
      "port": 22,
      "remoteDir": "/var/www/myapp",
      "imageName": "myapp-prod"
    },
    {
      "host": "production.example.com",
      "user": "deploy",
      "port": 22,
      "remoteDir": "/home/deploy/production",
      "imageName": "production-app"
    }
  ]
}
```

## Deployment Strategies

### Standard Deployment

The default deployment strategy:

1. Stops existing containers
2. Builds new Docker image
3. Starts new container
4. Brief downtime during transition

```bash
wheels docker deploy --remote
```

### Blue/Green Deployment

Zero-downtime deployment strategy:

1. Builds new Docker image
2. Starts new container (green) alongside existing (blue)
3. Updates nginx proxy to route traffic to new container
4. Stops old container after successful deployment

```bash
wheels docker deploy --remote --blueGreen
```

**Requirements for Blue/Green:**
- Nginx proxy container (`nginx-proxy`)
- Docker network (`web`)
- Both are automatically created if not present

## How It Works

### Local Deployment Process

1. **Check for docker-compose.yml**
   - If found: uses `docker compose up -d --build`
   - If not found: uses standard Docker commands with `Dockerfile`

2. **Build and Start**
   - Builds Docker image from Dockerfile
   - Stops existing containers (if any)
   - Starts new container with proper port mapping

3. **Output**
   - Container name
   - Access URL (e.g., `http://localhost:8080`)
   - Useful Docker commands for monitoring

### Remote Deployment Process

1. **Pre-flight Checks**
   - Verify SSH connection to server
   - Check Docker installation (or install if missing)
   - Create remote deployment directory

2. **Upload**
   - Create tarball of project source
   - Upload to remote server via SCP

3. **Build and Deploy**
   - Extract source on remote server
   - Build Docker image remotely
   - Stop old container (if exists)
   - Start new container

4. **Post-deployment**
   - Display deployment status
   - Show summary for all servers

## Docker Requirements

### Local Requirements

- Docker Desktop or Docker Engine installed
- Docker Compose (included in modern Docker installations)

### Remote Requirements

- SSH access to remote server
- Passwordless sudo access (for automatic Docker installation)
- Ubuntu/Debian or RHEL/CentOS/Fedora (for automatic Docker installation)

If Docker is not installed on the remote server, the command will:
1. Detect the OS type
2. Install Docker automatically (requires passwordless sudo)
3. Configure Docker for the deployment user
4. Proceed with deployment

## Troubleshooting

### Local Deployment Issues

**Error: "Docker is not installed or not accessible"**

- Ensure Docker Desktop is running (Mac/Windows)
- Ensure Docker Engine is running (Linux): `sudo systemctl start docker`

**Error: "No Dockerfile or docker-compose.yml found"**

- Run `wheels docker init` first to create configuration files

### Remote Deployment Issues

**Error: "SSH connection failed"**

- Verify server hostname/IP and SSH credentials
- Check if SSH key is properly configured
- Test manual SSH connection: `ssh user@host`

**Error: "User requires passwordless sudo access"**

Follow the instructions provided in the error message to configure sudoers:

```bash
# SSH into server
ssh user@host

# Edit sudoers file
sudo visudo

# Add this line
username ALL=(ALL) NOPASSWD:ALL
```

**Error: "No server configuration found"**

- Create `deploy-servers.txt` or `deploy-servers.json` in project root
- Or specify custom file with `--servers=path/to/file`

### Port Conflicts

If you see port already in use errors:

```bash
# Check what's using the port
docker ps
lsof -i :8080

# Stop conflicting containers
docker stop container_name
```

## Monitoring Deployment

### Local Monitoring

```bash
# Check container status
docker ps
# or with compose
docker compose ps

# View logs
docker logs -f container_name
# or with compose
docker compose logs -f

# Access container shell
docker exec -it container_name /bin/bash
```

### Remote Monitoring

```bash
# SSH into server
ssh user@host

# Check containers
docker ps

# View logs
docker logs -f container_name

# Monitor resources
docker stats
```

## Security Notes

1. **SSH Keys**: Use SSH key authentication instead of passwords
2. **Sudo Access**: Configure minimal sudo permissions for production
3. **Firewall**: Ensure proper firewall rules are in place
4. **Docker Socket**: The deployment sets permissions on `/var/run/docker.sock` for convenience; review for production security

## Best Practices

1. **Test Locally First**: Always test deployments locally before remote deployment
2. **Use Blue/Green for Production**: Minimize downtime with `--blueGreen` flag
3. **Version Control**: Keep `Dockerfile` and `docker-compose.yml` in version control
4. **Environment-Specific Configs**: Use different configuration files for staging/production
5. **Monitor Resources**: Keep track of Docker resource usage on remote servers
6. **Backup Data**: Always backup databases before major deployments
7. **Rollback Plan**: Keep previous images for quick rollback if needed

## Related Commands

- [wheels docker init](docker-init.md) - Initialize Docker configuration files
- [wheels docker build](docker-build.md) - Build Docker images
- [wheels docker push](docker-push.md) - Push Docker images to registries
- [wheels docker logs](docker-logs.md) - View container logs
- [wheels docker stop](docker-stop.md) - Stop Docker containers
- [wheels docker exec](docker-exec.md) - Execute commands in containers

---

**Note**: This command is part of the Wheels CLI tool suite for Docker management.