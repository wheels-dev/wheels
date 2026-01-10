# wheels plugin search

Search for available Wheels plugins on ForgeBox.

## Synopsis

```bash
wheels plugin search [query] [--format=<format>] [--orderBy=<field>]
```

## CommandBox Parameter Syntax

This command supports multiple parameter formats:

- **Positional parameters**: `wheels plugin search bcrypt` (search query)
- **Named parameters**: `query=value` (e.g., `query=auth`, `format=json`)
- **Flag parameters**: `--flag=value` (e.g., `--format=json`, `--orderBy=downloads`)

**Parameter Mixing Rules:**

**ALLOWED:**
- Positional: `wheels plugin search bcrypt`
- Positional + flags: `wheels plugin search auth --format=json`
- All named: `query=bcrypt format=json orderBy=downloads`
- Named + flags: `query=auth --format=json`

**NOT ALLOWED:**
- Positional + named for same param: `wheels plugin search bcrypt query=other`

**Recommendation:** Use positional for query, flags for options: `wheels plugin search auth --format=json --orderBy=downloads`

## Parameters

| Parameter | Required | Type   | Options                    | Default     | Description                              |
|-----------|----------|--------|----------------------------|-------------|------------------------------------------|
| `query`   | No       | string | -                          | (empty)     | Search term to filter plugins            |
| `format`  | No       | string | table, json                | table       | Output format for the results            |
| `orderBy` | No       | string | name, downloads, updated   | downloads   | Sort results by specified field          |

## Description

The `plugin search` command searches ForgeBox for available `cfwheels-plugins` type packages. You can search for all plugins or filter by keywords. Results can be sorted by name, downloads, or last updated date.

### Features

- Searches only `cfwheels-plugins` type packages
- Filters results by search term
- Multiple sort options
- Color-coded, formatted output
- JSON export support
- Dynamic column widths

## Examples

### Search all plugins

```bash
wheels plugin search
```

**Output:**
```
===========================================================
  Searching ForgeBox for Wheels Plugins
===========================================================

Found 5 plugins:

Name                          Version     Downloads   Description
-------------------------------------------------------------------------------
cfwheels-bcrypt               1.0.2       4393        CFWheels 2.x plugin helper meth...
shortcodes                    0.0.4       189         Shortcodes Plugin for CFWheels
cfwheels-authenticateThis     2.0.0       523         Adds bCrypt authentication helpe...
cfwheels-jwt                  2.1.0       412         CFWheels plugin for encoding and...
cfwheels-htmx-plugin          1.0.0       678         HTMX Plugin for CFWheels

-----------------------------------------------------------

Commands:
  wheels plugin install <name>    Install a plugin
  wheels plugin info <name>       View plugin details
```

### Search for specific plugin

```bash
wheels plugin search bcrypt
```

**Output:**
```
===========================================================
  Searching ForgeBox for Wheels Plugins
===========================================================

Search term: bcrypt

Found 1 plugin:

Name                    Version     Downloads   Description
-----------------------------------------------------------------------
cfwheels-bcrypt         1.0.2       4393        CFWheels 2.x plugin helper meth...

-----------------------------------------------------------

Commands:
  wheels plugin install <name>    Install a plugin
  wheels plugin info <name>       View plugin details
```

### No results found

```bash
wheels plugin search nonexistent
```

**Output:**
```
===========================================================
  Searching ForgeBox for Wheels Plugins
===========================================================

Search term: nonexistent

No plugins found matching 'nonexistent'

Try:
  wheels plugin search <different-keyword>
  wheels plugin list --available
```

### Sort by name

```bash
wheels plugin search --orderBy=name
```

Results will be sorted alphabetically by plugin name.

### Sort by last updated

```bash
wheels plugin search --orderBy=updated
```

Results will be sorted by most recently updated plugins first.

### Export as JSON

```bash
wheels plugin search --format=json
```

**Output:**
```json
{
  "plugins": [
    {
      "name": "CFWheels bCrypt",
      "slug": "cfwheels-bcrypt",
      "version": "1.0.2",
      "description": "CFWheels 2.x plugin helper methods for the bCrypt Java Lib",
      "author": "neokoenig",
      "downloads": 4393,
      "updateDate": "2022-05-30T02:09:07+00:00"
    },
    {
      "name": "Shortcodes",
      "slug": "shortcodes",
      "version": "0.0.4",
      "description": "Shortcodes Plugin for CFWheels",
      "author": "neokoenig",
      "downloads": 189,
      "updateDate": "2017-05-16T09:03:02+00:00"
    }
  ],
  "count": 2,
  "query": ""
}
```

## How It Works

1. **Execute ForgeBox Command**: Runs `forgebox show type=cfwheels-plugins` to get all plugins
2. **Parse Output**: Scans the formatted output for lines containing `Slug: "plugin-slug"`
3. **Extract Slugs**: Uses regex to extract slug values from quoted strings
4. **Filter by Query**: If search term provided, only processes slugs containing that term
5. **Fetch Details**: For each matching slug, calls `forgebox.getEntry(slug)` to get:
   - Plugin title and description
   - Latest version (from `latestVersion.version`)
   - Author username (from `user.username`)
   - Download count (from `hits`)
   - Last updated date
6. **Sort Results**: Sorts plugins by specified order (downloads, name, or updated date)
7. **Format Output**: Displays in table or JSON format with dynamic column widths

## Sort Options

### downloads (default)
Sorts by number of downloads, most popular first. Best for finding widely-used plugins.

### name
Sorts alphabetically by plugin name. Best for browsing all available plugins.

### updated
Sorts by last update date, most recent first. Best for finding actively maintained plugins.

## Search Tips

1. **Broad Search**: Start with general terms like "auth" or "cache"
2. **Case Insensitive**: Search is case-insensitive
3. **Partial Matching**: Matches plugins containing the search term anywhere in the slug
4. **Popular First**: Default sort shows most downloaded plugins first
5. **Empty Query**: Run without query to see all available plugins

## Output Formats

### Table Format (Default)
- Color-coded columns (cyan names, green versions, yellow downloads)
- Dynamic column widths based on content
- Truncated descriptions with ellipsis
- Clear section headers and dividers
- Helpful command suggestions

### JSON Format
- Structured data for programmatic use
- Includes plugin count
- Includes search query
- Complete plugin information

## Integration with Other Commands

After finding plugins:
```bash
# View detailed information
wheels plugin info cfwheels-bcrypt

# Install directly
wheels plugin install cfwheels-bcrypt

# List installed plugins
wheels plugin list
```

## Performance Notes

- Fetches all `cfwheels-plugins` from ForgeBox
- Filters results client-side
- Queries detailed info for each matching plugin
- May take a few seconds for large result sets
- Results are not cached (always fresh)

## Error Handling

If ForgeBox cannot be reached:
```
[ERROR] Error searching for plugins
Error: Connection timeout
```

If no plugins of type `cfwheels-plugins` exist:
```
No plugins found

Try:
  wheels plugin search <different-keyword>
  wheels plugin list --available
```

## Notes

- Only searches `cfwheels-plugins` type packages
- Requires internet connection to query ForgeBox
- Search is performed against plugin slugs
- Results include version, downloads, and description
- Dynamic table formatting adjusts to content
- Some plugins may not have complete metadata
- Plugins without valid metadata are skipped

## See Also

- [wheels plugin info](plugins-info.md) - View detailed plugin information
- [wheels plugin install](plugins-install.md) - Install a plugin
- [wheels plugin list](plugins-list.md) - List installed plugins
- [wheels plugin outdated](plugins-outdated.md) - Check for plugin updates
