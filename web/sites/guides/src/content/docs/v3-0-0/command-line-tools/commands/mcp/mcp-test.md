---
title: MCP Test
description: >-
  Test MCP (Model Context Protocol) connection and functionality with your AI
  IDE integration.
---

# MCP Test

## Overview

The `wheels mcp test` command verifies that your MCP (Model Context Protocol) integration is working correctly by testing the connection and functionality with configured AI IDEs.

## Usage

```bash
wheels mcp test [options]
```

## Options

| Option | Type | Description |
|--------|------|-------------|
| `--ide` | string | Test specific IDE configuration (`claude`, `cursor`, `continue`, `windsurf`) |
| `--all` | boolean | Test all configured IDEs |
| `--verbose` | boolean | Show detailed test output |

## Examples

### Basic Connection Test
```bash
wheels mcp test
```

### Test Specific IDE
```bash
wheels mcp test --ide=claude
```

### Test All Configured IDEs
```bash
wheels mcp test --all --verbose
```

## Test Results

### Successful Test Output
```
🧪 Testing MCP Integration
==================================================

✅ Server Connection: OK (200ms)
✅ Resource Access: OK (4 resources available)
✅ Tool Execution: OK (4 tools working)
✅ Claude Code Integration: OK
✅ Session Management: OK

All tests passed! MCP integration is working correctly.
```

### Failed Test Output
```
🧪 Testing MCP Integration
==================================================

✅ Server Connection: OK (150ms)
❌ Resource Access: FAILED (timeout)
⚠️  Tool Execution: PARTIAL (2/4 tools working)
❌ Claude Code Integration: FAILED (config invalid)
✅ Session Management: OK

2 tests failed. Run with --verbose for details.
```

## What Gets Tested

### Server Connectivity
- **Connection Test**: Verifies MCP server is accessible
- **Response Time**: Measures server response latency
- **HTTP Status**: Checks for valid HTTP responses
- **JSON-RPC Protocol**: Validates MCP protocol compliance

### Resource Access
- **Resource Listing**: Tests `resources/list` method
- **Resource Reading**: Tests `resources/read` for each resource
- **Content Validation**: Verifies resource content is valid
- **Permission Checks**: Ensures proper access controls

### Tool Functionality
- **Tool Discovery**: Tests `tools/list` method
- **Tool Execution**: Tests `tools/call` for each available tool
- **Parameter Validation**: Checks tool parameter handling
- **Error Handling**: Verifies proper error responses

### IDE Integration
- **Configuration Validation**: Checks IDE config file syntax
- **Connection Testing**: Tests actual IDE-to-server connection
- **Authentication**: Verifies authentication mechanisms
- **Session Persistence**: Tests session management

## Troubleshooting

### Common Test Failures

**1. Server Connection Failed**
```
❌ Server Connection: FAILED (connection refused)
```
**Solutions:**
- Start your Wheels server: `server start`
- Check if port is available
- Verify firewall settings

**2. Resource Access Timeout**
```
❌ Resource Access: FAILED (timeout after 30s)
```
**Solutions:**
- Check server performance
- Verify database connectivity
- Restart the Wheels application

**3. Tool Execution Errors**
```
⚠️ Tool Execution: PARTIAL (wheels_generate failed)
```
**Solutions:**
- Check file permissions
- Verify Wheels installation
- Review application logs

**4. IDE Configuration Issues**
```
❌ Claude Code Integration: FAILED (invalid JSON)
```
**Solutions:**
- Run `wheels mcp setup --ide=claude --force`
- Manually check `~/.claude/config.json`
- Validate JSON syntax

### Verbose Output Example
```bash
wheels mcp test --verbose
```
```
🧪 Testing MCP Integration (Verbose Mode)
==================================================

[1/5] Server Connection Test
├── Connecting to http://localhost:8080/wheels/mcp... ✅ (142ms)
├── Testing JSON-RPC protocol... ✅
├── Checking CORS headers... ✅
└── Validating session support... ✅

[2/5] Resource Access Test
├── Listing available resources... ✅ (4 found)
├── Testing wheels://api/documentation... ✅ (250KB)
├── Testing wheels://guides/all... ✅ (180KB)
├── Testing wheels://project/context... ✅ (15KB)
└── Testing wheels://patterns/common... ✅ (95KB)

[3/5] Tool Functionality Test
├── Discovering available tools... ✅ (4 found)
├── Testing wheels_generate... ✅
├── Testing wheels_migrate... ✅
├── Testing wheels_test... ✅
└── Testing wheels_server... ✅

[4/5] IDE Integration Test
├── Claude Code config... ✅ (~/.claude/config.json valid)
├── Cursor config... ❌ (not configured)
├── Continue config... ❌ (not configured)
└── Windsurf config... ❌ (not configured)

[5/5] Session Management Test
├── Creating new session... ✅
├── Session persistence... ✅
├── Session cleanup... ✅
└── Concurrent sessions... ✅

Test Summary:
✅ Passed: 20
❌ Failed: 0
⚠️  Warnings: 3 (unconfigured IDEs)

Overall Result: ✅ PASS
```

## Test Categories

### Quick Test (Default)
- Basic connectivity
- Resource availability
- Primary IDE configuration

### Full Test (`--all`)
- All IDE configurations
- Comprehensive tool testing
- Performance benchmarks
- Session management

### IDE-Specific Test (`--ide=specific`)
- Focused on single IDE
- Deep configuration validation
- Connection troubleshooting
- Integration verification

## Automated Testing

### CI/CD Integration
```bash
# Exit code 0 for success, non-zero for failure
wheels mcp test --quiet || exit 1
```

### Health Check Scripts
```bash
#!/bin/bash
# MCP health check
if wheels mcp test > /dev/null 2>&1; then
  echo "MCP: Healthy"
else
  echo "MCP: Unhealthy - running diagnostics..."
  wheels mcp test --verbose
fi
```

## Performance Metrics

The test command also provides performance metrics:

- **Connection Latency**: Time to establish MCP connection
- **Resource Load Time**: Time to fetch each resource
- **Tool Execution Time**: Time for each tool to complete
- **Memory Usage**: Server memory consumption during testing

## Related Commands

- [`wheels mcp setup`](/v3-0-0/command-line-tools/commands/mcp/mcp-setup/) - Configure MCP integration
- [`wheels mcp status`](/v3-0-0/command-line-tools/commands/mcp/mcp-status/) - Check MCP status
- [`wheels mcp update`](/v3-0-0/command-line-tools/commands/mcp/mcp-update/) - Update MCP configuration
- [`wheels mcp remove`](/v3-0-0/command-line-tools/commands/mcp/mcp-remove/) - Remove MCP integration