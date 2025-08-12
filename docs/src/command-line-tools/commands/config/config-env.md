# wheels config env (Coming Soon) 
*This command may not work as expected. A complete and stable version is **coming soon**.*

Manage environment-specific configuration for your Wheels application.

## Usage

```bash
wheels config env <action> [source] [target]
```

## Parameters

- `action` - (Required) Action to perform: `list`, `create`, `copy`
- `source` - (Optional) Source environment for copy action
- `target` - (Optional) Target environment for create or copy action

## Description

The `wheels config env` command provides tools for managing environment-specific configurations. It helps you list, create, and copy configurations between different environments.

## Examples

### List all environments
```bash
wheels config env list
```

### Create a new environment
```bash
wheels config env create production
```

### Copy environment configuration
```bash
wheels config env copy development production
```

## Actions

### List Environments

Display all available environments:

```bash
wheels config env list
```

Output:
```
Available Environments:
----------------------
• development (active)
• testing
• maintenance  
• production
```

### Create Environment

Create a new environment configuration:

```bash
wheels config env create staging
```

This creates a new environment configuration file at `/config/staging/settings.cfm`.

### Copy Environment

Copy configuration from one environment to another:

```bash
wheels config env copy development staging
```

This copies all settings from the development environment to the staging environment, preserving environment-specific values like datasource names.

## Notes

- Some operations require application restart
- Sensitive values protected by default
- Changes logged for audit purposes
- Use templates for consistency

## See Also

- [wheels config list](config-list.md) - List all settings
- [wheels config set](config-set.md) - Set configuration values
- [wheels env](../environment/env.md) - Environment management
- [Configuration Guide](../../configuration.md)