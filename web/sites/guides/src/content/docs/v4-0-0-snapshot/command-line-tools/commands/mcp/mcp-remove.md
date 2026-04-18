---
title: MCP Remove
description: >-
  Remove MCP (Model Context Protocol) integration and clean up AI IDE
  configurations.
---

# MCP Remove

## Overview

The `wheels mcp remove` command safely removes MCP (Model Context Protocol) integration from your AI IDEs and cleans up associated configuration files.

## Usage

```bash
wheels mcp remove [options]
```

## Options

| Option | Type | Description |
|--------|------|-------------|
| `--ide` | string | Remove from specific IDE (`claude`, `cursor`, `continue`, `windsurf`) |
| `--all` | boolean | Remove from all configured IDEs |
| `--backup` | boolean | Create backup before removal (default: true) |
| `--clean` | boolean | Remove all MCP-related files completely |
| `--confirm` | boolean | Skip confirmation prompts |

## Examples

### Remove from All IDEs
```bash
wheels mcp remove
```

### Remove from Specific IDE
```bash
wheels mcp remove --ide=claude
```

### Complete Cleanup
```bash
wheels mcp remove --all --clean --confirm
```

## Removal Process

### Standard Removal
```
🗑️  Removing MCP Integration
==================================================

Creating backups...
✅ Claude Code config backed up to ~/.claude/config.json.bak.2025-09-16

Removing MCP configuration...
✅ Removed MCP server "wheels" from Claude Code config
✅ Preserved other Claude Code settings

MCP integration removed successfully.
AI IDEs will no longer connect to your Wheels application.
```

### Complete Cleanup
```
🧹 Complete MCP Cleanup
==================================================

Creating backups...
✅ Configuration files backed up

Removing MCP configurations...
✅ Claude Code: MCP server "wheels" removed
✅ Cursor: MCP server "wheels" removed
✅ Continue: Not configured (skipped)
✅ Windsurf: Not configured (skipped)

Cleaning up MCP files...
✅ Removed ~/.wheels/mcp-cache/
✅ Removed temporary MCP files

Complete cleanup finished.
```

## What Gets Removed

### IDE Configuration Changes
- **MCP Server Entries**: Removes Wheels MCP server from IDE configs
- **Transport Settings**: Cleans up HTTP transport configuration
- **Capability Declarations**: Removes MCP capability settings
- **Session Management**: Removes MCP session configuration

### Configuration Preservation
The removal process preserves:
- **Other MCP Servers**: Keeps other MCP server configurations
- **IDE Settings**: Maintains all non-MCP IDE settings
- **Extensions**: Preserves other IDE extensions and plugins
- **Workspace Settings**: Keeps workspace-specific configurations

### File Cleanup (with --clean)
- **Cache Files**: Removes MCP cache and temporary files
- **Log Files**: Cleans up MCP-related log files
- **Backup Files**: Optionally removes old backup files

## Safety Features

### Backup Creation
Before removal, the command creates backups:
```
📦 Backup Locations:
├── Claude Code: ~/.claude/config.json.bak.2025-09-16
├── Cursor: ~/.cursor/config.json.bak.2025-09-16
└── Removal log: ~/.wheels/mcp-removal.log
```

### Confirmation Prompts
```bash
wheels mcp remove
```
```
⚠️  This will remove MCP integration from:
   ├── Claude Code ✅ (configured)
   ├── Cursor ❌ (not configured)
   ├── Continue ❌ (not configured)
   └── Windsurf ❌ (not configured)

Are you sure you want to continue? [y/N]:
```

### Dry Run Mode
```bash
wheels mcp remove --dry-run
```
```
🔍 MCP Removal Preview (Dry Run)
==================================================

Would remove from:
├── Claude Code: ~/.claude/config.json
  └── Remove MCP server "wheels"
├── Cursor: Not configured (skip)
├── Continue: Not configured (skip)
└── Windsurf: Not configured (skip)

No changes made (dry run mode).
Use 'wheels mcp remove --confirm' to execute.
```

## Troubleshooting Removal

### Common Issues

**1. Configuration File Locked**
```
❌ Cannot modify Claude Code config (file locked)
```
**Solutions:**
- Close Claude Code
- Check for file permissions
- Run as administrator (Windows)

**2. Backup Creation Failed**
```
❌ Failed to create backup for config
```
**Solutions:**
- Check disk space
- Verify file permissions
- Use `--backup=false` to skip backups

**3. Partial Removal**
```
⚠️ Partial removal completed (1 file failed)
```
**Solutions:**
- Check the removal log
- Manually complete remaining cleanup
- Re-run with `--clean` flag

## Recovery Options

### Restoring from Backup
If you need to restore MCP integration:

```bash
# Restore specific IDE
cp ~/.claude/config.json.bak.2025-09-16 ~/.claude/config.json

# Or re-setup from scratch
wheels mcp setup --ide=claude
```

### Partial Recovery
If you only want to restore certain configurations:

```bash
# View backup contents
cat ~/.claude/config.json.bak.2025-09-16

# Manually merge desired settings
```

## Post-Removal Verification

### Verify Removal
```bash
wheels mcp status
```
```
🤖 MCP Integration Status
==================================================

❌ Wheels Application: Detected (MCP disabled)
❌ MCP Server: Not configured

IDE Configurations:
├── Claude Code: ❌ Not configured
├── Cursor: ❌ Not configured
├── Continue: ❌ Not configured
└── Windsurf: ❌ Not configured

MCP integration is not active.
```

### Test IDE Behavior
After removal:
1. **Restart AI IDEs**: Ensure they load new configuration
2. **Check Connection**: Verify IDEs no longer try to connect to Wheels
3. **Review Logs**: Check for any connection error messages
4. **Test Other Features**: Ensure other IDE features still work

## Complete Cleanup Checklist

When using `--clean`, the command removes:

- [ ] MCP server configurations from all IDEs
- [ ] Wheels-specific MCP cache files
- [ ] Temporary MCP session files
- [ ] MCP connection logs
- [ ] Old backup files (optional)

## Re-enabling MCP

To re-enable MCP integration after removal:

```bash
# Fresh setup
wheels mcp setup

# Or restore from backup
cp ~/.claude/config.json.bak.2025-09-16 ~/.claude/config.json
```

## Security Considerations

### Why Remove MCP
- **Security**: Disable AI IDE access to development server
- **Privacy**: Remove potential data access points
- **Performance**: Reduce server load from MCP requests
- **Cleanup**: Remove unused configurations

### Safe Removal
- **Backup First**: Always create backups before removal
- **Test Thoroughly**: Verify IDEs work correctly after removal
- **Document Changes**: Keep record of what was removed
- **Team Communication**: Inform team members of MCP removal

## Related Commands

- [`wheels mcp setup`](/v4-0-0-snapshot/command-line-tools/commands/mcp/mcp-setup/) - Set up MCP integration
- [`wheels mcp status`](/v4-0-0-snapshot/command-line-tools/commands/mcp/mcp-status/) - Check MCP status
- [`wheels mcp test`](/v4-0-0-snapshot/command-line-tools/commands/mcp/mcp-test/) - Test MCP connection
- [`wheels mcp update`](/v4-0-0-snapshot/command-line-tools/commands/mcp/mcp-update/) - Update MCP configuration