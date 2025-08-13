# wheels plugin search (coming Soon)
*This command may not work as expected. A complete and stable version is **coming soon**.*

Search for Wheels plugins on ForgeBox.

## Synopsis

```bash
wheels plugin search [query] [--format=<format>] [--orderBy=<field>]
```

## Description

The `wheels plugin search` command searches ForgeBox for available Wheels plugins. You can search for all plugins or filter by keywords. Results can be sorted by various criteria and output in different formats.

## Arguments

### query (optional)
Search term to filter plugins. If omitted, all available plugins are shown.

## Options

### --format
Output format for the results.

- **Default**: `table`
- **Options**: `table`, `json`

### --orderBy
Sort results by specified field.

- **Default**: `downloads`
- **Options**: `name`, `downloads`, `updated`

## Examples

### Search all plugins
```bash
wheels plugin search
```

### Search for authentication plugins
```bash
wheels plugin search auth
```

### Search with specific sorting
```bash
wheels plugin search --orderBy=updated
```

### Get results in JSON format
```bash
wheels plugin search auth --format=json
```

### Search for API-related plugins
```bash
wheels plugin search "api builder"
```

## Output

### Table Format (default)
```
🔍 Searching ForgeBox for Wheels plugins...

┌─────────────────────────┬─────────┬───────────┬────────────┬─────────────────────────────────────────────────┐
│ Name                    │ Version │ Downloads │ Updated    │ Description                                     │
├─────────────────────────┼─────────┼───────────┼────────────┼─────────────────────────────────────────────────┤
│ wheels-auth            │ 2.1.0   │ 15,432    │ 2024-01-15 │ Complete authentication and authorization sys... │
│ wheels-api-builder     │ 1.5.0   │ 8,921     │ 2024-01-10 │ RESTful API scaffolding and documentation       │
│ wheels-cache-manager   │ 3.0.2   │ 6,543     │ 2024-01-08 │ Advanced caching strategies for Wheels apps     │
└─────────────────────────┴─────────┴───────────┴────────────┴─────────────────────────────────────────────────┘

Found 3 plugins

To install a plugin, use:
  wheels plugin install <plugin-name>
```

### JSON Format
```json
[
  {
    "slug": "wheels-auth",
    "name": "Wheels Authentication",
    "version": "2.1.0",
    "downloads": 15432,
    "updateDate": "2024-01-15T10:30:00Z",
    "summary": "Complete authentication and authorization system",
    "author": {
      "name": "John Doe"
    }
  }
]
```

## Search Tips

1. **Broad Search**: Start with general terms like "auth" or "api"
2. **Exact Phrases**: Use quotes for exact phrase matching
3. **Popular First**: Default sort by downloads shows most popular plugins
4. **Recent Updates**: Use `--orderBy=updated` to find actively maintained plugins

## Plugin Types

The search includes various plugin types:
- **Authentication & Security**
- **API & Web Services**
- **Database & ORM Extensions**
- **Testing & Development Tools**
- **UI Components & Themes**
- **Performance & Caching**
- **File Handling & Media**

## Integration with Other Commands

After finding plugins:
1. Get detailed info: `wheels plugin info <plugin-name>`
2. Install directly: `wheels plugin install <plugin-name>`
3. Check compatibility: `wheels plugin info <plugin-name>`

## Notes

- Search results are cached for 15 minutes
- Results limited to 50 plugins per search
- Only shows plugins compatible with cfwheels
- ForgeBox availability required

## See Also

- [wheels plugin info](plugins-info.md) - Show plugin details
- [wheels plugin install](plugins-install.md) - Install plugins
- [wheels plugin list](plugins-list.md) - List installed plugins