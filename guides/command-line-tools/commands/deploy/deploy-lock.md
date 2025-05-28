# deploy lock

Lock deployment state to prevent concurrent deployments and maintain deployment integrity.

## Synopsis

```bash
wheels deploy lock <action> [options]
```

## Description

The `wheels deploy lock` command manages deployment locks to prevent concurrent deployments, ensure deployment atomicity, and maintain system stability during critical operations. This is essential for coordinating deployments in team environments and automated systems.

## Actions

- `acquire` - Acquire a deployment lock
- `release` - Release an existing lock
- `status` - Check current lock status
- `force-release` - Force release a stuck lock (use with caution)
- `list` - List all active locks
- `wait` - Wait for lock to become available

## Options

- `--environment, -e` - Target environment to lock (default: production)
- `--reason` - Reason for acquiring lock (required for acquire)
- `--duration` - Lock duration in minutes (default: 30)
- `--wait-timeout` - Maximum time to wait for lock in seconds
- `--force` - Force acquire lock even if already locked
- `--owner` - Lock owner identifier (default: current user)
- `--metadata` - Additional lock metadata as JSON

## Examples

### Acquire deployment lock
```bash
wheels deploy lock acquire --reason "Deploying version 2.1.0"
```

### Check lock status
```bash
wheels deploy lock status
```

### Release lock
```bash
wheels deploy lock release
```

### Wait for lock availability
```bash
wheels deploy lock wait --wait-timeout 300
```

### Force release stuck lock
```bash
wheels deploy lock force-release --reason "Previous deployment crashed"
```

### List all locks
```bash
wheels deploy lock list
```

## Lock Information

Locks contain the following information:
- Lock ID
- Environment
- Owner (user/system)
- Acquisition time
- Expiration time
- Reason
- Associated deployment ID
- Metadata

## Lock Types

### Manual locks
User-initiated locks for maintenance or manual deployments:
```bash
wheels deploy lock acquire --reason "Database maintenance" --duration 60
```

### Automatic locks
System-acquired locks during automated deployments:
```bash
# Automatically acquired during deployment
wheels deploy exec
```

### Emergency locks
High-priority locks for critical operations:
```bash
wheels deploy lock acquire --force --reason "Emergency hotfix"
```

## Use Cases

### Maintenance window
```bash
# Lock environment for maintenance
wheels deploy lock acquire \
  --reason "Scheduled maintenance" \
  --duration 120 \
  --metadata '{"ticket": "MAINT-123"}'

# Perform maintenance...

# Release when done
wheels deploy lock release
```

### Coordinated deployment
```bash
# Wait for lock and deploy
wheels deploy lock wait --wait-timeout 600
wheels deploy exec --auto-lock
```

### CI/CD integration
```bash
# In CI/CD pipeline
if wheels deploy lock acquire --reason "CI/CD Deploy #${BUILD_ID}"; then
    wheels deploy exec
    wheels deploy lock release
else
    echo "Could not acquire lock"
    exit 1
fi
```

## Lock States

### Available
No active lock, deployments can proceed

### Locked
Active lock in place, deployments blocked

### Expired
Lock duration exceeded, can be cleaned up

### Force-locked
Emergency lock overriding normal locks

## Best Practices

1. **Always provide reasons**: Clear reasons help team coordination
2. **Set appropriate durations**: Don't lock longer than necessary
3. **Release locks promptly**: Release as soon as operation completes
4. **Handle lock failures**: Plan for scenarios when locks can't be acquired
5. **Monitor stuck locks**: Set up alerts for long-running locks
6. **Use force sparingly**: Only force-release when absolutely necessary
7. **Document lock usage**: Keep records of lock operations

## Error Handling

Common lock errors and solutions:

### Lock already exists
```bash
# Check who owns the lock
wheels deploy lock status

# Wait for it to be released
wheels deploy lock wait

# Or coordinate with lock owner
```

### Lock expired during operation
```bash
# Extend lock duration if still needed
wheels deploy lock acquire --extend
```

### Cannot release lock
```bash
# Verify you own the lock
wheels deploy lock status --verbose

# Force release if necessary
wheels deploy lock force-release --reason "Lock owner unavailable"
```

## Integration

The lock system integrates with:
- CI/CD pipelines for automated deployments
- Monitoring systems for lock alerts
- Deployment tools for automatic locking
- Team communication tools for notifications

## See Also

- [deploy exec](deploy-exec.md) - Execute deployment
- [deploy status](deploy-status.md) - Check deployment status
- [deploy rollback](deploy-rollback.md) - Rollback deployment