# wheels server start (Coming Soon)
*This command may not work as expected. A complete and stable version is **coming soon**.*

Start the Wheels development server with enhanced checks and features.

## Synopsis

```bash
wheels server start [options]
```

## Description

The `wheels server start` command starts a CommandBox server with Wheels-specific enhancements. It checks that you're in a valid Wheels application directory before starting and provides helpful error messages if not.

This command wraps CommandBox's native `server start` functionality while adding:
- Validation that the current directory is a Wheels application
- Automatic detection of existing running servers
- Wheels-specific configuration suggestions
- Integration with Wheels application context

## Options

### `port`
- **Type:** Numeric
- **Description:** Port number to start server on
- **Example:** `wheels server start port=8080`

### `host`
- **Type:** String
- **Default:** `127.0.0.1`
- **Description:** Host/IP address to bind server to
- **Example:** `wheels server start host=0.0.0.0`

### `--rewritesEnable`
- **Type:** Boolean flag
- **Description:** Enable URL rewriting for clean URLs
- **Example:** `wheels server start --rewritesEnable`

### `openbrowser`
- **Type:** Boolean
- **Default:** `true`
- **Description:** Open browser after starting server
- **Example:** `wheels server start openbrowser=false`

### `directory`
- **Type:** String
- **Default:** Current working directory
- **Description:** Directory to serve
- **Example:** `wheels server start directory=/path/to/app`

### `name`
- **Type:** String
- **Description:** Name for the server instance
- **Example:** `wheels server start name=myapp`

### `--force`
- **Type:** Boolean flag
- **Description:** Force start even if server is already running
- **Example:** `wheels server start --force`

## Examples

### Basic Usage
```bash
# Start server with defaults
wheels server start

# Start on specific port
wheels server start port=3000

# Start without opening browser
wheels server start openbrowser=false
```

### Advanced Usage
```bash
# Start with multiple options
wheels server start port=8080 host=0.0.0.0 --rewritesEnable

# Start with custom name
wheels server start name=myapp port=8080

# Force restart if already running
wheels server start --force
```

## Notes

- The command validates that the current directory contains a Wheels application by checking for `/vendor/wheels`, `/config`, and `/app` directories
- If a server is already running, use `--force` to start anyway or `wheels server restart` to restart
- After starting, the command displays helpful information about other server commands
- The server configuration can also be managed through `server.json` file

## Related Commands

- [`wheels server stop`](server-stop.md) - Stop the server
- [`wheels server restart`](server-restart.md) - Restart the server
- [`wheels server status`](server-status.md) - Check server status
- [`wheels server log`](server-log.md) - View server logs
- [`wheels server open`](server-open.md) - Open in browser

## See Also

- [CommandBox Server Documentation](https://commandbox.ortusbooks.com/embedded-server)
- [Wheels Configuration Guide](../../configuration/server-configuration.md)