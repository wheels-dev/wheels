# wheels docker exec

Execute commands in deployed containers. Works for both local and remote containers.

## Synopsis

```bash
wheels docker exec [options] "command"
```

## Description

The `wheels docker exec` command allows you to run arbitrary commands inside your running containers. It automatically locates the correct container based on the service name (e.g., `app`, `db`) and handles SSH connections for remote execution.

**Centralized Configuration**:
- **Source of Truth**: This command prioritizes settings from `config/deploy.yml` for server lists and project names.
- **Interactive TTY**: The `--interactive` flag provides a full TTY session, allowing you to run shells, REPLs, and database clients with proper signal handling (e.g., `Ctrl+C`).

## Arguments

| Argument | Description | Default |
|----------|-------------|---------|
| `command` | Command to execute in container | Required |

## Options

| Option | Description | Default |
|--------|-------------|---------|
| `--servers` | Specific servers to execute on (defaults to `config/deploy.yml`) | `""` |
| `--service` | Service to execute in: `app` or `db` | `app` |
| `--interactive` | Run command interactively with full TTY support | `false` |
| `--local` | Execute in local container | `true` |
| `--remote` | Execute in remote container | `false` |

## Detailed Examples

### Basic Execution

**List Files**
Quickly check the file structure inside your running application container.
```bash
wheels docker exec "ls -la /app"
```

**Check Database Connectivity**
Verify that your application container can reach the database service.
```bash
wheels docker exec "curl -v http://db:3306" --remote
```

**Run a CFML Script**
Execute a specific ColdFusion script or task using CommandBox.
```bash
wheels docker exec "box task run myTask"
```

### Interactive Sessions

**CommandBox REPL**
Start an interactive CommandBox shell to run ad-hoc CFML code.
```bash
wheels docker exec "box repl" --interactive
```

**Database Shell**
Connect directly to the database container's shell.
```bash
# For MySQL
wheels docker exec "mysql -u wheels -pwheels wheels" --service=db --interactive
```

**System Shell**
Get a bash shell inside the container for debugging.
```bash
wheels docker exec "bash" --interactive
```

### Remote Execution

**Tail Logs on Remote Server**
View the live application log file on a specific remote server.
```bash
wheels docker exec "tail -f logs/application.log" --servers=web1.example.com --remote
```

**Run Command on All Servers**
Execute a command across all servers defined in your configuration (non-interactive only).
```bash
# Clear cache on all servers
wheels docker exec "box task run clearCache" --remote
```

**Target Specific Service**
Run a command inside the database container instead of the app container.
```bash
wheels docker exec "ps aux" --service=db --remote
```

## Notes

*   **Interactive Mode**: When using `--interactive`, you can only target a single server. Attempting to run interactive commands on multiple servers simultaneously will result in an error.
*   **Service Discovery**: The command attempts to find the container name automatically. It looks for containers matching your project name and service (e.g., `myproject-app`, `myproject-db`). It also correctly identifies active containers in Blue/Green deployments (e.g., `myproject-app-green`).

## Best Practices

### 1. Quote All Complex Commands

Always quote commands to avoid shell interpretation issues:

```bash
wheels docker exec "command arg1 arg2"
```

### 2. Test Commands Locally First

Before running on remote servers:

```bash
# Test locally
wheels docker exec "ls -la" --local

# Then run remotely
wheels docker exec "ls -la"
```

### 3. Use Specific Server Selection

For interactive sessions, always specify a single server:

```bash
wheels docker exec "/bin/bash" --remote --servers=web1.example.com --interactive
```

### 4. Specify Service for Database Commands

Always use `service=db` for database operations:

```bash
wheels docker exec "mysql -u root -p" --service=db --interactive
```

### 5. Avoid Long-Running Commands on Multiple Servers

Long commands on multiple servers can be difficult to monitor:

```bash
# Better: Run on one server at a time
wheels docker exec "long-running-task" --servers=web1.example.com
wheels docker exec "long-running-task" ---servers=web2.example.com
```

### 6. Use Non-Interactive Mode for Scripts

For automated tasks, avoid interactive mode:

```bash
wheels docker exec "mysql -u root -ppass -e 'SELECT COUNT(*) FROM users;'" --service=db
```

### 7. Check Exit Codes

The command returns Docker exec exit codes (130 = Ctrl+C is acceptable):

```bash
wheels docker exec "test -f /app/config.cfm" && echo "File exists"
```

### 8. Be Careful with Destructive Commands

Always double-check before running destructive operations:

```bash
# Dangerous! Make sure you mean it
wheels docker exec "rm -rf /app/temp/*"
```

### 9. Use Absolute Paths

Avoid confusion by using absolute paths:

```bash
wheels docker exec "ls /app/logs" instead of "ls logs"
```

### 10. Handle Secrets Carefully

Avoid putting passwords in commands when possible:

```bash
# Bad: Password visible in command
wheels docker exec "mysql -u root -pMyPassword" --service=db

# Better: Use interactive mode
wheels docker exec "mysql -u root -p" --service=db --interactive
```

## Troubleshooting

### Command Hangs

If a command hangs:
1. Press `Ctrl+C` to interrupt
2. Check if command requires input
3. Use `--interactive` if needed
4. Verify container is responsive:
   ```bash
   wheels docker exec "echo test"
   ```

### Output Not Showing

If output doesn't appear:
1. Check if command produces output:
   ```bash
   wheels docker exec "ls -la"
   ```
2. Redirect stderr to stdout:
   ```bash
   wheels docker exec "command 2>&1"
   ```

### Interactive Mode Not Working

If interactive mode fails:
1. Verify single server selection
2. Check TTY support:
   ```bash
   wheels docker exec "tty" --interactive
   ```
3. Test SSH TTY allocation:
   ```bash
   ssh -t user@server
   ```

## Additional Notes

- Commands are executed inside running containers using `docker exec`
- SSH connections use key-based authentication
- Exit code 0 indicates success, 130 indicates Ctrl+C interrupt (acceptable)
- Interactive mode requires TTY allocation on both SSH and Docker levels
- Multiple server execution is sequential, not parallel
- Commands run with the container's default user (usually root or app user)
- Working directory depends on container's WORKDIR setting
- Container must be running for exec to work
- Blue/Green deployment containers are automatically detected
- Command output is streamed in real-time

## Related Commands

- [wheels docker init](docker-init.md) - Initialize Docker configuration files
- [wheels docker build](docker-build.md) - Build Docker images
- [wheels docker deploy](docker-deploy.md) - Build and deploy Docker containers
- [wheels docker logs](docker-logs.md) - View container logs
- [wheels docker stop](docker-stop.md) - Stop Docker containers

**Note**: This command is part of the Wheels CLI tool suite for Docker management.