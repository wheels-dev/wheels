# wheels docker logs

View deployment logs from servers.

## Synopsis

```bash
wheels docker logs [options]
```

## Description

The `wheels docker logs` command fetches and displays logs from running containers. It abstracts away the complexity of finding the correct container ID, especially in multi-server or Blue/Green environments.

**Centralized Configuration**:
- **Source of Truth**: This command prioritizes settings from `config/deploy.yml` for server lists and project names.
- **Local vs Remote**: You can explicitly switch between viewing local container logs and remote server logs using the `--local` flag.

## Options

| Option | Description | Default |
|--------|-------------|---------|
| `--servers` | Specific servers to check (defaults to `config/deploy.yml`) | `""` |
| `--local` | Fetch logs from local Docker environment | `false` |
| `--tail` | Number of lines to show | `100` |
| `--follow` | Follow log output in real-time | `false` |
| `--service` | Service to show logs for: `app` or `db` | `app` |
| `--since` | Show logs since timestamp | `""` |

## Detailed Examples

### Basic Usage

**View Recent Logs (Remote)**
Fetches the last 100 lines of logs from the application container on all configured remote servers.
```bash
wheels docker logs
```

**View Local Logs**
Fetches logs from the local Docker environment.
```bash
wheels docker logs --local
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
