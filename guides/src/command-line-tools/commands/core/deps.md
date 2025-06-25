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
  wheels-core @ ^3.0.0 (Production) - Installed
  wirebox @ ^7 (Production) - Installed
  testbox @ ^5 (Production) - Installed

Dev Dependencies:
  commandbox-dotenv @ * (Development) - Not Installed
  commandbox-cfformat @ * (Development) - Installed
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

# Install as development dependency
wheels deps install testbox --dev
```

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

Generated: 2025-06-04 10:05:35
Project: my-wheels-app
Project Version: 1.0.0
Wheels Version: 3.0.0
CFML Engine: Lucee 5.4.6.9

Dependencies:
  wheels-core @ ^3.0.0 - Installed: Yes
  wirebox @ ^7 - Installed: Yes

Dev Dependencies:
  testbox @ ^5 - Installed: Yes

Checking for outdated packages...
All packages are up to date!

Full report exported to: dependency-report-20250604-100535.json
```

## Integration with CommandBox

The `wheels deps` commands delegate to CommandBox's package management system:
- `install` uses `box install`
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
    "testbox": "^5",
    "commandbox-cfformat": "*"
  }
}
```

## Installation Status

The command checks for installed packages in the `/modules` directory. It handles various package naming conventions:
- Simple names: `wirebox`
- Namespaced: `forgebox:wirebox`
- Versioned: `wirebox@7.0.0`

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