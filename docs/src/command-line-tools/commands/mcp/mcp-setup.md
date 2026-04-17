---
description: >-
  Set up MCP (Model Context Protocol) integration for AI IDE support in your
  Wheels application using the LuCLI stdio MCP server.
---

# MCP Setup

## Overview

The `wheels mcp setup` command configures your Wheels project to work with AI coding assistants like Claude Code, Cursor, Continue, OpenCode, and Windsurf. Wheels uses the **LuCLI stdio MCP server** (`wheels mcp wheels`) as its canonical agent surface — your IDE launches the MCP server as a subprocess on demand; no port or running dev server required.

> **Note (Wheels 4.0+):** The previous HTTP-based MCP endpoint at `/wheels/mcp` is deprecated and will be removed in a future release. Run `wheels mcp setup --force` to migrate existing projects to the stdio configuration.

## Usage

```bash
wheels mcp setup [options]
```

## Options

| Option | Type | Description |
|--------|------|-------------|
| `--force` | boolean | Overwrite existing configuration files |

## Examples

### Basic Setup

```bash
# Generate .mcp.json and .opencode.json pointing at LuCLI stdio MCP
wheels mcp setup
```

### Migrate an Existing Project

```bash
# Overwrite pre-4.0 HTTP-based configs with stdio configs
wheels mcp setup --force
```

## What Gets Created

### `.mcp.json` (Claude Code, Cursor, Continue, Windsurf)

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

## Prerequisites

- `wheels` CLI on PATH (`brew install wheels` or equivalent)
- Your AI IDE supports MCP (Claude Code, Cursor, Continue, OpenCode, Windsurf, etc.)

## What the Agent Sees

After setup, your AI IDE discovers 16 Wheels tools:

`wheels_generate`, `wheels_migrate`, `wheels_seed`, `wheels_test`, `wheels_reload`, `wheels_analyze`, `wheels_validate`, `wheels_routes`, `wheels_info`, `wheels_destroy`, `wheels_doctor`, `wheels_stats`, `wheels_notes`, `wheels_db`, `wheels_upgrade`, `wheels_create`.

CLI-only commands (`start`, `stop`, `new`, `console`, `browser`) are hidden from the MCP surface — they remain reachable as CLI subcommands but don't make sense for agent calls.

## Next Steps

1. Restart your AI IDE so it re-reads the new `.mcp.json` / `.opencode.json`
2. Verify tool discovery in the IDE's MCP panel
3. Test a simple call: ask the agent to run `wheels_info` or `wheels_routes`

## Related

- [MCP Configuration Guide](mcp-configuration-guide.md) — deeper details on transports, per-IDE setup, troubleshooting
- [MCP Status](mcp-status.md) — check current MCP configuration
- [MCP Test](mcp-test.md) — verify MCP connectivity
- [MCP Remove](mcp-remove.md) — remove MCP integration
