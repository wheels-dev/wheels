# wheels server restart

Restart the Wheels development server and reload the application.

## Synopsis

```bash
wheels server restart [options]
```

## Description

The `wheels server restart` command restarts a running CommandBox server and automatically reloads the Wheels application. This ensures that both server-level and application-level changes are picked up.

## Options

### `name`
- **Type:** String
- **Description:** Name of the server to restart
- **Example:** `wheels server restart name=myapp`

### `--force`
- **Type:** Boolean flag
- **Description:** Force restart even if server appears stopped
- **Example:** `wheels server restart --force`

## Examples

```bash
# Restart the default server
wheels server restart

# Restart a specific named server
wheels server restart name=myapp

# Force restart
wheels server restart --force
```

## What It Does

1. Stops the running server
2. Starts the server again with the same configuration
3. Automatically runs `wheels reload` to refresh the application
4. Confirms successful restart

## Notes

- This command is particularly useful when you've made changes to server configuration or installed new dependencies
- The automatic application reload ensures that Wheels picks up any code changes
- If the reload fails, you may need to manually refresh your browser

## Related Commands

- [`wheels server start`](server-start.md) - Start the server
- [`wheels server stop`](server-stop.md) - Stop the server
- [`wheels server status`](server-status.md) - Check server status
- [`wheels reload`](../core/reload.md) - Reload just the application

## See Also

- [CommandBox Server Documentation](https://commandbox.ortusbooks.com/embedded-server)