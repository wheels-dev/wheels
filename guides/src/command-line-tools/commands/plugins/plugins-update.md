# wheels plugin update

Update a Wheels plugin to the latest or specified version.

## Synopsis

```bash
wheels plugin update <name> [--version=<version>] [--force]
```

## Description

The `wheels plugin update` command updates an installed Wheels plugin. By default, it updates to the latest version available on ForgeBox, but you can specify a particular version. The command handles dependency updates automatically.

## Arguments

### name (required)
The name of the plugin to update.

## Options

### --version
Specific version to update to.
- **Default**: latest
- **Example**: `--version=2.0.0`

### --force
Force update even if already at the target version.
- **Default**: false

## Examples

### Update to latest version
```bash
wheels plugin update wheels-auth
```

### Update to specific version
```bash
wheels plugin update wheels-api-builder --version=2.0.0
```

### Force reinstall current version
```bash
wheels plugin update wheels-cache --force
```

## Output Example

```
🔄 Updating plugin: wheels-auth

Current version: 2.0.0
Updating to: latest

Installing update...

✅ Plugin 'wheels-auth' updated successfully!

To see plugin info:
  wheels plugin info wheels-auth

To see all installed plugins:
  wheels plugin list
```

## Update Process

1. **Version Check**: Compares current vs available versions
2. **Dependency Resolution**: Checks dependency compatibility
3. **Backup**: Creates backup of current version (if applicable)
4. **Download**: Fetches new version from ForgeBox
5. **Installation**: Replaces old files with new version
6. **Configuration**: Preserves existing configuration
7. **Cleanup**: Removes temporary files

## Version Specifications

### Latest Version
```bash
wheels plugin update wheels-auth
```

### Specific Version
```bash
wheels plugin update wheels-auth --version=2.1.0
```

### Version Ranges
```bash
wheels plugin update wheels-auth --version=">=2.0.0 <3.0.0"
```

## Dependency Handling

Updates handle dependencies automatically:
- **Compatible Updates**: Proceeds automatically
- **Breaking Changes**: Prompts for confirmation
- **Conflicts**: Shows resolution options

## Configuration Preservation

The update process preserves:
- Plugin configuration files
- Custom modifications (warned if overwritten)
- Database migrations
- User-generated content

## Rollback Support

If update fails:
```bash
# Automatic rollback on failure
Plugin update failed. Rolling back to version 2.0.0...
Rollback complete.
```

## Pre-Update Checks

The command performs several checks:
1. **Installation Status**: Verifies plugin is installed
2. **Version Availability**: Confirms target version exists
3. **Compatibility**: Checks Wheels version compatibility
4. **Dependencies**: Validates dependency requirements
5. **Disk Space**: Ensures sufficient space

## Common Scenarios

### Regular Updates
```bash
# Check and update single plugin
wheels plugin info wheels-auth
wheels plugin update wheels-auth
```

### Major Version Updates
```bash
# Update with breaking changes
wheels plugin update wheels-api --version=3.0.0
# Prompts for confirmation due to major version change
```

### Development Updates
```bash
# Update dev dependency
wheels plugin update wheels-test-utils --dev
```

## Error Messages

### Plugin Not Installed
```
Error: Plugin 'wheels-auth' is not installed. Use 'wheels plugin install wheels-auth' to install it.
```

### Already Up-to-Date
```
Plugin is already at the latest version (2.1.0)
Use --force to reinstall anyway
```

### Version Not Found
```
Error: Version '3.0.0' not found for plugin 'wheels-auth'
Available versions: 2.1.0, 2.0.0, 1.9.0
```

## Best Practices

1. **Test First**: Update in development before production
2. **Read Changelogs**: Review breaking changes
3. **Backup**: Backup before major updates
4. **Dependencies**: Update dependencies first
5. **Incremental**: Update one version at a time for major changes

## Notes

- Updates modify box.json dependencies
- Some plugins may require application restart
- Configuration files are backed up before update
- Network connection required

## See Also

- [wheels plugin update:all](plugins-update-all.md) - Update all plugins
- [wheels plugin outdated](plugins-outdated.md) - Check for updates
- [wheels plugin info](plugins-info.md) - Show plugin details
- [wheels plugin list](plugins-list.md) - List installed plugins