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
==================================================
      Searching ForgeBox for Wheels Plugins
==================================================


Searching, please wait...



Found 25 plugin(s)
--------------------------------------------------

╔═══════════════════════════════════════╤══════════════════════════════════════╤═════════╤═══════════╤════════════════════════════════════════════════════╗
║ Name                                  │ Slug                                 │ Version │ Downloads │ Description                                        ║
╠═══════════════════════════════════════╪══════════════════════════════════════╪═════════╪═══════════╪════════════════════════════════════════════════════╣
║ CFWheels Models Default Scope         │ defaultScope                         │ 0.0.20  │ 4,804     │ CFWheels 2.1+ Add default scope to models for F... ║
╟───────────────────────────────────────┼──────────────────────────────────────┼─────────┼───────────┼────────────────────────────────────────────────────╢
║ CFWheels bCrypt                       │ cfwheels-bcrypt                      │ 1.0.2   │ 4,788     │ CFWheels 2.x plugin helper methods for the bCry... ║
╟───────────────────────────────────────┼──────────────────────────────────────┼─────────┼───────────┼────────────────────────────────────────────────────╢
║ CFWheels FlashMessages Bootstrap      │ cfwheels-flashmessages-bootstrap     │ 1.0.4   │ 3,965     │ CFWheels 2.0 plugin to add Bootstrap tags to fl... ║
╟───────────────────────────────────────┼──────────────────────────────────────┼─────────┼───────────┼────────────────────────────────────────────────────╢
║ CFWheels JS Confirm                   │ cfwheels-js-confirm                  │ 1.0.5   │ 3,916     │ JS Confirm - CFWheels Plugin                       ║
╟───────────────────────────────────────┼──────────────────────────────────────┼─────────┼───────────┼────────────────────────────────────────────────────╢
║ Datepicker                            │ datepicker                           │ 2.0.6   │ 3,906     │ Datepicker Plugin for CFWheels                     ║
╟───────────────────────────────────────┼──────────────────────────────────────┼─────────┼───────────┼────────────────────────────────────────────────────╢
║ CFWheels Example Plugin               │ cfwheels-plugin-example              │ 0.0.4   │ 3,804     │ CFWheels Example Plugin                            ║
╟───────────────────────────────────────┼──────────────────────────────────────┼─────────┼───────────┼────────────────────────────────────────────────────╢
║ Shortcodes                            │ shortcodes                           │ 0.0.4   │ 3,700     │ Shortcodes Plugin for CFWheels                     ║
╟───────────────────────────────────────┼──────────────────────────────────────┼─────────┼───────────┼────────────────────────────────────────────────────╢
║ Bens Json Serializer For Wheels       │ cfwheels-bens-json-serializer        │ 0.1.7   │ 3,683     │ Swaps renderWith()'s use of serializeJson() wit... ║
╟───────────────────────────────────────┼──────────────────────────────────────┼─────────┼───────────┼────────────────────────────────────────────────────╢
║ UnitTest Fixtures                     │ fixtures                             │ 0.0.9   │ 3,628     │ Use JSON files to lazily initialize (Create and... ║
╟───────────────────────────────────────┼──────────────────────────────────────┼─────────┼───────────┼────────────────────────────────────────────────────╢
║ CFWheels JWT                          │ cfwheels-jwt                         │ 1.0.2   │ 3,535     │ CFWheels plugin for encoding and decoding JSON ... ║
╟───────────────────────────────────────┼──────────────────────────────────────┼─────────┼───────────┼────────────────────────────────────────────────────╢
║ UpgradeAdvisor                        │ upgradeadvisor                       │ 0.8.1   │ 3,515     │ CFWheels 2.x Upgrade Advisor                       ║
╟───────────────────────────────────────┼──────────────────────────────────────┼─────────┼───────────┼────────────────────────────────────────────────────╢
║ CFWheels iCal4j                       │ cfwheels-ical4j                      │ 2.0.0   │ 3,475     │ CFWheels 2.x Plugin Date Repeats Methods via iC... ║
╟───────────────────────────────────────┼──────────────────────────────────────┼─────────┼───────────┼────────────────────────────────────────────────────╢
║ CFWheels HTMX Plugin                  │ cfwheels-htmx-plugin                 │ 1.0.4   │ 3,465     │ HTMX Plugin for CFWheels                           ║
╟───────────────────────────────────────┼──────────────────────────────────────┼─────────┼───────────┼────────────────────────────────────────────────────╢
║ CFWheels JS Disable                   │ cfwheels-js-disable                  │ 1.1     │ 3,231     │ JS Disable - CFWheels Plugin                       ║
╟───────────────────────────────────────┼──────────────────────────────────────┼─────────┼───────────┼────────────────────────────────────────────────────╢
║ Authenticate This!                    │ cfwheels-authenticateThis            │ 1.0.1   │ 3,114     │ CFWheels 2.x Adds bCrypt authentication helper ... ║
╟───────────────────────────────────────┼──────────────────────────────────────┼─────────┼───────────┼────────────────────────────────────────────────────╢
║ CFWheels LinkToDefaultTitle           │ link-to-default-title                │ 0.0.9   │ 3,107     │ This helper plugin will automatically display t... ║
╟───────────────────────────────────────┼──────────────────────────────────────┼─────────┼───────────┼────────────────────────────────────────────────────╢
║ CFWheels File Bin                     │ cfwheels-filebin                     │ 0.1.0   │ 3,105     │ CFWheels File Bin                                  ║
╟───────────────────────────────────────┼──────────────────────────────────────┼─────────┼───────────┼────────────────────────────────────────────────────╢
║ cfwheels ckEditor plugin              │ cfwheels-ckeditor-plugin             │ 1.0.1   │ 3,087     │ Over-ride the textArea() function                  ║
╟───────────────────────────────────────┼──────────────────────────────────────┼─────────┼───────────┼────────────────────────────────────────────────────╢
║ CFWheels Model Nesting                │ cfwheels-model-nesting               │ 0.0.5   │ 3,072     │ Model Nesting - fixes cfquery dot notation         ║
╟───────────────────────────────────────┼──────────────────────────────────────┼─────────┼───────────┼────────────────────────────────────────────────────╢
║ CFWheels SAML                         │ cfwheels-saml                        │ 1.0.0   │ 3,026     │ CFWheels plugin for SAML Single Sign-On            ║
╟───────────────────────────────────────┼──────────────────────────────────────┼─────────┼───────────┼────────────────────────────────────────────────────╢
║ CFWheels Disable Form Default IDs     │ cfwheels-disable-form-default-id     │ 0.0.2   │ 2,960     │ Disable IDs from being added to form inputs        ║
╟───────────────────────────────────────┼──────────────────────────────────────┼─────────┼───────────┼────────────────────────────────────────────────────╢
║ TitleTag Plugin                       │ cfwheels-titletag-plugin             │ 1.0.2   │ 2,934     │ DRY up your title tags. Allows you to define ea... ║
╟───────────────────────────────────────┼──────────────────────────────────────┼─────────┼───────────┼────────────────────────────────────────────────────╢
║ CFWheels DotEnvSettings Plugin        │ cfwheels-dotenvsettings              │ 1.0.0   │ 2,734     │ DotEnvSettings Plugin for CFWheels                 ║
╟───────────────────────────────────────┼──────────────────────────────────────┼─────────┼───────────┼────────────────────────────────────────────────────╢
║ cfwheels Bootstrap Multiselect plugin │ cfwheels-bootstrapmultiselect-plugin │ 1.0     │ 2,596     │ Creates a new function to allow for a multisele... ║
╟───────────────────────────────────────┼──────────────────────────────────────┼─────────┼───────────┼────────────────────────────────────────────────────╢
║ wheels I18n                           │ Wheels-i18n                          │ 1.0.0   │ 173       │ Internationalization (i18n) plugin for Wheels      ║
╚═══════════════════════════════════════╧══════════════════════════════════════╧═════════╧═══════════╧════════════════════════════════════════════════════╝

--------------------------------------------------

Total plugins found:      25
Sort order:               downloads
Most popular:             CFWheels Models Default Scope (4,804 downloads)


Commands
--------------------------------------------------
  - Install: wheels plugin install <name>
  - Details: wheels plugin info <name>
  - List installed: wheels plugin list

[INFO]: Tip
  Add --format=json for JSON output
  Sort with --orderBy=name,downloads,updated```

### Search for specific plugin

```bash
wheels plugin search bcrypt
```

**Output:**
```
==================================================
      Searching ForgeBox for Wheels Plugins
==================================================


Search term:              bcrypt

Searching, please wait...



Found 1 plugin(s)
--------------------------------------------------

╔═════════════════╤═════════════════╤═════════╤═══════════╤════════════════════════════════════════════════════╗
║ Name            │ Slug            │ Version │ Downloads │ Description                                        ║
╠═════════════════╪═════════════════╪═════════╪═══════════╪════════════════════════════════════════════════════╣
║ CFWheels bCrypt │ cfwheels-bcrypt │ 1.0.2   │ 4,788     │ CFWheels 2.x plugin helper methods for the bCry... ║
╚═════════════════╧═════════════════╧═════════╧═══════════╧════════════════════════════════════════════════════╝

--------------------------------------------------

Total plugins found:      1
Sort order:               downloads
Most popular:             CFWheels bCrypt (4,788 downloads)


Commands
--------------------------------------------------
  - Install: wheels plugin install <name>
  - Details: wheels plugin info <name>
  - List installed: wheels plugin list

[INFO]: Tip
  Add --format=json for JSON output
  Sort with --orderBy=name,downloads,updated
```

### No results found

```bash
wheels plugin search nonexistent
```

**Output:**
```
==================================================
      Searching ForgeBox for Wheels Plugins
==================================================


Search term:              nonexistent

Searching, please wait...


[WARNING]: No plugins found matching 'nonexistent'


Try
--------------------------------------------------
  - wheels plugin search <different-keyword>
  - wheels plugin list --available
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
