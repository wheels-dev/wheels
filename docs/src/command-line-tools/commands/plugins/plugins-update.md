# wheels plugin update

Update a Wheels plugin to the latest or a specified version from ForgeBox.

## Usage

```bash
wheels plugin update <name> [--version=<version>] [--force]
```

## Parameters

| Parameter | Required | Type    | Description                                        |
|-----------|----------|---------|----------------------------------------------------|
| `name`    | Yes      | string  | Name, slug, or folder name of the plugin to update|
| `version` | No       | string  | Specific version to update to (default: latest)    |
| `force`   | No       | boolean | Force update even if already at latest version     |

## Description

The `plugin update` command updates an installed Wheels plugin from the `/plugins` folder. It checks ForgeBox for the latest version, compares with the installed version, and performs the update if needed.

### Features

- Smart version checking (prevents unnecessary updates)
- Flexible plugin matching (by name, slug, or folder name)
- Real-time version queries from ForgeBox
- Clean removal and reinstallation process
- Helpful success and error messages
- Beautiful, color-coded output

## Examples

### Update to latest version

```bash
wheels plugin update bcrypt
```

**Output:**
```
===========================================================
  Updating Plugin: bcrypt
===========================================================

Plugin:          bcrypt
Current version: 0.0.3
Latest version:  0.0.4

Target version: 0.0.4
===========================================================

Removing old version...
Installing new version...

[CommandBox installation output...]

===========================================================

[OK] Plugin 'bcrypt' updated successfully!

Commands:
  wheels plugin info bcrypt   View plugin details
  wheels plugin list            View all installed plugins
```

### Plugin already up to date

```bash
wheels plugin update bcrypt
```

**Output:**
```
===========================================================
  Updating Plugin: bcrypt
===========================================================

Plugin:          bcrypt
Current version: 0.0.4
Latest version:  0.0.4

===========================================================

[OK] Plugin is already at the latest version (0.0.4)

Use --force to reinstall anyway:
  wheels plugin update bcrypt --force
```

### Update to specific version

```bash
wheels plugin update bcrypt --version=0.0.3
```

**Output:**
```
===========================================================
  Updating Plugin: bcrypt
===========================================================

Plugin:          bcrypt
Current version: 0.0.4
Latest version:  0.0.4

Target version: 0.0.3
===========================================================

Removing old version...
Installing new version...

[CommandBox installation output...]

===========================================================

[OK] Plugin 'bcrypt' updated successfully!

Commands:
  wheels plugin info bcrypt   View plugin details
  wheels plugin list            View all installed plugins
```

### Force reinstall

```bash
wheels plugin update bcrypt --force
```

**Output:**
```
===========================================================
  Updating Plugin: bcrypt
===========================================================

Plugin:          bcrypt
Current version: 0.0.4
Latest version:  0.0.4

Target version: 0.0.4
===========================================================

Removing old version...
Installing new version...

[CommandBox installation output...]

===========================================================

[OK] Plugin 'bcrypt' updated successfully!

Commands:
  wheels plugin info bcrypt   View plugin details
  wheels plugin list            View all installed plugins
```

### Plugin not installed

```bash
wheels plugin update nonexistent-plugin
```

**Output:**
```
===========================================================
  Updating Plugin: nonexistent-plugin
===========================================================

[ERROR] Plugin not found

Plugin 'nonexistent-plugin' is not installed

Install this plugin:
  wheels plugin install nonexistent-plugin
```

### Cannot reach ForgeBox

```bash
wheels plugin update bcrypt
```

**Output (network error):**
```
===========================================================
  Updating Plugin: bcrypt
===========================================================

Plugin:          bcrypt
Current version: 0.0.4

Error checking ForgeBox: Connection timeout

Unable to verify if update is needed

Options:
  - Specify a version:
    wheels plugin update bcrypt --version=x.x.x
  - Force reinstall:
    wheels plugin update bcrypt --force
```

## Update Process

1. **Find Plugin**: Searches `/plugins` folder for matching plugin by name, slug, or folder name
2. **Read Metadata**: Extracts current version and slug from plugin's `box.json`
3. **Query ForgeBox**: Uses `forgebox show` command to get latest version
4. **Version Comparison**: Cleans and compares versions to check if update needed
5. **Skip if Up-to-Date**: Exits early if already at target version (unless `--force`)
6. **Remove Old Version**: Deletes the plugin folder
7. **Install New Version**: Uses PackageService to download and install from ForgeBox
8. **Verify Location**: Moves plugin to `/plugins` if installed elsewhere
9. **Confirm Success**: Displays success message with helpful commands

## Plugin Matching

The command uses a smart matching algorithm to find plugins by:
1. **Folder name** (e.g., `bcrypt`)
2. **Slug from box.json** (e.g., `cfwheels-bcrypt`)
3. **Name from box.json** (e.g., `bcrypt`, `CFWheels Bcrypt`)
4. **Normalized variations** (strips `cfwheels-` and `wheels-` prefixes)

This means you can update using any of these:
```bash
wheels plugin update bcrypt
wheels plugin update cfwheels-bcrypt
wheels plugin update "CFWheels Bcrypt"
```

## Version Comparison

The command cleans versions before comparison:
- Removes all non-numeric characters except dots
- Example: `v0.0.4` becomes `0.0.4`
- Example: `0.0.4-beta` becomes `0.0.4`
- Compares cleaned strings for equality

If versions match, the plugin is considered up-to-date.

## Force Flag

Use `--force` to reinstall even when already up-to-date. Useful for:
- Recovering from corrupted installations
- Forcing cache refresh
- Testing installation process
- Reinstalling after manual modifications

## Error Handling

### Plugins Directory Not Found
```
[ERROR] Plugins directory not found
Plugin 'bcrypt' is not installed
```

### Plugin Not Installed
```
[ERROR] Plugin not found
Plugin 'bcrypt' is not installed

Install this plugin:
  wheels plugin install bcrypt
```

### ForgeBox Query Failed
```
Error checking ForgeBox: [error message]

Unable to verify if update is needed

Options:
  - Specify a version:
    wheels plugin update bcrypt --version=x.x.x
  - Force reinstall:
    wheels plugin update bcrypt --force
```

### Installation Failed
```
[ERROR] Error updating plugin
Error: [error message]
```

## Best Practices

1. **Check First**: Use `wheels plugin outdated` to see which plugins need updates
2. **Update One at a Time**: Test each plugin update individually
3. **Read Release Notes**: Check ForgeBox for breaking changes
4. **Test in Development**: Update in dev environment before production
5. **Keep Backups**: Commit your code before updating plugins

## Notes

- Only updates plugins from `/plugins` folder
- Only works with `cfwheels-plugins` type packages
- Removes old version completely before installing new version
- Uses ForgeBox slug for installation to ensure correct package
- Requires internet connection to query ForgeBox
- Version check is performed in real-time (not cached)
- After update, plugin may require application reload
- If installation fails, the old version is already removed (no automatic rollback)
- The command uses CommandBox's PackageService for downloading

## See Also

- [wheels plugin update:all](plugins-update-all.md) - Update all plugins
- [wheels plugin outdated](plugins-outdated.md) - Check for outdated plugins
- [wheels plugin info](plugins-info.md) - View plugin details
- [wheels plugin list](plugins-list.md) - List installed plugins
