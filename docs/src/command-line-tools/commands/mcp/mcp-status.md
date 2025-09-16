---
description: >-
  Check the current status of MCP (Model Context Protocol) integration in your
  Wheels application.
---

# MCP Status

## Overview

The `wheels mcp status` command displays the current configuration and status of MCP (Model Context Protocol) integration in your Wheels application. This helps verify that your AI IDE integration is properly configured and working.

## Usage

```bash
wheels mcp status [options]
```

## Options

| Option | Type | Description |
|--------|------|-------------|
| `--json` | boolean | Output status information in JSON format |

## Examples

### Basic Status Check
```bash
wheels mcp status
```
**Output:**
```
🤖 MCP Integration Status
==================================================

✅ Wheels Application: Detected
✅ MCP Server: Running on http://localhost:8080/wheels/mcp
✅ Server Status: Online

IDE Configurations:
├── Claude Code: ✅ Configured (~/.claude/config.json)
├── Cursor: ❌ Not configured
├── Continue: ❌ Not configured
└── Windsurf: ❌ Not configured

MCP Resources Available:
├── wheels://api/documentation - Complete API documentation
├── wheels://guides/all - Framework guides and tutorials
├── wheels://project/context - Current project structure
└── wheels://patterns/common - Common development patterns

MCP Tools Available:
├── wheels_generate - Generate models, controllers, views
├── wheels_migrate - Database migration operations
├── wheels_test - Run application tests
└── wheels_server - Server management operations
```

### JSON Output
```bash
wheels mcp status --json
```
**Output:**
```json
{
  "wheelsApp": true,
  "mcpServer": {
    "running": true,
    "url": "http://localhost:8080/wheels/mcp",
    "port": 8080
  },
  "ideConfigurations": {
    "claude": {
      "configured": true,
      "configPath": "~/.claude/config.json",
      "lastModified": "2025-09-16T10:30:00Z"
    },
    "cursor": {
      "configured": false,
      "configPath": "~/.cursor/config.json"
    },
    "continue": {
      "configured": false,
      "configPath": "~/.continue/config.json"
    },
    "windsurf": {
      "configured": false,
      "configPath": "~/.windsurf/config.json"
    }
  },
  "resources": [
    {
      "uri": "wheels://api/documentation",
      "name": "Complete API documentation"
    },
    {
      "uri": "wheels://guides/all",
      "name": "Framework guides and tutorials"
    },
    {
      "uri": "wheels://project/context",
      "name": "Current project structure"
    },
    {
      "uri": "wheels://patterns/common",
      "name": "Common development patterns"
    }
  ],
  "tools": [
    {
      "name": "wheels_generate",
      "description": "Generate models, controllers, views"
    },
    {
      "name": "wheels_migrate",
      "description": "Database migration operations"
    },
    {
      "name": "wheels_test",
      "description": "Run application tests"
    },
    {
      "name": "wheels_server",
      "description": "Server management operations"
    }
  ]
}
```

## Status Information

### Application Detection
- ✅ **Wheels Application Detected**: Confirms you're in a valid Wheels project
- ❌ **Not a Wheels Application**: Shows if run outside a Wheels project directory

### MCP Server Status
- ✅ **Server Running**: MCP server is active and accessible
- ⚠️ **Server Starting**: Server is in the process of starting up
- ❌ **Server Offline**: Server is not running or not accessible
- ❌ **Connection Failed**: Unable to connect to MCP endpoint

### IDE Configuration Status
For each supported IDE:
- ✅ **Configured**: Configuration file exists and contains valid MCP settings
- ⚠️ **Partial Configuration**: Configuration file exists but may be incomplete
- ❌ **Not Configured**: No MCP configuration found for this IDE
- ❌ **IDE Not Detected**: IDE is not installed on the system

### MCP Resources
Lists all available MCP resources that AI assistants can access:
- **API Documentation**: Complete framework API reference
- **Guides**: Tutorials and best practices
- **Project Context**: Current project structure and settings
- **Patterns**: Common development patterns and examples

### MCP Tools
Lists all available MCP tools that AI assistants can execute:
- **Code Generation**: Create models, controllers, views, migrations
- **Database Operations**: Run migrations, check schema
- **Testing**: Execute tests and validation
- **Server Management**: Control development server

## Troubleshooting

### Common Status Issues

**1. "Not a Wheels application"**
```bash
❌ Wheels Application: Not detected
```
**Solution:** Navigate to your Wheels project root directory

**2. "Server not running"**
```bash
❌ MCP Server: Offline
```
**Solutions:**
- Start your server: `server start` or `wheels server start`
- Check if port is available
- Verify server configuration

**3. "Connection failed"**
```bash
❌ Server Status: Connection failed
```
**Solutions:**
- Check firewall settings
- Verify port number
- Ensure server is accessible on localhost

**4. "IDE not configured"**
```bash
❌ Claude Code: Not configured
```
**Solution:** Run `wheels mcp setup --ide=claude`

### Configuration File Issues

**Invalid Configuration:**
```bash
⚠️ Cursor: Partial configuration (invalid JSON)
```
**Solution:** Run `wheels mcp setup --ide=cursor --force` to recreate

**Missing Configuration:**
```bash
❌ Continue: Configuration file not found
```
**Solution:** Run `wheels mcp setup --ide=continue`

## Monitoring Integration

### Continuous Monitoring
You can use the status command in scripts for monitoring:

```bash
# Check if MCP is healthy
if wheels mcp status --json | jq -r '.mcpServer.running' | grep -q true; then
  echo "MCP integration is healthy"
else
  echo "MCP integration needs attention"
fi
```

### Health Checks
The status command can be used in health check scripts:

```bash
# Simple health check
wheels mcp status > /dev/null && echo "OK" || echo "FAIL"
```

## Related Commands

- [`wheels mcp setup`](./mcp-setup.md) - Configure MCP integration
- [`wheels mcp test`](./mcp-test.md) - Test MCP connection
- [`wheels mcp update`](./mcp-update.md) - Update MCP configuration
- [`wheels mcp remove`](./mcp-remove.md) - Remove MCP integration

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success - MCP integration is healthy |
| 1 | Error - Not a Wheels application |
| 2 | Error - MCP server not accessible |
| 3 | Warning - Partial configuration detected |