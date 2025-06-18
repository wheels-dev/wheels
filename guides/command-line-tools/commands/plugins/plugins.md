# wheels plugins

Base command for plugin management in Wheels applications.

## Synopsis

```bash
wheels plugins [subcommand] [options]
```

## Description

The `wheels plugins` command provides comprehensive plugin management for Wheels applications. It handles plugin discovery, installation, configuration, and lifecycle management.

## Subcommands

| Command | Description |
|---------|-------------|
| `list` | List installed plugins |
| `install` | Install a plugin |
| `remove` | Remove a plugin |

## Options

| Option | Description |
|--------|-------------|
| `--help` | Show help information |
| `--version` | Show version information |

## Direct Usage

When called without subcommands, displays plugin overview:

```bash
wheels plugins
```

Output:
```
Wheels Plugin Manager
====================

Installed Plugins: 5
├── authentication (v2.1.0) - User authentication system
├── pagination (v1.5.2) - Advanced pagination helpers
├── validation (v3.0.1) - Extended validation rules
├── caching (v2.2.0) - Enhanced caching strategies
└── api-tools (v1.8.3) - RESTful API utilities

Available Updates: 2
- validation: v3.0.1 → v3.1.0
- api-tools: v1.8.3 → v2.0.0

Run 'wheels plugins list' for detailed information
```

## Examples

### Show plugin overview
```bash
wheels plugins
```

### Quick plugin check
```bash
wheels plugins --check
```

### Update all plugins
```bash
wheels plugins --update-all
```

### Plugin system info
```bash
wheels plugins --info
```

## Plugin System

### Plugin Structure
```
/plugins/
├── authentication/
│   ├── Authentication.cfc
│   ├── config/
│   ├── models/
│   ├── views/
│   └── plugin.json
├── pagination/
└── ...
```

### Plugin Metadata
Each plugin contains `plugin.json`:
```json
{
  "name": "authentication",
  "version": "2.1.0",
  "description": "User authentication system",
  "author": "Wheels Community",
  "wheels": ">=2.0.0",
  "dependencies": {
    "validation": ">=3.0.0"
  }
}
```

## Plugin Registry

### Official Registry
Default source for plugins:
```
https://www.forgebox.io/type/cfwheels-plugins/
```

### Custom Registries
Configure additional sources:
```json
{
  "pluginRegistries": [
    "https://www.forgebox.io/type/cfwheels-plugins/",
    "https://company.com/wheels-plugins/"
  ]
}
```

## Plugin Lifecycle

### Discovery
```bash
# Search for plugins
wheels plugins search authentication

# Browse categories
wheels plugins browse --category=security
```

### Installation
```bash
# Install from registry
wheels plugins install authentication

# Install from GitHub
wheels plugins install github:user/wheels-plugin

# Install from file
wheels plugins install ./my-plugin.zip
```

### Configuration
```bash
# Configure plugin
wheels plugins configure authentication

# View configuration
wheels plugins config authentication
```

### Updates
```bash
# Check for updates
wheels plugins outdated

# Update specific plugin
wheels plugins update authentication

# Update all plugins
wheels plugins update --all
```

## Plugin Development

### Create Plugin
```bash
# Generate plugin scaffold
wheels generate plugin my-plugin

# Plugin structure created:
# /plugins/my-plugin/
#   ├── MyPlugin.cfc
#   ├── plugin.json
#   ├── config/
#   ├── tests/
#   └── README.md
```

### Plugin API
```cfml
component extends="wheels.Plugin" {
    
    function init() {
        this.version = "1.0.0";
        this.author = "Your Name";
        this.description = "Plugin description";
    }
    
    function setup() {
        // Plugin initialization
    }
    
    function teardown() {
        // Plugin cleanup
    }
}
```

## Environment Support

### Environment-Specific Plugins
```json
{
  "plugins": {
    "production": ["caching", "monitoring"],
    "development": ["debug-toolbar", "profiler"],
    "all": ["authentication", "validation"]
  }
}
```

### Conditional Loading
```cfml
// In environment.cfm
if (get("environment") == "development") {
    addPlugin("debug-toolbar");
}
```

## Plugin Commands

Plugins can register custom commands:
```cfml
// In plugin
this.commands = {
    "auth:create-user": "commands/CreateUser.cfc",
    "auth:reset-password": "commands/ResetPassword.cfc"
};
```

Usage:
```bash
wheels auth:create-user admin@example.com
wheels auth:reset-password user123
```

## Dependency Management

### Automatic Resolution
```bash
# Installs plugin and dependencies
wheels plugins install api-tools
# Also installs: validation, serialization
```

### Conflict Resolution
```bash
# When conflicts exist
wheels plugins install authentication --resolve=prompt
```

Options:
- `prompt`: Ask for each conflict
- `newest`: Use newest version
- `oldest`: Keep existing version

## Plugin Storage

### Global Plugins
Shared across projects:
```bash
wheels plugins install authentication --global
```

Location: `~/.wheels/plugins/`

### Project Plugins
Project-specific:
```bash
wheels plugins install authentication
```

Location: `/plugins/`

## Security

### Plugin Verification
```bash
# Verify plugin signatures
wheels plugins verify authentication

# Install only verified plugins
wheels plugins install authentication --verified-only
```

### Permission Control
```json
{
  "pluginPermissions": {
    "fileSystem": ["read", "write"],
    "network": ["http", "https"],
    "database": ["read", "write"]
  }
}
```

## Troubleshooting

### Common Issues

1. **Plugin Not Loading**
   ```bash
   wheels plugins diagnose authentication
   ```

2. **Dependency Conflicts**
   ```bash
   wheels plugins deps --tree
   ```

3. **Version Incompatibility**
   ```bash
   wheels plugins check-compatibility
   ```

## Best Practices

1. **Version Lock**: Lock plugin versions for production
2. **Test Updates**: Test in development first
3. **Backup**: Backup before major updates
4. **Documentation**: Document custom plugins
5. **Security**: Verify plugin sources

## Plugin Cache

### Clear Cache
```bash
wheels plugins cache clear
```

### Rebuild Cache
```bash
wheels plugins cache rebuild
```

## Notes

- Plugins are loaded in dependency order
- Some plugins require application restart
- Global plugins override project plugins
- Plugin conflicts are resolved by load order

## See Also

- [wheels plugins list](plugins-list.md) - List plugins
- [wheels plugins install](plugins-install.md) - Install plugins
- [wheels plugins remove](plugins-remove.md) - Remove plugins
- [Plugin Development Guide](../../plugin-development.md)