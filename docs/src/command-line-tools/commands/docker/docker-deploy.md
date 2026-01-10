# wheels docker deploy

Unified Docker deployment command for Wheels apps. Deploys applications locally or to remote servers with support for Blue/Green deployment.

## Synopsis

```bash
wheels docker deploy [options]
```

## Description

The `wheels docker deploy` command manages the deployment lifecycle of your Dockerized application. It can start containers locally for development or testing, and perform robust deployments to remote servers, including zero-downtime Blue/Green deployments.

**Centralized Configuration**:
- **Source of Truth**: This command prioritizes settings from `config/deploy.yml` for server lists and target environments.
- **Interactive Versioning**: When multiple images or tags are detected, the command provides an interactive picker to choose exactly which version to deploy.

## Options

| Option | Description | Default |
|--------|-------------|---------|
| `--local` | Deploy to local Docker environment | `false` |
| `--remote` | Deploy to remote server(s) | `false` |
| `--environment` | Deployment environment (production, staging) - for local deployment | `production` |
| `--db` | Database to use (h2, mysql, postgres, mssql) - for local deployment | `mysql` |
| `--cfengine` | ColdFusion engine to use (lucee, adobe) - for local deployment | `lucee` |
| `--optimize` | Enable production optimizations - for local deployment | `true` |
| `--servers` | Server configuration file (defaults to `config/deploy.yml`) | `""` |
| `--skipDockerCheck` | Skip Docker installation check on remote servers | `false` |
| `--blueGreen` | Enable Blue/Green deployment strategy (zero downtime) - for remote deployment | `false` |

## Detailed Examples

### Local Deployment

**Quick Start (Production Mode)**
Starts the application locally, mimicking a production environment (optimized settings, no hot-reload).
```bash
wheels docker deploy --local
```

**Staging Environment**
Deploys locally with staging environment variables.
```bash
wheels docker deploy --local --environment=staging
```

**Custom Stack**
Deploys locally using PostgreSQL and Adobe ColdFusion.
```bash
wheels docker deploy --local --db=postgres --cfengine=adobe
```

### Remote Deployment

**Standard Deployment**
Deploys to all servers defined in your configuration (starting with `config/deploy.yml`). This stops the existing container, pulls/builds the new one, and starts it.
```bash
wheels docker deploy --remote
```

**Zero-Downtime Blue/Green Deployment**
Uses a Blue/Green strategy to ensure no downtime. Requires Nginx (automatically handled).
```bash
wheels docker deploy --remote --blueGreen
```

**Deploy to Specific Servers**
Uses an override server list file for deployment.
```bash
wheels docker deploy --remote --servers=staging-servers.yml
```

**Skip Docker Checks**
Speeds up deployment if you know Docker is already installed and configured on the remote servers.
```bash
wheels docker deploy --remote --skipDockerCheck
```

## Deployment Strategies Explained

### 1. Standard Remote Deployment
This is the default strategy when `--remote` is used.
1.  **Upload**: Tars and uploads your project source code to the remote server.
2.  **Build/Compose**:
    *   If `docker-compose.yml` exists: Runs `docker compose down` followed by `docker compose up -d --build`.
    *   If `Dockerfile` exists: Builds the image, stops/removes the old container, and runs the new one.
3.  **Downtime**: There is a short period (seconds to minutes) where the service is unavailable while the container restarts.

### 2. Blue/Green Deployment (`--blueGreen`)
This strategy is designed for zero-downtime updates.
1.  **State Detection**: The script checks which "color" (Blue or Green) is currently active.
2.  **Parallel Deployment**: It spins up the *new* version (e.g., Green) alongside the *old* version (Blue).
3.  **Health Check**: It waits for the new container to initialize.
4.  **Traffic Switch**: It updates an Nginx proxy to point traffic to the new container.
5.  **Cleanup**: The old container is stopped and removed.
*   **Requirement**: This strategy automatically sets up an `nginx-proxy` container on the remote server if one doesn't exist.

## Troubleshooting

**"User requires passwordless sudo access"**
If the remote user is not part of the `docker` group, the CLI tries to use `sudo`. If `sudo` requires a password, deployment will fail.
*   **Fix**: SSH into the server and run `sudo usermod -aG docker $USER`, then log out and back in. Or configure passwordless sudo.

**"SSH connection failed"**
*   **Fix**: Ensure your SSH keys are correctly loaded (`ssh-add -l`) and you can manually SSH into the server (`ssh user@host`).

**"Deployment script failed"**
*   **Fix**: Run with verbose output or check the logs on the remote server. Ensure the remote server has enough disk space.

## Server Configuration

See [wheels docker build](docker-build.md#server-configuration) for details on `deploy-servers.txt` and `deploy-servers.json`.
