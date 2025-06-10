# plugins remove

Removes an installed Wheels CLI plugin.

## Usage

```bash
wheels plugins remove <name> [--global] [--force]
```

## Parameters

- `name` - (Required) Plugin name to remove
- `--global` - (Optional) Remove globally installed plugin
- `--force` - (Optional) Force removal without confirmation

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
wheels plugins remove wheels-vue-cli
```

### Remove global plugin
```bash
wheels plugins remove wheels-docker --global
```

### Force removal (skip confirmation)
```bash
wheels plugins remove wheels-testing --force
```

### Remove global plugin without confirmation
```bash
wheels plugins remove wheels-cli-tools --global --force
```

## Removal Process

1. **Dependency Check**: Ensures no other plugins depend on this one
2. **Backup Creation**: Saves plugin files to backup directory
3. **Deactivation**: Disables plugin in application
4. **File Removal**: Deletes plugin files and directories
5. **Cleanup**: Removes configuration entries
6. **Verification**: Confirms successful removal

## Output

### With confirmation prompt (default)
```
Are you sure you want to remove the plugin 'wheels-vue-cli'? (y/n): y
🗑️  Removing plugin: wheels-vue-cli...

✅ Plugin removed successfully
```

### With force flag
```
🗑️  Removing plugin: wheels-vue-cli...

✅ Plugin removed successfully
```

### Cancellation
```
Are you sure you want to remove the plugin 'wheels-vue-cli'? (y/n): n
Plugin removal cancelled.
```

## Notes

- The `--force` flag skips the confirmation prompt
- Use `--global` to remove plugins installed globally
- Use `wheels plugins list` to verify removal
- Some plugins may require manual cleanup of configuration files
- Restart your application after removing plugins that affect core functionality