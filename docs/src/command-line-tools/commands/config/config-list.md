# wheels config list

List all configuration settings for your Wheels application.

## Usage

```bash
wheels config list
```

## Parameters

- `--environment` - (Optional) Environment to display settings for: `development`, `testing`, `production`
- `--filter` - (Optional) Filter results by this string
- `--show-sensitive` - (Optional) Show sensitive information (passwords, keys, etc.)

## Description

The `wheels config list` command displays all configuration settings for your Wheels application. It shows current values and helps you understand your application's configuration state.

## Examples

### List all settings
```bash
wheels config list
```

### Filter by pattern
```bash
wheels config list --filter=cache
wheels config list --filter=database
```

### Show sensitive values
```bash
wheels config list --show-sensitive
```

### Environment-specific settings
```bash
wheels config list --environment=production
wheels config list --environment=testing
```

### Combined options
```bash
wheels config list --environment=production --filter=cache --show-sensitive
```

## Output Example

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

When using `--show-sensitive`, password values are displayed:
```
reloadPassword                   mySecretPassword123
```

## Common Configuration Settings

The command displays all Wheels configuration settings including:

- **Database**: `dataSourceName`, `dataSourceUserName`, `dataSourcePassword`
- **Cache**: `cacheQueries`, `cacheActions`, `cachePages`, `cachePartials`
- **Security**: `reloadPassword`, `showDebugInformation`, `showErrorInformation`
- **URLs/Routing**: `urlRewriting`, `assetQueryString`, `assetPaths`
- **Environment**: `environment`, `hostName`

## Filtering

Use the `--filter` parameter to search for specific settings:

```bash
# Find all cache-related settings
wheels config list --filter=cache

# Find datasource settings
wheels config list --filter=datasource
```

## Security

By default, sensitive values like passwords are masked with asterisks (`********`). Use `--show-sensitive` to display actual values:

```bash
# Show all settings including passwords
wheels config list --show-sensitive
```

## Environment-Specific Settings

View settings for different environments:

```bash
# Production settings
wheels config list --environment=production

# Testing environment
wheels config list --environment=testing
```

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