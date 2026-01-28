# wheels plugins install

Install a Wheels plugin from ForgeBox into the `/plugins` folder.

## Synopsis

```bash
wheels plugins install <name> [--dev] [--version=<version>]
```

## CommandBox Parameter Syntax

This command supports multiple parameter formats:

- **Positional parameters**: `wheels plugins install cfwheels-bcrypt` (plugin name)
- **Named parameters**: `name=value` (e.g., `name=cfwheels-bcrypt`, `version=1.0.0`)
- **Flag parameters**: `--flag` equals `flag=true` (e.g., `--dev` equals `dev=true`)
- **Flag with value**: `--flag=value` (e.g., `--version=1.0.0`)

**Parameter Mixing Rules:**

✅ **ALLOWED:**
- Positional: `wheels plugins install cfwheels-bcrypt`
- Positional + flags: `wheels plugins install cfwheels-bcrypt --version=1.0.0`
- All named: `name=cfwheels-bcrypt version=1.0.0`

❌ **NOT ALLOWED:**
- Positional + named for same param: `wheels plugins install cfwheels-bcrypt name=other`

**Recommendation:** Use positional for plugin name, flags for options: `wheels plugins install cfwheels-bcrypt --version=1.0.0`

## Parameters

| Parameter | Required | Type    | Description                                    |
|-----------|----------|---------|------------------------------------------------|
| `name`    | Yes      | string  | Plugin name or slug from ForgeBox              |
| `dev`     | No       | boolean | Install as development dependency (not used)   |
| `version` | No       | string  | Specific version to install (default: latest)  |

## Description

The `plugins install` command installs `cfwheels-plugins` type packages from ForgeBox into your application's `/plugins` folder. The command validates that the package is a valid cfwheels-plugin before installation.

### Features

- Installs only `cfwheels-plugins` type packages
- Validates package type before installation
- Automatically places plugins in `/plugins` folder
- Supports specific version installation
- Beautiful, color-coded output
- Helpful error messages

### Package Type Validation

The command ensures that only packages with type `cfwheels-plugins` can be installed. This prevents accidental installation of non-plugin packages.

## Examples

### Install latest version from ForgeBox

```bash
wheels plugins install cfwheels-bcrypt
```

**Output:**
```
==================================================
                Installing Plugin
==================================================


Plugin:                   cfwheels-bcrypt
Version:                  latest

Creating C:\Users\Hp\cli_testingapp\db_app\plugins\/api-tools-1.0.0.zip
 ------------------------------------------------------------
Creating C:\Users\Hp\cli_testingapp\db_app\plugins\/my-helper-1.0.0.zip
 √ | Installing package [forgebox:cfwheels-bcrypt]
============================================================

[SUCCESS]: Plugin installed successfully!

CFWheels 2.x plugin helper methods for the bCrypt Java Lib


Commands
--------------------------------------------------
  - wheels plugin list          View all installed plugins
  - wheels plugin info cfwheels-bcrypt   View plugin details
```

### Install specific version

```bash
wheels plugins install cfwheels-shortcodes --version=0.0.3
```

**Output:**
```
===========================================================
  Installing Plugin
===========================================================

Plugin:  cfwheels-shortcodes
Version: 0.0.3

[CommandBox installation output...]

===========================================================

[OK] Plugin installed successfully!

Shortcode support for Wheels content

Commands:
  wheels plugin list          View all installed plugins
  wheels plugin info cfwheels-shortcodes   View plugin details
```

### Install using plugin name (matches slug)

```bash
wheels plugins install bcrypt
```

The command will find and install `cfwheels-bcrypt` from ForgeBox.

### Installation fails (wrong package type)

```bash
wheels plugins install commandbox-migrations
```

**Output:**
```
===========================================================
  Installing Plugin
===========================================================

Plugin:  commandbox-migrations
Version: latest

===========================================================

[ERROR] Failed to install plugin

Error: Only cfwheels-plugins can be installed via this command

Possible solutions:
  - Verify the plugin name is correct
  - Check if the plugin exists on ForgeBox:
    wheels plugin list --available
  - Ensure the plugin type is 'cfwheels-plugins'
```

### Installation fails (plugin not found)

```bash
wheels plugins install nonexistent-plugin
```

**Output:**
```
===========================================================
  Installing Plugin
===========================================================

Plugin:  nonexistent-plugin
Version: latest

===========================================================

[ERROR] Failed to install plugin

Error: Plugin not found on ForgeBox

Possible solutions:
  - Verify the plugin name is correct
  - Check if the plugin exists on ForgeBox:
    wheels plugin list --available
  - Ensure the plugin type is 'cfwheels-plugins'
```

## Installation Process

1. **Display Header**: Shows plugin name and target version
2. **Package Validation**: Verifies the package is type `cfwheels-plugins`
3. **Download**: Uses CommandBox's PackageService to download from ForgeBox
4. **Installation**: CommandBox installs the package
5. **Directory Move**: If installed to wrong location, moves to `/plugins` folder
6. **Verification**: Confirms installation success
7. **Display Results**: Shows success message with helpful next steps

## How It Works

The command uses PluginService which:
1. Calls ForgeBox API to check package type
2. Uses `packageService.installPackage()` to download and install
3. Checks common installation paths (`/modules/`, root)
4. Moves plugin to `/plugins/` folder if needed
5. Returns success/failure status

## Package Sources

### ForgeBox (Only Supported Source)

The command only supports installing from ForgeBox:

```bash
# By slug
wheels plugins install cfwheels-bcrypt

# By name (auto-finds slug)
wheels plugins install bcrypt

# Specific version
wheels plugins install cfwheels-bcrypt --version=0.0.4
```

### Unsupported Sources

The following sources are NOT supported:
- ❌ GitHub repositories
- ❌ Direct URLs
- ❌ Local ZIP files
- ❌ Local directories

To install plugins from these sources, use CommandBox's native `install` command and manually move to `/plugins` folder.

## Error Messages

### Package Type Validation Failed
```
[ERROR] Failed to install plugin
Error: Only cfwheels-plugins can be installed via this command
```
**Solution**: Verify the package type on ForgeBox is `cfwheels-plugins`

### Plugin Not Found
```
[ERROR] Failed to install plugin
Error: Plugin not found on ForgeBox
```
**Solution**: Check available plugins with `wheels plugin list --available`

### Network Error
```
[ERROR] Failed to install plugin
Error: Could not connect to ForgeBox
```
**Solution**: Check internet connection and ForgeBox status

## Notes

- Only installs `cfwheels-plugins` type packages from ForgeBox
- Plugins are installed to `/plugins` folder
- The `--dev` parameter is accepted but not currently used
- Package type validation prevents installation of incorrect packages
- If a plugin is already installed, it will be overwritten
- After installation, use `wheels plugin info <name>` to view details
- Restart your application to activate the new plugin
- The command automatically handles directory placement

## See Also

- [wheels plugin list](plugins-list.md) - List installed plugins
- [wheels plugin info](plugins-info.md) - View plugin details
- [wheels plugin update](plugins-update.md) - Update a plugin
- [wheels plugin remove](plugins-remove.md) - Remove a plugin
