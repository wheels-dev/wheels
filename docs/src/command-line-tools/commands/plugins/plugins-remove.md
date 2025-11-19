# plugins remove

Removes an installed Wheels CLI plugin.

## Synopsis

```bash
wheels plugins remove <name> [--force]
```

## CommandBox Parameter Syntax

This command supports multiple parameter formats:

- **Positional parameters**: `wheels plugins remove cfwheels-bcrypt` (plugin name)
- **Named parameters**: `name=value` (e.g., `name=cfwheels-bcrypt`)
- **Flag parameters**: `--flag` equals `flag=true` (e.g., `--force` equals `force=true`)

**Parameter Mixing Rules:**

**ALLOWED:**
- Positional: `wheels plugins remove cfwheels-bcrypt`
- Positional + flags: `wheels plugins remove cfwheels-bcrypt --force`
- All named: `name=cfwheels-bcrypt force=true`

**NOT ALLOWED:**
- Positional + named for same param: `wheels plugins remove cfwheels-bcrypt name=other`

**Recommendation:** Use positional for plugin name, flags for options: `wheels plugins remove cfwheels-bcrypt --force`

## Parameters

| Parameter | Required | Type    | Description                              |
|-----------|----------|---------|------------------------------------------|
| `name`    | Yes      | string  | Plugin name to remove                    |
| `--force` | No       | boolean | Force removal without confirmation       |

## Description

The `plugins remove` command safely uninstalls a plugin from your Wheels application. It:

- Checks if the plugin is installed
- Prompts for confirmation (unless `--force` is used)
- Removes plugin from box.json
- Cleans up plugin files
- Updates plugin registry

## Examples

### Basic plugin removal
```bash
wheels plugins remove wheels-vue-cli
```

### Force removal (skip confirmation)
```bash
wheels plugins remove wheels-testing --force
```

## Removal Process

1. **Installation Check**: Verifies the plugin is installed in box.json or plugins folder
2. **Confirmation**: Prompts user to confirm removal (unless --force is used)
3. **Removal**: Removes plugin entry from box.json
4. **File Cleanup**: Deletes plugin files via CommandBox package service
5. **Verification**: Confirms successful removal

## Output

### With confirmation prompt (default)
```
Are you sure you want to remove the plugin 'wheels-vue-cli'? (y/n): y
[*] Removing plugin: wheels-vue-cli...

[OK] Plugin removed successfully
Run 'wheels plugins list' to see remaining plugins
```

### With force flag
```
[*] Removing plugin: wheels-vue-cli...

[OK] Plugin removed successfully
Run 'wheels plugins list' to see remaining plugins
```

### Plugin not installed
```
Are you sure you want to remove the plugin 'bcrypt'? (y/n): y
[*] Removing plugin: bcrypt...

[ERROR] Failed to remove plugin: Plugin 'bcrypt' is not installed
```

### Cancellation
```
Are you sure you want to remove the plugin 'wheels-vue-cli'? (y/n): n
Plugin removal cancelled.
```

## Notes

- The `--force` flag skips the confirmation prompt
- Use `wheels plugins list` to verify removal
- The command checks if plugin is actually installed before removal
- Plugin must exist in box.json dependencies, devDependencies, or plugins folder
- Restart your application after removing plugins that affect core functionality
