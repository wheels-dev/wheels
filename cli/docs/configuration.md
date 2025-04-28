# Configuration Management Commands

The Wheels CLI provides tools to manage your application's configuration across different environments.

## Config List

List all configuration settings for your Wheels application.

### Usage

```bash
wheels config:list [--environment=] [--filter=] [--showSensitive=false]
```

### Parameters

- `environment`: Environment to display settings for (development, testing, production) (optional)
- `filter`: Filter results by this string (optional)
- `showSensitive`: Show sensitive information like passwords and keys (default: false)

### Examples

```bash
# List all configuration settings for current environment
wheels config:list

# List configuration for production environment
wheels config:list --environment=production

# List only database-related settings
wheels config:list --filter=dataSource

# Show sensitive information (passwords, etc.)
wheels config:list --showSensitive=true
```

## Config Set

Set configuration values for your Wheels application.

### Usage

```bash
wheels config:set [setting] [--environment=development] [--encrypt=false]
```

### Parameters

- `setting`: Key=Value pair for the setting to update (required)
- `environment`: Environment to apply settings to (development, testing, production, all) (default: development)
- `encrypt`: Encrypt sensitive values (default: false)

### Examples

```bash
# Set a basic configuration value
wheels config:set dataSourceName=myDB

# Set a value for production environment
wheels config:set reloadPassword=myStrongPassword --environment=production

# Set and encrypt a sensitive value
wheels config:set apiKey=1234567890 --encrypt=true
```

## Config Environment

Manage environment-specific settings for your Wheels application.

### Usage

```bash
wheels config:env [action] [--source=] [--target=]
```

### Parameters

- `action`: Action to perform (list, create, copy) (required)
- `source`: Source environment for copy action (required for copy action)
- `target`: Target environment for create or copy action (required for create and copy actions)

### Examples

```bash
# List available environments
wheels config:env list

# Create a new environment
wheels config:env create production

# Copy settings from one environment to another
wheels config:env copy development staging
```

## Configuration Best Practices

### Security

1. **Encrypt Sensitive Information**: Always use the `--encrypt=true` flag when setting passwords, API keys, or other sensitive values
2. **Environment-Specific Secrets**: Use different secrets for different environments
3. **Restrict Access**: Limit who can view and modify configuration settings

### Environment Management

1. **Environment Isolation**: Keep environment configurations completely separate
2. **Consistent Structure**: Maintain the same configuration structure across environments
3. **Default Values**: Provide sensible defaults for development environments
4. **Minimal Production Config**: Only include necessary settings in production

### Documentation

1. **Document Settings**: Maintain documentation for all configuration settings
2. **Track Changes**: Record when and why configuration changes are made
3. **Template Configurations**: Create template configurations for new deployments

## Configuration Files

Wheels uses several configuration files that can be managed through these commands:

- **config/settings.cfm**: Main application settings
- **config/environment.cfm**: Environment detection and configuration
- **config/routes.cfm**: URL routing configuration
- **config/design/datasources.cfm**: Database connection settings

The configuration commands help manage these files without having to edit them directly.

## Working with Multiple Environments

The Wheels CLI configuration commands make it easy to manage configurations across different environments:

```bash
# Setting up a new environment
wheels config:env create staging
wheels config:env copy development staging

# Customize the new environment
wheels config:set dataSourceName=staging_db --environment=staging
wheels config:set reloadPassword=stagingPass123 --environment=staging --encrypt=true
```

This approach ensures consistent configuration across all your environments while allowing for environment-specific customizations.