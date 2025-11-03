# Wheels config diff

## Overview

The `wheels config diff` command compares configuration settings and environment variables between two environments. It helps identify differences in both Wheels settings files and environment-specific `.env` files, making it easier to understand configuration variations across development, testing, and production environments.

## Command Syntax

```bash
wheels config diff <env1> <env2> [--changesOnly] [--format=<format>] [--env] [--settings]
```

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| env1 | string | Yes | First environment to compare (e.g., development, testing, production) |
| env2 | string | Yes | Second environment to compare |
| --changesOnly | flag | No | Only show differences, hide identical values |
| --format | string | No | Output format: `table` (default) or `json` |
| --env | flag | No | Compare only environment variables |
| --settings | flag | No | Compare only Wheels settings |

## Comparison Modes

The command can operate in three modes:

1. **Both (Default)** - Compares both settings and environment variables
2. **Environment Variables Only** - Use `--env` flag
3. **Settings Only** - Use `--settings` flag

## Basic Usage

### Compare All Configurations
```bash
# Compare everything between development and production
wheels config diff development production
```

### Compare Only Differences
```bash
# Show only the differences, hide identical values
wheels config diff development production --changesOnly
```

### Compare Environment Variables Only
```bash
# Compare only .env files between environments
wheels config diff development production --env
```

### Compare Settings Only
```bash
# Compare only Wheels settings files
wheels config diff development production --settings
```

### JSON Output Format
```bash
# Output comparison as JSON for parsing
wheels config diff development production --format=json
```

## What Gets Compared

### Settings Configuration
The command compares:
- Base settings from `config/settings.cfm`
- Environment-specific overrides from `config/{environment}/settings.cfm`
- All `set()` function calls are parsed and compared

### Environment Variables
The command compares:
- Environment-specific files: `.env.{environment}`
- Falls back to `.env` for development environment if `.env.development` doesn't exist
- All KEY=VALUE pairs are parsed with proper handling of:
  - Comments (lines starting with #)
  - Inline comments
  - Quoted values (single or double quotes)
  - Whitespace trimming

## File Locations

### Settings Files
```
config/
├── settings.cfm                 # Base settings
├── development/
│   └── settings.cfm             # Development overrides
├── testing/
│   └── settings.cfm             # Testing overrides
└── production/
    └── settings.cfm             # Production overrides
```

### Environment Files
```
project_root/
├── .env                         # Base/development environment variables
├── .env.development             # Development-specific variables
├── .env.testing                 # Testing-specific variables
└── .env.production              # Production-specific variables
```

## Output Format

### Table Format (Default)

The table output is organized into clear sections:

```
========================================
Configuration Comparison: development vs production
========================================

[SETTINGS CONFIGURATION]

Different Values:
┌──────────────────────┬────────────┬────────────┐
│ Setting              │ development│ production │
├──────────────────────┼────────────┼────────────┤
│ showDebugInformation │ true       │ false      │
│ cacheQueries         │ false      │ true       │
└──────────────────────┴────────────┴────────────┘

Only in development:
┌─────────────────┬──────────┐
│ Setting         │ Value    │
├─────────────────┼──────────┤
│ debugPlugin     │ true     │
└─────────────────┴──────────┘

Only in production:
┌─────────────────┬──────────┐
│ Setting         │ Value    │
├─────────────────┼──────────┤
│ forceSSL        │ true     │
└─────────────────┴──────────┘

[ENVIRONMENT VARIABLES]

Different Values:
┌──────────────┬────────────────┬────────────────┐
│ Variable     │ development    │ production     │
├──────────────┼────────────────┼────────────────┤
│ DB_NAME      │ app_dev        │ app_prod       │
│ DEBUG_MODE   │ true           │ false          │
└──────────────┴────────────────┴────────────────┘

========================================
SUMMARY
========================================
Settings:
  Total: 25
  Identical: 20
  Different: 2
  Unique: 3

Environment Variables:
  Total: 15
  Identical: 10
  Different: 2
  Unique: 3

Overall:
  Total configurations: 40
  Identical: 30
  Different: 4
  Unique: 6
  Similarity: 75%
```

### JSON Format

```json
{
  "env1": "development",
  "env2": "production",
  "comparisons": {
    "settings": {
      "identical": [...],
      "different": [...],
      "onlyInFirst": [...],
      "onlyInSecond": [...]
    },
    "env": {
      "identical": [...],
      "different": [...],
      "onlyInFirst": [...],
      "onlyInSecond": [...]
    }
  },
  "summary": {
    "settings": {
      "totalSettings": 25,
      "identical": 20,
      "different": 2,
      "onlyInFirst": 1,
      "onlyInSecond": 2
    },
    "env": {
      "totalVariables": 15,
      "identical": 10,
      "different": 2,
      "onlyInFirst": 1,
      "onlyInSecond": 2
    },
    "overall": {
      "total": 40,
      "identical": 30,
      "different": 4,
      "unique": 6,
      "similarity": 75
    }
  }
}
```

## Security Features

### Automatic Masking
The command automatically masks sensitive values containing these keywords:
- password
- secret
- key
- token
- apikey/api_key
- private
- credential
- auth
- passphrase
- salt

Masked values appear as `***MASKED***` in the output.

### Example
```
┌──────────────┬────────────────┬────────────────┐
│ Variable     │ development    │ production     │
├──────────────┼────────────────┼────────────────┤
│ DB_PASSWORD  │ ***MASKED***   │ ***MASKED***   │
│ API_KEY      │ ***MASKED***   │ ***MASKED***   │
└──────────────┴────────────────┴────────────────┘
```

## Common Use Cases

### Pre-Deployment Verification
```bash
# Verify configuration differences before deploying to production
wheels config diff testing production --changesOnly
```

### Environment Synchronization Check
```bash
# Check if development and testing have similar configurations
wheels config diff development testing
```

### Security Audit
```bash
# Review all security-related settings between environments
wheels config diff development production --settings | grep -i "debug\|error\|ssl"
```

### CI/CD Pipeline Integration
```bash
# In your deployment script
wheels config diff staging production --format=json > config-diff.json
# Parse JSON to validate critical settings match expectations
```

### Environment Variable Validation
```bash
# Ensure all required environment variables exist in production
wheels config diff development production --env --changesOnly
```

### Quick Similarity Check
```bash
# Get a quick overview of configuration similarity
wheels config diff development testing | grep "Similarity:"
```

## Examples

### Example 1: Basic Comparison
```bash
wheels config diff development production
```
Shows all differences and similarities between development and production configurations.

### Example 2: Changes Only
```bash
wheels config diff testing production --changesOnly
```
Shows only the differences, useful for quick reviews.

### Example 3: Environment Variables Focus
```bash
wheels config diff development staging --env --changesOnly
```
Shows only environment variable differences between development and staging.

### Example 4: JSON for Automation
```bash
wheels config diff development production --format=json | jq '.summary.overall.similarity'
```
Outputs similarity percentage for automated checks.

### Example 5: Settings Validation
```bash
wheels config diff development production --settings --changesOnly
```
Validates only Wheels settings differences.

## Error Handling

### Environment Not Found
```
Warning: Settings for environment 'staging' not found!
```
The command continues with available data and shows warnings for missing files.

### No Configuration File
```
Warning: No settings.cfm file found in config directory
```
The command will still compare environment variables if available.

### Same Environment Comparison
```
Error: Cannot compare an environment to itself
```
You must specify two different environments.

### Invalid Format
```
Error: Invalid format: xml. Valid formats are: table, json
```
Only `table` and `json` formats are supported.

## Best Practices

1. **Regular Comparisons** - Run comparisons before each deployment to catch unintended changes

2. **Use changesOnly for Reviews** - Focus on differences during code reviews

3. **Automate with JSON** - Use JSON output in CI/CD pipelines for automated validation

4. **Document Differences** - Keep a record of intentional differences between environments

5. **Security First** - Always review security-related settings (debug, error handling, SSL)

6. **Version Control** - Track both settings files and environment files in version control (except sensitive .env files)

## Tips

- Use `--changesOnly` to quickly identify configuration drift
- Pipe JSON output to `jq` for advanced filtering and processing
- Create aliases for common comparisons (e.g., `alias cfgdiff='wheels config diff'`)
- Review the similarity percentage as a quick health check
- Use the command before and after configuration changes to verify impact
- Combine with `wheels config check` for comprehensive configuration validation

## File Format Examples

### Settings File (config/production/settings.cfm)
```cfm
<cfscript>
// Production-specific settings
set(showDebugInformation = false);
set(showErrorInformation = false);
set(sendEmailOnError = true);
set(errorEmailAddress = "admin@example.com");
set(cacheQueries = true);
set(forceSSL = true);
</cfscript>
```

### Environment File (.env.production)
```bash
# Production Environment Variables
WHEELS_ENV=production

# Database Configuration
DB_HOST=prod.database.com
DB_PORT=3306
DB_NAME=app_production
DB_USER=prod_user
DB_PASSWORD=secure_password_here

# Application Settings
DEBUG_MODE=false
LOG_LEVEL=error
SESSION_TIMEOUT=30

# API Keys
API_KEY=prod_api_key_here
SECRET_KEY=prod_secret_key
```

## Troubleshooting

### Files Not Being Read
- Ensure files exist in the correct locations
- Check file permissions (must be readable)
- Verify file naming conventions (.env.{environment})

### Parsing Issues
- Check for syntax errors in settings.cfm files
- Ensure .env files use proper KEY=VALUE format
- Remove any special characters that might cause parsing errors

### Missing Comparisons
- If using `--env` or `--settings`, ensure you're not filtering out the data you want
- Check that both environments have the respective files

### Performance Issues
- Large configuration files may take time to parse
- Consider using `--changesOnly` to reduce output
- Use JSON format for faster processing in scripts

## Related Commands

- `wheels config check` - Validate configuration for issues
- `wheels get environment` - Display current environment
- `wheels env merge` - Merge environment configurations
- `wheels env set` - Set environment variables

## Summary

The `wheels config diff` command is an essential tool for managing multi-environment Wheels applications. It provides comprehensive comparison capabilities for both application settings and environment variables, helping teams maintain consistency and catch configuration drift before it causes issues in production.