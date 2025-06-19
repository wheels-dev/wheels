# wheels server status

Show detailed status of the Wheels development server.

## Synopsis

```bash
wheels server status [options]
```

## Description

The `wheels server status` command displays the current status of your CommandBox server along with Wheels-specific information. It provides more context than the standard server status command.

## Options

### `name`
- **Type:** String
- **Description:** Name of the server to check
- **Example:** `wheels server status name=myapp`

### `--json`
- **Type:** Boolean flag
- **Description:** Output status in JSON format
- **Example:** `wheels server status --json`

### `--verbose`
- **Type:** Boolean flag
- **Description:** Show detailed server information
- **Example:** `wheels server status --verbose`

## Examples

```bash
# Check default server status
wheels server status

# Check specific server
wheels server status name=myapp

# Get JSON output for scripting
wheels server status --json

# Show verbose details
wheels server status --verbose
```

## Output Information

When the server is running, displays:
- Server running status
- URL and port information
- Wheels framework version
- Application root directory
- Quick action suggestions

Example output:
```
Wheels Server Status
===================

Status: Running
URL: http://127.0.0.1:60000
PID: 12345

Wheels Application Info:
  Wheels Version: 2.5.0
  Application Root: /Users/you/myapp

Quick Actions:
  wheels server open     - Open in browser
  wheels server log      - View logs
  wheels reload          - Reload application
```

## Notes

- The command enhances CommandBox's native status with Wheels-specific information
- Use `--json` format when integrating with scripts or other tools
- The verbose flag shows additional server configuration details

## Related Commands

- [`wheels server start`](server-start.md) - Start the server
- [`wheels server stop`](server-stop.md) - Stop the server
- [`wheels server log`](server-log.md) - View server logs

## See Also

- [CommandBox Server Documentation](https://commandbox.ortusbooks.com/embedded-server)