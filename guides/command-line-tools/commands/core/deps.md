# wheels deps

Manage Wheels-specific dependencies and plugins.

## Synopsis

```bash
wheels deps <action> [name] [version]
```

## Description

The `wheels deps` command helps manage Wheels plugins and dependencies in your application.

## Arguments

| Argument | Description | Default |
|----------|-------------|---------|
| `action` | **Required** - Action to perform: `list`, `install`, `update`, `remove`, `report` | None |
| `name` | Plugin/dependency name (required for install/update/remove actions) | None |
| `version` | Specific version to install (optional, for install action only) | Latest version |

## Actions

### List
Display all installed plugins and dependencies.

```bash
wheels deps list
```

Output shows:
- Plugin name
- Version
- Author
- Status (Enabled/Disabled)

### Install
Install a new plugin or dependency.

```bash
wheels deps install <name>
wheels deps install <name> <version>
```

Examples:
```bash
wheels deps install multimodule
wheels deps install scaffold 2.1.0
```

### Update
Update an existing plugin or dependency.

```bash
wheels deps update <name>
```

Example:
```bash
wheels deps update multimodule
```

### Remove
Remove a plugin or dependency.

```bash
wheels deps remove <name>
```

Example:
```bash
wheels deps remove oldplugin
```

**Note**: Remove action will ask for confirmation before proceeding.

### Report
Generate a comprehensive dependency report.

```bash
wheels deps report
```

The report includes:
- All installed plugins
- Version information
- Dependencies between plugins
- Compatibility status
- Export to file

## Output Examples

### List Output
```
Installed Plugins:

Plugin        Version    Author         Status
----------    -------    ------------   --------
multimodule   1.0.0      Chris Peters   Enabled
scaffold      2.1.0      Tom Bellinson  Enabled
database      1.5.0      Per Djurner    Disabled
```

### Install Output
```
Installing multimodule...
✅ multimodule installed successfully
Version: 1.0.0
```

### Report Output
```
Dependency Report:

Plugins:
Plugin        Version    Dependencies
----------    -------    --------------
multimodule   1.0.0      None
scaffold      2.1.0      multimodule

Compatibility:
Component    Version    Status        Notes
---------    -------    -----------   ----------------
wheels       2.5.0      Compatible    
lucee        5.3.10     Compatible    
```

## Error Handling

Common errors:
- Plugin not found
- Version conflicts
- Missing dependencies
- Network connectivity issues

## Best Practices

1. **Before Installing**: Check compatibility with `wheels deps report`
2. **Regular Updates**: Keep plugins updated for security
3. **Test After Changes**: Run tests after installing/updating
4. **Document Dependencies**: Keep track of required plugins

## Notes

- Plugins are installed to the `/plugins` directory
- Some plugins may require configuration after installation
- Use `wheels plugins list` for more detailed plugin management

## See Also

- [wheels plugins install](../plugins/plugins-install.md) - Install plugins with more options
- [wheels plugins list](../plugins/plugins-list.md) - List plugins with filtering
- [wheels plugins remove](../plugins/plugins-remove.md) - Remove plugins
- [wheels init](init.md) - Initialize application