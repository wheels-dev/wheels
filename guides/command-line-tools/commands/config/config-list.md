# wheels config list

List all configuration settings for your Wheels application.

## Synopsis

```bash
wheels config list [options]
```

## Description

The `wheels config list` command displays all configuration settings for your Wheels application. It shows current values, defaults, and helps you understand your application's configuration state.

## Options

| Option | Description | Default |
|--------|-------------|---------|
| `--filter` | Filter settings by name or pattern | Show all |
| `--category` | Filter by category (database, cache, security, etc.) | All |
| `--format` | Output format (table, json, yaml, env) | `table` |
| `--show-defaults` | Include default values | `false` |
| `--show-source` | Show where setting is defined | `false` |
| `--environment` | Show for specific environment | Current |
| `--verbose` | Show detailed information | `false` |
| `--help` | Show help information |

## Examples

### List all settings
```bash
wheels config list
```

### Filter by pattern
```bash
wheels config list --filter=cache
wheels config list --filter="database*"
```

### Show specific category
```bash
wheels config list --category=security
```

### Export as JSON
```bash
wheels config list --format=json > config.json
```

### Show with sources
```bash
wheels config list --show-source --show-defaults
```

### Environment-specific
```bash
wheels config list --environment=production
```

## Output Example

### Basic Output
```
Wheels Configuration Settings
============================

Setting                          Value
-------------------------------- --------------------------------
dataSourceName                   wheels_dev
environment                      development
reloadPassword                   ********
showDebugInformation            true
showErrorInformation            true
cacheFileChecking               false
cacheQueries                    false
cacheActions                    false
urlRewriting                    partial
assetQueryString                true
assetPaths                      true
```

### Verbose Output
```
Wheels Configuration Settings
============================

Database Settings
-----------------
dataSourceName                   wheels_dev
  Source: /config/development/settings.cfm
  Default: wheels
  Type: string
  
dataSourceUserName              [not set]
  Source: default
  Default: 
  Type: string

Cache Settings
--------------
cacheQueries                    false
  Source: /config/development/settings.cfm
  Default: false
  Type: boolean
  Description: Cache database query results
```

## Configuration Categories

### Database
- `dataSourceName` - Primary datasource
- `dataSourceUserName` - Database username
- `dataSourcePassword` - Database password
- `database` - Database name

### Cache
- `cacheQueries` - Cache query results
- `cacheActions` - Cache action output
- `cachePages` - Cache full pages
- `cachePartials` - Cache partial views
- `cacheFileChecking` - Check file modifications

### Security
- `reloadPassword` - Application reload password
- `showDebugInformation` - Show debug info
- `showErrorInformation` - Show error details
- `encryptionKey` - Data encryption key
- `sessionTimeout` - Session duration

### URLs/Routing
- `urlRewriting` - URL rewriting mode
- `assetQueryString` - Add version to assets
- `assetPaths` - Use asset paths

### Development
- `environment` - Current environment
- `hostName` - Application hostname
- `deletePluginDirectories` - Remove plugin dirs
- `overwritePlugins` - Allow plugin overwrites

## Filtering Options

### By Pattern
```bash
# All cache settings
wheels config list --filter=cache*

# Settings containing "database"
wheels config list --filter=*database*

# Specific setting
wheels config list --filter=reloadPassword
```

### By Category
```bash
# Database settings only
wheels config list --category=database

# Security settings
wheels config list --category=security

# Multiple categories
wheels config list --category=database,cache
```

## Output Formats

### Table (Default)
Human-readable table format

### JSON
```bash
wheels config list --format=json
```
```json
{
  "settings": {
    "dataSourceName": "wheels_dev",
    "environment": "development",
    "cacheQueries": false
  }
}
```

### YAML
```bash
wheels config list --format=yaml
```
```yaml
settings:
  dataSourceName: wheels_dev
  environment: development
  cacheQueries: false
```

### Environment Variables
```bash
wheels config list --format=env
```
```
WHEELS_DATASOURCE=wheels_dev
WHEELS_ENVIRONMENT=development
WHEELS_CACHE_QUERIES=false
```

## Source Information

When using `--show-source`:

### Source Types
- **File**: Specific configuration file
- **Environment**: Environment variable
- **Default**: Framework default
- **Plugin**: Set by plugin
- **Runtime**: Set during runtime

### Source Priority
1. Runtime settings (highest)
2. Environment variables
3. Environment-specific config
4. Base configuration
5. Plugin settings
6. Framework defaults (lowest)

## Advanced Usage

### Compare Environments
```bash
# Compare dev and production
wheels config list --environment=development > dev.json
wheels config list --environment=production > prod.json
diff dev.json prod.json
```

### Audit Configuration
```bash
# Find non-default settings
wheels config list --show-defaults | grep -v "default"

# Find security issues
wheels config list --category=security --check
```

### Export for Documentation
```bash
# Markdown format
wheels config list --format=markdown > CONFIG.md

# Include descriptions
wheels config list --verbose --format=markdown
```

## Integration

### CI/CD Usage
```bash
# Verify required settings
required="dataSourceName,reloadPassword"
wheels config list --format=json | jq --arg req "$required" '
  .settings | with_entries(select(.key | IN($req | split(","))))
'
```

### Monitoring
```bash
# Check for changes
wheels config list --format=json > config-current.json
diff config-baseline.json config-current.json
```

## Special Values

### Hidden Values
Sensitive settings show as asterisks:
- Passwords: `********`
- Keys: `****...****`
- Secrets: `[hidden]`

### Complex Values
- Arrays: `["item1", "item2"]`
- Structs: `{key: "value"}`
- Functions: `[function]`

## Best Practices

1. **Regular Audits**: Check configuration regularly
2. **Document Changes**: Track setting modifications
3. **Environment Parity**: Keep environments similar
4. **Secure Secrets**: Don't expose sensitive data
5. **Version Control**: Track configuration files

## Troubleshooting

### Missing Settings
- Check environment-specific files
- Verify file permissions
- Look for syntax errors

### Incorrect Values
- Check source precedence
- Verify environment variables
- Review recent changes

## Notes

- Some settings require restart to take effect
- Sensitive values are automatically hidden
- Custom settings from plugins included
- Performance impact minimal

## See Also

- [wheels config set](config-set.md) - Set configuration values
- [wheels config env](config-env.md) - Environment configuration
- [wheels env](../environment/env.md) - Environment management
- [Configuration Guide](../../configuration.md)