---
description: >-
  Set up MCP (Model Context Protocol) integration for AI IDE support in your
  Wheels application.
---

# MCP Setup

## Overview

The `wheels mcp setup` command configures your Wheels project to work seamlessly with AI coding assistants like Claude Code, Cursor, Continue, and Windsurf. Wheels includes a **native CFML MCP server** that runs directly within your application - no Node.js required!

## Usage

```bash
wheels mcp setup [options]
```

## Options

| Option | Type | Description |
|--------|------|-------------|
| `--port` | numeric | Port number for Wheels server (auto-detected if not provided) |
| `--ide` | string | Specific IDE to configure (`claude`, `cursor`, `continue`, `windsurf`) |
| `--all` | boolean | Configure all detected IDEs |
| `--force` | boolean | Overwrite existing configuration files |
| `--noAutoStart` | boolean | Don't automatically start server if not running |

## Examples

### Basic Setup
```bash
# Auto-detect settings and configure available IDEs
wheels mcp setup
```

### IDE-Specific Setup
```bash
# Configure only Claude Code
wheels mcp setup --ide=claude

# Configure only Cursor
wheels mcp setup --ide=cursor

# Configure all detected IDEs
wheels mcp setup --all
```

### Custom Configuration
```bash
# Use specific port
wheels mcp setup --port=8080

# Force overwrite existing configs
wheels mcp setup --force

# Setup without auto-starting server
wheels mcp setup --noAutoStart
```

## How It Works

### Native CFML MCP Server
Wheels includes a built-in MCP (Model Context Protocol) server that runs directly within your CFML application:

- **No dependencies**: No Node.js installation required
- **Integrated**: Runs within your Wheels application context
- **Secure**: Uses your application's existing security model
- **Performant**: Direct CFML execution without external processes

### MCP Server Endpoint
The setup command configures access to your Wheels application's MCP server at:
```
http://localhost:[port]/wheels/mcp
```

### Available Resources
The MCP server provides access to:
- **API Documentation**: Complete Wheels framework documentation
- **Project Context**: Current project structure and configuration
- **Code Patterns**: Common Wheels patterns and best practices
- **Guides**: Framework tutorials and examples

### Available Tools
- **Code Generation**: Generate models, controllers, views, migrations
- **Database Operations**: Run migrations, check schema
- **Server Management**: Start, stop, restart development server
- **Testing**: Run Wheels tests and validation

## Supported IDEs

### Claude Code
Configuration file: `~/.claude/config.json`
```json
{
  "mcpServers": {
    "wheels": {
      "transport": {
        "type": "http",
        "url": "http://localhost:[port]/wheels/mcp"
      }
    }
  }
}
```

### Cursor
Configuration file: `~/.cursor/config.json`
```json
{
  "mcpServers": {
    "wheels": {
      "transport": {
        "type": "http",
        "url": "http://localhost:[port]/wheels/mcp"
      }
    }
  }
}
```

### Continue
Configuration file: `~/.continue/config.json`
```json
{
  "mcpServers": {
    "wheels": {
      "transport": {
        "type": "http",
        "url": "http://localhost:[port]/wheels/mcp"
      }
    }
  }
}
```

### Windsurf
Configuration file: `~/.windsurf/config.json`
```json
{
  "mcpServers": {
    "wheels": {
      "transport": {
        "type": "http",
        "url": "http://localhost:[port]/wheels/mcp"
      }
    }
  }
}
```

## Prerequisites

1. **Wheels Application**: Must be run from a Wheels project root directory
2. **Running Server**: Wheels development server should be running (auto-started if needed)
3. **IDE Installation**: Target AI IDE should be installed and configured

## Verification

After setup, verify the integration:

### Check MCP Status
```bash
wheels mcp status
```

### Test Connection
```bash
wheels mcp test
```

### Manual Verification
Visit the MCP endpoint directly:
```bash
curl http://localhost:[port]/wheels/mcp
```

## Troubleshooting

### Common Issues

**1. "Not a Wheels application"**
- Ensure you're in the root directory of a Wheels project
- Check for `/vendor/wheels`, `/config`, and `/app` folders

**2. "Server not running"**
- Start your Wheels server: `server start` (CommandBox)
- Or use `wheels server start`

**3. "Port detection failed"**
- Specify port manually: `--port=8080`
- Check your `server.json` configuration

**4. "IDE not detected"**
- Install the target AI IDE first
- Use `--ide=specific` to configure manually
- Check IDE documentation for configuration paths

### Configuration File Locations

The setup command creates or updates configuration files in these locations:

- **macOS**: `~/.[ide]/config.json`
- **Windows**: `%USERPROFILE%\.[ide]\config.json`
- **Linux**: `~/.[ide]/config.json`

## Advanced Usage

### Custom MCP Server Configuration
You can customize the MCP server behavior in your Wheels application settings:

```cfm
// /config/settings.cfm
set(mcpEnabled=true);
set(mcpAllowedOrigins="*");
set(mcpSessionTimeout=3600);
```

### IDE-Specific Settings
Some IDEs support additional MCP configuration options:

```json
{
  "mcpServers": {
    "wheels": {
      "transport": {
        "type": "http",
        "url": "http://localhost:8080/wheels/mcp"
      },
      "capabilities": {
        "resources": {},
        "tools": {},
        "prompts": {}
      }
    }
  }
}
```

## Security Considerations

- **Development Only**: MCP integration is intended for development environments
- **Local Access**: Default configuration allows localhost access only
- **Authentication**: Uses your Wheels application's existing security model
- **Firewall**: Ensure your development server is not exposed to external networks

## Related Commands

- [`wheels mcp status`](./mcp-status.md) - Check MCP integration status
- [`wheels mcp test`](./mcp-test.md) - Test MCP connection
- [`wheels mcp update`](./mcp-update.md) - Update MCP configuration
- [`wheels mcp remove`](./mcp-remove.md) - Remove MCP integration