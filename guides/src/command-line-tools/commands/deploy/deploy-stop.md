# deploy stop

Stop deployed containers on servers.

## Synopsis

```bash
wheels deploy:stop [options]
```

## Description

The `wheels deploy:stop` command stops Docker containers on your deployment servers. It can either stop containers (keeping them for later restart) or completely remove them. This is useful for maintenance, troubleshooting, or decommissioning deployments.

## Options

- `servers=<string>` - Stop on specific servers (comma-separated list)
- `--remove` - Remove containers after stopping (default: false)
- `--force` - Skip confirmation prompt (default: false)

## Examples

### Stop containers on all servers
```bash
wheels deploy:stop
```

### Stop containers on specific servers
```bash
wheels deploy:stop servers=web1.example.com,web2.example.com
```

### Stop and remove containers
```bash
wheels deploy:stop --remove
```

### Force stop without confirmation
```bash
wheels deploy:stop --force
```

### Stop and remove on specific server
```bash
wheels deploy:stop servers=web1.example.com --remove --force
```

## How It Works

The stop command:
1. Connects to target servers via SSH
2. Navigates to the deployment directory (`/opt/{serviceName}`)
3. Executes `docker compose stop` (or `docker compose down` with --remove)
4. Optionally removes volumes with --remove flag

## Stop vs Remove

### Stop (default)
- Stops running containers
- Preserves container state and data
- Containers can be restarted later
- Uses `docker compose stop`

### Remove (--remove flag)
- Stops and removes containers
- Removes container volumes
- Complete cleanup of deployment
- Uses `docker compose down -v`

## Output Example

```
Wheels Deploy Stop
==================================================
WARNING: This will stop your application on the following servers:
web1.example.com, web2.example.com

Are you sure you want to continue? (yes/no): yes

Server: web1.example.com
------------------------------
Stopping containers...
✓ Containers stopped successfully

Server: web2.example.com
------------------------------
Stopping containers...
✓ Containers stopped successfully

Operation completed.

To restart: wheels deploy:push --no-build
To remove completely: wheels deploy:stop --remove
```

## Use Cases

### Temporary maintenance
```bash
# Stop containers for maintenance
wheels deploy:stop

# Perform maintenance tasks...

# Restart containers
wheels deploy:push --no-build
```

### Troubleshooting
```bash
# Stop problematic server
wheels deploy:stop servers=web2.example.com

# Debug issue...

# Restart after fix
wheels deploy:push servers=web2.example.com --no-build
```

### Complete removal
```bash
# Remove deployment completely
wheels deploy:stop --remove --force
```

### Emergency stop
```bash
# Quick stop without prompts
wheels deploy:stop --force
```

## Best Practices

1. **Confirm before stopping**: Always verify servers unless using --force
2. **Check status first**: Run `wheels deploy:status` before stopping
3. **Use --remove carefully**: This permanently removes containers and volumes
4. **Document stops**: Keep track of why containers were stopped
5. **Plan restarts**: Know how to restart containers quickly
6. **Test in staging**: Practice stop/start procedures in non-production

## Container Management

### Restart stopped containers
```bash
# Quick restart without rebuilding
wheels deploy:push --no-build --no-push
```

### Check container status
```bash
# Verify containers are stopped
wheels deploy:status
```

### Clean up old images
```bash
# After stopping, clean up disk space
wheels deploy:exec "docker image prune -f"
```

## Troubleshooting

### Containers won't stop
- Check for hung processes inside containers
- Use `docker ps` directly on the server
- May need to use `docker kill` as last resort

### Permission errors
- Ensure SSH user has Docker permissions
- Check if user is in docker group
- Verify sudo access if needed

### Restart issues
- Ensure `.env.deploy` file still exists
- Check if volumes were removed with --remove
- Verify Docker daemon is running

## Notes

- Stop command uses Docker Compose commands
- Confirmation prompt helps prevent accidental stops
- Remove flag permanently deletes container data
- Stopped containers retain their configuration
- Works with the deployment structure created by deploy:init

## See Also

- [wheels deploy:push](deploy-push.md) - Deploy/restart application
- [wheels deploy:status](deploy-status.md) - Check deployment status
- [wheels deploy:logs](deploy-logs.md) - View container logs