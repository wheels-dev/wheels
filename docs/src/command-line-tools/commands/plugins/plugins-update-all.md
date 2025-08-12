# wheels plugin update:all (coming Soon)
*This command may not work as expected. A complete and stable version is **coming soon**.*

Update all installed Wheels plugins to their latest versions.

## Synopsis

```bash
wheels plugin update:all [--dry-run] [--force]
```

## Description

The `wheels plugin update:all` command checks all installed plugins for available updates and updates them to their latest versions. It handles dependencies automatically and can preview changes before applying them.

## Options

### --dry-run
Show what would be updated without actually updating.
- **Default**: false

### --force
Force update even if already at latest version.
- **Default**: false

## Examples

### Update all plugins
```bash
wheels plugin update:all
```

### Preview updates
```bash
wheels plugin update:all --dry-run
```

### Force update all
```bash
wheels plugin update:all --force
```

## Output Example

### Checking Phase
```
🔄 Checking for plugin updates...

Checking wheels-auth... update available (2.0.0 → 2.1.0)
Checking wheels-api-builder... up to date (1.5.0)
Checking wheels-cache... update available (3.0.1 → 3.1.0)
Checking wheels-validation... up to date (2.2.0)

Updates available:

  📦 wheels-auth: 2.0.0 → 2.1.0
  📦 wheels-cache: 3.0.1 → 3.1.0

Update 2 plugins? (y/N):
```

### Update Phase
```
Updating wheels-auth...
  ✅ Updated successfully!

Updating wheels-cache...
  ✅ Updated successfully!

Update Summary:

✅ 2 plugins updated successfully
❌ 0 plugins failed to update
⚠️  0 plugins could not be checked

To see all installed plugins:
  wheels plugin list
```

## Dry Run Mode

Preview changes without updating:

```bash
wheels plugin update:all --dry-run
```

Output:
```
Updates available:

  📦 wheels-auth: 2.0.0 → 2.1.0
  📦 wheels-cache: 3.0.1 → 3.1.0

Dry run mode - no updates will be performed
Remove --dry-run to actually update plugins
```

## Update Process

1. **Discovery**: Finds all installed plugins
2. **Version Check**: Queries ForgeBox for latest versions
3. **Comparison**: Identifies outdated plugins
4. **Confirmation**: Asks for user confirmation (unless --force)
5. **Sequential Updates**: Updates each plugin in dependency order
6. **Summary**: Reports success/failure for each plugin

## Dependency Resolution

The command handles dependencies intelligently:
- Updates dependencies before dependent plugins
- Resolves version conflicts automatically
- Warns about breaking changes

## Batch Operations

### Selective Updates
While update:all updates everything, you can:
```bash
# Update only production dependencies
wheels plugin update:all --production

# Update only dev dependencies
wheels plugin update:all --dev
```

## Error Handling

### Partial Failures
If some plugins fail to update:
```
Update Summary:

✅ 3 plugins updated successfully
❌ 1 plugin failed to update
⚠️  1 plugin could not be checked

Failed updates:
- wheels-payment: Network timeout

To retry failed updates individually:
  wheels plugin update wheels-payment
```

### Rollback on Failure
Each plugin update is isolated - failures don't affect other updates.

## Progress Indicators

For many plugins, shows progress:
```
🔄 Checking for plugin updates... [5/10]
```

## Conflict Resolution

When conflicts arise:
```
Dependency conflict detected:
  wheels-auth 2.1.0 requires wheels-validation >=3.0.0
  Current: wheels-validation 2.2.0

Options:
1. Update wheels-validation first
2. Skip wheels-auth update
3. Force update (may cause issues)

Choose option (1-3):
```

## Best Practices

1. **Regular Updates**: Run weekly in development
2. **Test First**: Always test in development environment
3. **Dry Run**: Use --dry-run before production updates
4. **Incremental**: Update frequently to avoid large jumps
5. **Backup**: Backup before bulk updates

## Performance

- Checks are performed in parallel for speed
- Updates are sequential for safety
- Results are cached for 5 minutes

## Common Workflows

### Development Routine
```bash
# Monday morning routine
wheels plugin outdated
wheels plugin update:all --dry-run
wheels plugin update:all
wheels test app
```

### Production Updates
```bash
# Production update process
wheels plugin update:all --dry-run > updates.log
# Review updates.log
wheels plugin update:all
wheels reload
```

## Notes

- Requires internet connection
- Updates modify box.json
- Some plugins may require restart
- Updates are logged for troubleshooting

## See Also

- [wheels plugin update](plugins-update.md) - Update single plugin
- [wheels plugin outdated](plugins-outdated.md) - Check for updates
- [wheels plugin list](plugins-list.md) - List installed plugins
- [wheels plugin info](plugins-info.md) - Show plugin details