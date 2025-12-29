# Wheels Docker Push Command Guide

## Overview

The `wheels docker push` command uploads Docker images to container registries. It works in conjunction with `wheels docker login` to authenticate and push images to Docker Hub, Amazon ECR, Google Container Registry, Azure Container Registry, GitHub Container Registry, and private registries.

## Prerequisites

Before pushing images, you must:

1. **Authenticate with the registry:**
   ```bash
   wheels docker login --registry=dockerhub --username=myuser
   ```

2. **Have a built image:**
   ```bash
   wheels docker build --local
   ```
   Or use the `--build` flag with the push command to build automatically.

## Command Syntax

```bash
wheels docker push [OPTIONS]
```

## Parameters

| Parameter | Type | Default | Required | Description |
|-----------|------|---------|----------|-------------|
| `--local` | boolean | `true` (if neither flag set) | No | Push image from local machine |
| `--remote` | boolean | `false` | No | Push image from remote server(s) |
| `--servers` | string | `""` | No | Comma-separated list of server numbers to push from (e.g., "1,3,5") - **Remote only** |
| `--registry` | string | `"dockerhub"` | No | Registry type: dockerhub, ecr, gcr, acr, ghcr, private |
| `--image` | string | `""` | No | Full image name with registry path (auto-detected if not specified) |
| `--username` | string | `""` | Conditional* | Registry username (required for dockerhub, ghcr, private) |
| `--password` | string | `""` | No | Registry password or token (uses existing credentials if not provided) |
| `--tag` | string | `"latest"` | No | Tag/version to apply (e.g., v1.0.0, latest) |
| `--build` | boolean | `false` | No | Build the image before pushing |
| `--namespace` | string | `""` | No | Registry namespace/username prefix |

**Note:** Username is loaded from `docker-config.json` if available (created by `wheels docker login`).

## Configuration File

After running `wheels docker login`, credentials are saved to `docker-config.json`:

```json
{
  "registry": "dockerhub",
  "username": "myusername",
  "image": ""
}
```

The push command automatically reads this configuration, so you don't need to specify registry and username again.

## Usage Examples

### Local Push

#### Basic Local Push (Using Saved Configuration)

After logging in with `wheels docker login`:

```bash
wheels docker push
# or explicitly
wheels docker push --local
```

This uses the registry and username from `docker-config.json`.

#### Push with Explicit Registry and Username

```bash
wheels docker push --local --registry=dockerhub --username=myuser
```

#### Push with Custom Tag

```bash
# Push as version 1.0.0
wheels docker push --local --tag=v1.0.0

# Push as latest (default)
wheels docker push --local --tag=latest

# Push with semantic versioning
wheels docker push --local --tag=v2.1.3
```

#### Build and Push in One Command

```bash
wheels docker push --local --build
```

This will:
1. Build the Docker image
2. Push it to the registry

#### Push with Full Image Name

```bash
wheels docker push --local --image=myusername/myapp:v1.0.0
```

#### Push to Docker Hub with Namespace

```bash
wheels docker push --local --registry=dockerhub --username=myuser --namespace=myorganization
```

Creates image: `myorganization/projectname:latest`

### Registry-Specific Examples

#### Docker Hub

```bash
# Using saved credentials
wheels docker push --local

# Explicit credentials
wheels docker push --local --registry=dockerhub --username=myuser --password=mytoken

# With custom tag
wheels docker push --local --registry=dockerhub --username=myuser --tag=v1.0.0

# Build and push
wheels docker push --local --registry=dockerhub --username=myuser --build
```

#### Amazon ECR

```bash
# ECR requires full image path
wheels docker push --local --registry=ecr --image=123456789012.dkr.ecr.us-east-1.amazonaws.com/myapp:latest

# With custom tag
wheels docker push --local --registry=ecr --image=123456789012.dkr.ecr.us-east-1.amazonaws.com/myapp:v1.0.0

# Build and push to ECR
wheels docker push --local --registry=ecr --image=123456789012.dkr.ecr.us-east-1.amazonaws.com/myapp:latest --build
```

#### Google Container Registry

```bash
# GCR push
wheels docker push --local --registry=gcr --image=gcr.io/my-project-id/myapp:latest

# Regional GCR
wheels docker push --local --registry=gcr --image=us.gcr.io/my-project-id/myapp:latest

# With tag
wheels docker push --local --registry=gcr --image=gcr.io/my-project-id/myapp:v1.0.0
```

#### Azure Container Registry

```bash
# ACR push
wheels docker push --local --registry=acr --username=myregistry --image=myregistry.azurecr.io/myapp:latest

# With custom tag
wheels docker push --local --registry=acr --username=myregistry --image=myregistry.azurecr.io/myapp:v1.0.0
```

#### GitHub Container Registry

```bash
# GHCR push
wheels docker push --local --registry=ghcr --username=githubuser --image=ghcr.io/githubuser/myapp:latest

# Organization repository
wheels docker push --local --registry=ghcr --username=githubuser --image=ghcr.io/myorg/myapp:latest

# With tag
wheels docker push --local --registry=ghcr --username=githubuser --tag=v1.0.0
```

#### Private Registry

```bash
# Private registry push
wheels docker push --local --registry=private --username=registryuser --image=registry.company.com/myapp:latest

# With custom port
wheels docker push --local --registry=private --username=registryuser --image=registry.company.com:5000/myapp:latest
```

### Remote Push

#### Basic Remote Push

Push from all configured remote servers:

```bash
wheels docker push --remote --registry=dockerhub --username=myuser
```

#### Push from Specific Servers

```bash
# Push from servers 1 and 3 only
wheels docker push --remote --servers=1,3 --registry=dockerhub --username=myuser

# Push from server 2
wheels docker push --remote --servers=2 --registry=dockerhub --username=myuser
```

#### Remote Push with Authentication

```bash
wheels docker push --remote --registry=dockerhub --username=myuser --password=mytoken
```

#### Remote Push with Custom Tag

```bash
wheels docker push --remote --registry=dockerhub --username=myuser --tag=v1.0.0
```

#### Remote Push to ECR

```bash
wheels docker push --remote --registry=ecr --image=123456789012.dkr.ecr.us-east-1.amazonaws.com/myapp:latest
```

## How It Works

### Local Push Process

1. **Load Configuration**
   - Reads `docker-config.json` for saved registry settings
   - Uses provided parameters to override config values
   - Defaults to Docker Hub if no registry specified

2. **Check Docker Installation**
   - Verifies Docker is installed and running
   - Ensures Docker daemon is accessible

3. **Build Image (if requested)**
   - Runs `docker build` or `docker compose build`
   - Creates image with project name

4. **Check Image Existence**
   - Verifies local image exists
   - Prompts to build if image not found

5. **Determine Final Image Name**
   - Constructs registry-specific image path
   - Applies namespace and tag
   - Format varies by registry type

6. **Tag Image**
   - Tags local image with registry path
   - Example: `myapp:latest` → `username/myapp:v1.0.0`

7. **Authenticate (if needed)**
   - Uses provided password to login
   - Otherwise uses existing Docker credentials

8. **Push Image**
   - Uploads image layers to registry
   - Shows progress and completion status

### Remote Push Process

1. **Load Server Configuration**
   - Reads `deploy-servers.txt` or `deploy-servers.json`
   - Filters servers if `--servers` specified

2. **For Each Server:**
   - Test SSH connection
   - Verify image exists on remote server
   - Tag image with registry path (if custom tag specified)
   - Login to registry on remote server
   - Execute `docker push` command
   - Report success/failure

3. **Summary**
   - Display push results for all servers
   - Show success and failure counts

### Image Naming Convention

The command automatically constructs the correct image name based on registry type:

| Registry | Image Format | Example |
|----------|-------------|---------|
| Docker Hub | `username/projectname:tag` | `myuser/myapp:v1.0.0` |
| ECR | `account.dkr.ecr.region.amazonaws.com/repo:tag` | `123456789012.dkr.ecr.us-east-1.amazonaws.com/myapp:v1.0.0` |
| GCR | `gcr.io/project-id/repo:tag` | `gcr.io/my-project/myapp:v1.0.0` |
| ACR | `registry.azurecr.io/repo:tag` | `myregistry.azurecr.io/myapp:v1.0.0` |
| GHCR | `ghcr.io/username/repo:tag` | `ghcr.io/myuser/myapp:v1.0.0` |
| Private | `registry.domain.com/repo:tag` | `registry.company.com/myapp:v1.0.0` |

## Complete Workflow Examples

### Workflow 1: First-Time Push to Docker Hub

```bash
# Step 1: Initialize Docker files
wheels docker init

# Step 2: Login to Docker Hub
wheels docker login --registry=dockerhub --username=myuser

# Step 3: Build and push
wheels docker push --local --build
```

### Workflow 2: Version Release to Docker Hub

```bash
# Build image
wheels docker build --local --tag=myapp:v1.0.0

# Push with version tag
wheels docker push --local --tag=v1.0.0

# Also push as latest
wheels docker push --local --tag=latest
```

### Workflow 3: Push to Multiple Registries

```bash
# Push to Docker Hub
wheels docker login --registry=dockerhub --username=myuser
wheels docker push --local --registry=dockerhub --username=myuser --tag=v1.0.0

# Push to GitHub Container Registry
wheels docker login --registry=ghcr --username=myuser --password=ghp_token
wheels docker push --local --registry=ghcr --username=myuser --tag=v1.0.0

# Push to ECR
wheels docker login --registry=ecr --image=123456789012.dkr.ecr.us-east-1.amazonaws.com/myapp
wheels docker push --local --registry=ecr --image=123456789012.dkr.ecr.us-east-1.amazonaws.com/myapp:v1.0.0
```

### Workflow 4: Development → Staging → Production

```bash
# Development (local testing)
wheels docker build --local
wheels docker push --local --tag=dev

# Staging (build and push to staging)
wheels docker build --local --tag=myapp:staging --nocache
wheels docker push --local --tag=staging

# Production (clean build and push)
wheels docker build --local --tag=myapp:v1.0.0 --nocache --pull
wheels docker push --local --tag=v1.0.0
wheels docker push --local --tag=latest
```

### Workflow 5: Remote Server Push

```bash
# Build on remote servers
wheels docker build --remote

# Push from remote servers to registry
wheels docker push --remote --registry=dockerhub --username=myuser --password=mytoken

# Or push from specific servers only
wheels docker push --remote --servers=1,3 --registry=dockerhub --username=myuser
```

## Docker Requirements

### Local Requirements

- Docker Desktop (Mac/Windows) or Docker Engine (Linux) installed and running
- Docker daemon accessible
- Image already built (or use `--build` flag)
- Authentication credentials (via `wheels docker login` or `--password`)

### Remote Requirements

- SSH access to remote servers
- Docker installed on remote servers
- Built image on remote server
- Server configuration file (`deploy-servers.txt` or `deploy-servers.json`)

## Troubleshooting

### Common Issues

#### Authentication Failed

**Error:** "unauthorized: authentication required" or "denied: requested access to the resource is denied"

**Solutions:**

```bash
# Login first
wheels docker login --registry=dockerhub --username=myuser

# Or provide password explicitly
wheels docker push --local --password=mytoken

# For Docker Hub, use access token instead of password
wheels docker login --registry=dockerhub --username=myuser --password=dckr_pat_abc123
```

#### Image Not Found

**Error:** "Local image 'projectname:latest' not found"

**Solutions:**

```bash
# Build the image first
wheels docker build --local

# Or use --build flag to build automatically
wheels docker push --local --build

# Check if image exists
docker images
```

#### Tag Already Exists

**Error:** "tag already exists" or attempting to overwrite existing tag

**Solution:**
```bash
# Use a new version tag
wheels docker push --local --tag=v1.0.1

# Or force overwrite by building and pushing again
wheels docker push --local --build --tag=v1.0.0
```

#### Wrong Image Name Format

**Error:** "invalid reference format" or "repository name must be lowercase"

**Solutions:**

```bash
# Ensure correct format for registry
# Docker Hub: username/repo:tag
wheels docker push --local --registry=dockerhub --username=myuser --tag=v1.0.0

# ECR: Include full registry URL
wheels docker push --local --registry=ecr --image=123456789012.dkr.ecr.us-east-1.amazonaws.com/myapp:v1.0.0

# Check current images
docker images
```

#### ECR Authentication Expiry

**Error:** "no basic auth credentials" or "token expired" for ECR

**Solution:**

ECR tokens expire after 12 hours. Re-authenticate:

```bash
# Re-login to ECR
wheels docker login --registry=ecr --image=123456789012.dkr.ecr.us-east-1.amazonaws.com/myapp

# Then push again
wheels docker push --local --registry=ecr --image=123456789012.dkr.ecr.us-east-1.amazonaws.com/myapp:latest
```

#### Network Timeout

**Error:** "net/http: TLS handshake timeout" or push taking too long

**Solutions:**

```bash
# Check internet connection
ping hub.docker.com

# Check Docker daemon
docker ps

# Try pushing again
wheels docker push --local

# For large images, push may take time - be patient
```

#### Permission Denied (Remote)

**Error:** "permission denied" when pushing from remote server

**Solutions:**

```bash
# SSH into remote server and check
ssh user@host

# Ensure user can run docker
docker ps

# Add user to docker group if needed
sudo usermod -aG docker $USER
newgrp docker

# Or use sudo (not recommended for production)
```

#### Registry Not Supported

**Error:** "Unsupported registry: xyz"

**Solution:**

```bash
# Check supported registries
# dockerhub, ecr, gcr, acr, ghcr, private

# Use correct registry name
wheels docker push --local --registry=dockerhub --username=myuser
```

### Debugging Push Issues

```bash
# Check Docker credentials
cat ~/.docker/config.json

# Verify you can login manually
docker login

# Check if image exists locally
docker images

# Try manual push to test
docker tag myapp:latest username/myapp:latest
docker push username/myapp:latest

# Check docker-config.json
cat docker-config.json
```

## Advanced Usage

### Multi-Architecture Images

Push images for multiple architectures:

```bash
# Build for multiple platforms (requires Docker Buildx)
docker buildx create --use
docker buildx build --platform linux/amd64,linux/arm64 -t username/myapp:v1.0.0 --push .

# Or push separately
wheels docker build --local --tag=myapp:amd64
wheels docker push --local --tag=v1.0.0-amd64

wheels docker build --local --tag=myapp:arm64
wheels docker push --local --tag=v1.0.0-arm64
```

### Automated Tagging Strategy

```bash
#!/bin/bash
# auto-tag-push.sh

# Get version from VERSION file
VERSION=$(cat VERSION)
COMMIT=$(git rev-parse --short HEAD)
DATE=$(date +%Y%m%d)

# Build once
wheels docker build --local

# Push multiple tags
wheels docker push --local --tag=$VERSION
wheels docker push --local --tag=$VERSION-$COMMIT
wheels docker push --local --tag=$VERSION-$DATE
wheels docker push --local --tag=latest
```

### Conditional Pushing

```bash
#!/bin/bash
# conditional-push.sh

# Only push on main branch
if [ "$GIT_BRANCH" == "main" ]; then
    echo "Main branch detected, pushing to production registry"
    wheels docker push --local --registry=dockerhub --username=produser --tag=latest
elif [ "$GIT_BRANCH" == "develop" ]; then
    echo "Develop branch detected, pushing to staging registry"
    wheels docker push --local --registry=dockerhub --username=staginguser --tag=develop
else
    echo "Feature branch, skipping push"
fi
```

### Image Size Optimization Before Push

```bash
# Build with optimization
wheels docker build --local --nocache

# Check image size
docker images myapp:latest

# If too large, optimize Dockerfile and rebuild
# Then push
wheels docker push --local
```

## Best Practices

### 1. Always Tag Production Images

```bash
# Bad - using only latest
wheels docker push --local --tag=latest

# Good - use semantic versioning
wheels docker push --local --tag=v1.0.0
wheels docker push --local --tag=latest
```

### 2. Use Access Tokens, Not Passwords

```bash
# Bad - using account password
wheels docker push --local --password=mypassword123

# Good - using access token
wheels docker push --local --password=dckr_pat_abc123xyz
```

### 3. Separate Development and Production Images

```bash
# Development
wheels docker push --local --tag=dev

# Staging
wheels docker push --local --tag=staging

# Production
wheels docker push --local --tag=v1.0.0
wheels docker push --local --tag=latest
```

### 4. Test Images Locally Before Pushing

```bash
# Build and test
wheels docker build --local
docker run -d -p 8080:8080 myapp:latest

# Test the application
curl http://localhost:8080

# If successful, push
wheels docker push --local
```

### 5. Use Meaningful Tags

```bash
# Good tagging examples
wheels docker push --local --tag=v1.0.0          # Semantic version
wheels docker push --local --tag=v1.0.0-hotfix1  # Hotfix version
wheels docker push --local --tag=20241224        # Date-based
wheels docker push --local --tag=prod-stable     # Environment + status
```

### 6. Keep Build and Push Separate for Large Images

```bash
# Build separately (can take time)
wheels docker build --local --nocache

# Push when ready
wheels docker push --local --tag=v1.0.0
```

### 7. Clean Up Old Images Locally

```bash
# After pushing, clean up local images to save space
docker images
docker rmi old-image:old-tag

# Or prune unused images
docker image prune -a
```

### 8. Document Your Registry Structure

Create a `REGISTRY.md` in your project:

```markdown
# Docker Registry Structure

## Docker Hub (Production)
- `username/myapp:latest` - Latest stable release
- `username/myapp:v*` - Versioned releases

## GHCR (Development)
- `ghcr.io/username/myapp:dev` - Development builds
- `ghcr.io/username/myapp:pr-*` - PR builds

## ECR (Internal)
- `123456789012.dkr.ecr.us-east-1.amazonaws.com/myapp:staging` - Staging
```

### 9. Automate Version Bumping

```bash
#!/bin/bash
# bump-and-push.sh

# Increment version
npm version patch  # or use semantic-release

# Get new version
VERSION=$(node -p "require('./package.json').version")

# Build and push
wheels docker build --local
wheels docker push --local --tag=v$VERSION
wheels docker push --local --tag=latest

# Git tag
git tag v$VERSION
git push --tags
```

### 10. Monitor Push Metrics

Track push times and sizes for optimization:

```bash
# Before push
START_TIME=$(date +%s)

# Push
wheels docker push --local --tag=v1.0.0

# After push
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))
echo "Push took $DURATION seconds"
```

## Security Considerations

### 1. Never Commit Credentials

```bash
# Add to .gitignore
echo "docker-config.json" >> .gitignore
echo ".dockercfg" >> .gitignore
echo "*.pem" >> .gitignore
```

### 2. Use Registry Access Controls

- Enable private repositories for sensitive images
- Use registry webhooks for security scanning
- Implement image signing for production

### 3. Scan Images Before Pushing

```bash
# Install trivy or similar scanner
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  aquasec/trivy image myapp:latest

# Only push if scan passes
wheels docker push --local --tag=v1.0.0
```

### 4. Limit Registry Permissions

- Use read-only tokens for pulling
- Use write tokens for push operations
- Rotate tokens regularly

### 5. Enable Image Vulnerability Scanning

Most registries offer built-in scanning:
- Docker Hub: Enable Vulnerability Scanning
- ECR: Enable Enhanced Scanning
- GHCR: Enable Dependabot
- ACR: Enable Microsoft Defender

## Related Commands

- [wheels docker init](docker-init.md) - Initialize Docker configuration files
- [wheels docker build](docker-build.md) - Build Docker images
- [wheels docker login](docker-login.md) - Authenticate with registries
- [wheels docker deploy](docker-deploy.md) - Build and deploy Docker containers
- [wheels docker logs](docker-logs.md) - View container logs
- [wheels docker exec](docker-exec.md) - Execute commands in containers
- [wheels docker stop](docker-stop.md) - Stop Docker containers

---

**Note**: This command is part of the Wheels CLI tool suite for Docker management.