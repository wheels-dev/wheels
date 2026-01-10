# wheels env switch

Switch to a different environment in your Wheels application.

## Synopsis

```bash
wheels env switch [name] [options]
```

## Description

The `wheels env switch` command changes the active environment for your Wheels application by updating the `wheels_env` variable in the `.env` file. It validates the environment configuration, optionally creates backups, and can restart the application server.

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

### Combine multiple options
```bash
wheels env switch production --backup --restart --check
```

## What It Does

1. **Validates Target Environment** (if `--check` is enabled):
   - Checks for `.env.[environment]` file
   - Checks for `config/[environment]/settings.cfm` file
   - Validates environment configuration

2. **Creates Backup** (if `--backup` is enabled):
   - Backs up current `.env` file
   - Backs up `server.json` if it exists
   - Creates timestamped backup files

3. **Updates Configuration**:
   - Updates or creates `wheels_env` variable in `.env`
   - Falls back to `environment` variable if `wheels_env` doesn't exist
   - Updates `server.json` profile if file exists

4. **Restarts Application** (if `--restart` is enabled):
   - Stops and starts CommandBox server if `server.json` exists
   - Falls back to `wheels reload` command

## Output Example

```
Environment Switch
==================================================

Current Environment: development
Target Environment:  staging

Validating target environment... [OK]
Creating backup... [OK]
  Backup saved: .env.backup-20240115-103045
Switching environment... [OK]
Updated environment variable... [OK]

==================================================
[SUCCESS] Environment switched successfully!

Environment Details:
- Environment: staging
- Database:    wheels_staging
- Debug Mode:  Enabled
- Cache:       Partial

IMPORTANT:
- Restart your application server for changes to take effect
- Run 'wheels reload' if using Wheels development server
- Or use 'wheels env switch staging --restart' next time
```

## Environment File Updates

### .env File
The command updates or creates the `wheels_env` variable:

Before:
```
wheels_env=development
# or
environment=development
```

After:
```
wheels_env=staging
```

If no environment variable exists, it adds:
```
wheels_env=staging
```

## Validation Process

The validation checks for required environment files:

1. **Environment Configuration File**:
   - Checks: `.env.[environment]`
   - Location: Project root

2. **Wheels Settings File**:
   - Checks: `config/[environment]/settings.cfm`
   - Location: Project config directory

### Validation Rules:
- **Valid**: Both files exist
- **Valid with warning**: One file exists
- **Invalid**: Neither file exists (unless `--force` is used)

## Options Details

### --check (default: true)
Validates the target environment before switching:
```bash
# With validation (default)
wheels env switch production

# Skip validation
wheels env switch production --no-check
```

### --backup (default: false)
Creates timestamped backups before switching:
```bash
wheels env switch production --backup
# Creates: .env.backup-20240115-103045
# Creates: server.json.backup-20240115-103045 (if exists)
```

### --restart (default: false)
Automatically restarts the application:
```bash
wheels env switch production --restart
```

### --force (default: false)
Bypasses validation and confirmation prompts:
```bash
# Force switch even if validation fails
wheels env switch production --force

# Combine with other options
wheels env switch production --force --no-check
```

### --quiet (default: false)
Minimal output for scripting:
```bash
wheels env switch production --quiet
# Output: Environment switched to production
```

## Production Safety

When switching to production from another environment:
- Displays warning about production implications
- Requires confirmation (unless `--force` or `--quiet`)
- Shows warnings about debug mode, caching, and error handling

Warning message:
```
WARNING: Switching to PRODUCTION environment
   This will:
   - Disable debug mode
   - Enable full caching
   - Hide detailed error messages

Are you sure you want to continue? (yes/no):
```

## Error Handling

If the switch fails:
- Displays error message
- Provides troubleshooting suggestions
- Sets exit code 1 for scripting

Example error output:
```
[X] Failed to switch environment
  Error: Environment 'invalid' is not configured

Suggestions:
- Check if you have write permissions for .env file
- Ensure the environment name is valid
- Try running with administrator/sudo privileges if needed
- Use --force to bypass validation checks
```

## Backup Files

The `--backup` option creates timestamped backup files:

### Created Files:
- `.env.backup-YYYYMMDD-HHMMSS` - Backup of current .env file
- `server.json.backup-YYYYMMDD-HHMMSS` - Backup of server.json (if exists)

### Manual Restore:
If you need to restore from a backup:
```bash
# Restore .env file
cp .env.backup-20240115-103045 .env

# Restore server.json
cp server.json.backup-20240115-103045 server.json

# Reload application
wheels reload
```

## Service Management

### With --restart Option
When using `--restart`, the command will:

1. **If server.json exists**:
   - Stop CommandBox server
   - Start CommandBox server

2. **If server.json doesn't exist**:
   - Execute `wheels reload` command

### Manual Restart
If `--restart` is not used, you need to manually restart:
```bash
# CommandBox server
server restart

# Or Wheels development server
wheels reload
```

## Environment-Specific Configuration

The command reads additional configuration from `.env.[environment]` files if they exist:

### Supported Variables:
- `database` - Database connection name
- `debug` - Debug mode (true/false)
- `cache` - Cache configuration

Example `.env.production`:
```
database=wheels_production
debug=false
cache=full
```

## Integration Examples

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

# Switch environment with backup
wheels env switch $1 --backup

# Run migrations
wheels dbmigrate latest

# Clear caches
wheels cache clear

# Verify environment
wheels env current
```

### Automated Testing
```bash
# Switch to testing environment quietly
wheels env switch testing --quiet --force

# Run tests
wheels test run

# Switch back to development
wheels env switch development --quiet
```

## Troubleshooting

### Switch Failed
- Check validation errors in output
- Verify `.env.[environment]` file exists
- Verify `config/[environment]/settings.cfm` exists
- Use `--force` to bypass validation

### Application Not Responding After Switch
- Ensure server was restarted
- Check `.env` file for correct `wheels_env` value
- Review application logs for errors
- Manually restart services if needed

### Permission Issues
- Check write permissions for `.env` file
- Run with appropriate privileges
- Ensure backup directory is writable

### Validation Warnings
- Warning appears if only one configuration file exists
- Environment may work but might not be fully configured
- Check both `.env.[environment]` and `config/[environment]/settings.cfm`

## Best Practices

1. **Always validate**: Keep `--check` enabled for production switches
2. **Create backups**: Use `--backup` for critical environment changes
3. **Test first**: Switch in staging before production
4. **Use --restart**: Automatically restart to apply changes immediately
5. **Document changes**: Log environment switches in deployment notes

## Security Considerations

- Production switches require explicit confirmation
- Backup files contain sensitive configuration
- `.env` files should be in `.gitignore`
- Use `--quiet` mode carefully in automated scripts
- Review environment-specific configurations regularly

## Notes

- The command modifies the `.env` file in place
- Creates `wheels_env` variable if it doesn't exist
- Falls back to updating `environment` variable if found
- Some changes require application restart to take effect
- Database connections may need to be reset after switching
- Cached data should be cleared after environment switch

## Exit Codes

- `0` - Success
- `1` - Failure (validation error, write error, or user cancellation)

## See Also

- [wheels env](env.md) - Environment management overview
- [wheels env list](env-list.md) - List available environments
- [wheels env setup](env-setup.md) - Setup new environments
- [wheels env current](env-current.md) - Show current environment
- [wheels reload](../core/reload.md) - Reload application