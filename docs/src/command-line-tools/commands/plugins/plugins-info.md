# wheels plugin info (coming Soon)
*This command may not work as expected. A complete and stable version is **coming soon**.*

Show detailed information about a Wheels plugin.

## Synopsis

```bash
wheels plugin info <name>
```

## Description

The `wheels plugin info` command displays comprehensive information about a specific Wheels plugin. It shows both ForgeBox metadata and local installation status, helping you make informed decisions about plugin usage.

## Arguments

### name (required)
The name of the plugin to show information for.

## Examples

### Show plugin information
```bash
wheels plugin info wheels-auth
```

### Check a specific plugin
```bash
wheels plugin info wheels-api-builder
```

## Output Example

```
📦 Plugin Information: wheels-auth

✅ Status: Installed locally
📌 Version: 2.0.0

ForgeBox Information:
📝 Name: Wheels Authentication Plugin
🔗 Slug: wheels-auth
🏷️  Latest Version: 2.1.0
📁 Type: cfwheels-plugins
📄 Description: Complete authentication and authorization system for Wheels applications
👤 Author: John Doe
📊 Downloads: 15,432
📅 Created: 2022-03-15
🔄 Updated: 2024-01-15
🌐 Homepage: https://github.com/johndoe/wheels-auth
💻 Repository: https://github.com/johndoe/wheels-auth.git
🐛 Issues: https://github.com/johndoe/wheels-auth/issues
⚖️  License: MIT

Dependencies:
  • wheels-validation: >=1.0.0
  • bcrypt: >=1.0.0

Available Versions:
  • 2.1.0 (2024-01-15)
  • 2.0.0 (2023-11-20)
  • 1.9.5 (2023-09-10)
  • 1.9.0 (2023-07-05)
  • 1.8.0 (2023-05-01)
  ... and 12 more

Installation:
To update this plugin:
  wheels plugin update wheels-auth

To see all available plugins:
  wheels plugin search
```

## Information Sections

### Status Information
- **Installation Status**: Whether plugin is installed locally or globally
- **Installed Version**: Current version if installed
- **Update Available**: Shows if newer version exists

### ForgeBox Metadata
- **Name & Description**: Official plugin name and purpose
- **Version Info**: Latest version and version history
- **Author Details**: Plugin creator information
- **Statistics**: Download count and activity metrics
- **Links**: Homepage, repository, and issue tracker
- **License**: Distribution license

### Dependencies
Lists required dependencies with version constraints.

### Version History
Shows recent versions with release dates (limited to 5 most recent).

## Installation Commands

Based on status, suggests appropriate commands:
- **Not Installed**: `wheels plugin install <name>`
- **Installed**: `wheels plugin update <name>`
- **Outdated**: Shows update command with version

## Use Cases

### Pre-Installation Check
```bash
# Check plugin before installing
wheels plugin info wheels-cache-manager
```

### Version Verification
```bash
# Check if update available
wheels plugin info wheels-api-builder
```

### Dependency Review
```bash
# Review dependencies before installation
wheels plugin info wheels-payment-gateway
```

## Notes

- Requires internet connection for ForgeBox data
- Shows local installation status first
- Caches ForgeBox data for 5 minutes
- Works with both installed and uninstalled plugins

## Error Handling

### Plugin Not Found
```
Error: Plugin 'wheels-unknown' not found on ForgeBox or installed locally
```

### Network Issues
Shows local information if available, with warning about missing ForgeBox data.

## See Also

- [wheels plugin search](plugins-search.md) - Search for plugins
- [wheels plugin install](plugins-install.md) - Install plugins
- [wheels plugin update](plugins-update.md) - Update plugins
- [wheels plugin list](plugins-list.md) - List installed plugins