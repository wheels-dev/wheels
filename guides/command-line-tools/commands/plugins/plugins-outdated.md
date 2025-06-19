# wheels plugin outdated

List installed plugins that have newer versions available.

## Synopsis

```bash
wheels plugin outdated [--format=<format>]
```

## Description

The `wheels plugin outdated` command checks all installed plugins against ForgeBox to identify which ones have updates available. This helps maintain plugins at their latest versions for security and feature updates.

## Options

### --format
Output format for the results.
- **Default**: `table`
- **Options**: `table`, `json`

## Examples

### Check for outdated plugins
```bash
wheels plugin outdated
```

### Get results in JSON format
```bash
wheels plugin outdated --format=json
```

## Output Example

### Table Format (default)
```
📊 Checking for outdated plugins...

Checking wheels-auth... outdated
Checking wheels-api-builder... up to date
Checking wheels-cache... outdated
Checking wheels-validation... up to date

Outdated Plugins:

┌──────────────────────┬─────────┬────────┬──────┬────────────┐
│ Plugin               │ Current │ Latest │ Type │ Updated    │
├──────────────────────┼─────────┼────────┼──────┼────────────┤
│ wheels-auth         │ 2.0.0   │ 2.1.0  │ prod │ 2024-01-15 │
│ wheels-cache        │ 3.0.1   │ 3.1.0  │ prod │ 2024-01-10 │
└──────────────────────┴─────────┴────────┴──────┴────────────┘

Found 2 outdated plugins

Update Commands:

Update all plugins:
  wheels plugin update:all

Update specific plugin:
  wheels plugin update <plugin-name>

Preview updates without installing:
  wheels plugin update:all --dry-run
```

### JSON Format
```json
[
  {
    "name": "wheels-auth",
    "currentVersion": "2.0.0",
    "latestVersion": "2.1.0",
    "isDev": false,
    "updateDate": "2024-01-15T10:30:00Z",
    "author": "John Doe"
  },
  {
    "name": "wheels-cache",
    "currentVersion": "3.0.1",
    "latestVersion": "3.1.0",
    "isDev": false,
    "updateDate": "2024-01-10T14:45:00Z",
    "author": "Jane Smith"
  }
]
```

## Status Indicators

During checking:
- `checking...` - Currently checking plugin
- `outdated` - Newer version available
- `up to date` - Already at latest version
- `error` - Could not check (network issue, etc.)

## Information Shown

For each outdated plugin:
- **Plugin Name**: Name of the plugin
- **Current Version**: Currently installed version
- **Latest Version**: Newest available version
- **Type**: prod (production) or dev (development)
- **Updated**: Date of latest version release

## Update Strategies

Based on results, different update approaches:

### Single Plugin Update
```bash
wheels plugin update wheels-auth
```

### Batch Update
```bash
wheels plugin update:all
```

### Preview First
```bash
wheels plugin update:all --dry-run
```

## Version Comparison

The command performs semantic version comparison:
- **Major**: Breaking changes (1.x.x → 2.x.x)
- **Minor**: New features (x.1.x → x.2.x)
- **Patch**: Bug fixes (x.x.1 → x.x.2)

## Check Frequency

Best practices for checking:
- **Development**: Weekly or before starting new features
- **Staging**: Before deployment to production
- **Production**: Monthly or quarterly
- **CI/CD**: As part of build process

## Error Handling

### Network Issues
```
⚠️  Could not check 1 plugin:
  • wheels-payment
```

### All Up to Date
```
✅ All plugins are up to date!
```

## Integration with CI/CD

Use in automated workflows:

```bash
# Check and fail if outdated
wheels plugin outdated --format=json | jq 'length > 0' && exit 1
```

## Performance

- Checks are performed in parallel
- Results cached for 5 minutes
- Only checks plugins in box.json

## Filtering Options

Future versions will support:
```bash
# Check only production dependencies
wheels plugin outdated --production

# Check only dev dependencies
wheels plugin outdated --dev

# Check specific plugin
wheels plugin outdated wheels-auth
```

## Notes

- Requires internet connection
- Checks against ForgeBox registry
- Respects version constraints in box.json
- Does not modify any files

## See Also

- [wheels plugin update](plugins-update.md) - Update single plugin
- [wheels plugin update:all](plugins-update-all.md) - Update all plugins
- [wheels plugin list](plugins-list.md) - List installed plugins
- [wheels plugin info](plugins-info.md) - Show plugin details