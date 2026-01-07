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

## Options

| Option | Description | Default |
|--------|-------------|---------|
| `command` | **Required**. Command to execute in container | |
| `--servers` | Specific servers to execute on (defaults to `config/deploy.yml`) | `""` |
| `--service` | Service to execute in: `app` or `db` | `app` |
| `--interactive` | Run command interactively with full TTY support | `false` |
| `--local` | Execute in local container | `false` |

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
wheels docker exec "curl -v http://db:3306"
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
wheels docker exec "tail -f logs/application.log" --servers=web1.example.com
```

**Run Command on All Servers**
Execute a command across all servers defined in your configuration (non-interactive only).
```bash
# Clear cache on all servers
wheels docker exec "box task run clearCache"
```

**Target Specific Service**
Run a command inside the database container instead of the app container.
```bash
wheels docker exec "ps aux" --service=db
```

## Notes

*   **Interactive Mode**: When using `--interactive`, you can only target a single server. Attempting to run interactive commands on multiple servers simultaneously will result in an error.
*   **Service Discovery**: The command attempts to find the container name automatically. It looks for containers matching your project name and service (e.g., `myproject-app`, `myproject-db`). It also correctly identifies active containers in Blue/Green deployments (e.g., `myproject-app-green`).
