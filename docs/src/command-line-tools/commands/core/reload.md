# wheels reload

Reload the Wheels application in different modes.

## Synopsis

```bash
wheels reload [options]
wheels r [options]
```

## Description

The `wheels reload` command reloads your Wheels application, clearing caches and reinitializing the framework. This is useful during development when you've made changes to configuration, routes, or framework settings. Note: the server must be running for this command to work.

## Arguments

| Argument | Description | Default |
|----------|-------------|---------|
| `mode` | Reload mode: `development`, `testing`, `maintenance`, `production` | `development` |
| `password` | **Required** - The reload password configured in your application | None |


## Reload Modes

### Development Mode
```bash
wheels reload password=mypassword
```
- Enables debugging
- Shows detailed error messages
- Disables caching
- Ideal for active development

### Testing Mode
```bash
wheels reload mode=testing password=mypassword
```
- Optimized for running tests
- Consistent environment
- Predictable caching

### Maintenance Mode
```bash
wheels reload mode=maintenance password=mypassword
```
- Shows maintenance page to users
- Allows admin access
- Useful for deployments

### Production Mode
```bash
wheels reload mode=production password=mypassword
```
- Full caching enabled
- Minimal error information
- Optimized performance

## Examples

### Basic reload (development mode)
```bash
wheels reload password=wheels
```

### Reload in production mode
```bash
wheels reload mode=production password=mySecretPassword
```

### Using the alias
```bash
wheels r password=wheels
```

### Reload for testing
```bash
wheels reload mode=testing password=wheels
```

## Security

- The reload password must match the one configured in your Wheels application
- Password is sent via URL parameter to the running application
- Always use a strong password in production environments

## Configuration

Set the reload password in your Wheels `settings.cfm`:

```cfml
set(reloadPassword="mySecretPassword");
```

## Notes

- Reload clears all application caches
- Session data may be lost during reload
- Database connections are refreshed
- All singletons are recreated
- The server must be running for this command to work

## Common Issues

- **Invalid password**: Check password in settings.cfm
- **Server not running**: Start server with `box server start`
- **Connection refused**: Ensure server is accessible on expected port
- **Timeout**: Large applications may take time to reload

## See Also

- [wheels init](init.md) - Initialize application configuration=
- [wheels info](info.md) - Display application information