# wheels env

Base command for environment management in Wheels applications.

## Synopsis

```bash
wheels env [subcommand] [options]
```

## Description

The `wheels env` command provides comprehensive environment management for Wheels applications. It handles environment configuration, switching between environments, and managing environment-specific settings.

## Subcommands

| Command | Description |
|---------|-------------|
| `setup` | Setup a new environment |
| `list` | List available environments |
| `switch` | Switch to a different environment |

## Options

| Option | Description |
|--------|-------------|
| `--help` | Show help information |
| `--version` | Show version information |

## Direct Usage

When called without subcommands, displays current environment:

```bash
wheels env
```

Output:
```
Current Environment: development
Configuration File: /config/development/settings.cfm
Database: wheels_dev
Mode: development
Debug: enabled
```

## Examples

### Show current environment
```bash
wheels env
```

### Quick environment info
```bash
wheels env --info
```

### List all environments
```bash
wheels env list
```

### Switch environment
```bash
wheels env switch production
```

## Environment Configuration

Each environment has its own configuration:

```
/config/
  ├── development/
  │   └── settings.cfm
  ├── testing/
  │   └── settings.cfm
  ├── production/
  │   └── settings.cfm
  └── environment.cfm
```

## Environment Variables

The command respects these environment variables:

| Variable | Description | Default |
|----------|-------------|---------|
| `WHEELS_ENV` | Current environment | `development` |
| `WHEELS_DATASOURCE` | Database name | Per environment |
| `WHEELS_DEBUG` | Debug mode | Per environment |

## Environment Detection

Order of precedence:
1. Command line argument
2. `WHEELS_ENV` environment variable
3. `.wheels-env` file
4. Default (`development`)

## Common Environments

### Development
- Debug enabled
- Detailed error messages
- Hot reload active
- Development database

### Testing
- Test database
- Fixtures loaded
- Debug enabled
- Isolated from production

### Production
- Debug disabled
- Optimized performance
- Production database
- Error handling active

### Staging
- Production-like
- Separate database
- Debug configurable
- Pre-production testing

## Environment Files

### .wheels-env
Local environment override:
```
production
```

### .env.[environment]
Environment-specific variables:
```bash
# .env.production
DATABASE_URL=mysql://prod@host/db
CACHE_ENABLED=true
DEBUG_MODE=false
```

## Integration

### With Other Commands

Many commands respect current environment:
```bash
# Uses current environment's database
wheels dbmigrate latest

# Reloads in current environment
wheels reload

# Tests run in test environment
wheels test run
```

### In Application Code

Access current environment:
```cfml
<cfset currentEnv = get("environment")>
<cfif currentEnv eq "production">
    <!--- Production-specific code --->
</cfif>
```

## Best Practices

1. **Never commit** `.wheels-env` file
2. **Use testing** environment for tests
3. **Match staging** to production closely
4. **Separate databases** per environment
5. **Environment-specific** configuration files

## Use Cases

1. **Local Development**: Switch between feature environments
2. **Testing**: Isolated test environment
3. **Deployment**: Environment-specific configurations
4. **Debugging**: Quick environment switching
5. **Team Development**: Consistent environments

## Notes

- Environment changes may require application restart
- Database connections are environment-specific
- Some settings only take effect after reload
- Use version control for environment configs

## See Also

- [wheels env setup](env-setup.md) - Setup new environment
- [wheels env list](env-list.md) - List environments
- [wheels env switch](env-switch.md) - Switch environments
- [wheels config](../config/config-env.md) - Configuration management