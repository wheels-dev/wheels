# plugins info

Shows detailed information about a Wheels plugin, including version, description, author, and links.

## Usage

```bash
wheels plugins info <name>
```

## Parameters

| Parameter | Required | Type   | Description                           |
|-----------|----------|--------|---------------------------------------|
| `name`    | Yes      | string | Name or slug of the plugin to inspect |

## Description

The `plugins info` command displays comprehensive information about a Wheels plugin. It prioritizes local installation data when available, only querying ForgeBox when the plugin is not installed locally.

### Information Displayed

When the plugin is **installed locally**, the command shows:
- Installation status
- Plugin name and version
- Slug
- Type (mvc, plugin, etc.)
- Author information
- Description
- Homepage URL
- Repository URL
- Documentation URL
- Issues/Bugs URL
- Keywords

When the plugin is **not installed**, the command shows:
- Installation status
- ForgeBox package information
- Available versions
- Installation instructions

## Examples

### Check installed plugin
```bash
wheels plugins info wheels-core
```

**Output:**
```
===========================================================
  Plugin Information: wheels-core
===========================================================


Status
--------------------------------------------------
  [OK] Installed locally

Wheels Core
Wheels Framework Core Directory

Details:
  Version:     3.0.0-SNAPSHOT+1030
  Slug:        wheels-core
  Type:        mvc
  Author:      Wheels Core Team and Community
  Keywords:    mvc, rails, wheels, wheels.dev, core

Links:
  Homepage:    https://wheels.dev/
  Repository:  https://github.com/wheels-dev/wheels
  Docs:        https://wheels.dev/docs
  Issues:      https://github.com/wheels-dev/wheels/issues

Commands
--------------------------------------------------
  - Update:  wheels plugin update wheels-core
  - Search:  wheels plugin search
```

### Check plugin not installed
```bash
wheels plugins info wheels-vue-cli
```

**Output:**
```
==================================================
        Plugin Information: wheels-vue-cli
==================================================



Status
--------------------------------------------------
[WARNING]: Not installed

[FAILED]: Plugin Not Found

The plugin 'wheels-vue-cli' was not found in:
  - Local installation (box.json dependencies)
  - ForgeBox repository

[INFO]: Possible reasons
  - Plugin name may be misspelled
  - Plugin may not exist on ForgeBox
  - Network connection issues

[INFO]: Suggestions
  - Search for available plugins: wheels plugin list --available
  - Verify the correct plugin name
```

### Plugin not found anywhere
```bash
wheels plugins info nonexistent-plugin
```

**Output:**
```
==================================================
      Plugin Information: nonexistent-plugin
==================================================



Status
--------------------------------------------------
[WARNING]: Not installed

[FAILED]: Plugin Not Found

The plugin 'nonexistent-plugin' was not found in:
  - Local installation (box.json dependencies)
  - ForgeBox repository

[INFO]: Possible reasons
  - Plugin name may be misspelled
  - Plugin may not exist on ForgeBox
  - Network connection issues

[INFO]: Suggestions
  - Search for available plugins: wheels plugin list --available
  - Verify the correct plugin name
```

## How It Works

1. **Check Local Installation**: First checks if the plugin is installed in:
   - `box.json` dependencies
   - `box.json` devDependencies
   - Reads plugin's local `box.json` for detailed information

2. **Display Local Information**: If installed, shows all metadata from the plugin's `box.json`

3. **ForgeBox Fallback**: Only queries ForgeBox if the plugin is not installed locally

4. **Installation Commands**: Shows appropriate commands based on installation status

## Notes

- The command prioritizes local plugin data over ForgeBox data for accuracy
- No network call is made for installed plugins (faster response)
- Use `wheels plugin search` to browse all available plugins
- Plugin names can include variations (e.g., "wheels-core", "cfwheels-core")
