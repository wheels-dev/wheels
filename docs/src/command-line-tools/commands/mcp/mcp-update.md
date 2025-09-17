---
description: >-
  Update MCP (Model Context Protocol) configuration and settings for AI IDE
  integration.
---

# MCP Update

## Overview

The `wheels mcp update` command updates your existing MCP (Model Context Protocol) configuration to ensure compatibility with the latest AI IDE versions and MCP protocol changes.

## Usage

```bash
wheels mcp update [options]
```

## Options

| Option | Type | Description |
|--------|------|-------------|
| `--ide` | string | Update specific IDE configuration (`claude`, `cursor`, `continue`, `windsurf`) |
| `--all` | boolean | Update all configured IDEs |
| `--backup` | boolean | Create backup of existing configurations (default: true) |
| `--noBackup` | boolean | Skip creating configuration backups |

## Examples

### Update All Configurations
```bash
wheels mcp update
```

### Update Specific IDE
```bash
wheels mcp update --ide=claude
```

### Update Without Backup
```bash
wheels mcp update --noBackup
```

## What Gets Updated

### Configuration Schema
- **Protocol Version**: Updates to latest MCP protocol version
- **Capability Declaration**: Adds new MCP capabilities
- **Transport Settings**: Optimizes connection parameters
- **Security Settings**: Updates authentication methods

### URL and Endpoint Updates
- **Server URL**: Updates MCP server endpoint if changed
- **Port Detection**: Refreshes port detection logic
- **Path Updates**: Updates MCP resource and tool paths

### IDE-Specific Updates
- **Claude Code**: Updates for latest Claude Code versions
- **Cursor**: Compatibility with new Cursor releases
- **Continue**: Support for Continue protocol changes
- **Windsurf**: Integration with Windsurf updates

## Update Process

### Backup Creation
```
📦 Creating Configuration Backups
==================================================

✅ Claude Code config backed up to ~/.claude/config.json.bak.2025-09-16
✅ Cursor config backed up to ~/.cursor/config.json.bak.2025-09-16

Backups created successfully.
```

### Configuration Update
```
🔄 Updating MCP Configuration
==================================================

✅ Claude Code: Updated (~/.claude/config.json)
  ├── Protocol version: 2024-11-05 → 2024-12-01
  ├── Added capability: prompts
  └── Updated transport settings

✅ Cursor: Updated (~/.cursor/config.json)
  ├── Protocol version: 2024-11-05 → 2024-12-01
  └── Added session management

Configuration update completed successfully.
```

## Version Compatibility

### MCP Protocol Versions
- **2024-11-05**: Initial MCP protocol support
- **2024-12-01**: Added prompts capability
- **2025-01-15**: Enhanced session management
- **Latest**: Always updates to current version

### IDE Version Support
| IDE | Minimum Version | Recommended Version |
|-----|-----------------|-------------------|
| Claude Code | 1.0.0 | Latest |
| Cursor | 0.28.0 | Latest |
| Continue | 0.8.0 | Latest |
| Windsurf | 1.0.0 | Latest |

## Configuration Changes

### Before Update (Example)
```json
{
  "mcpServers": {
    "wheels": {
      "transport": {
        "type": "http",
        "url": "http://localhost:8080/wheels/mcp"
      }
    }
  }
}
```

### After Update (Example)
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
      },
      "protocolVersion": "2024-12-01",
      "sessionManagement": {
        "enabled": true,
        "timeout": 3600
      }
    }
  }
}
```

## Troubleshooting Updates

### Common Update Issues

**1. Backup Creation Failed**
```
❌ Failed to create backup for Claude Code config
```
**Solutions:**
- Check file permissions
- Ensure sufficient disk space
- Use `--noBackup` to skip backup creation

**2. Configuration Lock**
```
❌ Configuration file is locked by another process
```
**Solutions:**
- Close the AI IDE
- Check for file locks
- Run as administrator (Windows)

**3. Invalid Existing Configuration**
```
⚠️ Existing configuration has syntax errors
```
**Solutions:**
- Review backup file
- Use `wheels mcp setup --force` to recreate
- Manually fix JSON syntax errors

### Rollback Process
If update causes issues, you can rollback:

```bash
# Restore from backup
cp ~/.claude/config.json.bak.2025-09-16 ~/.claude/config.json

# Or recreate from scratch
wheels mcp setup --ide=claude --force
```

## Update Notifications

### When to Update
- New AI IDE versions are released
- MCP protocol updates are available
- Wheels framework updates include MCP changes
- Configuration issues are detected

### Automatic Update Checks
The update command can check for available updates:

```bash
# Check for available updates
wheels mcp update --check-only
```

```
🔍 Checking for MCP Updates
==================================================

✅ Current Protocol Version: 2024-11-05
📦 Available Update: 2024-12-01
  ├── Added prompts capability
  ├── Enhanced session management
  └── Improved error handling

Run 'wheels mcp update' to apply updates.
```

## Best Practices

### Before Updating
1. **Test Current Setup**: Run `wheels mcp test` to ensure current config works
2. **Backup Manually**: Create manual backups of important configurations
3. **Check IDE Version**: Ensure your AI IDE is up to date
4. **Review Changes**: Check what changes the update will make

### After Updating
1. **Test Integration**: Run `wheels mcp test` to verify updates
2. **Check IDE Connection**: Verify AI IDE can still connect
3. **Review Logs**: Check for any error messages
4. **Update Documentation**: Update any custom documentation

## Scheduling Updates

### Automated Updates
You can set up automated MCP configuration updates:

```bash
# Add to cron job (daily check)
0 9 * * * cd /path/to/wheels/project && wheels mcp update --check-only
```

### Development Team Updates
For development teams, coordinate updates:

```bash
# Team update script
#!/bin/bash
echo "Updating MCP configuration for all team members..."
wheels mcp update --all --backup
wheels mcp test --verbose
```

## Related Commands

- [`wheels mcp setup`](./mcp-setup.md) - Initial MCP configuration
- [`wheels mcp status`](./mcp-status.md) - Check current status
- [`wheels mcp test`](./mcp-test.md) - Test MCP functionality
- [`wheels mcp remove`](./mcp-remove.md) - Remove MCP integration