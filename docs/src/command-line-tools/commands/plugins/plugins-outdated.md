# wheels plugin outdated

Check for outdated Wheels plugins that have newer versions available on ForgeBox.

## Usage

```bash
wheels plugin outdated [--format=<format>]
```

## Parameters

| Parameter | Required | Type   | Options      | Default | Description                           |
|-----------|----------|--------|--------------|---------|---------------------------------------|
| `format`  | No       | string | table, json  | table   | Output format for outdated plugin list|

## Description

The `plugins outdated` command checks all installed plugins in the `/plugins` folder against ForgeBox to identify which ones have updates available. It performs real-time version checks and displays the results in a clear, formatted output.

### Features

- Checks only `cfwheels-plugins` type packages
- Real-time version checking via ForgeBox
- Color-coded status indicators
- Detailed version comparison
- Helpful update commands

## Examples

### Check for outdated plugins

```bash
wheels plugin outdated
```

**Output (with outdated plugins):**
```
===========================================================
  Checking for Plugin Updates
===========================================================

  bcrypt                                  [OUTDATED] 0.0.3 -> 0.0.4
  shortcodes                              [OK] v0.0.4
  wheels-test                             [OK] v1.0.0

===========================================================

Found 1 outdated plugin:

Plugin              Current     Latest
-----------------------------------------------
bcrypt              0.0.3       0.0.4

-----------------------------------------------------------

Commands:

  wheels plugin update bcrypt
```

**Output (all up to date):**
```
===========================================================
  Checking for Plugin Updates
===========================================================

  bcrypt                                  [OK] v0.0.4
  shortcodes                              [OK] v0.0.4
  wheels-test                             [OK] v1.0.0

===========================================================

[OK] All plugins are up to date!
```

**Output (with errors):**
```
===========================================================
  Checking for Plugin Updates
===========================================================

  bcrypt                                  [OK] v0.0.4
  problematic-plugin                      [ERROR] Could not check version
  shortcodes                              [OK] v0.0.4

===========================================================

[OK] All plugins are up to date!

Could not check 1 plugin:

  - problematic-plugin
```

### Multiple outdated plugins

```bash
wheels plugin outdated
```

**Output:**
```
===========================================================
  Checking for Plugin Updates
===========================================================

  bcrypt                                  [OUTDATED] 0.0.3 -> 0.0.4
  shortcodes                              [OUTDATED] 0.0.3 -> 0.0.4
  wheels-test                             [OK] v1.0.0

===========================================================

Found 2 outdated plugins:

Plugin              Current     Latest
-----------------------------------------------
bcrypt              0.0.3       0.0.4
shortcodes          0.0.3       0.0.4

-----------------------------------------------------------

Commands:

Update all outdated plugins:
  wheels plugin update:all

Update specific plugin:
  wheels plugin update <plugin-name>
```

### Export as JSON

```bash
wheels plugin outdated --format=json
```

**Output:**
```json
{
  "outdated": [
    {
      "name": "bcrypt",
      "slug": "cfwheels-bcrypt",
      "currentVersion": "0.0.3",
      "latestVersion": "0.0.4"
    },
    {
      "name": "shortcodes",
      "slug": "cfwheels-shortcodes",
      "currentVersion": "0.0.3",
      "latestVersion": "0.0.4"
    }
  ],
  "count": 2,
  "errors": []
}
```

## Status Indicators

During checking, each plugin displays:
- **[OUTDATED]** (yellow) - Newer version available
- **[OK]** (green) - Already at latest version
- **[ERROR]** (red) - Could not check version (network issue, plugin not on ForgeBox, etc.)

## How It Works

1. **Plugin Discovery**: Scans `/plugins` folder for installed plugins
2. **Version Query**: Uses `forgebox show` command for each plugin to get latest version
3. **Version Comparison**: Cleans and compares version strings (strips non-numeric characters)
4. **Display Results**: Shows outdated plugins with current and latest versions
5. **Update Suggestions**: Provides appropriate update commands

## Version Comparison

The command performs string-based version comparison after cleaning:
- Removes non-numeric characters except dots (e.g., "v0.0.4" becomes "0.0.4")
- Compares cleaned versions for equality
- Marks as outdated if versions differ

## Update Strategies

### Update Single Plugin
```bash
wheels plugin update bcrypt
```

### Update All Outdated Plugins
```bash
wheels plugin update:all
```

## Error Handling

### Network Issues
If ForgeBox cannot be reached, the plugin is marked with `[ERROR]` and listed separately.

### No Plugins Installed
```
===========================================================
  Checking for Plugin Updates
===========================================================

No plugins installed in /plugins folder
Install plugins with: wheels plugin install <plugin-name>
```

## Notes

- Only checks plugins from `/plugins` folder (not box.json dependencies)
- Only works with `cfwheels-plugins` type packages
- Requires internet connection to query ForgeBox
- Version check is performed in real-time (not cached)
- Plugins are checked sequentially with status updates
- Use `wheels plugin update:all` to update all outdated plugins at once
- Dynamic table formatting adjusts column widths based on content

## See Also

- [wheels plugin update](plugins-update.md) - Update a single plugin
- [wheels plugin update:all](plugins-update-all.md) - Update all plugins
- [wheels plugin list](plugins-list.md) - List installed plugins
- [wheels plugin info](plugins-info.md) - Show plugin details
