# Wheels get settings

## Overview

The `wheels get settings` command displays the current Wheels application settings for your environment. It shows all configuration settings that are active, including defaults and any custom overrides from your configuration files. You can view all settings or filter to see specific ones.

## Command Syntax

```bash
wheels get settings [settingName]
```

## Parameters

### Optional Parameters
- **`settingName`** - Optional setting name or pattern to filter results. Can be a partial match.

## Basic Usage Examples

### Display All Settings
```bash
wheels get settings
```
Shows all active settings for the current environment

### Filter Specific Setting
```bash
wheels get settings cacheQueries
```
Shows only the `cacheQueries` setting

### Filter by Pattern
```bash
wheels get settings cache
```
Shows all settings containing "cache" in their name (e.g., `cacheQueries`, `cachePages`, `cacheImages`)

## How It Works

### Settings Resolution Order

The command resolves settings in the same order as Wheels:

1. **Default Wheels Settings** - Built-in framework defaults
2. **Application Settings** - From `/config/settings.cfm`
3. **Environment Settings** - From `/config/[environment]/settings.cfm`

Each level overrides the previous one, with environment-specific settings having the highest priority.

### Environment Detection

The command automatically detects the current environment using the same logic as `wheels get environment`:
- Checks `.env` file for `WHEELS_ENV`
- Checks system environment variable
- Checks `server.json`
- Defaults to `development`

### Settings Parsing

The command parses `set()` function calls in your settings files:
```coldfusion
// config/settings.cfm
set(dataSourceName="myapp_db");
set(cacheQueries=true);
set(errorEmailAddress="admin@example.com");
```

## Output Examples

### All Settings Display
```
Wheels Settings (development environment):

allowConcurrentRequestScope:   false
cacheActions:                  false
cacheCullInterval:              5
cacheCullPercentage:            10
cacheDatabaseSchema:            false
cacheFileChecking:              false
cacheImages:                    false
cacheModelConfig:               false
cachePages:                     false
cachePartials:                  false
cacheQueries:                   false
cacheRoutes:                    false
dataSourceName:                 myapp_db
errorEmailAddress:              admin@example.com
showDebugInformation:           true
showErrorInformation:           true
URLRewriting:                   partial

Total settings: 17
```

### Filtered Settings Display
```bash
wheels get settings cache
```
```
==================================================
    Wheels Settings (development environment)
==================================================


╔═══════════════════════╤═══════╗
║ Setting               │ Value ║
╠═══════════════════════╪═══════╣
║ cacheActions          │ false ║
╟───────────────────────┼───────╢
║ cacheControllerConfig │ false ║
╟───────────────────────┼───────╢
║ cacheCullInterval     │ true  ║
╟───────────────────────┼───────╢
║ cacheCullPercentage   │ true  ║
╟───────────────────────┼───────╢
║ cacheDatabaseSchema   │ false ║
╟───────────────────────┼───────╢
║ cacheFileChecking     │ false ║
╟───────────────────────┼───────╢
║ cacheImages           │ false ║
╟───────────────────────┼───────╢
║ cacheModelConfig      │ false ║
╟───────────────────────┼───────╢
║ cachePages            │ false ║
╟───────────────────────┼───────╢
║ cachePartials         │ false ║
╟───────────────────────┼───────╢
║ cacheQueries          │ false ║
╟───────────────────────┼───────╢
║ cacheRoutes           │ false ║
╟───────────────────────┼───────╢
║ cacheViewConfig       │ false ║
╚═══════════════════════╧═══════╝
Total settings:           13
```

### Single Setting Display
```bash
wheels get settings dataSourceName
```
```
==================================================
    Wheels Settings (development environment)
==================================================


╔════════════════╤══════════════╗
║ Setting        │ Value        ║
╠════════════════╪══════════════╣
║ dataSourceName │ wheelstestdb ║
╚════════════════╧══════════════╝

Total settings:           1

[INFO]: Settings loaded from:
  - config/settings.cfm (global defaults)
  - config/development/settings.cfm (environment overrides)

[INFO]: Filtered by: 'dataSourceName'
  - Showing 1 matching setting(s)
```

### No Matches Found
```bash
wheels get settings nonexistent
```
```
[WARNING]: No settings found matching 'nonexistent'
```

## Common Wheels Settings

### Caching Settings
- `cacheActions` - Cache action output
- `cacheQueries` - Cache database query results
- `cachePages` - Cache entire page output
- `cachePartials` - Cache partial/template output
- `cacheImages` - Cache generated images
- `cacheRoutes` - Cache routing configuration
- `cacheModelConfig` - Cache model configurations
- `cacheControllerConfig` - Cache controller configurations
- `cacheViewConfig` - Cache view configurations
- `cacheDatabaseSchema` - Cache database schema information
- `cacheFileChecking` - Check for file changes when caching

### Database Settings
- `dataSourceName` - Primary datasource name
- `useExpandedColumnAliases` - Use expanded column aliases in queries
- `useTimestampsOnDeletedColumn` - Add timestamps to soft-deleted records
- `migratorTableName` - Table name for migration versions

### Error Handling Settings
- `showDebugInformation` - Display debug information
- `showErrorInformation` - Display error details
- `sendEmailOnError` - Send email notifications on errors
- `errorEmailAddress` - Email address for error notifications
- `errorEmailServer` - SMTP server for error emails
- `errorEmailSubject` - Subject line for error emails
- `includeErrorInEmailSubject` - Include error details in email subject

### URL Settings
- `URLRewriting` - URL rewriting mode (`none`, `partial`, `full`)

### Plugin Settings
- `overwritePlugins` - Allow plugin overwrites
- `deletePluginDirectories` - Delete plugin directories on uninstall
- `loadIncompatiblePlugins` - Load plugins with version mismatches

## Common Use Cases

### Development vs Production Comparison
```bash
# Check development settings
WHEELS_ENV=development wheels get settings cache

# Check production settings
WHEELS_ENV=production wheels get settings cache
```

### Verify Database Configuration
```bash
wheels get settings dataSourceName
```

### Check All Caching Settings
```bash
wheels get settings cache
```

### Debugging Configuration Issues
```bash
# See all current settings
wheels get settings

# Check specific problematic setting
wheels get settings showDebugInformation
```

### Pre-deployment Verification
```bash
# Verify production settings
WHEELS_ENV=production wheels get settings
```

## Settings File Examples

### Basic Application Settings
```coldfusion
// config/settings.cfm
set(dataSourceName="myapp");
set(URLRewriting="partial");
set(errorEmailAddress="admin@myapp.com");
```

### Environment-Specific Settings
```coldfusion
// config/production/settings.cfm
set(cacheQueries=true);
set(cachePages=true);
set(cachePartials=true);
set(showDebugInformation=false);
set(showErrorInformation=false);
set(sendEmailOnError=true);
```

```coldfusion
// config/development/settings.cfm
set(cacheQueries=false);
set(showDebugInformation=true);
set(showErrorInformation=true);
set(sendEmailOnError=false);
```

## Data Type Support

The command correctly interprets different data types:

### Boolean Values
```coldfusion
set(cacheQueries=true);
set(showDebugInformation=false);
```

### Numeric Values
```coldfusion
set(cacheCullInterval=5);
set(cacheCullPercentage=10);
```

### String Values
```coldfusion
set(dataSourceName="myapp_db");
set(errorEmailAddress="admin@example.com");
```

### Complex Values
Arrays and structs are displayed with summary information:
```
complexSetting:                 [array with 5 items]
structSetting:                  {3 items}
```

## Error Handling

The command will show an error if:
- Not run from a Wheels application directory
- Settings files cannot be read
- Settings files contain syntax errors

### Not a Wheels Application
```
Error: This command must be run from a Wheels application directory
```

### Read Error
```
Error reading settings: [specific error message]
Details: [additional error details if available]
```

## Best Practices

1. **Environment-Specific Configs** - Keep environment-specific settings in separate files (`/config/[environment]/settings.cfm`)

2. **Document Custom Settings** - Comment your custom settings in the configuration files

3. **Use Consistent Naming** - Follow Wheels naming conventions for custom settings

4. **Verify Before Deployment** - Always check settings for the target environment before deploying

5. **Sensitive Data** - Keep sensitive settings (API keys, passwords) in environment variables or `.env` files

## Integration with Other Commands

Works well with other Wheels CLI commands:

```bash
# Check environment, then settings
wheels get environment
wheels get settings

# Verify cache settings before clearing cache
wheels get settings cache
wheels clear cache

# Check database settings before running migrations
wheels get settings dataSourceName
wheels db migrate
```

## Tips

- Setting names are case-insensitive when filtering
- The filter matches any part of the setting name
- Settings are displayed in alphabetical order
- Boolean values display as `true` or `false`
- Complex values (arrays, structs) show a summary
- The command shows which environment's settings are being displayed

## Troubleshooting

### Settings Not Showing Expected Values
1. Check which environment is active: `wheels get environment`
2. Verify the settings file exists in the correct location
3. Check for syntax errors in your settings files
4. Ensure settings use the correct `set()` function syntax

### Missing Settings
If expected settings are missing:
- Verify they're defined using `set()` function
- Check file paths: `/config/settings.cfm` and `/config/[environment]/settings.cfm`
- Ensure no syntax errors prevent parsing

### Filter Not Working
- Remember the filter is case-insensitive
- The filter matches any part of the setting name
- Use more specific terms for precise filtering

## Limitations

- The command parses settings files statically and may not capture all dynamic settings
- Complex CFML expressions in settings may not be fully evaluated
- Settings defined outside of `set()` function calls may not be detected
- Runtime settings modifications are not reflected