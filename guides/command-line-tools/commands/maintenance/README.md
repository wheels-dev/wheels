# Maintenance Commands

Commands for managing application maintenance mode and cleaning up temporary files.

## Available Commands

### Maintenance Mode
- [wheels maintenance:on](maintenance-mode.md#wheels-maintenanceon) - Enable maintenance mode
- [wheels maintenance:off](maintenance-mode.md#wheels-maintenanceoff) - Disable maintenance mode

### Cleanup Commands
- [wheels cleanup:logs](cleanup-commands.md#wheels-cleanuplogs) - Remove old log files
- [wheels cleanup:tmp](cleanup-commands.md#wheels-cleanuptmp) - Remove temporary files
- [wheels cleanup:sessions](cleanup-commands.md#wheels-cleanupsessions) - Remove expired sessions

## Quick Examples

### Enable Maintenance Mode
```bash
# Basic maintenance
wheels maintenance:on

# With custom message
wheels maintenance:on message="Back at 3:00 PM"

# Allow admin access
wheels maintenance:on allowedIPs="192.168.1.100"
```

### Cleanup Old Files
```bash
# Clean logs older than 7 days
wheels cleanup:logs

# Clean all temp files
wheels cleanup:tmp --force

# Clean expired sessions
wheels cleanup:sessions
```

## Common Workflows

### Deployment with Maintenance
```bash
# Enable maintenance
wheels maintenance:on message="Upgrading..." --force

# Deploy and migrate
git pull && wheels dbmigrate latest

# Clean up and disable maintenance
wheels cleanup:tmp --force
wheels maintenance:off --force
```

### Scheduled Cleanup
```bash
# Add to crontab
0 2 * * * wheels cleanup:logs days=30 --force
0 3 * * * wheels cleanup:tmp --force
0 4 * * * wheels cleanup:sessions --force
```

## See Also
- [Asset and Cache Management](../assets-cache-management.md)
- [Server Management](../server/server.md)
- [Database Management](../database/database-management.md)