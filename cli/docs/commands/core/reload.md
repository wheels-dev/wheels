# wheels reload

Reload the Wheels application in different modes.

## Synopsis

```bash
wheels reload [mode] [password]
```

## Description

The `wheels reload` command reloads your Wheels application, clearing caches and reinitializing the framework. This is useful during development when you've made changes to configuration, routes, or framework settings.

## Arguments

| Argument | Description | Default |
|----------|-------------|---------|
| `mode` | Reload mode: `development`, `testing`, `maintenance`, `production` | `development` |
| `password` | Reload password (overrides configured password) | From `.wheels-cli.json` |

## Options

| Option | Description |
|--------|-------------|
| `--help` | Show help information |

## Reload Modes

### Development Mode
```bash
wheels reload development
```
- Enables debugging
- Shows detailed error messages
- Disables caching
- Ideal for active development

### Testing Mode
```bash
wheels reload testing
```
- Optimized for running tests
- Consistent environment
- Predictable caching

### Maintenance Mode
```bash
wheels reload maintenance
```
- Shows maintenance page to users
- Allows admin access
- Useful for deployments

### Production Mode
```bash
wheels reload production
```
- Full caching enabled
- Minimal error information
- Optimized performance

## Examples

### Basic reload (development mode)
```bash
wheels reload
```

### Reload in production mode
```bash
wheels reload production
```

### Reload with custom password
```bash
wheels reload development mySecretPassword
```

### Reload for testing
```bash
wheels reload testing
```

## Security

- The reload password must match the one configured in your Wheels application
- Default password from `.wheels-cli.json` is used if not specified
- Password is sent securely to the application

## Configuration

Set the default reload password in `.wheels-cli.json`:

```json
{
  "reload": "mySecretPassword"
}
```

Or in your Wheels `settings.cfm`:

```cfml
set(reloadPassword="mySecretPassword");
```

## Notes

- Reload clears all application caches
- Session data may be lost during reload
- Database connections are refreshed
- All singletons are recreated

## Common Issues

- **Invalid password**: Check password in settings
- **Timeout**: Large applications may take time to reload
- **Memory issues**: Monitor JVM heap during reload

## See Also

- [wheels init](init.md) - Initialize application configuration
- [wheels watch](watch.md) - Auto-reload on file changes
- [wheels config set](../config/config-set.md) - Configure reload settings