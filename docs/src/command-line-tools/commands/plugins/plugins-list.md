# wheels plugins list

Lists installed Wheels plugins from the `/plugins` folder or shows available plugins from ForgeBox.

## Usage

```bash
wheels plugins list [--format=<format>] [--available]
```

## Parameters

| Parameter     | Required | Type    | Options      | Default | Description                                |
|---------------|----------|---------|--------------|---------|-------------------------------------------|
| `format`      | No       | string  | table, json  | table   | Output format for the plugin list         |
| `available`   | No       | boolean | true, false  | false   | Show available plugins from ForgeBox      |

## Description

The `plugins list` command displays information about Wheels plugins. By default, it shows plugins installed locally in the `/plugins` folder. With the `--available` flag, it queries ForgeBox to show all available `cfwheels-plugins` packages.

### Local Plugin Information

When listing installed plugins, the command displays:
- Plugin name
- Version number
- Description (if available)

### Available Plugin Information

When using `--available`, the command shows all `cfwheels-plugins` type packages from ForgeBox.

## Examples

### List installed plugins

```bash
wheels plugins list
```

**Output:**
```
==================================================
           Installed Wheels Plugins (3)
==================================================


╔══════════════════╤═════════╤════════════════════════════════════════════════════╗
║ Plugin Name      │ Version │ Description                                        ║
╠══════════════════╪═════════╪════════════════════════════════════════════════════╣
║ wheels-api-tools │ 1.0.0   │                                                    ║
╟──────────────────┼─────────┼────────────────────────────────────────────────────╢
║ CFWheels bCrypt  │ 1.0.2   │ CFWheels 2.x plugin helper methods for the bCrypt  ║
╟──────────────────┼─────────┼────────────────────────────────────────────────────╢
║ wheels-my-helper │ 1.0.0   │                                                    ║
╚══════════════════╧═════════╧════════════════════════════════════════════════════╝

------------------------------------------------------------

Total plugins:            3
Latest plugin:            wheels-api-tools (1.0.0)


Commands
--------------------------------------------------
  - wheels plugin info <name>      View plugin details
  - wheels plugin update:all       Update all plugins
  - wheels plugin outdated         Check for updates
  - wheels plugin install <name>   Install new plugin
  - wheels plugin remove <name>    Remove a plugin

[INFO]: Tip
  Add --format=json for JSON output
```

### List with no plugins installed

```bash
wheels plugins list
```

**Output:**
```
===========================================================
  Installed Wheels Plugins
===========================================================

No plugins installed in /plugins folder

Install plugins with:
  wheels plugin install <plugin-name>

See available plugins:
  wheels plugin list --available
```

### Export as JSON

```bash
wheels plugins list --format=json
```

**Output:**
```json
{
  "plugins": [
    {
      "name": "bcrypt",
      "slug": "cfwheels-bcrypt",
      "version": "0.0.4",
      "description": "Bcrypt encryption for Wheels"
    },
    {
      "name": "shortcodes",
      "slug": "cfwheels-shortcodes",
      "version": "0.0.4",
      "description": "Shortcode support"
    }
  ],
  "count": 2
}
```

### Show available plugins from ForgeBox

```bash
wheels plugins list --available
```

**Output:**
```
===========================================================
  Available Wheels Plugins on ForgeBox
===========================================================

Contacting ForgeBox, please wait...

[Lists all cfwheels-plugins type packages from ForgeBox using 'forgebox show']
```

## How It Works

1. **Local Plugin Detection**: Scans the `/plugins` folder for subdirectories
2. **Metadata Extraction**: Reads each plugin's `box.json` file for name, version, slug, and description
3. **Dynamic Formatting**: Calculates column widths based on content for clean alignment
4. **ForgeBox Integration**: Uses `forgebox show type=cfwheels-plugins` for available plugins

## Notes

- Only lists plugins from the `/plugins` folder (not box.json dependencies)
- Only works with `cfwheels-plugins` type packages
- Plugins without a valid `box.json` are ignored
- Column widths adjust dynamically for optimal display
- JSON output includes plugin count for programmatic use
- Use `wheels plugin info <name>` to see detailed information about a specific plugin