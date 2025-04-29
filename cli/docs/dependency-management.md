# Dependency Management Commands

The Wheels CLI provides commands to manage Wheels-specific dependencies and plugins, ensuring compatibility and proper versioning.

## Dependencies Command

Manage Wheels-specific dependencies and plugins with version control.

### Usage

```bash
wheels deps [action] [name] [version]
```

### Parameters

- `action`: Action to perform (list, install, update, remove, report) (required)
- `name`: Name of the plugin or dependency (required for install, update, remove)
- `version`: Version to install (optional, for install action)

### Examples

```bash
# List all installed dependencies and plugins
wheels deps list

# Install a specific plugin
wheels deps install DBMigrate

# Install a specific version of a plugin
wheels deps install DBMigrate 1.0.0

# Update a plugin to the latest version
wheels deps update DBMigrate

# Remove a plugin
wheels deps remove DBMigrate

# Generate a dependency report
wheels deps report
```

## Actions

### List

Lists all installed dependencies and plugins.

```bash
wheels deps list
```

This command displays:
- Plugin name
- Version
- Author
- Status (enabled/disabled)

### Install

Installs a specific plugin or dependency.

```bash
wheels deps install [name] [version]
```

This command:
- Downloads the specified plugin
- Installs it in the correct location
- Configures the plugin for use with your application
- Enables the plugin

### Update

Updates a plugin or dependency to the latest version.

```bash
wheels deps update [name]
```

This command:
- Checks for updates to the specified plugin
- Downloads the latest version
- Updates the plugin files
- Maintains your configuration

### Remove

Removes a plugin or dependency from your application.

```bash
wheels deps remove [name]
```

This command:
- Removes the plugin files
- Updates your configuration to reflect the removal
- Cleans up any plugin-specific resources

### Report

Generates a comprehensive dependency report.

```bash
wheels deps report
```

This command produces a report containing:
- List of installed plugins with versions
- Dependencies between plugins
- Compatibility status with your Wheels version
- Potential conflicts or issues

## Dependency Report

The dependency report provides valuable information about your application's dependencies:

### Plugins Section

Lists all plugins with:
- Name
- Version
- Author
- Dependencies on other plugins

### Compatibility Section

Analyzes compatibility of all components:
- Component name
- Version
- Compatibility status
- Notes about potential issues

### Export Options

The report can be:
- Displayed in the console
- Exported to a file for reference
- Used for documentation purposes

## Best Practices for Dependency Management

### Version Pinning

Specify exact versions for critical dependencies:

```bash
wheels deps install DBMigrate 1.5.2
```

This ensures consistent behavior across environments.

### Regular Updates

Schedule regular updates to keep dependencies secure:

```bash
# Update all plugins to latest compatible versions
wheels deps list | grep Plugin | awk '{print $1}' | xargs -I{} wheels deps update {}
```

### Pre-Update Testing

Before updating in production:
1. Run `wheels deps update [name]` in development
2. Test thoroughly
3. Update your test/staging environment
4. Finally update production

### Dependency Documentation

Keep a record of why each dependency is needed:

```
# Example dependency documentation in project README
## Dependencies
- DBMigrate: Database migration support
- Scaffold: UI generation for CRUD operations
```

## Managing Plugin Conflicts

When you encounter plugin conflicts:

1. Use `wheels deps report` to identify the conflict
2. Try updating all involved plugins to their latest versions
3. Check if a compatibility patch is available
4. Contact plugin authors if necessary
5. Consider creating a custom fork if needed

## Extending the Dependency System

The Wheels dependency system can be extended to handle:

### Custom Repositories

Install from private or custom repositories:

```bash
wheels deps install MyPrivatePlugin --repo=https://private-repo.example.com
```

### Development Dependencies

Mark dependencies as development-only:

```bash
wheels deps install TestingUtilities --dev=true
```

### Dependency Groups

Organize dependencies into logical groups:

```bash
wheels deps install ReportingPackage --group=reporting
```

This structured approach to dependency management helps maintain a clean, conflict-free application that can be easily updated and deployed.