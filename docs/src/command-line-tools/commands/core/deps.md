# wheels deps

Manage application dependencies using box.json.

## Synopsis

```bash
wheels deps <action> [name] [options]
```

## Description

The `wheels deps` command provides a streamlined interface for managing your Wheels application's dependencies through box.json. It integrates with CommandBox's package management system while providing Wheels-specific conveniences.

## Arguments

| Argument | Description | Default |
|----------|-------------|---------|
| `action` | **Required** - Action to perform: `list`, `install`, `update`, `remove`, `report` | None |
| `name` | Package name (required for install/update/remove actions) | None |
| `version` | Specific version to install (optional, for install action only) | Latest version |

## Options

| Option | Description | Default |
|--------|-------------|---------|
| `--dev` | Install as development dependency (install action only) | false |

## Actions

### List
Display all dependencies from box.json with their installation status.

```bash
wheels deps list
```

Output shows:
- Package name
- Version specification
- Type (Production/Development)
- Installation status

Example output:
```
Dependencies:
  cbvalidation @ ^4.6.0+28 (Production) - Not Installed
  wirebox @ ^7.4.2+24 (Production) - Not Installed
  shortcodes @ ^0.0.4 (Production) - Not Installed

Dev Dependencies:
  testbox @ ^6.4.0+17 (Development) - Installed
```

### Install
Install a new dependency and add it to box.json.

```bash
wheels deps install <name>
wheels deps install <name> <version>
wheels deps install <name> --dev
```

Examples:
```bash
# Install latest version as production dependency
wheels deps install cbvalidation

# Install specific version
wheels deps install cbvalidation 3.0.0

# Install as development dependency (saves to devDependencies)
wheels deps install testbox --dev
```

**Important**: The `--dev` flag uses CommandBox's `--saveDev` flag internally, ensuring packages are correctly saved to the `devDependencies` section of box.json.

### Update
Update an existing dependency to the latest version allowed by its version specification.

```bash
wheels deps update <name>
```

Example:
```bash
wheels deps update wirebox
```

The command will:
- Check if the dependency exists in box.json
- Determine if it's a production or dev dependency
- Update to the latest compatible version
- Show version change information

### Remove
Remove a dependency from both box.json and the file system.

```bash
wheels deps remove <name>
```

Example:
```bash
wheels deps remove oldpackage
```

**Note**: Remove action will ask for confirmation before proceeding.

### Report
Generate a comprehensive dependency report with outdated package check.

```bash
wheels deps report
```

The report includes:
- Project information (name, version)
- Wheels version
- CFML engine details
- All dependencies with installation status
- Development dependencies
- Installed modules information
- Outdated package check
- Export to JSON file

Example output:
```
Dependency Report:

Generated: 2025-09-19 11:38:44
Wheels Version: 3.0.0-SNAPSHOT
CFML Engine: Lucee 5.4.6.9

Dependencies:
  cbvalidation @ ^4.6.0+28 - Installed: No
  shortcodes @ ^0.0.4 - Installed: No
  wirebox @ ^7.4.2+24 - Installed: No

Dev Dependencies:
  testbox @ ^6.4.0+17 - Installed: Yes

Checking for outdated packages...
┌────────────────┬───────────┬──────────┬──────────┬─────────────────────┐
│ Package        │ Installed │ Update   │ Latest   │ Location            │
├────────────────┼───────────┼──────────┼──────────┼─────────────────────┤
│ testbox@^6.4.. │ 6.4.0+17  │ 6.4.0+17 │ 6.4.0+17 │ /testbox            │
└────────────────┴───────────┴──────────┴──────────┴─────────────────────┘

There are no outdated dependencies!

Full report exported to: dependency-report-20250919-113851.json
```

## Integration with CommandBox

The `wheels deps` commands delegate to CommandBox's package management system:
- `install` uses `box install` with `--saveDev` flag for dev dependencies
- `update` uses `box update`
- `remove` uses `box uninstall`
- `report` uses `box outdated`

This ensures compatibility with the broader CFML package ecosystem.

## Working with box.json

The command manages two dependency sections in box.json:

### Production Dependencies
```json
{
  "dependencies": {
    "wheels-core": "^3.0.0",
    "wirebox": "^7"
  }
}
```

### Development Dependencies
```json
{
  "devDependencies": {
    "testbox": "^6",
    "commandbox-cfformat": "*"
  }
}
```

## Installation Status

The command checks for installed packages using the `installPaths` defined in box.json to determine actual installation locations. This ensures accurate detection regardless of where packages are installed:

### Detection Method:
1. **Primary**: Checks the exact path specified in `box.json` → `installPaths`
2. **Fallback**: Checks standard locations like `/modules` directory

### Supported Package Formats:
- Simple names: `wirebox`
- Namespaced: `forgebox:wirebox`
- Versioned: `wirebox@7.0.0`

### Example Install Paths:
```json
"installPaths": {
    "testbox": "testbox/",
    "wirebox": "wirebox/",
    "cbvalidation": "modules/cbvalidation/",
    "shortcodes": "plugins/Shortcodes/"
}
```

The installation status reflects the physical presence of packages on the filesystem, not just their listing in box.json dependencies.

## Error Handling

Common scenarios:
- **No box.json**: Prompts to run `box init`
- **Package not found**: Shows available dependencies
- **Update failures**: Shows current and attempted versions
- **Network issues**: Displays CommandBox error messages

## Best Practices

1. **Initialize First**: Run `box init` before managing dependencies
2. **Use Version Constraints**: Specify version ranges for stability
3. **Separate Dev Dependencies**: Use `--dev` for test/build tools
4. **Regular Updates**: Run `wheels deps report` to check for outdated packages
5. **Commit box.json**: Always version control your dependency specifications

## Notes

- Dependencies are installed to the `/modules` directory
- The command respects CommandBox's dependency resolution
- Version specifications follow npm-style semver patterns
- Dev dependencies are not installed in production environments

## See Also

- [box install](https://commandbox.ortusbooks.com/package-management/installing-packages) - CommandBox package installation
- [box.json](https://commandbox.ortusbooks.com/package-management/box.json) - Package descriptor documentation
- [wheels init](init.md) - Initialize a Wheels application
- [wheels plugins](../plugins/plugins.md) - Manage Wheels CLI plugins