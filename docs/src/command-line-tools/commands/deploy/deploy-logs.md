# deploy logs (Coming Soon)
*This command may not work as expected. A complete and stable version is **coming soon**.*

View deployment logs from servers.

## Synopsis

```bash
wheels deploy:logs [options]
```

## Description

The `wheels deploy:logs` command allows you to view Docker container logs from your deployed application and database containers. This is essential for troubleshooting issues, monitoring application behavior, and debugging production problems.

## Options

- `servers=<string>` - Specific servers to check (comma-separated list)
- `tail=<number>` - Number of lines to show (default: 100)
- `--follow` - Follow log output in real-time (default: false)
- `service=<string>` - Service to show logs for: app or db (default: app)
- `since=<string>` - Show logs since timestamp (e.g., "2023-01-01", "1h", "5m")

## Examples

### View recent application logs
```bash
wheels deploy:logs
```

### Follow logs in real-time
```bash
wheels deploy:logs --follow
```

### View last 50 lines from specific server
```bash
wheels deploy:logs tail=50 servers=web1.example.com
```

### View database logs
```bash
wheels deploy:logs service=db
```

### View logs from the last hour
```bash
wheels deploy:logs since=1h
```

### Follow database logs from specific server
```bash
wheels deploy:logs service=db --follow servers=web2.example.com
```

### View logs since specific date
```bash
wheels deploy:logs since=2024-01-15
```

## How It Works

The command:
1. Connects to target servers via SSH
2. Executes `docker logs` on the specified container
3. Streams or displays the output based on options
4. Supports multiple servers with clear separation

## Output Example

### Single server logs
```
Wheels Deployment Logs
==================================================

[2024-01-15 14:30:00] INFO: Server started on port 3000
[2024-01-15 14:30:01] INFO: Database connection established
[2024-01-15 14:30:02] INFO: Wheels application initialized
[2024-01-15 14:35:00] INFO: Request processed: GET /
[2024-01-15 14:40:00] WARN: Slow query detected (1.2s)
[2024-01-15 14:45:00] ERROR: Failed to send email: SMTP connection refused
```

### Multiple servers
```
Wheels Deployment Logs
==================================================

=== Server: web1.example.com ===

[2024-01-15 14:30:00] INFO: Server started on port 3000
[2024-01-15 14:35:00] INFO: Health check passed

=== Server: web2.example.com ===

[2024-01-15 14:30:05] INFO: Server started on port 3000
[2024-01-15 14:35:05] INFO: Health check passed
```

## Use Cases

### Real-time monitoring
```bash
# Monitor application logs
wheels deploy:logs --follow

# Monitor database logs
wheels deploy:logs service=db --follow
```

### Troubleshooting errors
```bash
# View recent errors (combine with grep)
wheels deploy:logs tail=500 | grep ERROR

# Check specific time period
wheels deploy:logs since=30m | grep -i error
```

### Database debugging
```bash
# View database startup logs
wheels deploy:logs service=db tail=200

# Monitor database queries
wheels deploy:logs service=db --follow | grep Query
```

### Performance analysis
```bash
# Find slow queries
wheels deploy:logs service=db since=1h | grep "Slow query"

# Check request processing times
wheels deploy:logs since=1h | grep "Request processed"
```

## Time Formats

The `since` parameter accepts various formats:
- Relative: `5m`, `2h`, `1d`, `1w`
- ISO 8601: `2024-01-15T14:30:00`
- Date only: `2024-01-15`
- Docker format: `2024-01-15T14:30:00.000000000Z`

## Service Selection

### Application logs (default)
Shows logs from the main application container:
```bash
wheels deploy:logs
```

### Database logs
Shows logs from the database container:
```bash
wheels deploy:logs service=db
```

## Best Practices

1. **Use tail wisely**: Start with reasonable line counts to avoid overwhelming output
2. **Follow sparingly**: Use --follow only when actively monitoring
3. **Filter at source**: Use `since` to reduce data transfer
4. **Combine with tools**: Pipe to grep, awk, or other tools for analysis
5. **Monitor both services**: Check both app and database logs when troubleshooting

## Troubleshooting

### Container not found
- Verify deployment is active with `wheels deploy:status`
- Check service name matches (app or db)
- Ensure container is running

### No logs appearing
- Container might be new with no logs yet
- Check if logging is configured correctly
- Verify Docker logging driver settings

### SSH timeout
- Logs might be very large
- Use `tail` parameter to limit output
- Use `since` to reduce time range

### Permission denied
- Ensure SSH user has Docker access
- Check if user is in docker group
- Verify sudo permissions if needed

## Advanced Usage

### Export logs to file
```bash
# Save logs for analysis
wheels deploy:logs tail=1000 > app-logs.txt

# Save database logs
wheels deploy:logs service=db since=1d > db-logs.txt
```

### Continuous monitoring with timestamps
```bash
# Add timestamps if not present
wheels deploy:logs --follow | while read line; do
  echo "$(date '+%Y-%m-%d %H:%M:%S') $line"
done
```

### Log analysis pipeline
```bash
# Count errors by type
wheels deploy:logs since=1h | grep ERROR | cut -d: -f3- | sort | uniq -c | sort -nr
```

## Notes

- Logs are retrieved directly from Docker containers
- No log rotation or management is performed by this command
- Large log files may take time to transfer
- Follow mode requires stable SSH connection
- Container must be running to view logs

## See Also

- [wheels deploy:status](deploy-status.md) - Check deployment status
- [wheels deploy:exec](deploy-exec.md) - Execute commands in containers
- [wheels deploy:push](deploy-push.md) - Deploy application