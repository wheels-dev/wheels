# wheels server log (Coming Soon)
*This command may not work as expected. A complete and stable version is **coming soon**.*

Tail the Wheels development server logs.

## Synopsis

```bash
wheels server log [options]
```

## Description

The `wheels server log` command displays and follows the server log output, making it easy to monitor your application's behavior and debug issues.

## Options

### `name`
- **Type:** String
- **Description:** Name of the server whose logs to display
- **Example:** `wheels server log name=myapp`

### `--follow`
- **Type:** Boolean flag
- **Default:** `true`
- **Description:** Follow log output (like tail -f)
- **Example:** `wheels server log --follow`

### `lines`
- **Type:** Numeric
- **Default:** `50`
- **Description:** Number of lines to show initially
- **Example:** `wheels server log lines=100`

### `--debug`
- **Type:** Boolean flag
- **Description:** Show debug-level logging
- **Example:** `wheels server log --debug`

## Examples

```bash
# Follow logs (default behavior)
wheels server log

# Show last 100 lines
wheels server log lines=100

# Show logs without following
wheels server log --follow=false

# Enable debug logging
wheels server log --debug
```

## Log Information

The logs typically include:
- HTTP request/response information
- Application errors and stack traces
- Database queries (if enabled)
- Custom application logging
- Server startup/shutdown messages

## Keyboard Shortcuts

- **Ctrl+C** - Stop following logs and return to command prompt
- **Ctrl+L** - Clear the screen (while following)

## Notes

- By default, the command follows log output (similar to `tail -f`)
- Use `--debug` to see more detailed logging information
- The number of initial lines shown can be customized with the `lines` parameter
- Logs are stored in the CommandBox server's log directory

## Related Commands

- [`wheels server start`](server-start.md) - Start the server
- [`wheels server status`](server-status.md) - Check server status
- [`wheels test debug`](../testing/test-debug.md) - Debug mode for tests

## See Also

- [CommandBox Logging Documentation](https://commandbox.ortusbooks.com/embedded-server/configuring-your-server/server-logs)
- [Wheels Debugging Guide](../../../working-with-wheels/debugging.md)