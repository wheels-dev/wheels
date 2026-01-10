# wheels plugin update:all

Update all installed Wheels plugins to their latest versions from ForgeBox.

## Usage

```bash
wheels plugin update:all [--dryRun]
```

## Parameters

| Parameter | Required | Type    | Description                                        |
|-----------|----------|---------|----------------------------------------------------|
| `dryRun` | No       | boolean | Preview updates without actually installing them   |

## Description

The `plugin update:all` command checks all installed plugins in the `/plugins` folder against ForgeBox and updates any outdated plugins to their latest versions. It provides a clear summary of what will be updated and handles each plugin update sequentially.

### Features

- Checks all plugins for updates in one command
- Color-coded status indicators for each plugin
- Detailed update summary
- dryRun mode to preview changes
- Individual plugin update tracking
- Helpful error reporting

## Examples

### Update all plugins

```bash
wheels plugin update:all
```

**Output (with updates available):**
```
===========================================================
  Checking for Plugin Updates
===========================================================

  bcrypt                                  [OUTDATED] 0.0.3 -> 0.0.4
  shortcodes                              [OUTDATED] 0.0.3 -> 0.0.4
  wheels-test                             [OK] v1.0.0

===========================================================

Found 2 outdated plugins

Updating Plugins:

Plugin                Current         Latest          Status
---------------------------------------------------------------
bcrypt                0.0.3           0.0.4           [UPDATE]
shortcodes            0.0.3           0.0.4           [UPDATE]

-----------------------------------------------------------

Updating bcrypt from 0.0.3 to 0.0.4...
[CommandBox installation output...]
[OK] bcrypt updated successfully

Updating shortcodes from 0.0.3 to 0.0.4...
[CommandBox installation output...]
[OK] shortcodes updated successfully

===========================================================
  Update Summary
===========================================================

[OK] 2 plugins updated successfully

Updated plugins:
  - bcrypt (0.0.3 -> 0.0.4)
  - shortcodes (0.0.3 -> 0.0.4)

Commands:
  wheels plugin list              View all installed plugins
  wheels plugin outdated          Check for more updates
```

### All plugins up to date

```bash
wheels plugin update:all
```

**Output:**
```
===========================================================
  Checking for Plugin Updates
===========================================================

  bcrypt                                  [OK] v0.0.4
  shortcodes                              [OK] v0.0.4
  wheels-test                             [OK] v1.0.0

===========================================================

[OK] All plugins are already up to date!

No updates required.

Commands:
  wheels plugin list              View all installed plugins
  wheels plugin outdated          Check for updates
```

### dryRun mode (preview only)

```bash
wheels plugin update:all --dryRun
```

**Output:**
```
===========================================================
  Checking for Plugin Updates (DRY RUN)
===========================================================

  bcrypt                                  [OUTDATED] 0.0.3 -> 0.0.4
  shortcodes                              [OUTDATED] 0.0.3 -> 0.0.4
  wheels-test                             [OK] v1.0.0

===========================================================

Found 2 outdated plugins

Would Update:

Plugin                Current         Latest
---------------------------------------------------------------
bcrypt                0.0.3           0.0.4
shortcodes            0.0.3           0.0.4

-----------------------------------------------------------

[DRY RUN] No updates performed

To perform these updates:
  wheels plugin update:all
```

### With some failures

```bash
wheels plugin update:all
```

**Output:**
```
===========================================================
  Checking for Plugin Updates
===========================================================

  bcrypt                                  [OUTDATED] 0.0.3 -> 0.0.4
  problematic-plugin                      [ERROR] Could not check version
  shortcodes                              [OK] v0.0.4

===========================================================

Found 1 outdated plugin

Updating Plugins:

Plugin                Current         Latest          Status
---------------------------------------------------------------
bcrypt                0.0.3           0.0.4           [UPDATE]

-----------------------------------------------------------

Updating bcrypt from 0.0.3 to 0.0.4...
[CommandBox installation output...]
[OK] bcrypt updated successfully

===========================================================
  Update Summary
===========================================================

[OK] 1 plugin updated successfully

Updated plugins:
  - bcrypt (0.0.3 -> 0.0.4)

Could not check 1 plugin:
  - problematic-plugin

Commands:
  wheels plugin list              View all installed plugins
  wheels plugin outdated          Check for more updates
```

### No plugins installed

```bash
wheels plugin update:all
```

**Output:**
```
===========================================================
  Checking for Plugin Updates
===========================================================

No plugins installed in /plugins folder
Install plugins with: wheels plugin install <plugin-name>
```

## Update Process

1. **Display Header**: Shows command is checking for updates
2. **Plugin Discovery**: Scans `/plugins` folder for installed plugins
3. **Version Checking**: Queries ForgeBox for each plugin's latest version
4. **Status Display**: Shows color-coded status for each plugin
5. **Update List**: Displays table of plugins that need updating
6. **Sequential Updates**: Updates each plugin one at a time
7. **Progress Tracking**: Shows success/failure for each update
8. **Summary Report**: Displays final update statistics
9. **Helpful Commands**: Suggests next steps

## Status Indicators

During checking, each plugin displays:
- **[OUTDATED]** (yellow) - Update available, will be updated
- **[OK]** (green) - Already at latest version
- **[ERROR]** (red) - Could not check version

During updates:
- **[UPDATE]** (yellow) - Plugin will be updated
- **[OK]** (green) - Update completed successfully
- **[ERROR]** (red) - Update failed

## dryRun Mode

Use `--dryRun` to preview updates without actually performing them. This is useful for:
- Checking what would be updated before committing
- Testing in CI/CD pipelines
- Reviewing changes before production updates
- Planning maintenance windows

```bash
wheels plugin update:all --dryRun
```

The dryRun mode:
- Checks all plugins for updates
- Shows what would be updated
- Does NOT download or install anything
- Provides command to perform actual updates

## Update Strategy

The command updates plugins sequentially:
1. One plugin at a time (safer than parallel)
2. Continues updating even if one fails
3. Tracks success/failure for each plugin
4. Provides detailed summary at the end

## Error Handling

### Version Check Failures
Plugins where version cannot be checked are listed separately and skipped for updates.

### Update Failures
If a plugin update fails:
- The failure is tracked
- Other updates continue
- Error is reported in summary
- Plugin can be updated individually later

### Network Issues
If ForgeBox cannot be reached:
```
===========================================================
  Checking for Plugin Updates
===========================================================

  bcrypt                                  [ERROR] Could not check version
  shortcodes                              [ERROR] Could not check version

===========================================================

[ERROR] Unable to check for updates

Could not check 2 plugins due to network issues.
Please check your internet connection and try again.
```

## Best Practices

1. **Regular Updates**: Run weekly or monthly to stay current
2. **Test First**: Always test updates in development before production
3. **Use dryRun**: Preview updates with `--dryRun` before applying
4. **Read Release Notes**: Check ForgeBox for breaking changes
5. **Commit First**: Commit your code before updating plugins
6. **Update Individually**: For critical plugins, use `wheels plugin update <name>`

## Integration with Other Commands

### Check Before Updating
```bash
# See which plugins are outdated
wheels plugin outdated

# Update all outdated plugins
wheels plugin update:all
```

### Update Individual Plugins
```bash
# Update all plugins except one
wheels plugin update:all --dryRun  # See what would update
wheels plugin update plugin1        # Update individually
wheels plugin update plugin2
```

## Notes

- Only updates plugins from `/plugins` folder
- Only works with `cfwheels-plugins` type packages
- Updates are performed sequentially (not in parallel)
- Each update is independent - failures don't affect other updates
- Requires internet connection to query ForgeBox and download updates
- Version checks are performed in real-time (not cached)
- Progress is shown for each plugin update
- After updates, plugins may require application reload
- Failed updates can be retried individually with `wheels plugin update <name>`
- The command does NOT update plugins that are already at latest version

## See Also

- [wheels plugin update](plugins-update.md) - Update a single plugin
- [wheels plugin outdated](plugins-outdated.md) - Check for outdated plugins
- [wheels plugin list](plugins-list.md) - List installed plugins
- [wheels plugin info](plugins-info.md) - View plugin details
