# wheels config set

Set configuration values for your Wheels application.

## Usage

```bash
wheels config set <key>=<value> [--environment=<env>] [--encrypt]
```

## Parameters

- `setting` - (Required) Key=Value pair for the setting to update
- `--environment` - (Optional) Environment to apply settings to: `development`, `testing`, `production`, `all`. Default: `development`
- `--encrypt` - (Optional) Encrypt sensitive values

## Description

The `wheels config set` command updates configuration settings in your Wheels application. Settings must be provided in `key=value` format.

## Examples

### Set basic configuration
```bash
wheels config set dataSourceName=wheels_production
```

### Set for specific environment
```bash
wheels config set showDebugInformation=false --environment=production
wheels config set reloadPassword=newPassword --environment=production
```

### Set for all environments
```bash
wheels config set defaultLayout=main --environment=all
```

### Set encrypted value
```bash
wheels config set apiKey=sk_live_abc123 --encrypt
wheels config set dataSourcePassword=mySecret --encrypt
```

## Configuration Values

The command accepts various value types:

### String Values
```bash
wheels config set appName="My Wheels App"
wheels config set emailFrom=noreply@example.com
```

### Boolean Values
```bash
wheels config set showDebugInformation=true
wheels config set cacheQueries=false
```

### Numeric Values
```bash
wheels config set sessionTimeout=1800
wheels config set maxUploadSize=10485760
```

## Where Settings Are Saved

Settings are saved to environment-specific configuration files:

- **Development**: `/config/development/settings.cfm`
- **Testing**: `/config/testing/settings.cfm`  
- **Production**: `/config/production/settings.cfm`
- **All environments**: `/config/settings.cfm`

Example:
```cfml
// Added to /config/production/settings.cfm
set(dataSourceName="wheels_production");
```

## Sensitive Values

Use the `--encrypt` flag for sensitive values:

```bash
wheels config set reloadPassword=mySecret --encrypt
wheels config set apiKey=sk_live_123456 --encrypt
```

## Environment-Specific Settings

Target specific environments with the `--environment` flag:

```bash
# Development only
wheels config set showDebugInformation=true --environment=development

# Production only
wheels config set cacheQueries=true --environment=production

# All environments
wheels config set appName="My App" --environment=all
```

## Best Practices

1. **Use environment-specific settings**: Don't set production values in development
2. **Encrypt sensitive data**: Use `--encrypt` for passwords and keys
3. **Test changes**: Verify settings with `wheels config list`
4. **Restart after changes**: Some settings require application restart

## Notes

- Some settings require application restart
- Encrypted values can't be read back
- Changes are logged for audit
- Use environment variables for containers

## See Also

- [wheels config list](config-list.md) - List configuration
- [wheels config env](config-env.md) - Environment config
- [wheels env](../environment/env.md) - Environment management
- [Configuration Guide](../../configuration.md)