# plugins remove

Removes an installed plugin from your CFWheels application.

## Usage

```bash
wheels plugins remove <plugin> [--backup] [--force]
```

## Parameters

- `plugin` - (Required) Name of the plugin to remove
- `--backup` - (Optional) Create a backup before removal. Default: true
- `--force` - (Optional) Force removal even if other plugins depend on it

## Description

The `plugins remove` command safely uninstalls a plugin from your CFWheels application. It:

- Checks for dependent plugins
- Creates a backup (by default)
- Removes plugin files
- Cleans up configuration
- Updates plugin registry

## Examples

### Basic plugin removal
```bash
wheels plugins remove authentication
```

### Remove without backup
```bash
wheels plugins remove cache-manager --no-backup
```

### Force removal (ignore dependencies)
```bash
wheels plugins remove routing --force
```

### Remove multiple plugins
```bash
wheels plugins remove plugin1
wheels plugins remove plugin2
```

## Removal Process

1. **Dependency Check**: Ensures no other plugins depend on this one
2. **Backup Creation**: Saves plugin files to backup directory
3. **Deactivation**: Disables plugin in application
4. **File Removal**: Deletes plugin files and directories
5. **Cleanup**: Removes configuration entries
6. **Verification**: Confirms successful removal

## Output

```
Removing plugin: authentication
================================

Checking dependencies... ✓
Creating backup at /backups/plugins/authentication-2.1.0-20240115.zip... ✓
Deactivating plugin... ✓
Removing plugin files... ✓
Cleaning configuration... ✓

Plugin 'authentication' removed successfully!

Note: Backup saved to /backups/plugins/authentication-2.1.0-20240115.zip
      You may need to restart your application.
```

## Dependency Handling

If other plugins depend on the one being removed:

```
Cannot remove plugin: routing
=============================

The following plugins depend on 'routing':
- advanced-routing (v1.2.0)
- api-framework (v3.0.1)

Options:
1. Remove dependent plugins first
2. Use --force to remove anyway (may break functionality)
```

## Backup Management

Backups are stored in `/backups/plugins/` with timestamp:
- Format: `[plugin-name]-[version]-[timestamp].zip`
- Example: `authentication-2.1.0-20240115143022.zip`

### Restore from backup
```bash
# Manually restore a plugin
wheels plugins install /backups/plugins/authentication-2.1.0-20240115.zip
```

## Notes

- Always restart your application after removing plugins
- Backups are kept for 30 days by default
- Some plugins may leave configuration files that need manual cleanup
- Database tables created by plugins are not automatically removed
- Use `wheels plugins list` to verify removal