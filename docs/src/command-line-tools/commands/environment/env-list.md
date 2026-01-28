# wheels env list

List all available environments for your Wheels application.

## Synopsis

```bash
wheels env list [options]
```

## Description

The `wheels env list` command displays all configured environments in your Wheels application. It shows environment details, current active environment, and configuration status.

## Options

| Option | Description | Default |
|--------|-------------|---------|
| `--format` | Output format (table, json, yaml) | `table` |
| `--verbose` | Show detailed configuration | `false` |
| `--check` | Validate environment configurations | `false` |
| `--filter` | Filter by environment type | All |
| `--sort` | Sort by (name, type, modified) | `name` |

## Examples

### List all environments
```bash
wheels env list
```

### Show detailed information
```bash
wheels env list --verbose
```

### Output as JSON
```bash
wheels env list --format=json
```

### Check environment validity
```bash
wheels env list --check
```

### Filter production environments
```bash
wheels env list --filter=production
```

## Output Example

### Basic Output
```
==================================================
              Available Environments
==================================================


╔═════════════╤═════════════╤══════════╤════════════╤════════╤═════════╗
║ Name        │ Type        │ Database │ Status     │ Active │ DB Type ║
╠═════════════╪═════════════╪══════════╪════════════╪════════╪═════════╣
║ development │ Development │ mydb_app │ [OK] Valid │ NO     │ mysql   ║
╚═════════════╧═════════════╧══════════╧════════════╧════════╧═════════╝


Total Environments:       1
Current Environment:
[INFO]: * = Currently active environment
[INFO]: Use 'wheels env list --verbose' for detailed information
```

### Verbose Output
```
==================================================
              Available Environments
==================================================

Total Environments:       1
Current Environment:


development * [Active]
--------------------------------------------------
  Type:        Development
  Database:    wheels_dev
  Datasource:  wheels_development
  Debug:       Enabled
  Cache:       Disabled
  Config:      /config/development/settings.cfm
  Modified:    2024-01-10 14:23:45
  
testing
--------------------------------------------------
  Type:        Testing
  Database:    wheels_test
  Datasource:  wheels_testing
  Debug:       Enabled
  Cache:       Disabled
  Config:      /config/testing/settings.cfm
  Modified:    2024-01-08 09:15:22

staging
--------------------------------------------------
  Type:        Staging
  Database:    wheels_staging
  Datasource:  wheels_staging
  Debug:       Partial
  Cache:       Enabled
  Config:      /config/staging/settings.cfm
  Modified:    2024-01-12 16:45:00
```

## JSON Output Format

```json
{
  "environments": [
    {
      "name": "development",
      "type": "Development",
      "active": true,
      "database": "wheels_dev",
      "datasource": "wheels_development",
      "debug": true,
      "cache": false,
      "configPath": "/config/development/settings.cfm",
      "lastModified": "2024-01-10T14:23:45Z",
      "status": "valid"
    },
    {
      "name": "production",
      "type": "Production",
      "active": false,
      "database": "wheels_prod",
      "datasource": "wheels_production",
      "debug": false,
      "cache": true,
      "configPath": "/config/production/settings.cfm",
      "lastModified": "2024-01-12T16:45:00Z",
      "status": "valid"
    }
  ],
  "current": "development",
  "total": 5
}
```

## Environment Status

### Status Indicators
- `OK Valid` - Configuration is valid and working
- `Active` - Currently active environment
- `WARN Invalid` - Configuration errors

### Validation Checks
When using `--check`:
1. Configuration file exists
2. Syntax is valid
3. Database connection works
4. Required settings present

## Environment Types

### Standard Types
- **Development**: Local development
- **Testing**: Automated testing
- **Staging**: Pre-production
- **Production**: Live environment

### Custom Types
- User-defined environments
- Special purpose configs
- Client-specific setups

## Filtering Options

### By Type
```bash
# Production environments only
wheels env list --filter=production

# Development environments
wheels env list --filter=development
```

### By Status
```bash
# Valid environments only
wheels env list --filter=valid

# Environments with issues
wheels env list --filter=issues
```

### By Pattern
```bash
# Environments containing "prod"
wheels env list --filter="*prod*"

# Can also be written as
wheels env list --filter=*prod*
```

## Sorting Options

### By Name
```bash
wheels env list --sort=name
```

### By Type
```bash
wheels env list --sort=type
```

### By Last Modified
```bash
wheels env list --sort=modified
```


## Environment Details

When using `--verbose`, shows:

1. **Configuration**:
   - Config file path
   - Last modified date
   - File size

2. **Database**:
   - Database name
   - Datasource name

3. **Settings**:
   - Debug mode
   - Cache settings
   - Custom configurations


## Troubleshooting

### No Environments Listed
- Check `/config/` directory
- Verify environment.cfm exists
- Run `wheels env setup` to create

### Invalid Environment
- Check configuration syntax
- Verify database credentials
- Test database connection

### Missing Current Environment
- Check WHEELS_ENV variable
- Verify environment.cfm logic
- Set environment explicitly

## Best Practices

1. **Regular Checks**: Validate environments periodically
2. **Documentation**: Keep environment purposes clear
3. **Consistency**: Use consistent naming
4. **Cleanup**: Remove unused environments
5. **Security**: Don't expose production details

## Notes

- Current environment marked with asterisk (*)
- Invalid environments shown but marked
- Verbose mode may expose sensitive data
- JSON format useful for automation

## See Also

- [wheels env](env.md) - Environment management overview
- [wheels env setup](env-setup.md) - Setup new environment
- [wheels env switch](env-switch.md) - Switch environments
- [wheels config list](../config/config-list.md) - List configuration