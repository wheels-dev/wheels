# Wheels Docker Build Command Guide

## Overview

The `wheels docker build` command builds Docker images for your Wheels application without starting containers. This is useful for creating images that can be deployed later, testing build processes, or preparing images for remote deployment.

## Prerequisites

Before using this command, you must first initialize Docker configuration files:

```bash
wheels docker init
```

This will create the necessary `Dockerfile` and optionally `docker-compose.yml` files in your project directory.

## Command Syntax

```bash
wheels docker build [OPTIONS]
```

## Parameters

| Parameter | Type | Default | Required | Description |
|-----------|------|---------|----------|-------------|
| `--local` | boolean | `true` (if neither flag set) | No | Build Docker image on local machine |
| `--remote` | boolean | `false` | No | Build Docker image on remote server(s) |
| `--servers` | string | `""` | No | Comma-separated list of server numbers to build on (e.g., "1,3,5") - **Remote only** |
| `--tag` | string | `"project-name:latest"` | No | Custom tag for the Docker image |
| `--nocache` | boolean | `false` | No | Build without using cache (forces fresh build) |
| `--pull` | boolean | `false` | No | Always attempt to pull a newer version of the base image |

## Usage Examples

### Local Build

#### Basic Local Build

Build Docker image locally with default settings:

```bash
wheels docker build
# or explicitly
wheels docker build --local
```

This will:
- Use `docker-compose.yml` if available, otherwise use `Dockerfile`
- Build the image with default tag (project-name:latest)
- Use Docker cache if available
- Not pull base image updates

#### Build with Custom Tag

```bash
wheels docker build --local --tag=myapp:v1.0.0
```

#### Build Without Cache

Force a fresh build without using cached layers:

```bash
wheels docker build --local --nocache
```

#### Build with Latest Base Image

Pull the latest version of the base image before building:

```bash
wheels docker build --local --pull
```

#### Complete Local Build Example

Build with custom tag, no cache, and pull latest base image:

```bash
wheels docker build --local --tag=myapp:production --nocache --pull
```

### Remote Build

#### Basic Remote Build

Build on all configured remote servers:

```bash
wheels docker build --remote
```

This will build on all servers listed in `deploy-servers.txt` or `deploy-servers.json`.

#### Build on Specific Servers

Build only on selected servers (by number):

```bash
# Build on servers 1 and 3 only
wheels docker build --remote --servers=1,3

# Build on servers 1, 2, and 5
wheels docker build --remote --servers=1,2,5
```

**Note:** Server numbers correspond to the order they appear in your configuration file (1-indexed).

#### Remote Build with Custom Tag

```bash
wheels docker build --remote --tag=myapp:staging
```

#### Remote Build Without Cache

```bash
wheels docker build --remote --nocache
```

#### Remote Build with Latest Base Image

```bash
wheels docker build --remote --pull
```

#### Complete Remote Build Example

Build on specific servers with custom tag, no cache, and pull updates:

```bash
wheels docker build --remote --servers=1,3 --tag=myapp:v2.0.0 --nocache --pull
```

## Server Configuration

For remote builds, you need a server configuration file. The format is the same as used by `wheels docker deploy`.

### Text File Format (deploy-servers.txt)

```text
192.168.1.100 ubuntu 22
production.example.com deploy 22 /var/www/myapp myapp-prod
staging.example.com staginguser 2222 /home/staginguser/app staging-app
```

**Server Selection:**
- Server 1: 192.168.1.100
- Server 2: production.example.com
- Server 3: staging.example.com

To build only on servers 1 and 3:
```bash
wheels docker build --remote --servers=1,3
```

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
    },
    {
      "host": "staging.example.com",
      "user": "staginguser",
      "port": 2222,
      "remoteDir": "/home/staginguser/app",
      "imageName": "staging-app"
    }
  ]
}
```

## How It Works

### Local Build Process

1. **Check Docker Installation**
   - Verifies Docker is installed and accessible
   - Ensures Docker daemon is running

2. **Detect Build Method**
   - If `docker-compose.yml` exists: uses `docker compose build`
   - Otherwise: uses `docker build` with Dockerfile

3. **Build Image**
   - Applies specified options (tag, nocache, pull)
   - Builds image layers
   - Tags the final image

4. **Output**
   - Confirms successful build
   - Shows image tag
   - Provides next steps (how to run/deploy)

### Remote Build Process

1. **Load Server Configuration**
   - Reads `deploy-servers.txt` or `deploy-servers.json`
   - Filters servers if `--servers` parameter is provided

2. **For Each Server:**
   - Test SSH connection
   - Check if remote directory exists
   - Upload source code if needed
   - Detect build method (compose vs. Dockerfile)
   - Execute build command remotely
   - Handle sudo requirements automatically

3. **Summary**
   - Reports success/failure for each server
   - Displays overall build statistics

## Build Options Explained

### --nocache

Forces Docker to rebuild all layers from scratch without using the cache.

**When to use:**
- After changing base image or dependencies
- When troubleshooting build issues
- To ensure a completely fresh build
- Before production deployments

**Example:**
```bash
wheels docker build --nocache
```

### --pull

Tells Docker to always pull the latest version of the base image specified in your Dockerfile.

**When to use:**
- To get security updates in base images
- When you want the latest patches
- For regular maintenance builds
- Before important deployments

**Example:**
```bash
wheels docker build --pull
```

### --tag

Assigns a custom tag to the built image instead of the default `project-name:latest`.

**Tag Format:** `name:version`

**Common patterns:**
```bash
# Version tags
wheels docker build --tag=myapp:v1.0.0
wheels docker build --tag=myapp:v2.1.3

# Environment tags
wheels docker build --tag=myapp:production
wheels docker build --tag=myapp:staging
wheels docker build --tag=myapp:dev

# Date-based tags
wheels docker build --tag=myapp:2024-12-24
wheels docker build --tag=myapp:20241224-1530

# Git-based tags
wheels docker build --tag=myapp:main
wheels docker build --tag=myapp:feature-auth
```

## Docker Requirements

### Local Requirements

- Docker Desktop (Mac/Windows) or Docker Engine (Linux) installed
- Docker daemon running
- Docker Compose (included in modern Docker installations)

### Remote Requirements

- SSH access to remote server
- Docker installed on remote server
- Source code present in remote directory (uploaded automatically if missing)
- Proper permissions to run Docker (user in docker group or sudo access)

## Troubleshooting

### Local Build Issues

**Error: "Docker is not installed or not accessible"**

Solution:
```bash
# Check if Docker is running
docker --version

# Start Docker Desktop (Mac/Windows)
# Or start Docker service (Linux)
sudo systemctl start docker
```

**Error: "No Dockerfile or docker-compose.yml found"**

Solution:
```bash
# Initialize Docker files first
wheels docker init
```

**Build fails with cache issues**

Solution:
```bash
# Build without cache
wheels docker build --nocache
```

**Need latest security updates**

Solution:
```bash
# Pull latest base image
wheels docker build --pull
```

### Remote Build Issues

**Error: "SSH connection failed"**

Solution:
- Verify SSH credentials: `ssh user@host`
- Check if SSH keys are configured
- Ensure server is accessible from your network

**Error: "No Dockerfile found on remote server"**

Solution:
The command automatically uploads source code if the remote directory doesn't exist. If you see this error:
- Ensure your local Dockerfile exists
- Try removing the remote directory and rebuilding
- Manually upload files with `scp` if needed

**Error: "Remote command failed"**

Solution:
- Check if user has Docker permissions
- Verify user is in docker group: `groups username`
- Add user to docker group: `sudo usermod -aG docker username`
- Or ensure user has sudo access

**Build succeeds but image not found**

Solution:
```bash
# Check images on remote server
ssh user@host "docker images"

# Verify the tag name matches
wheels docker build --remote --tag=correct-name:latest
```

### Permission Issues

**Docker permission denied**

On remote server:
```bash
# Add user to docker group
sudo usermod -aG docker $USER

# Apply group changes (logout/login or use)
newgrp docker

# Or fix socket permissions (temporary)
sudo chmod 666 /var/run/docker.sock
```

## Build Verification

### Local Verification

After building locally, verify the image:

```bash
# List all images
docker images

# List specific project images
docker images project-name

# Inspect the image
docker inspect project-name:latest

# Check image size
docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}"
```

### Remote Verification

After building remotely, verify on the server:

```bash
# SSH into server
ssh user@host

# List images
docker images

# Check specific image
docker images myapp

# Get detailed information
docker inspect myapp:latest
```

## Advanced Usage

### Build Different Versions

```bash
# Development build
wheels docker build --tag=myapp:dev

# Staging build with fresh base
wheels docker build --tag=myapp:staging --pull

# Production build (complete fresh build)
wheels docker build --tag=myapp:production --nocache --pull
```

### Multi-Environment Remote Builds

Assuming your `deploy-servers.txt` has:
1. dev-server (development)
2. staging-server (staging)
3. prod-server-1 (production)
4. prod-server-2 (production)

```bash
# Build only on development
wheels docker build --remote --servers=1 --tag=myapp:dev

# Build only on staging
wheels docker build --remote --servers=2 --tag=myapp:staging

# Build on both production servers
wheels docker build --remote --servers=3,4 --tag=myapp:prod-v1.0 --nocache
```

## Best Practices

1. **Use Version Tags for Production**
   ```bash
   wheels docker build --tag=myapp:v1.0.0
   ```
   Avoid using `:latest` in production environments.

2. **Regular Cache Clearing**
   Periodically rebuild without cache to prevent stale layers:
   ```bash
   wheels docker build --nocache
   ```

3. **Pull Base Image Updates**
   Regular security updates:
   ```bash
   wheels docker build --pull
   ```

4. **Test Builds Locally First**
   Always build and test locally before remote builds:
   ```bash
   wheels docker build --local
   # Test the image
   docker run -d -p 8080:8080 project-name:latest
   # If successful, build remotely
   wheels docker build --remote
   ```

5. **Selective Server Builds**
   Build on staging before production:
   ```bash
   # Build on staging first
   wheels docker build --remote --servers=2 --tag=myapp:v1.0.0
   
   # After validation, build on production
   wheels docker build --remote --servers=3,4 --tag=myapp:v1.0.0
   ```

6. **Tag Naming Convention**
   Use consistent tagging:
   - `project:v1.0.0` - Semantic versioning
   - `project:prod-20241224` - Production with date
   - `project:staging` - Environment-based
   - `project:feature-name` - Feature branches

7. **Monitor Build Output**
   Watch for warnings and errors during build process to catch issues early.

8. **Keep Dockerfiles Optimized**
   - Use multi-stage builds
   - Minimize layer count
   - Order instructions from least to most frequently changing
   - Clean up in the same layer where files are created

## Build vs Deploy

Understanding when to use `build` vs `deploy`:

### Use `wheels docker build` when:
- You want to create an image without running it
- Testing Docker configuration changes
- Preparing images for later deployment
- Building on CI/CD pipeline
- Creating multiple tagged versions
- Building on remote servers for later use

### Use `wheels docker deploy` when:
- You want to build AND run the application
- Deploying to servers with containers running
- Full deployment workflow needed
- Starting services immediately

### Combined Workflow:
```bash
# 1. Build the image
wheels docker build --tag=myapp:v1.0.0 --nocache

# 2. Test locally if needed
docker run -d -p 8080:8080 myapp:v1.0.0

# 3. Deploy to remote servers
wheels docker deploy --remote --blueGreen
```

## Monitoring Build Progress

### Local Monitoring

Build progress is shown in real-time:
```bash
wheels docker build --local
# Output shows:
# - Layer building
# - Cache usage
# - Final image ID and size
```

### Remote Monitoring

For remote builds, watch SSH output:
```bash
wheels docker build --remote
# Output shows:
# - SSH connection status
# - Source upload progress
# - Build step output from remote server
# - Success/failure summary
```

To monitor manually on remote server:
```bash
# In another terminal
ssh user@host "docker ps"
ssh user@host "docker images"
```

## Related Commands

- [wheels docker init](docker-init.md) - Initialize Docker configuration files
- [wheels docker deploy](docker-deploy.md) - Build and deploy Docker containers
- [wheels docker push](docker-push.md) - Push Docker images to registries
- [wheels docker logs](docker-logs.md) - View container logs
- [wheels docker stop](docker-stop.md) - Stop Docker containers
- [wheels docker exec](docker-exec.md) - Execute commands in containers

---

**Note**: This command is part of the Wheels CLI tool suite for Docker management.