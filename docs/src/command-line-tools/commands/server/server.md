# wheels server (Coming Soon)
*This command may not work as expected. A complete and stable version is **coming soon**.*

Manage the Wheels development server with enhanced functionality.

## Synopsis

```bash
wheels server [subcommand] [options]
```

## Description

The `wheels server` command provides a suite of server management tools that wrap CommandBox's native server functionality with Wheels-specific enhancements. These commands add validation, helpful error messages, and integration with the Wheels framework.

## Available Subcommands

- [`start`](server-start.md) - Start the development server
- [`stop`](server-stop.md) - Stop the development server
- [`restart`](server-restart.md) - Restart the development server
- [`status`](server-status.md) - Show server status
- [`log`](server-log.md) - Tail server logs
- [`open`](server-open.md) - Open application in browser

## Key Features

### Wheels Application Validation
All server commands check that you're working in a valid Wheels application directory before executing. This prevents common errors and provides helpful guidance.

### Enhanced Status Information
When checking server status, the commands also display:
- Wheels framework version
- Application root directory
- Quick action suggestions

### Integrated Restart
The `restart` command not only restarts the server but also reloads the Wheels application, ensuring your changes are picked up.

### Smart Browser Opening
The `open` command can open specific paths in your application and works with your preferred browser.

## Examples

```bash
# Display available server commands
wheels server

# Start server on port 8080
wheels server start port=8080

# Check if server is running
wheels server status

# Tail the server logs
wheels server log

# Open admin panel in browser
wheels server open /admin
```

## Configuration

Server settings can be configured through:

1. **Command line options** - Pass options directly to commands
2. **server.json** - Create a `server.json` file in your project root
3. **box.json** - Configure server settings in your `box.json`

Example `server.json`:
```json
{
  "web": {
    "port": 8080,
    "host": "127.0.0.1",
    "rewrites": {
      "enable": true
    }
  }
}
```

## Integration with CommandBox

These commands are thin wrappers around CommandBox's native server commands, providing:
- Validation specific to Wheels applications
- Better error messages and guidance
- Integration with Wheels-specific features
- Consistent command structure

You can always use the native CommandBox commands directly if needed:
```bash
# Native CommandBox commands still work
server start
server stop
server status
```

## Troubleshooting

### Server won't start
1. Check if a server is already running: `wheels server status`
2. Try forcing a start: `wheels server start --force`
3. Check for port conflicts: `wheels server start port=8081`

### Can't find Wheels application
Ensure you're in a directory containing:
- `/vendor/wheels` - The Wheels framework
- `/config` - Configuration files
- `/app` - Application code

### Server starts but application doesn't work
1. Check logs: `wheels server log`
2. Verify database connection in datasource settings
3. Try reloading: `wheels reload`

## See Also

- [CommandBox Server Documentation](https://commandbox.ortusbooks.com/embedded-server)
- [Wheels Installation Guide](../../../introduction/getting-started/)