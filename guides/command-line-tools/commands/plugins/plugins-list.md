# plugins list

Lists all installed plugins in your CFWheels application with version and status information.

## Usage

```bash
wheels plugins list [--format=<format>] [--status=<status>]
```

## Parameters

- `--format` - (Optional) Output format: `table`, `json`, `simple`. Default: `table`
- `--status` - (Optional) Filter by status: `all`, `active`, `inactive`. Default: `all`

## Description

The `plugins list` command displays information about all plugins installed in your CFWheels application, including:

- Plugin name and version
- Installation status (active/inactive)
- Compatibility with current CFWheels version
- Description and author information
- Dependencies on other plugins

## Examples

### List all plugins
```bash
wheels plugins list
```

### Show only active plugins
```bash
wheels plugins list --status=active
```

### Export as JSON
```bash
wheels plugins list --format=json
```

### Simple listing (names only)
```bash
wheels plugins list --format=simple
```

## Output

### Table Format (Default)
```
CFWheels Plugins
================

Name                Version    Status    Compatible    Description
-----------------------------------------------------------------
Authentication      2.1.0      Active    ✓            User authentication and authorization
DBMigrate          3.0.2      Active    ✓            Database migration management
Routing            1.5.1      Active    ✓            Advanced routing capabilities
TestBox            2.0.0      Inactive  ✓            Enhanced testing framework
CacheManager       1.2.3      Active    ✗            Advanced caching (requires update)

Total: 5 plugins (4 active, 1 inactive)
```

### JSON Format
```json
{
  "plugins": [
    {
      "name": "Authentication",
      "version": "2.1.0",
      "status": "active",
      "compatible": true,
      "description": "User authentication and authorization",
      "author": "CFWheels Team",
      "dependencies": []
    }
  ],
  "summary": {
    "total": 5,
    "active": 4,
    "inactive": 1
  }
}
```

## Plugin Statuses

- **Active**: Plugin is loaded and functioning
- **Inactive**: Plugin is installed but not loaded
- **Error**: Plugin failed to load (check logs)
- **Incompatible**: Plugin requires different CFWheels version

## Notes

- Plugins are loaded from the `/plugins` directory
- Plugin order matters for dependencies
- Incompatible plugins may cause application errors
- Use `wheels plugins install` to add new plugins