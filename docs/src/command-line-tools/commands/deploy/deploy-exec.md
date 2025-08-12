# wheels deploy exec (Coming Soon)
*This command may not work as expected. A complete and stable version is **coming soon**.*

Execute commands in deployed containers.

## Synopsis

```bash
wheels deploy:exec <command> [options]
```

## Description

The `wheels deploy:exec` command allows you to execute commands inside deployed Docker containers on your servers. This is useful for running administrative tasks, debugging, or accessing services directly.

## Arguments

- `command` - Command to execute in container (required)

## Options

- `servers=<string>` - Execute on specific servers (comma-separated list)
- `service=<string>` - Service to execute in: app or db (default: app)
- `--interactive` - Run command interactively (default: false)

## Examples

### List files in application container
```bash
wheels deploy:exec "ls -la"
```

### Run database migrations
```bash
wheels deploy:exec "box run-script migrate"
```

### Access CommandBox REPL interactively
```bash
wheels deploy:exec "box repl" --interactive
```

### Execute MySQL commands in database container
```bash
wheels deploy:exec "mysql -u root -p" service=db --interactive
```

### Check application logs
```bash
wheels deploy:exec "tail -f logs/application.log"
```

### Execute on specific server
```bash
wheels deploy:exec "df -h" servers=web1.example.com
```

## How It Works

The command:
1. Connects to target servers via SSH
2. Determines the container name based on service
3. Executes the command using `docker exec`
4. Returns the output or provides interactive access

## Service Selection

### Application Container (default)
```bash
# Executes in the main application container
wheels deploy:exec "ls -la"
```

### Database Container
```bash
# Executes in the database container
wheels deploy:exec "mysql -u root -p" service=db --interactive
```

## Interactive vs Non-Interactive

### Non-Interactive (default)
- Command runs and returns output
- Suitable for simple commands
- Output is captured and displayed

### Interactive Mode
- Provides terminal access
- Required for commands needing input
- Useful for REPL, database shells, etc.

## Output Example

### Non-interactive command
```
Wheels Deploy Remote Execution
==================================================
Executing: ls -la
Container: myapp

total 24
drwxr-xr-x 1 root root 4096 Jan 15 14:30 .
drwxr-xr-x 1 root root 4096 Jan 15 14:30 ..
drwxr-xr-x 1 root root 4096 Jan 15 14:30 app
drwxr-xr-x 1 root root 4096 Jan 15 14:30 config
-rw-r--r-- 1 root root  512 Jan 15 14:30 box.json
-rw-r--r-- 1 root root  256 Jan 15 14:30 server.json
```

### Multiple servers
```
Wheels Deploy Remote Execution
==================================================
Executing: uptime
Container: myapp

Server: web1.example.com
------------------------------
 14:35:22 up 45 days,  3:21,  0 users,  load average: 0.15, 0.12, 0.18

Server: web2.example.com
------------------------------
 14:35:23 up 32 days,  7:45,  0 users,  load average: 0.23, 0.19, 0.21
```

## Common Use Cases

### Administrative Tasks
```bash
# Clear application cache
wheels deploy:exec "box run-script clearCache"

# Run scheduled tasks
wheels deploy:exec "box task run maintenance"

# Check disk usage
wheels deploy:exec "df -h /app"
```

### Database Operations
```bash
# MySQL backup
wheels deploy:exec "mysqldump -u root myapp > /backup/myapp.sql" service=db

# PostgreSQL vacuum
wheels deploy:exec "psql -U postgres -c 'VACUUM ANALYZE;'" service=db

# Check database size
wheels deploy:exec "mysql -u root -e 'SELECT table_schema, SUM(data_length + index_length) / 1024 / 1024 AS size_mb FROM information_schema.tables GROUP BY table_schema;'" service=db
```

### Debugging
```bash
# View application logs
wheels deploy:exec "tail -n 100 /app/logs/application.log"

# Check running processes
wheels deploy:exec "ps aux"

# Monitor resource usage
wheels deploy:exec "top -b -n 1"

# Check environment variables
wheels deploy:exec "env | grep WHEELS"
```

### File Management
```bash
# Create backup
wheels deploy:exec "tar -czf /tmp/backup.tar.gz /app/uploads"

# Check file permissions
wheels deploy:exec "ls -la /config"

# Remove old logs
wheels deploy:exec "find /app/logs -name '*.log' -mtime +30 -delete"
```

## Security Considerations

1. **Command Injection**: Commands are passed directly to the shell
2. **Permissions**: Runs with container user permissions
3. **Sensitive Data**: Be careful with commands that expose secrets
4. **Audit Trail**: Commands are not logged by default

## Limitations

- Cannot execute commands requiring GUI
- Interactive mode requires TTY support
- Output limited by SSH buffer size
- No automatic error handling

## Best Practices

1. **Quote Complex Commands**: Use quotes for commands with special characters
2. **Test First**: Test commands locally before running in production
3. **Use Service Parameter**: Specify service explicitly for clarity
4. **Avoid Sensitive Output**: Redirect sensitive data to files
5. **Check Exit Codes**: Verify command success in scripts

## Troubleshooting

### Container Not Found
- Verify deployment is active
- Check container name matches service name
- Ensure Docker is running

### Permission Denied
- Check SSH user has Docker access
- Verify container user permissions
- Use sudo if necessary (configure in deploy.json)

### Command Not Found
- Ensure command exists in container
- Check PATH environment variable
- Use full path to executables

### Interactive Mode Issues
- Ensure terminal supports TTY
- Use SSH directly for complex interactions
- Check SSH client configuration

## See Also

- [wheels deploy:status](deploy-status.md) - Check deployment status
- [wheels deploy:logs](deploy-logs.md) - View deployment logs
- [wheels deploy:push](deploy-push.md) - Deploy application