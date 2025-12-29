# Wheels Docker Login Command Guide

## Overview

The `wheels docker login` command authenticates with container registries, allowing you to push and pull private images. It supports multiple popular registries including Docker Hub, Amazon ECR, Google Container Registry, Azure Container Registry, GitHub Container Registry, and private registries.

## Command Syntax

```bash
wheels docker login [OPTIONS]
```

## Parameters

| Parameter | Type | Default | Required | Description |
|-----------|------|---------|----------|-------------|
| `--registry` | string | `"dockerhub"` | No | Registry type: dockerhub, ecr, gcr, acr, ghcr, private |
| `--username` | string | `""` | Yes* | Registry username (required for dockerhub, ghcr, private) |
| `--password` | string | `""` | No | Registry password or token (will prompt if empty) |
| `--image` | string | `""` | Conditional | Image name (required for ECR/ACR to determine region/registry) |
| `--local` | boolean | `true` | No | Execute login locally |

**Note:** Username requirements vary by registry type. For ECR and GCR, authentication is handled differently.

## Supported Registries

| Registry | Value | Username Required | Password Handling | Additional Requirements |
|----------|-------|-------------------|-------------------|------------------------|
| Docker Hub | `dockerhub` | Yes | Prompted/provided | Docker Hub account |
| Amazon ECR | `ecr` | No* | AWS CLI | AWS credentials configured, `--image` parameter |
| Google GCR | `gcr` | No* | gcloud CLI | gcloud configured, service account |
| Azure ACR | `acr` | Yes | Prompted/provided | Azure credentials, `--image` parameter |
| GitHub CR | `ghcr` | Yes | Personal Access Token | GitHub PAT with package permissions |
| Private Registry | `private` | Yes | Prompted/provided | Custom registry URL in `--image` |

*Uses CLI tools for authentication

## Usage Examples

### Docker Hub Login

#### Basic Docker Hub Login (Interactive)

Login to Docker Hub with password prompt:

```bash
wheels docker login --registry=dockerhub --username=myusername
```

You'll be prompted to enter your password securely.

#### Docker Hub Login with Password

Provide password directly (less secure, not recommended for production):

```bash
wheels docker login --registry=dockerhub --username=myusername --password=mypassword
```

#### Docker Hub Login with Access Token

Use a personal access token instead of password:

```bash
wheels docker login --registry=dockerhub --username=myusername --password=dckr_pat_abc123xyz
```

### Amazon ECR (Elastic Container Registry)

#### ECR Login with Image URL

The `--image` parameter is required to determine the AWS region and registry:

```bash
wheels docker login --registry=ecr --image=123456789012.dkr.ecr.us-east-1.amazonaws.com/myapp:latest
```

#### ECR Login with Different Regions

```bash
# US East region
wheels docker login --registry=ecr --image=123456789012.dkr.ecr.us-east-1.amazonaws.com/myapp

# EU West region
wheels docker login --registry=ecr --image=123456789012.dkr.ecr.eu-west-1.amazonaws.com/myapp

# Asia Pacific region
wheels docker login --registry=ecr --image=123456789012.dkr.ecr.ap-southeast-1.amazonaws.com/myapp
```

**Prerequisites for ECR:**
- AWS CLI installed and configured
- AWS credentials set up (via `aws configure` or environment variables)
- Proper IAM permissions for ECR

### Google Container Registry (GCR)

#### GCR Login

```bash
wheels docker login --registry=gcr --image=gcr.io/my-project-id/myapp:latest
```

**GCR Authentication Methods:**

Different authentication formats supported:
```bash
# Standard GCR
wheels docker login --registry=gcr --image=gcr.io/project-id/image

# Regional GCR (US)
wheels docker login --registry=gcr --image=us.gcr.io/project-id/image

# Regional GCR (EU)
wheels docker login --registry=gcr --image=eu.gcr.io/project-id/image

# Regional GCR (Asia)
wheels docker login --registry=gcr --image=asia.gcr.io/project-id/image
```

**Prerequisites for GCR:**
- gcloud CLI installed and configured
- Service account with Container Registry permissions
- gcloud authentication set up (`gcloud auth configure-docker`)

### Azure Container Registry (ACR)

#### ACR Login with Username

```bash
wheels docker login --registry=acr --username=myregistry --image=myregistry.azurecr.io/myapp:latest
```

#### ACR Login with Service Principal

```bash
wheels docker login --registry=acr --username=service-principal-id --password=service-principal-password --image=myregistry.azurecr.io/myapp
```

**Prerequisites for ACR:**
- Azure CLI installed (optional but recommended)
- Azure Container Registry credentials
- Registry URL in the format: `registryname.azurecr.io`

### GitHub Container Registry (GHCR)

#### GHCR Login with Personal Access Token

```bash
wheels docker login --registry=ghcr --username=githubusername --password=ghp_yourpersonalaccesstoken
```

#### GHCR Login (Interactive)

```bash
wheels docker login --registry=ghcr --username=githubusername
# Password will be prompted
```

**Creating a GitHub Personal Access Token:**
1. Go to GitHub Settings → Developer settings → Personal access tokens
2. Generate new token (classic)
3. Select scopes: `write:packages`, `read:packages`, `delete:packages`
4. Copy the token (starts with `ghp_`)

**GHCR Image Format:**
```bash
ghcr.io/username/repository-name:tag
ghcr.io/organization/repository-name:tag
```

### Private Registry Login

#### Private Registry Login

```bash
wheels docker login --registry=private --username=registryuser --image=registry.company.com/myapp:latest
```

#### Private Registry with Custom Port

```bash
wheels docker login --registry=private --username=registryuser --image=registry.company.com:5000/myapp:latest
```

#### Self-Hosted Registry

```bash
wheels docker login --registry=private --username=admin --password=secret --image=localhost:5000/myapp
```

## Configuration File

After successful login, credentials are saved to `docker-config.json` in your project root:

```json
{
  "registry": "dockerhub",
  "username": "myusername",
  "image": ""
}
```

This configuration is used by the `wheels docker push` command for automatic registry detection.

**Note:** The password is NOT saved in this file. Docker stores credentials securely in the system keychain or credentials store.

## How It Works

### Authentication Flow

1. **Validate Parameters**
   - Check if registry type is supported
   - Verify required parameters for the registry type
   - Validate image format if provided

2. **Docker Installation Check**
   - Verify Docker is installed and running locally
   - Ensure Docker daemon is accessible

3. **Registry-Specific Authentication**
   - **Docker Hub/GHCR/Private:** Uses `docker login` with username/password
   - **ECR:** Uses AWS CLI to get temporary credentials
   - **GCR:** Uses gcloud helper for authentication
   - **ACR:** Uses Azure credentials with `docker login`

4. **Save Configuration**
   - Stores registry settings in `docker-config.json`
   - Does not store sensitive credentials in the file
   - Used for subsequent push operations

### Where Credentials Are Stored

Docker stores credentials securely in:

- **macOS:** macOS Keychain
- **Windows:** Windows Credential Manager
- **Linux:** 
  - `~/.docker/config.json` (with credential helpers)
  - Or encrypted using `pass`, `secretservice`, or other helpers

## Registry-Specific Setup

### Docker Hub Setup

1. **Create Docker Hub Account**
   - Visit https://hub.docker.com
   - Sign up for free account

2. **Create Access Token (Recommended)**
   ```bash
   # Login to Docker Hub web interface
   # Account Settings → Security → New Access Token
   # Use token instead of password
   wheels docker login --registry=dockerhub --username=myuser --password=dckr_pat_token
   ```

### Amazon ECR Setup

1. **Install AWS CLI**
   ```bash
   # macOS
   brew install awscli
   
   # Linux
   curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
   unzip awscliv2.zip
   sudo ./aws/install
   
   # Windows
   # Download MSI installer from AWS website
   ```

2. **Configure AWS Credentials**
   ```bash
   aws configure
   # Enter: AWS Access Key ID
   # Enter: AWS Secret Access Key
   # Enter: Default region (e.g., us-east-1)
   # Enter: Default output format (json)
   ```

3. **Verify ECR Access**
   ```bash
   aws ecr describe-repositories
   ```

4. **Login to ECR**
   ```bash
   wheels docker login --registry=ecr --image=123456789012.dkr.ecr.us-east-1.amazonaws.com/myapp
   ```

### Google Container Registry Setup

1. **Install gcloud CLI**
   ```bash
   # macOS
   brew install --cask google-cloud-sdk
   
   # Linux
   curl https://sdk.cloud.google.com | bash
   exec -l $SHELL
   
   # Windows
   # Download installer from Google Cloud
   ```

2. **Authenticate with gcloud**
   ```bash
   gcloud auth login
   gcloud config set project YOUR-PROJECT-ID
   ```

3. **Configure Docker for GCR**
   ```bash
   gcloud auth configure-docker
   ```

4. **Login via Wheels**
   ```bash
   wheels docker login --registry=gcr --image=gcr.io/my-project/myapp
   ```

### Azure Container Registry Setup

1. **Install Azure CLI (Optional)**
   ```bash
   # macOS
   brew install azure-cli
   
   # Linux
   curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
   
   # Windows
   # Download MSI from Microsoft
   ```

2. **Get ACR Credentials**
   ```bash
   # Via Azure Portal
   # Container Registry → Access keys → Enable Admin user
   # Copy Username and Password
   
   # Or via CLI
   az acr credential show --name myregistry
   ```

3. **Login**
   ```bash
   wheels docker login --registry=acr --username=myregistry --image=myregistry.azurecr.io/myapp
   ```

### GitHub Container Registry Setup

1. **Create Personal Access Token**
   - GitHub → Settings → Developer settings → Personal access tokens
   - Generate new token (classic)
   - Select scopes: `write:packages`, `read:packages`
   - Copy token (starts with `ghp_`)

2. **Login to GHCR**
   ```bash
   wheels docker login --registry=ghcr --username=your-github-username --password=ghp_yourtoken
   ```

3. **Verify Authentication**
   ```bash
   docker pull ghcr.io/your-username/your-image:latest
   ```

## Docker Requirements

### Local Requirements

- Docker Desktop (Mac/Windows) or Docker Engine (Linux) installed and running
- Docker daemon accessible
- Internet connection for registry authentication

### Command-Line Tools (Registry-Specific)

| Registry | Required Tool | Installation |
|----------|--------------|--------------|
| Docker Hub | Docker CLI | Included with Docker |
| ECR | AWS CLI | `brew install awscli` or download from AWS |
| GCR | gcloud CLI | `brew install google-cloud-sdk` or download |
| ACR | Azure CLI (optional) | `brew install azure-cli` or download |
| GHCR | Docker CLI | Included with Docker |
| Private | Docker CLI | Included with Docker |

## Troubleshooting

### Common Issues

#### Docker Not Running

**Error:** "Docker is not installed or not accessible"

**Solution:**
```bash
# Check Docker status
docker --version
docker ps

# Start Docker Desktop (Mac/Windows)
# Or start Docker daemon (Linux)
sudo systemctl start docker
```

#### Authentication Failed

**Error:** "Login failed" or "unauthorized"

**Solutions:**

For **Docker Hub:**
```bash
# Verify credentials
# Try password reset at hub.docker.com
# Use access token instead of password
wheels docker login --registry=dockerhub --username=user --password=dckr_pat_token
```

For **ECR:**
```bash
# Verify AWS credentials
aws sts get-caller-identity

# Check ECR permissions
aws ecr describe-repositories

# Reconfigure AWS
aws configure
```

For **GCR:**
```bash
# Verify gcloud authentication
gcloud auth list

# Re-authenticate
gcloud auth login
gcloud auth configure-docker
```

For **GHCR:**
```bash
# Verify token has correct permissions
# Regenerate token with write:packages scope
# Ensure username is correct (case-sensitive)
```

#### Invalid Image Format

**Error:** "Invalid image format" or "Could not parse registry URL"

**Solution:**
```bash
# Ensure correct format for each registry:

# Docker Hub
--image=username/repository:tag

# ECR
--image=123456789012.dkr.ecr.region.amazonaws.com/repository:tag

# GCR
--image=gcr.io/project-id/repository:tag

# ACR
--image=registryname.azurecr.io/repository:tag

# GHCR
--image=ghcr.io/username/repository:tag
```

#### ECR Region Issues

**Error:** "No basic auth credentials" for ECR

**Solution:**
```bash
# Ensure image URL includes correct region
wheels docker login --registry=ecr --image=123456789012.dkr.ecr.us-east-1.amazonaws.com/myapp

# Verify AWS region configuration
aws configure get region

# Set region explicitly
export AWS_REGION=us-east-1
```

#### Permission Denied

**Error:** "Permission denied" when running Docker commands

**Solution:**
```bash
# Add user to docker group (Linux)
sudo usermod -aG docker $USER
newgrp docker

# Restart Docker Desktop (Mac/Windows)
```

### Debug Mode

To troubleshoot authentication issues:

```bash
# Check Docker credentials
docker-credential-desktop list  # macOS
docker-credential-wincred list  # Windows
cat ~/.docker/config.json       # Linux

# Test manual login
docker login registry.example.com

# Verify stored credentials
docker logout registry.example.com
docker login registry.example.com
```

## Security Best Practices

### 1. Use Access Tokens Instead of Passwords

```bash
# Docker Hub - create access token
wheels docker login --registry=dockerhub --username=user --password=dckr_pat_abc123

# GitHub - use personal access token
wheels docker login --registry=ghcr --username=user --password=ghp_token123
```

### 2. Limit Token Permissions

- Grant minimum required permissions
- Use read-only tokens when only pulling images
- Use tokens for authentication

### 3. Rotate Credentials Regularly

```bash
# Logout and login with new credentials
docker logout
wheels docker login --registry=dockerhub --username=user
```

### 4. Avoid Hardcoding Passwords

```bash
# Bad - password in command
wheels docker login --registry=dockerhub --username=user --password=secret123

# Good - let it prompt
wheels docker login --registry=dockerhub --username=user

# Better - use environment variable
export DOCKER_PASSWORD="secret123"
wheels docker login --registry=dockerhub --username=user --password=$DOCKER_PASSWORD
```

### 5. Never Hardcode Credentials

```bash
# Never commit credentials to version control
echo "docker-config.json" >> .gitignore
```

### 6. Use Service Accounts for Production

- **ECR:** Use IAM roles instead of access keys
- **GCR:** Use service accounts with limited permissions
- **ACR:** Use service principals with specific roles
- **GHCR:** Use machine users or bot accounts

### 7. Enable Two-Factor Authentication

Enable 2FA on registry accounts where supported:
- Docker Hub: Account Settings → Security
- GitHub: Settings → Password and authentication

### 8. Audit Access Logs

Regularly review access logs:
```bash
# AWS CloudTrail for ECR
# Azure Monitor for ACR
# GitHub audit log for GHCR
```

## Multiple Registry Workflow

Working with multiple registries:

```bash
# Login to Docker Hub
wheels docker login --registry=dockerhub --username=user1

# Login to GitHub Container Registry
wheels docker login --registry=ghcr --username=user2

# Login to ECR
wheels docker login --registry=ecr --image=123456789012.dkr.ecr.us-east-1.amazonaws.com/myapp

# Build once
wheels docker build --tag=myapp:v1.0.0

# Push to multiple registries
docker tag myapp:v1.0.0 user1/myapp:v1.0.0
docker push user1/myapp:v1.0.0

docker tag myapp:v1.0.0 ghcr.io/user2/myapp:v1.0.0
docker push ghcr.io/user2/myapp:v1.0.0

docker tag myapp:v1.0.0 123456789012.dkr.ecr.us-east-1.amazonaws.com/myapp:v1.0.0
docker push 123456789012.dkr.ecr.us-east-1.amazonaws.com/myapp:v1.0.0
```

## Verification

### Verify Successful Login

```bash
# Check Docker config
cat ~/.docker/config.json

# Should show authenticated registries
{
  "auths": {
    "https://index.docker.io/v1/": {},
    "ghcr.io": {},
    "123456789012.dkr.ecr.us-east-1.amazonaws.com": {}
  }
}
```

### Test Authentication

```bash
# Try pulling a private image
docker pull your-registry/private-image:latest

# Or push a test image
docker tag hello-world your-registry/test:latest
docker push your-registry/test:latest
```

## Related Commands

- [wheels docker init](docker-init.md) - Initialize Docker configuration files
- [wheels docker build](docker-build.md) - Build Docker images
- [wheels docker deploy](docker-deploy.md) - Build and deploy Docker containers
- [wheels docker push](docker-push.md) - Push Docker images to registries
- [wheels docker logs](docker-logs.md) - View container logs
- [wheels docker exec](docker-exec.md) - Execute commands in containers
- [wheels docker stop](docker-stop.md) - Stop Docker containers

---

**Note**: This command is part of the Wheels CLI tool suite for Docker management.