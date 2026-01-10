# wheels docker build

Unified Docker build command for Wheels apps. Builds Docker images locally or on remote servers.

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
| `--local` | Build Docker image on local machine | `false` |
| `--remote` | Build Docker image on remote server(s) | `false` |
| `--servers` | Comma-separated list of server numbers to build on (e.g., "1,3,5") - for remote only | `""` |
| `--tag` | Custom tag for the Docker image (default: project-name:latest) | `""` |
| `--nocache` | Build without using cache | `false` |
| `--pull` | Always attempt to pull a newer version of the base image | `false` |

## Detailed Examples

### Local Development Builds

**Standard Build**
Builds the image using the `Dockerfile` in the current directory. Tags it with the folder name (e.g., `my-app:latest`).
```bash
wheels docker build --local
```

**Force Rebuild**
If you've changed base image dependencies or want to ensure a clean build, use `--nocache` and `--pull`.
```bash
wheels docker build --local --nocache --pull
```

**Custom Tagging**
Useful when building specific versions for release.
```bash
wheels docker build --local --tag=my-company/my-app:v2.0.0
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

## How It Works

### Local Build Strategy (`--local`)

1.  **Prerequisite Check**: Verifies that Docker is installed and running.
2.  **Compose Detection**:
    *   **If `docker-compose.yml` exists**: It executes `docker compose build`. This is ideal for complex apps with multiple services (app, db, redis).
    *   **If only `Dockerfile` exists**: It executes `docker build -t [tag] .`.
3.  **Tagging**: If no custom tag is provided, it sanitizes the current directory name to create a valid Docker tag (e.g., `My Project` -> `my-project:latest`).

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
