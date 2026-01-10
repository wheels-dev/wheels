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
| `--local` | Stop containers on local machine | `false` |
| `--remote` | Stop containers on remote server(s) | `false` |
| `--servers` | Specific servers to stop (defaults to `config/deploy.yml`) | `""` |
| `--removeContainer` | Also remove the container after stopping | `false` |

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
