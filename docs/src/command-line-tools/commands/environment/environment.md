# wheels environment (coming Soon)
*This command may not work as expected. A complete and stable version is **coming soon**.*

Display or switch the current Wheels environment.

## Synopsis

```bash
wheels environment [action] [value] [options]
```

## Description

The `wheels environment` command manages your Wheels application environment settings. It can display the current environment, switch between environments, and list all available environments. Environment changes can trigger automatic application reloads to ensure your settings take effect immediately.

## Arguments

### `action`
- **Type:** String
- **Default:** `show`
- **Options:** `show`, `set`, `list`
- **Description:** Action to perform
- **Example:** `wheels environment set production`

### `value`
- **Type:** String
- **Description:** Environment value when using set action
- **Options:** `development`, `testing`, `production`, `maintenance`
- **Example:** `wheels environment set development`

## Options

### `--reload`
- **Type:** Boolean
- **Default:** `true`
- **Description:** Reload application after changing environment
- **Example:** `wheels environment set production --reload=false`

## Examples

### Basic Usage
```bash
# Show current environment
wheels environment

# Set environment to production
wheels environment set production

# Set environment without reload
wheels environment set development --reload=false

# List all available environments
wheels environment list
```

### Quick Switching
```bash
# Shortcut syntax - if action matches an environment name
wheels environment development   # Same as: wheels environment set development
wheels environment production    # Same as: wheels environment set production
wheels environment testing       # Same as: wheels environment set testing
```

## Environment Details

### development
- **Description:** Development mode with debugging enabled, no caching
- **Use for:** Local development and debugging
- **Features:**
  - Debug information displayed
  - Error details shown
  - No query caching
  - No view caching
  - Hot reloading enabled

### testing
- **Description:** Testing mode for running automated tests
- **Use for:** Running test suites and CI/CD pipelines
- **Features:**
  - Consistent test environment
  - Test database connections
  - Predictable caching behavior
  - Error details available

### production
- **Description:** Production mode with caching enabled, debugging disabled
- **Use for:** Live production servers
- **Features:**
  - Query caching enabled
  - View caching enabled
  - Debug information hidden
  - Optimized performance
  - Error pages for users

### maintenance
- **Description:** Maintenance mode to show maintenance page
- **Use for:** During deployments or maintenance windows
- **Features:**
  - Maintenance page displayed
  - Admin access still available
  - Database migrations possible
  - Public access restricted

## How It Works

1. **Configuration Storage**: Environment settings are stored in:
   - `.env` file (WHEELS_ENV variable)
   - Environment variables
   - Application configuration

2. **Runtime Detection**: The environment is determined by:
   - Checking server environment variables
   - Reading `.env` file
   - Defaulting to development

3. **Change Process**:
   - Updates `.env` file
   - Optionally reloads application
   - Changes take effect immediately (if reloaded)

## Output Examples

### Current Environment Display
```
Current Wheels Environment
=========================

Environment: development
Wheels Version: 2.5.0
Data Source: myapp_dev
Server: Lucee 5.3.10.120

Environment Settings:
  cacheQueries: false
  cachePartials: false
  cachePages: false
  cacheActions: false
  showDebugInformation: true
  showErrorInformation: true
```

### Environment List
```
Available Wheels Environments
============================

development (current)
  Description: Development mode with debugging enabled, no caching
  Use for: Local development and debugging

testing
  Description: Testing mode for running automated tests
  Use for: Running test suites and CI/CD pipelines

production
  Description: Production mode with caching enabled, debugging disabled
  Use for: Live production servers

maintenance
  Description: Maintenance mode to show maintenance page
  Use for: During deployments or maintenance windows
```

## Configuration

### Using .env File
Create or modify `.env` in your project root:
```bash
WHEELS_ENV=production
```

### Using Environment Variables
Set system environment variable:
```bash
export WHEELS_ENV=production
```

### Precedence Order
1. System environment variables (highest priority)
2. `.env` file
3. Default (development)

## Best Practices

1. **Development Workflow**
   - Use `development` for local work
   - Switch to `testing` before running tests
   - Never use `development` in production

2. **Production Deployment**
   - Always use `production` environment
   - Set via environment variables for security
   - Disable reload after deployment

3. **Testing Strategy**
   - Use `testing` for automated tests
   - Ensure consistent test environment
   - Reset between test runs

4. **Maintenance Windows**
   - Switch to `maintenance` during deployments
   - Provide clear maintenance messages
   - Switch back to `production` when complete

## Troubleshooting

### Environment not changing
1. Check if server needs restart: `wheels server restart`
2. Verify `.env` file permissions
3. Check for system environment variable conflicts

### Server required for some operations
- Some environment checks require running server
- Start server first: `wheels server start`
- File-based changes work without server

### Permission issues
- Ensure write access to `.env` file
- Check directory permissions
- Run with appropriate user privileges

## Security Notes

- Don't commit `.env` files with production settings
- Use environment variables in production
- Restrict access to environment commands in production
- Log environment changes for audit trails

## Related Commands

- [`wheels reload`](../core/reload.md) - Reload application
- [`wheels server restart`](../server/server-restart.md) - Restart server
- [`wheels console`](console.md) - Test in different environments

## See Also

- [Wheels Configuration Guide](../../../working-with-wheels/configuration-and-defaults.md)
- [Environment Variables Documentation](../../../working-with-wheels/switching-environments.md)