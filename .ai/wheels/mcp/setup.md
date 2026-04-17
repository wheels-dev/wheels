# MCP Setup

Configure your AI IDE to use the Wheels MCP server. The same stdio config works for Claude Code, Cursor, Continue, and Windsurf; OpenCode uses a slightly different shape.

## Prerequisites

- Install the `wheels` CLI on PATH: `brew install wheels` (macOS) or the Chocolatey equivalent on Windows
- Confirm with: `wheels --version` (should show 0.3.8 or later — 0.3.7 and earlier miss the output-capture fix)

## Fast path

From your Wheels project root:

```bash
wheels mcp setup
```

This writes `.mcp.json` + `.opencode.json` with the stdio config. Restart your AI IDE to pick them up.

To migrate an existing project away from the legacy HTTP config:

```bash
wheels mcp setup --force
```

## Manual config

### `.mcp.json` (Claude Code, Cursor, Continue, Windsurf)

```json
{
  "mcpServers": {
    "wheels": {
      "command": "wheels",
      "args": ["mcp", "wheels"]
    }
  }
}
```

If you want the Browser MCP alongside Wheels:

```json
{
  "mcpServers": {
    "wheels": {
      "command": "wheels",
      "args": ["mcp", "wheels"]
    },
    "browsermcp": {
      "command": "npx",
      "args": ["@browsermcp/mcp@latest"]
    }
  }
}
```

### `.opencode.json` (OpenCode)

```json
{
  "$schema": "https://opencode.ai/config.json",
  "mcp": {
    "wheels": {
      "type": "local",
      "command": ["wheels", "mcp", "wheels"],
      "enabled": true
    }
  }
}
```

## Verify the connection

After restarting the IDE, open its MCP panel and confirm 16 tools are visible:

```
wheels_generate    wheels_migrate    wheels_seed       wheels_test
wheels_reload      wheels_analyze    wheels_validate   wheels_routes
wheels_info        wheels_destroy    wheels_doctor     wheels_stats
wheels_notes       wheels_db         wheels_upgrade    wheels_create
```

Ask the agent to run a safe read-only tool like `wheels_info` or `wheels_routes` to confirm the bridge works end-to-end.

## Troubleshooting

### Tools list is empty or wrong count

- Older LuCLI (<0.3.4) doesn't honor `mcpHiddenTools()` — you'd see 23–24 tools including `mcp`, `d`, `new`, `console`, `start`, `stop`, `browser`, `mcphiddentools`. Upgrade: `brew upgrade wheels`.
- Older LuCLI (<0.3.7) has broken MCP output capture — tools return empty content. Same fix: upgrade.

### `command not found: wheels` from the IDE

The IDE may not inherit your shell PATH. Either:

- Use an absolute path: `"command": "/opt/homebrew/bin/wheels"` (macOS) or the equivalent path from `which wheels`
- Configure the IDE's MCP integration to source your shell profile before launching subprocesses

### Agent sees empty input schemas

- The function's signature is untyped (`public string function foo()` with no declared parameters). Rich schemas require typed signatures — see [overview.md](overview.md) for the pattern.
- Requires LuCLI ≥ v0.3.8 for CLI positional args to bind to typed params. MCP named args work on any version.

### Tool runs but response is truncated or incomplete

- Deprecation notice from the HTTP endpoint? You're still pointed at the old HTTP MCP. Run `wheels mcp setup --force` and restart the IDE.
- Stdio output capture issue: upgrade to LuCLI ≥ v0.3.7.

## See also

- [overview.md](overview.md) — architecture and tool inventory
- [tool-reference.md](tool-reference.md) — per-tool input parameters
