# Wheels Docker Exec Command Guide

## Overview

The `wheels docker exec` command allows you to execute commands inside deployed Docker containers on remote servers. This is essential for debugging, database operations, running scripts, and interactive shell access to your running containers.

---

## Command Syntax

```bash
wheels docker exec "command" [options]
```

---

## Parameters Reference

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `command` | String | **Yes** | - | Command to execute in the container (must be quoted if contains spaces) |
| `servers` | String | No | "" | Specific servers to execute on (comma-separated list, file path, or default config) |
| `service` | String | No | "app" | Service to execute in: `app` or `db` |
| `interactive` | Boolean | No | false | Run command interactively with TTY allocation |

---

## Usage Examples

### Basic Command Execution

#### List Files in App Container

Execute a simple command in the application container:

```bash
wheels docker exec "ls -la"
```

#### Check Current Directory

```bash
wheels docker exec "pwd"
```

#### View Environment Variables

```bash
wheels docker exec "env"
```

#### Check Running Processes

```bash
wheels docker exec "ps aux"
```

---

### File Operations

#### View File Contents

```bash
wheels docker exec "cat config/settings.cfm"
```

#### Search Files

```bash
wheels docker exec "grep -r 'TODO' ."
```

#### Check Disk Usage

```bash
wheels docker exec "df -h"
```

#### Find Large Files

```bash
wheels docker exec "du -sh * | sort -h"
```

---

### Interactive Mode

#### Interactive Shell (Bash)

Open an interactive bash shell in the container:

```bash
wheels docker exec "/bin/bash" --interactive
```

#### Interactive Shell (Sh)

If bash is not available:

```bash
wheels docker exec "/bin/sh" --interactive
```

#### CommandBox REPL

Open CommandBox REPL for debugging:

```bash
wheels docker exec "box repl" --interactive
```

#### Interactive File Editor

Edit files interactively:

```bash
wheels docker exec "vi config/settings.cfm" --interactive
```

**Note:** Press `Ctrl+C` or type `exit` to close interactive sessions.

---

### Database Operations

#### Execute MySQL Query (Non-Interactive)

```bash
wheels docker exec "mysql -u root -ppassword -e 'SHOW DATABASES;'" service=db
```

#### Interactive MySQL Shell

```bash
wheels docker exec "mysql -u root -p" service=db --interactive
```

#### PostgreSQL Query

```bash
wheels docker exec "psql -U postgres -c 'SELECT version();'" service=db
```

#### Interactive PostgreSQL Shell

```bash
wheels docker exec "psql -U postgres" service=db --interactive
```

#### Database Backup

```bash
wheels docker exec "mysqldump -u root -ppassword mydb > /tmp/backup.sql" service=db
```

#### Check Database Status

```bash
wheels docker exec "mysql -u root -ppassword -e 'SHOW STATUS;'" service=db
```

---

### Application Monitoring

#### Tail Application Logs

```bash
wheels docker exec "tail -f logs/application.log"
```

#### View Recent Errors

```bash
wheels docker exec "tail -n 100 logs/error.log"
```

#### Check Memory Usage

```bash
wheels docker exec "free -m"
```

#### Monitor CPU Usage

```bash
wheels docker exec "top -bn1"
```

#### Check Network Connections

```bash
wheels docker exec "netstat -tuln"
```

---

### Server Selection

#### Execute on Specific Server

Run command on a single server:

```bash
wheels docker exec "ls -la" servers=web1.example.com
```

#### Execute on Multiple Servers

Run command across multiple servers:

```bash
wheels docker exec "df -h" servers=web1.example.com,web2.example.com,web3.example.com
```

#### Use Custom Configuration File

```bash
wheels docker exec "pwd" servers=production-servers.json
```

**Note:** Interactive mode only works with a single server.

---

### Service Selection

#### Execute in Application Container (Default)

```bash
wheels docker exec "ls /app" service=app
```

#### Execute in Database Container

```bash
wheels docker exec "ls /var/lib/mysql" service=db
```

---

## Advanced Usage Examples

### Debugging Production Issues

#### Check Application Status

```bash
wheels docker exec "curl -I http://localhost:8080"
```

#### Investigate Memory Leaks

```bash
wheels docker exec "ps aux --sort=-%mem | head -10"
```

#### Analyze Log Patterns

```bash
wheels docker exec "grep -i 'error' logs/*.log | wc -l"
```

#### Check Configuration Files

```bash
wheels docker exec "cat /app/config/settings.cfm"
```

### Database Maintenance

#### Check Database Size

```bash
wheels docker exec "mysql -u root -p -e 'SELECT table_schema AS Database, ROUND(SUM(data_length + index_length) / 1024 / 1024, 2) AS Size_MB FROM information_schema.tables GROUP BY table_schema;'" service=db --interactive
```

#### Optimize Tables

```bash
wheels docker exec "mysql -u root -p -e 'OPTIMIZE TABLE users;'" service=db --interactive
```

#### Check Slow Queries

```bash
wheels docker exec "tail -100 /var/log/mysql/slow-query.log" service=db
```

### Performance Analysis

#### Generate Thread Dump

```bash
wheels docker exec "jstack 1"
```

#### Check Open File Descriptors

```bash
wheels docker exec "lsof | wc -l"
```

#### Monitor Disk I/O

```bash
wheels docker exec "iostat -x 1 5"
```

### Application Management

#### Clear Cache

```bash
wheels docker exec "rm -rf /app/tmp/cache/*"
```

#### Reload Application

```bash
wheels docker exec "box server restart"
```

#### Run Migrations

```bash
wheels docker exec "box migrate up"
```

#### Check Box Server Status

```bash
wheels docker exec "box server status"
```

---

## Interactive Mode Details

### When to Use Interactive Mode

Use `--interactive` when you need:
- Two-way communication with the command
- Input prompts (passwords, confirmations)
- Interactive shells (bash, psql, mysql)
- Text editors (vi, nano)
- REPL environments (box repl)

### Single Server Limitation

Interactive mode only works with **one server at a time**:

**This will error:**
```bash
wheels docker exec "/bin/bash" servers=web1.example.com,web2.example.com --interactive
```

**Error:** "Cannot run interactive commands on multiple servers simultaneously."

**Correct usage:**
```bash
wheels docker exec "/bin/bash" servers=web1.example.com --interactive
```

### TTY Allocation

When `--interactive` is enabled:
- SSH allocates a TTY with `-t` flag
- Docker exec uses `-it` flags (interactive + TTY)
- Input/output streams are properly connected
- Ctrl+C, Ctrl+D, and other control sequences work correctly

---

## Server Configuration

The exec command uses the same server configuration as other Docker commands.

### Configuration Files

Default locations in project root:
1. `deploy-servers.txt`
2. `deploy-servers.json`

### deploy-servers.txt Format

```text
web1.example.com deploy 22
web2.example.com deploy 22
db.example.com deploy 22
```

### deploy-servers.json Format

```json
{
  "servers": [
    {
      "host": "web1.example.com",
      "user": "deploy",
      "port": 22,
      "imageName": "myapp"
    },
    {
      "host": "db.example.com",
      "user": "deploy",
      "port": 22,
      "imageName": "myapp"
    }
  ]
}
```

### Direct Server Specification

You can specify servers directly without a config file:

```bash
wheels docker exec "ls" servers=192.168.1.100
```

This uses defaults:
- User: `deploy`
- Port: `22`
- Remote Dir: `/home/deploy/app`
- Image Name: `app`

---

## Container Detection

The exec command intelligently locates the correct container.

### Application Container Detection

For `service=app`, searches for:
1. Exact project name match
2. `[project-name]-blue` (Blue/Green deployment)
3. `[project-name]-green` (Blue/Green deployment)
4. First container matching project name pattern

### Database Container Detection

For `service=db`, searches for:
1. `[project-name]-db`
2. `db`

### Example

If your project is named "myblog":
- App containers: `myblog`, `myblog-blue`, `myblog-green`
- DB containers: `myblog-db`, `db`

---

## Command Quoting

### When to Quote Commands

**Always quote commands that contain:**
- Spaces
- Special characters (|, >, <, &, ;)
- Multiple arguments

**Examples:**

**Correct:**
```bash
wheels docker exec "ls -la /app"
wheels docker exec "echo 'Hello World'"
wheels docker exec "ps aux | grep java"
```

**Incorrect:**
```bash
wheels docker exec ls -la /app        # May fail
wheels docker exec echo Hello World   # May fail
```

### Shell Pipes and Redirects

Commands with pipes and redirects must be quoted:

```bash
wheels docker exec "cat logs/app.log | grep ERROR"
wheels docker exec "ls -la > /tmp/files.txt"
wheels docker exec "tail -f logs/app.log & echo $!"
```

---

## Error Handling

### Container Not Found

**Error:** "Could not find running container for service: app"

**Solutions:**

1. Verify containers are running:
   ```bash
   wheels docker status
   ```

2. Check container names:
   ```bash
   ssh user@server docker ps
   ```

3. Specify correct service:
   ```bash
   wheels docker exec "ls" service=db
   ```

### SSH Connection Failed

**Error:** "SSH connection failed"

**Solutions:**

1. Test SSH manually:
   ```bash
   ssh user@server
   ```

2. Verify SSH keys:
   ```bash
   ssh-add -l
   ```

3. Check port configuration (default: 22)

### Command Failed

**Error:** "Command failed with exit code: 1"

**Solutions:**

1. Test command locally first:
   ```bash
   docker exec container-name command
   ```

2. Check if command exists in container:
   ```bash
   wheels docker exec "which ls"
   ```

3. Verify file paths:
   ```bash
   wheels docker exec "ls -la /app"
   ```

### Permission Denied

**Error:** Permission denied errors inside container

**Solutions:**

1. Check user permissions:
   ```bash
   wheels docker exec "whoami"
   wheels docker exec "id"
   ```

2. Use sudo if available:
   ```bash
   wheels docker exec "sudo ls /root"
   ```

3. Check file ownership:
   ```bash
   wheels docker exec "ls -la /app"
   ```

---

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
docker exec container-name ls -la

# Then run remotely
wheels docker exec "ls -la"
```

### 3. Use Specific Server Selection

For interactive sessions, always specify a single server:

```bash
wheels docker exec "/bin/bash" servers=web1.example.com --interactive
```

### 4. Specify Service for Database Commands

Always use `service=db` for database operations:

```bash
wheels docker exec "mysql -u root -p" service=db --interactive
```

### 5. Avoid Long-Running Commands on Multiple Servers

Long commands on multiple servers can be difficult to monitor:

```bash
# Better: Run on one server at a time
wheels docker exec "long-running-task" servers=web1.example.com
wheels docker exec "long-running-task" servers=web2.example.com
```

### 6. Use Non-Interactive Mode for Scripts

For automated tasks, avoid interactive mode:

```bash
wheels docker exec "mysql -u root -ppass -e 'SELECT COUNT(*) FROM users;'" service=db
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
wheels docker exec "mysql -u root -pMyPassword" service=db

# Better: Use interactive mode
wheels docker exec "mysql -u root -p" service=db --interactive
```

---

## Common Use Cases

### Debugging Application Issues

```bash
# Check if application is responding
wheels docker exec "curl -I http://localhost:8080"

# View recent errors
wheels docker exec "tail -100 logs/error.log"

# Check Java process
wheels docker exec "ps aux | grep java"

# View memory usage
wheels docker exec "free -m"
```

### Database Operations

```bash
# Check database connection
wheels docker exec "mysql -u root -p -e 'SELECT 1;'" service=db --interactive

# View tables
wheels docker exec "mysql -u root -p -e 'SHOW TABLES;'" service=db --interactive

# Check database size
wheels docker exec "mysql -u root -p -e 'SELECT table_schema, SUM(data_length + index_length) / 1024 / 1024 AS size_mb FROM information_schema.tables GROUP BY table_schema;'" service=db --interactive
```

### File Management

```bash
# Find configuration files
wheels docker exec "find /app -name '*.cfm'"

# Check file permissions
wheels docker exec "ls -la /app/config"

# Search log files
wheels docker exec "grep -r 'ERROR' /app/logs"
```

### Performance Monitoring

```bash
# CPU usage
wheels docker exec "top -bn1 | head -20"

# Memory usage by process
wheels docker exec "ps aux --sort=-%mem | head -10"

# Disk usage
wheels docker exec "df -h"

# Network stats
wheels docker exec "netstat -s"
```

---

## Integration with Other Commands

### Check Status First

```bash
# Check container status
wheels docker status

# Then execute commands
wheels docker exec "ls -la"
```

### View Logs After Execution

```bash
# Execute command
wheels docker exec "box migrate up"

# Check logs for results
wheels docker logs tail=50
```

### Stop and Restart After Changes

```bash
# Make configuration changes
wheels docker exec "echo 'setting=value' >> /app/config/local.cfm"

# Restart container
wheels docker stop --remote
wheels docker deploy remote
```

---

## Security Considerations

### 1. SSH Key Authentication

Ensure SSH keys are properly configured:
```bash
ssh-add ~/.ssh/id_rsa
```

### 2. Avoid Hardcoded Credentials

Don't include passwords in commands:
```bash
# Bad
wheels docker exec "mysql -u root -pSecretPassword" service=db

# Good
wheels docker exec "mysql -u root -p" service=db --interactive
```

### 3. Limit Command Execution

Only give access to trusted users who should execute commands in production.

### 4. Audit Command History

Keep track of executed commands for security audits.

### 5. Use Read-Only Commands When Possible

Prefer read-only operations for investigation:
```bash
wheels docker exec "cat /app/config/settings.cfm"  # Read-only
# vs
wheels docker exec "rm /app/config/settings.cfm"   # Destructive
```

---

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

---

## Related Commands

- [wheels docker init](docker-init.md) - Initialize Docker configuration files
- [wheels docker build](docker-build.md) - Build Docker images
- [wheels docker deploy](docker-deploy.md) - Build and deploy Docker containers
- [wheels docker logs](docker-logs.md) - View container logs
- [wheels docker stop](docker-stop.md) - Stop Docker containers
- [wheels docker push](docker-push.md) - Push Docker images to registries

---

**Note**: This command is part of the Wheels CLI tool suite for Docker management.

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