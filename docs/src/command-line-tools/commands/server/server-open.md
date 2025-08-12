# wheels server open (Coming Soon)
*This command may not work as expected. A complete and stable version is **coming soon**.*

Open the Wheels application in a web browser.

## Synopsis

```bash
wheels server open [path] [options]
```

## Description

The `wheels server open` command opens your Wheels application in a web browser. It automatically detects the server URL and can open specific paths within your application.

## Arguments

### `path`
- **Type:** String
- **Default:** `/`
- **Description:** URL path to open (e.g., `/admin`, `/users`)
- **Example:** `wheels server open /admin`

## Options

### `--browser`
- **Type:** String
- **Description:** Specific browser to use (chrome, firefox, safari, etc.)
- **Example:** `wheels server open --browser=firefox`

### `name`
- **Type:** String
- **Description:** Name of the server to open
- **Example:** `wheels server open name=myapp`

## Examples

```bash
# Open application homepage
wheels server open

# Open admin panel
wheels server open /admin

# Open users listing
wheels server open /users

# Open in specific browser
wheels server open --browser=chrome

# Open path in Firefox
wheels server open /dashboard --browser=firefox
```

## Supported Browsers

The `--browser` option supports:
- `chrome` - Google Chrome
- `firefox` - Mozilla Firefox
- `safari` - Safari (macOS)
- `edge` - Microsoft Edge
- `opera` - Opera

If no browser is specified, your system's default browser is used.

## Notes

- The command first checks if the server is running before attempting to open
- If the server isn't running, it will suggest starting it first
- The path argument should start with `/` for proper URL construction
- The browser must be installed on your system to use the `--browser` option

## Error Messages

### "Server doesn't appear to be running"
The server must be started before you can open it in a browser:
```bash
wheels server start
wheels server open
```

## Related Commands

- [`wheels server start`](server-start.md) - Start the server
- [`wheels server status`](server-status.md) - Check if server is running

## See Also

- [CommandBox Browser Integration](https://commandbox.ortusbooks.com/embedded-server)