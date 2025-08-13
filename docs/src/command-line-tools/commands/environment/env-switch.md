# wheels env switch (coming Soon)
*This command works correctly without options (parameters). Option support is under development and will be **available soon**.*

Switch to a different environment in your Wheels application.

## Synopsis

```bash
wheels env switch [name] [options]
```

## Description

The `wheels env switch` command changes the active environment for your Wheels application. It updates configuration files, environment variables, and optionally restarts services to apply the new environment settings.

## Arguments

| Argument | Description | Default |
|----------|-------------|---------|
| `name` | Target environment name | Required |

## Options

| Option | Description | Default |
|--------|-------------|---------|
| `--check` | Validate before switching | `true` |
| `--restart` | Restart application after switch | `false` |
| `--backup` | Backup current environment | `false` |
| `--force` | Force switch even with issues | `false` |
| `--quiet` | Suppress output | `false` |
| `--help` | Show help information |

## Examples

### Switch to staging
```bash
wheels env switch staging
```

### Switch with application restart
```bash
wheels env switch production --restart
```

### Force switch without validation
```bash
wheels env switch testing --force
```

### Switch with backup
```bash
wheels env switch production --backup
```

### Quiet switch for scripts
```bash
wheels env switch development --quiet
```

## What It Does

1. **Validates Target Environment**:
   - Checks if environment exists
   - Verifies configuration
   - Tests database connection

2. **Updates Configuration**:
   - Sets WHEELS_ENV variable
   - Updates .wheels-env file
   - Modifies environment.cfm if needed

3. **Applies Changes**:
   - Clears caches
   - Reloads configuration
   - Restarts services (if requested)

4. **Verifies Switch**:
   - Confirms environment active
   - Checks application health
   - Reports status

## Output Example

```
Switching environment...

Current: development
Target:  staging

✓ Validating staging environment
✓ Configuration valid
✓ Database connection successful
✓ Updating environment settings
✓ Clearing caches
✓ Environment switched successfully

New Environment: staging
Database: wheels_staging
Debug: Enabled
Cache: Partial
```

## Environment File Updates

### .wheels-env
Before:
```
development
```

After:
```
staging
```

### Environment Variables
Updates system environment:
```bash
export WHEELS_ENV=staging
export WHEELS_DATASOURCE=wheels_staging
```

## Validation Process

Before switching, validates:

1. **Configuration**:
   - File exists
   - Syntax valid
   - Required settings present

2. **Database**:
   - Connection works
   - Tables accessible
   - Migrations current

3. **Dependencies**:
   - Required services available
   - File permissions correct
   - Resources accessible

## Switch Strategies

### Safe Switch (Default)
```bash
wheels env switch production
```
- Full validation
- Graceful transition
- Rollback on error

### Fast Switch
```bash
wheels env switch staging --force --no-check
```
- Skip validation
- Immediate switch
- Use with caution

### Zero-Downtime Switch
```bash
wheels env switch production --strategy=blue-green
```
- Prepare new environment
- Switch load balancer
- No service interruption

## Backup and Restore

### Create Backup
```bash
wheels env switch production --backup
# Creates: .wheels-env-backup-20240115-103045
```

### Restore from Backup
```bash
wheels env restore --from=.wheels-env-backup-20240115-103045
```

### Manual Restore
```bash
# If switch fails
cp .wheels-env-backup-20240115-103045 .wheels-env
wheels reload
```

## Service Management

### With Restart
```bash
wheels env switch production --restart
```

Restarts:
- Application server
- Cache services
- Background workers

### Service-Specific
```bash
wheels env switch staging --restart-services=app,cache
```

## Pre/Post Hooks

Configure in `.wheels-cli.json`:

```json
{
  "env": {
    "switch": {
      "pre": [
        "wheels test run --quick",
        "git stash"
      ],
      "post": [
        "wheels dbmigrate latest",
        "wheels cache clear",
        "npm run build"
      ]
    }
  }
}
```

## Environment-Specific Actions

### Development → Production
```bash
wheels env switch production
# Warning: Switching from development to production
# - Debug will be disabled
# - Caching will be enabled
# - Error details will be hidden
# Continue? (y/N)
```

### Production → Development
```bash
wheels env switch development
# Warning: Switching from production to development
# - Debug will be enabled
# - Caching will be disabled
# - Sensitive data may be exposed
# Continue? (y/N)
```

## Integration

### CI/CD Pipeline
```yaml
- name: Switch to staging
  run: |
    wheels env switch staging --check
    wheels test run
    wheels deploy exec staging
```

### Deployment Scripts
```bash
#!/bin/bash
# deploy.sh

# Switch environment
wheels env switch $1 --backup

# Run migrations
wheels dbmigrate latest

# Clear caches
wheels cache clear

# Verify
wheels env | grep $1
```

## Rollback

If switch fails or causes issues:

```bash
# Automatic rollback
wheels env switch production --auto-rollback

# Manual rollback
wheels env switch:rollback

# Force previous environment
wheels env switch development --force
```

## Troubleshooting

### Switch Failed
- Check validation errors
- Verify target environment exists
- Use `--force` if necessary

### Application Not Responding
- Check service status
- Review error logs
- Manually restart services

### Database Connection Issues
- Verify credentials
- Check network access
- Test connection manually

## Best Practices

1. **Always Validate**: Don't skip checks in production
2. **Use Backups**: Enable backup for critical switches
3. **Test First**: Switch in staging before production
4. **Monitor After**: Check application health post-switch
5. **Document Changes**: Log environment switches

## Security Considerations

- Production switches require confirmation
- Sensitive configs protected
- Audit trail maintained
- Access controls enforced

## Notes

- Some changes require application restart
- Database connections may need reset
- Cached data cleared on switch
- Background jobs may need restart

## See Also

- [wheels env](env.md) - Environment management overview
- [wheels env list](env-list.md) - List environments
- [wheels env setup](env-setup.md) - Setup environments
- [wheels reload](../core/reload.md) - Reload application