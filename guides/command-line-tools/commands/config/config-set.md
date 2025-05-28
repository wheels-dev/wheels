# wheels config set

Set configuration values for your Wheels application.

## Synopsis

```bash
wheels config set [key] [value] [options]
```

## Description

The `wheels config set` command updates configuration settings in your Wheels application. It can modify settings in configuration files, set environment-specific values, and manage runtime configurations.

## Arguments

| Argument | Description | Required |
|----------|-------------|----------|
| `key` | Configuration key to set | Yes |
| `value` | Value to set | Yes (unless --delete) |

## Options

| Option | Description | Default |
|--------|-------------|---------|
| `--environment` | Target environment | Current |
| `--global` | Set globally across all environments | `false` |
| `--file` | Configuration file to update | Auto-detect |
| `--type` | Value type (string, number, boolean, json) | Auto-detect |
| `--encrypt` | Encrypt sensitive values | Auto for passwords |
| `--delete` | Delete the configuration key | `false` |
| `--force` | Overwrite without confirmation | `false` |
| `--help` | Show help information |

## Examples

### Set basic configuration
```bash
wheels config set dataSourceName wheels_production
```

### Set with specific type
```bash
wheels config set cacheQueries true --type=boolean
wheels config set sessionTimeout 3600 --type=number
```

### Set for specific environment
```bash
wheels config set showDebugInformation false --environment=production
```

### Set complex value
```bash
wheels config set cacheSettings '{"queries":true,"pages":false}' --type=json
```

### Delete configuration
```bash
wheels config set oldSetting --delete
```

### Set encrypted value
```bash
wheels config set apiKey sk_live_abc123 --encrypt
```

## Configuration Types

### String Values
```bash
wheels config set appName "My Wheels App"
wheels config set emailFrom "noreply@example.com"
```

### Boolean Values
```bash
wheels config set showDebugInformation true
wheels config set cacheQueries false
```

### Numeric Values
```bash
wheels config set sessionTimeout 1800
wheels config set maxUploadSize 10485760
```

### JSON/Complex Values
```bash
wheels config set mailSettings '{"server":"smtp.example.com","port":587}'
wheels config set allowedDomains '["example.com","app.example.com"]'
```

## Where Settings Are Saved

### Environment-Specific
Default location: `/config/[environment]/settings.cfm`

```cfml
// Added to /config/production/settings.cfm
set(dataSourceName="wheels_production");
```

### Global Settings
Location: `/config/settings.cfm`

```bash
wheels config set defaultLayout "main" --global
```

### Environment Variables
For system-level settings:

```bash
wheels config set DATABASE_URL "mysql://..." --env-var
```

## Value Type Detection

The command auto-detects types:
- `true/false` → boolean
- Numbers → numeric
- JSON syntax → struct/array
- Default → string

Override with `--type`:
```bash
wheels config set port "8080" --type=string
```

## Sensitive Values

### Automatic Encryption
These patterns trigger encryption:
- `*password*`
- `*secret*`
- `*key*`
- `*token*`

### Manual Encryption
```bash
wheels config set customSecret "value" --encrypt
```

### Encrypted Storage
```cfml
// Stored as:
set(apiKey=decrypt("U2FsdGVkX1+..."));
```

## Validation

Before setting, validates:
1. Key name syntax
2. Value type compatibility
3. Environment existence
4. File write permissions

## Interactive Mode

For sensitive values:
```bash
wheels config set reloadPassword
# Enter value (hidden): ****
# Confirm value: ****
```

## Batch Operations

### From File
```bash
# config.txt
dataSourceName=wheels_prod
cacheQueries=true
sessionTimeout=3600

wheels config set --from-file=config.txt
```

### Multiple Values
```bash
wheels config set \
  dataSourceName=wheels_prod \
  cacheQueries=true \
  sessionTimeout=3600
```

## Configuration Precedence

Order of precedence (highest to lowest):
1. Runtime `set()` calls
2. Environment variables
3. Environment-specific settings
4. Global settings
5. Framework defaults

## Rollback

### Create Backup
```bash
wheels config set dataSourceName wheels_new --backup
# Creates: .wheels-config-backup-20240115-103045
```

### Restore
```bash
wheels config restore --from=.wheels-config-backup-20240115-103045
```

## Special Keys

### Reserved Keys
Some keys have special behavior:
- `environment` - Switches environment
- `reloadPassword` - Always encrypted
- `dataSourcePassword` - Hidden in output

### Computed Keys
Some settings affect others:
```bash
wheels config set environment production
# Also updates: debug settings, cache settings
```

## Environment Variables

### Set as Environment Variable
```bash
wheels config set WHEELS_DATASOURCE wheels_prod --env-var
```

### Export Format
```bash
wheels config set --export-env > .env
```

## Validation Rules

### Key Naming
- Alphanumeric and underscores
- No spaces or special characters
- Case-sensitive

### Value Constraints
```bash
# Validates port range
wheels config set port 80000 --type=number
# Error: Port must be between 1-65535

# Validates boolean
wheels config set cacheQueries maybe --type=boolean
# Error: Value must be true or false
```

## Best Practices

1. **Use Correct Types**: Specify type for clarity
2. **Environment-Specific**: Don't set production values globally
3. **Encrypt Secrets**: Always encrypt sensitive data
4. **Backup First**: Create backups before changes
5. **Document Changes**: Add comments in config files

## Advanced Usage

### Conditional Setting
```bash
# Set only if not exists
wheels config set apiUrl "https://api.example.com" --if-not-exists

# Set only if current value matches
wheels config set cacheQueries true --if-value=false
```

### Template Variables
```bash
wheels config set dbName "wheels_${ENVIRONMENT}" --parse-template
```

## Troubleshooting

### Permission Denied
- Check file write permissions
- Run with appropriate user
- Verify directory ownership

### Setting Not Taking Effect
- Restart application
- Clear caches
- Check precedence order

### Invalid Value
- Verify type compatibility
- Check for typos
- Review validation rules

## Integration

### CI/CD Pipeline
```yaml
- name: Configure production
  run: |
    wheels config set environment production
    wheels config set dataSourceName ${{ secrets.DB_NAME }}
    wheels config set reloadPassword ${{ secrets.RELOAD_PASS }}
```

### Docker
```dockerfile
RUN wheels config set dataSourceName ${DB_NAME} \
    && wheels config set cacheQueries true
```

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