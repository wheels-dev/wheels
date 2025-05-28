# deploy stop

Stop an active deployment or deployment services.

## Synopsis

```bash
wheels deploy stop [options]
```

## Description

The `wheels deploy stop` command halts active deployments, stops deployment services, or shuts down deployed applications. It provides controlled shutdown capabilities for maintenance, emergency stops, or cleanup operations.

## Options

- `--deployment-id, -d` - Specific deployment to stop
- `--environment, -e` - Target environment (default: production)
- `--force` - Force stop without graceful shutdown
- `--timeout` - Graceful shutdown timeout in seconds (default: 300)
- `--service` - Stop specific service only
- `--all` - Stop all deployments and services
- `--reason` - Reason for stopping (required for audit)
- `--notify` - Send notifications about stop action
- `--backup` - Create backup before stopping

## Examples

### Stop active deployment
```bash
wheels deploy stop --deployment-id dep-123456 --reason "User requested"
```

### Emergency stop
```bash
wheels deploy stop --force --reason "Critical error detected"
```

### Graceful shutdown
```bash
wheels deploy stop --timeout 600 --reason "Scheduled maintenance"
```

### Stop specific service
```bash
wheels deploy stop --service web --environment staging
```

### Stop all services
```bash
wheels deploy stop --all --environment development
```

## Stop Types

### Graceful stop
Default behavior that ensures clean shutdown:
```bash
wheels deploy stop --reason "Maintenance window"
```

Process:
1. Stop accepting new requests
2. Complete active requests
3. Flush caches and buffers
4. Close database connections
5. Terminate processes

### Force stop
Immediate termination for emergencies:
```bash
wheels deploy stop --force --reason "Security incident"
```

Process:
1. Send SIGTERM to all processes
2. Wait 10 seconds
3. Send SIGKILL if needed
4. Force close connections

### Partial stop
Stop specific components:
```bash
# Stop web servers only
wheels deploy stop --service web

# Stop background workers
wheels deploy stop --service workers

# Stop specific instance
wheels deploy stop --instance i-1234567890
```

## Use Cases

### Maintenance window
```bash
# Stop for maintenance
wheels deploy stop \
  --environment production \
  --reason "Database maintenance" \
  --notify \
  --backup

# Perform maintenance...

# Restart services
wheels deploy exec
```

### Emergency response
```bash
# Immediate stop for security issue
wheels deploy stop \
  --force \
  --all \
  --reason "Security breach detected" \
  --notify
```

### Rolling stop
```bash
# Stop instances one by one
for instance in $(wheels deploy status --format json | jq -r '.instances[]'); do
  wheels deploy stop --instance $instance --timeout 300
  sleep 30
done
```

### Scheduled stop
```bash
# Stop at specific time
echo "wheels deploy stop --reason 'Scheduled shutdown'" | at 02:00
```

## Stop Process Details

### Pre-stop actions
1. Validate stop request
2. Check for active operations
3. Create backup if requested
4. Send notifications
5. Update deployment status

### Stop sequence
1. Mark deployment as stopping
2. Stop load balancer traffic
3. Drain active connections
4. Stop application services
5. Stop background jobs
6. Release resources
7. Update status to stopped

### Post-stop actions
1. Verify all services stopped
2. Log stop completion
3. Send completion notifications
4. Update monitoring systems
5. Release deployment locks

## Service-Specific Stops

### Web servers
```bash
wheels deploy stop --service web --drain-timeout 300
```
- Stops accepting new connections
- Completes active requests
- Removes from load balancer

### Database
```bash
wheels deploy stop --service database --backup
```
- Creates final backup
- Closes all connections
- Flushes buffers
- Stops database service

### Cache services
```bash
wheels deploy stop --service cache --persist
```
- Persists cache to disk
- Stops cache service
- Preserves cache data

### Queue workers
```bash
wheels deploy stop --service workers --complete-jobs
```
- Stops accepting new jobs
- Completes current jobs
- Gracefully shuts down

## Best Practices

1. **Always provide reasons**: Document why services were stopped
2. **Use graceful stops**: Allow services to shut down cleanly
3. **Create backups**: Backup before stopping production services
4. **Notify stakeholders**: Inform team about stop actions
5. **Monitor stop process**: Ensure services stop correctly
6. **Plan restarts**: Have restart procedures ready
7. **Test stop procedures**: Practice emergency stops

## Error Handling

### Stop failures
```bash
# If graceful stop fails, force stop
wheels deploy stop --reason "Maintenance"
if [ $? -ne 0 ]; then
  wheels deploy stop --force --reason "Graceful stop failed"
fi
```

### Hung processes
```bash
# Check for processes that won't stop
wheels deploy status --detailed

# Force stop specific process
wheels deploy stop --force --process-id 12345
```

### Rollback after stop
```bash
# If stop causes issues, quickly restart
wheels deploy stop --reason "Configuration change"
# ... issues detected ...
wheels deploy exec --emergency
```

## Integration

Stop operations integrate with:
- Monitoring systems for stop alerts
- Load balancers for traffic management
- Backup systems for pre-stop backups
- Notification systems for team alerts

### Monitoring integration
```bash
# Stop with monitoring notification
wheels deploy stop \
  --reason "Planned maintenance" \
  --notify-monitoring \
  --expected-downtime 3600
```

### Load balancer integration
```bash
# Remove from load balancer before stop
wheels deploy proxy route --backend app-01 --weight 0
sleep 300  # Allow connections to drain
wheels deploy stop --instance app-01
```

## Recovery

### Restart after stop
```bash
# Normal restart
wheels deploy exec

# Quick restart with previous config
wheels deploy exec --quick-start

# Restart specific services
wheels deploy start --service web
```

### Verify recovery
```bash
# Check services are running
wheels deploy status --health

# Monitor logs
wheels deploy logs --tail --since "stop completed"
```

## See Also

- [deploy exec](deploy-exec.md) - Start deployment
- [deploy status](deploy-status.md) - Check deployment status
- [deploy rollback](deploy-rollback.md) - Rollback deployment