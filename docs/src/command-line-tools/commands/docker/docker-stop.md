# wheels docker stop

Unified Docker stop command for Wheels apps. Stops containers locally or on remote servers.

## Synopsis

```bash
wheels docker stop [options]
```

## Description

The `wheels docker stop` command halts running containers. It supports stopping containers locally or across multiple remote servers.

**Centralized Configuration**:
- **Source of Truth**: This command prioritizes settings from `config/deploy.yml` for server lists and project names, ensuring you only stop the containers relevant to your current project.

## Options

| Option | Description | Default |
|--------|-------------|---------|
| `--local` | Stop containers on local machine | `true` |
| `--remote` | Stop containers on remote server(s) | `false` |
| `--servers` | Specific servers to stop (defaults to `config/deploy.yml`) | `""` |
| `--removeContainer` | Also remove the container after stopping | `false` |

**Note**: If neither `--local` nor `--remote` is specified, `--local` is used by default.

## Detailed Examples

### Local Management

**Stop Services**
Stops the running containers but keeps them (and their logs/state) intact.
```bash
wheels docker stop --local
```

**Stop and Cleanup**
Stops the containers and removes them. This is useful for a full reset or to free up names.
```bash
wheels docker stop --local --removeContainer
```

### Remote Management

**Stop All Remote Servers**
Halts the application on all configured servers. Useful for maintenance windows.
```bash
wheels docker stop --remote
```

**Stop Specific Servers**
Stops the application only on specific servers (e.g., taking a node out of rotation).
```bash
wheels docker stop --remote --servers=1
```

**Full Remote Cleanup**
Stops and removes containers on remote servers.
```bash
wheels docker stop --remote --removeContainer
```

## How It Works

1.  **Environment Detection**: It checks for `docker-compose.yml`.
2.  **Graceful Shutdown**:
    *   **Docker Compose**: Runs `docker compose down`. This stops and removes containers, networks, and volumes defined in the compose file.
    *   **Standard Docker**: Runs `docker stop [container_name]`. This sends `SIGTERM` to the main process, allowing it to shut down gracefully.
3.  **Removal (`--removeContainer`)**:
    *   If using standard Docker, this flag triggers `docker rm [container_name]` after stopping.
    *   If using Docker Compose, `down` already removes containers, so this flag is redundant but harmless.

## Best Practices

### 1. Always Test Locally First

Before stopping remote servers:
```bash
# Test the stop command locally
wheels docker stop --local

# Verify it works as expected
docker ps -a
```

### 2. Use Server Selection for Staged Rollouts

Don't stop all servers at once in production:
```bash
# Stop first half
wheels docker stop --remote --servers=1,2

# Verify, then stop second half
wheels docker stop --remote --servers=3,4
```

### 3. Remove Containers During Maintenance

For major updates or troubleshooting:
```bash
wheels docker stop --remote --removeContainer
```

This ensures a completely clean slate for the next deployment.

### 4. Check Status After Stopping

Verify containers are stopped:
```bash
wheels docker stop --local
docker ps -a
```

## Common Workflows

### Development Cycle

```bash
# 1. Stop local containers
wheels docker stop --local --removeContainer

# 2. Make code changes
# ... edit files ...

# 3. Rebuild and restart
wheels docker build --local
wheels docker deploy --local
```

### Deployment Update

```bash
# 1. Build new image
wheels docker build --remote

# 2. Stop old containers (staged)
wheels docker stop --remote --servers=1,3,5

# 3. Deploy new version
wheels docker deploy --remote --servers=1,3,5

# 4. Stop remaining servers
wheels docker stop --remote --servers=2,4,6

# 5. Deploy to remaining servers
wheels docker deploy --remote --servers=2,4,6
```

### Emergency Rollback

```bash
# 1. Stop all production servers
wheels docker stop --remote --servers=1,2,3,4

# 2. Deploy previous version
wheels docker deploy --remote --servers=production-servers.json

# 3. Verify deployment
wheels docker logs --remote --servers=1 --tail=100
```

### Complete Cleanup

```bash
# Stop and remove everything
wheels docker stop --local --removeContainer
wheels docker stop --remote --removeContainer
```

## Additional Notes

- Default mode is `--local` if neither `--local` nor `--remote` is specified
- Cannot specify both `--local` and `--remote` simultaneously
- SSH connections use key-based authentication (password auth not supported)
- Containers are stopped gracefully with default Docker stop timeout (10 seconds)
- Docker Compose down removes networks automatically
- The `--removeContainer` flag only removes the container, not the image
- Server selection is 1-indexed (starts at 1, not 0)
- Invalid server numbers are skipped with warnings
- The command attempts to detect sudo requirements automatically
- Exit status reflects overall operation success

## Related Commands

- [wheels docker init](docker-init.md) - Initialize Docker configuration files
- [wheels docker build](docker-build.md) - Build Docker images
- [wheels docker deploy](docker-deploy.md) - Build and deploy Docker containers
- [wheels docker logs](docker-logs.md) - View container logs
- [wheels docker exec](docker-exec.md) - Execute commands in containers

**Note**: This command is part of the Wheels CLI tool suite for Docker management.