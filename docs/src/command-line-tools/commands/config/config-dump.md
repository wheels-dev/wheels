# Wheels Config Dump Command Guide

## Overview

The `wheels config dump` command exports your Wheels application configuration settings for inspection, backup, or migration purposes. It can display configurations in multiple formats and optionally mask sensitive values for security.

## Basic Usage

```bash
wheels config dump
```

This displays the current environment's configuration in a formatted table in the console.

## Command Syntax

```bash
wheels config dump [environment] [--format=<type>] [--output=<file>] [--noMask]
```

## Arguments and Options

### Positional Arguments

| Argument | Required | Description | Default |
|----------|----------|-------------|---------|
| `environment` | No | The environment to dump (development, testing, production) | Auto-detects from WHEELS_ENV or defaults to "development" |

### Options

| Option | Description | Values | Default |
|--------|-------------|--------|---------|
| `--format=<type>` | Output format for the configuration | `table`, `json`, `env`, `cfml` | Console: `table`<br>File: `json` |
| `--output=<file>` | File path to save the configuration | Any valid file path | None (displays to console) |
| `--noMask` | Don't mask sensitive values (passwords, keys, tokens, etc.) | Flag (true/false) | `false` (sensitive values are masked) |

### Option Details

#### `--format`
Specifies the output format for the configuration dump:
- **`table`**: Formatted tables organized by category (best for console viewing)
- **`json`**: Structured JSON format (best for programmatic use and file storage)
- **`env`**: Environment variables format (.env compatible)
- **`cfml`**: Wheels set() statements format

#### `--output`
When specified, saves the configuration to a file instead of displaying to console. If no format is explicitly specified with `--output`, JSON format is automatically used for better file compatibility.

#### `--noMask`
**⚠️ Security Warning**: This option exposes sensitive configuration data including passwords, API keys, and tokens. Only use when absolutely necessary and ensure the output is stored securely.

## Output Formats

### Table Format (Console Default)
Displays configuration in organized categories with formatted tables:
- DATABASE Settings
- CACHING Settings  
- SECURITY Settings
- ENVIRONMENT Settings
- OTHER Settings

### JSON Format (File Default)
Exports configuration as structured JSON:
```json
{
  "datasource": "myapp",
  "cacheQueries": false,
  "environment": "development",
  "_environment": {
    "WHEELS_ENV": "development"
  }
}
```

### Environment Variables Format (.env)
Exports as environment variables compatible with .env files:
```bash
## Application Settings
DATASOURCE=myapp
CACHE_QUERIES=false
ENVIRONMENT=development
```

### CFML Format
Exports as Wheels `set()` statements:
```cfml
// Wheels Configuration Export
set(datasource = "myapp");
set(cacheQueries = false);
set(environment = "development");
```

## Common Use Cases

### 1. Quick Configuration Review
```bash
# View current configuration
wheels config dump

# View production configuration
wheels config dump production
```

### 2. Backup Configuration
```bash
# Backup as JSON (default for files)
wheels config dump --output=config-backup.json

# Backup with timestamp
wheels config dump --output="backup/config-$(date +%Y%m%d).json"
```

### 3. Environment Comparison
```bash
# Export different environments
wheels config dump development --output=dev-config.json
wheels config dump production --output=prod-config.json

# Then compare using diff tools
diff dev-config.json prod-config.json
```

### 4. Generate Environment Files
```bash
# Create .env file template
wheels config dump --format=env --output=.env.template

# Create environment-specific files
wheels config dump production --format=env --output=.env.production
```

### 5. Migration Between Servers
```bash
# Export from source server (masked)
wheels config dump --output=config-export.json

# Export with sensitive data (be careful!)
wheels config dump --noMask --output=config-complete.json
```

### 6. Generate CFML Settings
```bash
# Create settings file for another environment
wheels config dump --format=cfml --output=config/staging/settings.cfm
```

## Security Considerations

### Automatic Masking
By default, the command masks sensitive values containing these keywords:
- password
- secret
- key
- token
- apikey / api_key
- private
- credential
- auth
- passphrase
- salt
- pwd

Masked values appear as: `***MASKED***`

### Using --noMask
Only use `--noMask` when:
- You need complete configuration for migration
- Output is being saved to a secure location
- You're in a development environment

**Never commit unmasked configuration files to version control!**

## Configuration Sources

The command loads configuration from multiple sources in order:

1. **Base Settings**: `/config/settings.cfm`
2. **Environment Settings**: `/config/[environment]/settings.cfm`
3. **Environment Variables**: `.env` file (if exists)

Environment detection checks (in order):
1. `.env` file: `WHEELS_ENV` variable
2. System environment: `WHEELS_ENV` variable
3. System environment: `ENVIRONMENT` variable
4. Default: `development`

## File Output Behavior

When using `--output`:
- **No format specified**: Automatically uses JSON format
- **Format specified**: Uses the specified format
- **Notification**: Displays which format was used in the success message

```bash
# These save as JSON
wheels config dump --output=config.json
wheels config dump --output=settings.txt

# This saves as ENV format
wheels config dump --format=env --output=settings.env

# This explicitly saves as table format
wheels config dump --format=table --output=config.txt
```

## Examples

### Basic Examples
```bash
# View current configuration
wheels config dump

# View testing environment configuration
wheels config dump testing

# Export as JSON to console
wheels config dump --format=json
```

### Advanced Examples
```bash
# Complete production backup (unmasked)
wheels config dump production --noMask --output=prod-complete.json

# Generate environment file for Docker
wheels config dump --format=env --output=docker/.env

# Create CFML settings for new environment
wheels config dump --format=cfml --output=config/custom/settings.cfm

# Quick masked backup with date
wheels config dump --output="backups/config-$(date +%Y%m%d-%H%M%S).json"
```

### Pipeline Integration
```bash
# CI/CD configuration validation
wheels config dump --format=json | jq '.datasource'

# Environment variable generation for deployment
wheels config dump production --format=env --output=/tmp/app.env
```

## Troubleshooting

### No settings.cfm file found
**Error**: "No settings.cfm file found in config directory"
**Solution**: Ensure you're running the command from your Wheels application root directory

### Invalid format specified
**Error**: "Invalid format: [format]. Valid formats are: table, json, env, cfml"
**Solution**: Use one of the supported formats: table, json, env, or cfml

### File write permissions
**Error**: "Failed to write file"
**Solution**: Ensure you have write permissions for the specified output directory

### Environment not detected
**Issue**: Always shows "development" environment
**Solution**: Set the WHEELS_ENV environment variable or create a .env file with WHEELS_ENV=production

## Best Practices

1. **Regular Backups**: Schedule regular configuration exports as part of your backup strategy
2. **Version Control**: Store masked configuration exports in version control for tracking changes
3. **Environment Validation**: Use dumps to verify configuration changes before deployment
4. **Security First**: Always use masked output unless absolutely necessary
5. **Documentation**: Keep exported configurations with deployment documentation

## Support

For issues or questions about the `wheels config dump` command:
1. Check the Wheels documentation
2. Verify your Wheels and CommandBox versions are compatible
3. Ensure proper file permissions and paths
4. Review the command output for specific error messages