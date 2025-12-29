# wheels docker logs

View deployment logs from servers.

## Synopsis

```bash
wheels docker logs [options]
```

## Description

The `wheels docker logs` command fetches and displays logs from running containers. It supports fetching logs from specific services (app, db) and can stream logs in real-time. It abstracts away the complexity of finding the correct container ID, especially in multi-server or Blue/Green environments.

## Options

| Option | Description | Default |
|--------|-------------|---------|
| `--servers` | Specific servers to check (comma-separated list of hosts or file path) | `""` |
| `--tail` | Number of lines to show | `100` |
| `--follow` | Follow log output in real-time | `false` |
| `--service` | Service to show logs for: `app` or `db` | `app` |
| `--since` | Show logs since timestamp (e.g., "2023-01-01", "1h", "5m") | `""` |

## Detailed Examples

### Basic Usage

**View Recent Logs**
Fetches the last 100 lines of logs from the application container on all configured servers.
```bash
wheels docker logs
```

**View Database Logs**
Fetches logs from the database service container.
```bash
wheels docker logs --service=db
```

### Real-Time Monitoring

**Follow Logs**
Streams logs in real-time from a specific server. Useful for debugging startup issues or watching traffic.
*   **Note**: You must specify a single server when using `--follow`.
```bash
wheels docker logs --follow --servers=web1.example.com
```

### Filtering Logs

**Show More History**
View the last 500 lines of logs.
```bash
wheels docker logs --tail=500
```

**Time-Based Filtering**
View logs generated in the last hour.
```bash
wheels docker logs --since=1h
```

**Specific Time Range**
View logs since a specific timestamp (ISO 8601 format).
```bash
wheels docker logs --since="2023-10-27T14:00:00"
```

### Troubleshooting Scenarios

**Debugging Startup Failures**
If your app isn't starting, checking the logs immediately after deployment is crucial.
```bash
wheels docker logs --tail=50 --servers=problematic-server.com
```

**Checking Database Errors**
If the app reports database connection errors, check the DB logs for rejection messages or startup errors.
```bash
wheels docker logs --service=db --tail=100
```

## Notes

*   **Service Discovery**: Automatically finds the correct container, handling Blue/Green deployment naming (e.g., it knows to look at `myapp-green` if that's the active container).
*   **SSH**: Uses your local SSH configuration. Ensure you have access to the servers.

## Related Commands

- [wheels docker init](docker-init.md) - Initialize Docker configuration files
- [wheels docker build](docker-build.md) - Build Docker images
- [wheels docker deploy](docker-deploy.md) - Build and deploy Docker containers
- [wheels docker exec](docker-exec.md) - Execute commands in containers
- [wheels docker stop](docker-stop.md) - Stop Docker containers
- [wheels docker push](docker-push.md) - Push Docker images to registries

---

**Note**: This command is part of the Wheels CLI tool suite for Docker management.
