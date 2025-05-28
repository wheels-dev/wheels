# deploy logs

View and manage deployment logs for troubleshooting and monitoring.

## Synopsis

```bash
wheels deploy logs [options]
```

## Description

The `wheels deploy logs` command provides access to deployment logs, allowing you to view, search, and export logs from past and current deployments. This is essential for troubleshooting deployment issues, auditing deployment history, and monitoring deployment progress.

## Options

- `--deployment-id, -d` - Specific deployment ID to view logs for
- `--environment, -e` - Filter logs by environment (default: all)
- `--tail, -f` - Follow log output in real-time
- `--lines, -n` - Number of lines to display (default: 100)
- `--since` - Show logs since timestamp (e.g., "2023-01-01", "1h", "30m")
- `--until` - Show logs until timestamp
- `--grep, -g` - Filter logs by pattern (regex supported)
- `--level` - Filter by log level (debug, info, warn, error)
- `--format` - Output format (text, json, csv) (default: text)
- `--output, -o` - Export logs to file
- `--no-color` - Disable colored output

## Examples

### View recent deployment logs
```bash
wheels deploy logs
```

### Follow current deployment logs
```bash
wheels deploy logs --tail
```

### View specific deployment logs
```bash
wheels deploy logs --deployment-id dep-123456
```

### Filter by time range
```bash
wheels deploy logs --since "1 hour ago" --until "30 minutes ago"
```

### Search for errors
```bash
wheels deploy logs --grep "error|failed" --level error
```

### Export logs to file
```bash
wheels deploy logs --deployment-id dep-123456 --output deployment.log
```

### View logs in JSON format
```bash
wheels deploy logs --format json --lines 50
```

## Log Levels

Logs are categorized by severity:

- **DEBUG**: Detailed diagnostic information
- **INFO**: General informational messages
- **WARN**: Warning messages for potential issues
- **ERROR**: Error messages for failures
- **FATAL**: Critical errors causing deployment failure

## Log Structure

Each log entry contains:
- Timestamp
- Log level
- Deployment stage
- Component/service
- Message
- Additional metadata

Example log entry:
```
2023-12-01 14:23:45 [INFO] [pre-deploy] [backup] Starting database backup
2023-12-01 14:23:47 [INFO] [pre-deploy] [backup] Backup completed successfully
2023-12-01 14:23:48 [INFO] [deploy] [app] Deploying application version 2.1.0
2023-12-01 14:23:52 [ERROR] [deploy] [app] Failed to start service: connection refused
```

## Use Cases

### Real-time monitoring
```bash
# Monitor ongoing deployment
wheels deploy logs --tail --deployment-id current
```

### Troubleshooting failures
```bash
# Find errors in recent deployments
wheels deploy logs --since "1 day ago" --level error

# Search for specific error
wheels deploy logs --grep "database connection" --level error
```

### Audit trail
```bash
# Export deployment logs for audit
wheels deploy logs \
  --since "2023-01-01" \
  --until "2023-12-31" \
  --format csv \
  --output audit-2023.csv
```

### Performance analysis
```bash
# Find slow operations
wheels deploy logs --grep "took [0-9]+ seconds" | grep -E "took [0-9]{3,} seconds"
```

## Advanced Filtering

### Complex grep patterns
```bash
# Find database-related errors
wheels deploy logs --grep "database|sql|connection.*error"

# Find deployment timing
wheels deploy logs --grep "(started|completed|failed).*deploy"
```

### Multiple filters
```bash
# Production errors in last hour
wheels deploy logs \
  --environment production \
  --level error \
  --since "1 hour ago"
```

### Log aggregation
```bash
# Count errors by component
wheels deploy logs --level error --format json | \
  jq -r '.component' | sort | uniq -c
```

## Log Retention

- Logs are retained based on environment settings
- Default retention periods:
  - Production: 90 days
  - Staging: 30 days
  - Development: 7 days
- Archived logs available through backup systems

## Best Practices

1. **Use appropriate filters**: Narrow down logs to relevant entries
2. **Export important logs**: Save logs for failed deployments
3. **Monitor in real-time**: Use --tail for active deployments
4. **Regular log review**: Periodically review logs for patterns
5. **Set up alerts**: Configure alerts for error patterns
6. **Maintain log hygiene**: Ensure logs are meaningful and not excessive

## Integration

Log viewing integrates with:
- Monitoring systems (Datadog, New Relic, etc.)
- Log aggregation services (ELK stack, Splunk)
- Alerting systems for error notifications
- CI/CD pipelines for deployment history

## Troubleshooting

### No logs appearing
```bash
# Check deployment status
wheels deploy status

# Verify deployment ID
wheels deploy list --recent
```

### Log export failing
```bash
# Check available disk space
df -h

# Try smaller time range or line limit
wheels deploy logs --lines 1000 --output partial.log
```

## See Also

- [deploy status](deploy-status.md) - Check deployment status
- [deploy exec](deploy-exec.md) - Execute deployment
- [deploy audit](deploy-audit.md) - Audit deployment configuration