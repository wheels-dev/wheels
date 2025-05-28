# wheels config env

Manage environment-specific configuration for your Wheels application.

## Synopsis

```bash
wheels config env [action] [environment] [options]
```

## Description

The `wheels config env` command provides specialized tools for managing environment-specific configurations. It helps you create, compare, sync, and validate configurations across different environments.

## Actions

| Action | Description |
|--------|-------------|
| `show` | Display environment configuration |
| `compare` | Compare configurations between environments |
| `sync` | Synchronize settings between environments |
| `validate` | Validate environment configuration |
| `export` | Export environment configuration |
| `import` | Import environment configuration |

## Arguments

| Argument | Description | Required |
|----------|-------------|----------|
| `action` | Action to perform | Yes |
| `environment` | Target environment name | Depends on action |

## Options

| Option | Description | Default |
|--------|-------------|---------|
| `--format` | Output format (table, json, yaml, diff) | `table` |
| `--output` | Output file path | Console |
| `--filter` | Filter settings by pattern | Show all |
| `--include-defaults` | Include default values | `false` |
| `--safe` | Hide sensitive values | `true` |
| `--force` | Force operation without confirmation | `false` |
| `--help` | Show help information |

## Examples

### Show environment config
```bash
wheels config env show production
```

### Compare environments
```bash
wheels config env compare development production
```

### Sync configurations
```bash
wheels config env sync development staging
```

### Validate configuration
```bash
wheels config env validate production
```

### Export configuration
```bash
wheels config env export production --format=json > prod-config.json
```

## Show Environment Configuration

Display all settings for an environment:

```bash
wheels config env show staging
```

Output:
```
Environment: staging
Configuration File: /config/staging/settings.cfm
Last Modified: 2024-01-15 10:30:45

Settings:
---------
dataSourceName: wheels_staging
environment: staging
showDebugInformation: true
showErrorInformation: true
cacheQueries: false
cacheActions: true
urlRewriting: partial

Database:
---------
Server: localhost
Database: wheels_staging
Port: 3306

Features:
---------
Debug: Enabled
Cache: Partial
Reload: Protected
```

## Compare Environments

### Basic Comparison
```bash
wheels config env compare development production
```

Output:
```
Comparing: development → production

Setting                 Development          Production
--------------------- ------------------- -------------------
environment           development         production
dataSourceName        wheels_dev          wheels_prod
showDebugInformation  true               false
showErrorInformation  true               false
cacheQueries          false              true
cacheActions          false              true

Differences: 6
Only in development: 2
Only in production: 1
```

### Detailed Diff
```bash
wheels config env compare development production --format=diff
```

Output:
```diff
--- development
+++ production
@@ -1,6 +1,6 @@
-environment=development
-dataSourceName=wheels_dev
-showDebugInformation=true
-showErrorInformation=true
-cacheQueries=false
-cacheActions=false
+environment=production
+dataSourceName=wheels_prod
+showDebugInformation=false
+showErrorInformation=false
+cacheQueries=true
+cacheActions=true
```

## Synchronize Environments

### Copy Settings
```bash
wheels config env sync production staging
```

Prompts:
```
Sync configuration from production to staging?

Settings to copy:
- cacheQueries: false → true
- cacheActions: false → true
- sessionTimeout: 1800 → 3600

Settings to preserve:
- dataSourceName: wheels_staging
- environment: staging

Continue? (y/N)
```

### Selective Sync
```bash
wheels config env sync production staging --filter=cache*
```

### Safe Sync
```bash
wheels config env sync production staging --safe
# Excludes: passwords, keys, datasources
```

## Validate Configuration

### Full Validation
```bash
wheels config env validate production
```

Output:
```
Validating: production

✓ Configuration file exists
✓ Syntax is valid
✓ Required settings present
✓ Database connection successful
⚠ Warning: Debug information enabled
✗ Error: Missing encryption key

Status: FAILED (1 error, 1 warning)
```

### Quick Check
```bash
wheels config env validate all
```

Shows validation summary for all environments.

## Export Configuration

### Export Formats

JSON:
```bash
wheels config env export production --format=json
```

YAML:
```bash
wheels config env export production --format=yaml
```

Environment variables:
```bash
wheels config env export production --format=env
```

### Export Options
```bash
# Include descriptions
wheels config env export production --verbose

# Exclude sensitive data
wheels config env export production --safe

# Filter specific settings
wheels config env export production --filter=cache*
```

## Import Configuration

### From File
```bash
wheels config env import staging --from=staging-config.json
```

### Merge Import
```bash
wheels config env import staging --from=updates.json --merge
```

### Validation
```bash
wheels config env import staging --from=config.json --validate
```

## Environment Templates

### Create Template
```bash
wheels config env export production --template > environment-template.json
```

### Use Template
```bash
wheels config env create qa --from-template=environment-template.json
```

## Bulk Operations

### Update Multiple Environments
```bash
# Update all non-production environments
for env in development staging qa; do
  wheels config env sync production $env --filter=cache*
done
```

### Batch Validation
```bash
wheels config env validate all --report=validation-report.html
```

## Configuration Inheritance

Show inheritance chain:
```bash
wheels config env show staging --show-inheritance
```

Output:
```
Inheritance Chain:
1. /config/staging/settings.cfm (environment-specific)
2. /config/settings.cfm (global)
3. Framework defaults

Override Summary:
- From global: 15 settings
- From defaults: 45 settings
- Environment-specific: 8 settings
```

## Security Features

### Safe Mode
Hide sensitive values:
```bash
wheels config env show production --safe
```

Sensitive patterns:
- `*password*`
- `*secret*`
- `*key*`
- `*token*`

### Audit Trail
```bash
wheels config env audit production
```

Shows configuration change history.

## Integration

### CI/CD Usage
```yaml
- name: Validate configs
  run: |
    wheels config env validate all
    wheels config env compare staging production --fail-on-diff
```

### Documentation
```bash
# Generate environment docs
wheels config env export all --format=markdown > ENVIRONMENTS.md
```

## Best Practices

1. **Regular Validation**: Check configs before deployment
2. **Environment Parity**: Keep environments similar
3. **Safe Exports**: Never export sensitive data
4. **Version Control**: Track configuration files
5. **Document Differences**: Explain why environments differ

## Troubleshooting

### Validation Failures
- Check syntax errors
- Verify required settings
- Test database connections

### Sync Issues
- Review protected settings
- Check file permissions
- Verify source environment

### Import Problems
- Validate import format
- Check for conflicts
- Review type mismatches

## Notes

- Some operations require application restart
- Sensitive values protected by default
- Changes logged for audit purposes
- Use templates for consistency

## See Also

- [wheels config list](config-list.md) - List all settings
- [wheels config set](config-set.md) - Set configuration values
- [wheels env](../environment/env.md) - Environment management
- [Configuration Guide](../../configuration.md)