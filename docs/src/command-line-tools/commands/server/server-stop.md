# wheels server stop (Coming Soon)
*This command may not work as expected. A complete and stable version is **coming soon**.*

Stop the Wheels development server.

## Synopsis

```bash
wheels server stop [options]
```

## Description

The `wheels server stop` command stops a running CommandBox server. It provides a simple way to shut down your development server cleanly.

## Options

### `name`
- **Type:** String
- **Description:** Name of the server to stop (if multiple servers are running)
- **Example:** `wheels server stop name=myapp`

### `--force`
- **Type:** Boolean flag
- **Description:** Force stop all running servers
- **Example:** `wheels server stop --force`

## Examples

```bash
# Stop the default server
wheels server stop

# Stop a specific named server
wheels server stop name=myapp

# Force stop all servers
wheels server stop --force
```

## Notes

- If no server name is specified, stops the server in the current directory
- Use `--force` to stop all running servers at once
- The command will confirm when the server has been stopped successfully

## Related Commands

- [`wheels server start`](server-start.md) - Start the server
- [`wheels server restart`](server-restart.md) - Restart the server
- [`wheels server status`](server-status.md) - Check server status

## See Also

- [CommandBox Server Documentation](https://commandbox.ortusbooks.com/embedded-server)