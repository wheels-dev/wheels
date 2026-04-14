# wheels docker build

Unified Docker build command for Wheels apps. Builds Docker images locally or on remote servers. This is useful for creating images that can be deployed later, testing build processes, or preparing images for remote deployment.

## Prerequisites

Before using this command, you must first initialize Docker configuration files:

```bash
wheels docker init
```

This will create the necessary `Dockerfile` and optionally `docker-compose.yml` files in your project directory.

## Synopsis

```bash
wheels docker build [options]
```

## Description

The `wheels docker build` command handles the building of Docker images for your application. It can build images on your local machine or trigger builds on configured remote servers. 

**Centralized Configuration**:
- **Source of Truth**: This command prioritizes settings from `config/deploy.yml` for server lists and image repository names.
- **Strategy Detection**: It automatically detects if you are using a `docker-compose.yml` file or a standalone `Dockerfile` and adjusts its build strategy accordingly.

## Options

| Option | Description | Default |
|--------|-------------|---------|
| `--local` | Build Docker image on local machine | `true` |
| `--remote` | Build Docker image on remote server(s) | `false` |
| `--servers` | Comma-separated list of server numbers to build on (e.g., "1,3,5") - for remote only | `""` |
| `--nocache` | Build without using cache | `false` |
| `--pull` | Always attempt to pull a newer version of the base image | `false` |

**Note**: If neither `--local` nor `--remote` is specified, `--local` is used by default.

## Detailed Examples

### Local Development Builds

**Standard Build**
Builds the image using the `Dockerfile` in the current directory.
```bash
wheels docker build --local
```

**Force Rebuild**
If you've changed base image dependencies or want to ensure a clean build, use `--nocache` and `--pull`.
```bash
wheels docker build --local --nocache --pull
```

### Remote Server Builds

**Build on All Servers**
Triggers the build process on every server listed in your `config/deploy.yml` (or legacy `deploy-servers.txt`/`deploy-servers.json`).
```bash
wheels docker build --remote
```

**Build on Specific Servers**
Useful if you want to update only a subset of servers (e.g., only the staging servers).
```bash
# Build only on the first and third server defined in your config
wheels docker build --remote --servers=1,3
```

**Remote Build with Cache Busting**
Forces the remote servers to pull fresh base images and ignore build cache.
```bash
wheels docker build --remote --nocache --pull
```

### Remote Build Requirements

If you plan to use --remote builds, your server must be prepared to allow automated SSH execution and Docker access.

The Wheels CLI executes Docker commands remotely over SSH, for example:
```bash
ssh user@host "docker ps"
ssh user@host "docker compose build"
```
Because these commands run non-interactively, the server must support passwordless SSH authentication and the user must have permission to run Docker commands.

#### Configure Passwordless SSH Access

Generate an SSH key if you do not already have one:
```bash
ssh-keygen -t rsa -b 4096
```
Press Enter to accept the default location.

Copy your public key to the remote server:
```bash
ssh-copy-id user@host
```
Verify that you can log in without entering a password:
```bash
ssh user@host
```
If configured correctly, the connection should work without prompting for a password.

#### Ensure Docker Permissions

The remote user must have permission to run Docker commands. Otherwise you may see an error such as:
```
permission denied while trying to connect to the Docker daemon socket
```
Add the user to the Docker group on the remote server:
```bash
sudo usermod -aG docker user
```
Apply the group changes:
```bash
newgrp docker
```
Alternatively, log out and log back into the server.

Verify Docker access:
```bash
docker ps
```
If this command runs successfully without sudo, the server is correctly configured.

## How It Works

### Local Build Strategy (`--local`)

1.  **Prerequisite Check**: Verifies that Docker is installed and running.
2.  **Compose Detection**:
    *   **If `docker-compose.yml` exists**: It executes `docker compose build`. This is ideal for complex apps with multiple services (app, db, redis).
    *   **If only `Dockerfile` exists**: It executes `docker build -t [tag] .`.

### Remote Build Strategy (`--remote`)

1.  **Server Connection**: Reads your server config and connects via SSH.
2.  **Environment Prep**:
    *   Checks if the remote directory exists.
    *   **Auto-Upload**: If the directory is missing, it automatically tars and uploads your source code to the server.
3.  **Remote Execution**:
    *   It intelligently detects if the remote user has `docker` group privileges.
    *   If not, it attempts to use `sudo` for docker commands.
    *   It runs the appropriate build command (Compose or Standard) on the remote host.

## Server Configuration
 
This command looks for server configurations in this order of priority:
 
**Option A: `config/deploy.yml` (Recommended)**
The primary source of truth for all Wheels Docker operations.
```yaml
name: myapp
image: myuser/myapp
servers:
  - host: 192.168.1.100
    user: ubuntu
    role: production
```

**Option B: `deploy-servers.json` (Legacy)**
```json
{
  "servers": [
    {
      "host": "192.168.1.100",
      "user": "ubuntu",
      "port": 22,
      "remoteDir": "/var/www/myapp",
      "imageName": "custom-image-name"
    }
  ]
}
```
 
**Option C: `deploy-servers.txt` (Legacy)**
Space-separated columns: Host, User, Port (optional).
```text
# Host          User    Port
192.168.1.100   ubuntu  22
prod-1.example.com deploy 2202
prod-2.example.com deploy 2202
```

If **port is omitted**, it defaults to:
```text
22
```

**Extended Format (Recommended for Remote Builds)**

You can optionally define:

- remoteDir → Directory where the app lives on the server
- imageName → Custom image name override
```text
# Host                User        Port   RemoteDir               ImageName
192.168.1.100         ubuntu      22     /var/www/myapp          myapp-prod
staging.example.com   deploy      2222   /home/deploy/app        myapp-staging
```

## Build vs Deploy

Understanding when to use `build` vs `deploy`:

### Use `wheels docker build` when:
- You want to create an image without running it
- Testing Docker configuration changes
- Preparing images for later deployment
- Building on CI/CD pipeline
- Building on remote servers for later use

### Use `wheels docker deploy` when:
- You want to build AND run the application
- Deploying to servers with containers running
- Full deployment workflow needed
- Starting services immediately

### Combined Workflow:
```bash
# 1. Build the image
wheels docker build --nocache

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
- [wheels docker logs](docker-logs.md) - View container logs
- [wheels docker exec](docker-exec.md) - Execute commands in containers
- [wheels docker stop](docker-stop.md) - Stop Docker containers

**Note**: This command is part of the Wheels CLI tool suite for Docker management.