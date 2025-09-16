---
description: >-
  MCP (Model Context Protocol) commands for integrating Wheels with AI coding
  assistants like Claude Code, Cursor, and Continue.
---

# MCP Commands

The MCP (Model Context Protocol) commands enable seamless integration between your Wheels application and AI coding assistants. Wheels includes a **native CFML MCP server** that runs directly within your application - no Node.js required!

## Overview

MCP is a protocol that allows AI coding assistants to interact with your development environment, providing context-aware assistance, code generation, and project management capabilities.

### What MCP Enables
- **Context-Aware AI**: AI assistants understand your Wheels project structure
- **Code Generation**: Generate models, controllers, views, and migrations
- **Real-time Assistance**: Get help with Wheels-specific patterns and best practices
- **Project Management**: Execute CLI commands through your AI assistant
- **Documentation Access**: AI assistants have access to complete Wheels documentation

## Available Commands

### Core Commands
- [`wheels mcp setup`](./mcp-setup.md) - Configure MCP integration for AI IDEs
- [`wheels mcp status`](./mcp-status.md) - Check current MCP integration status
- [`wheels mcp test`](./mcp-test.md) - Test MCP connection and functionality
- [`wheels mcp update`](./mcp-update.md) - Update MCP configuration
- [`wheels mcp remove`](./mcp-remove.md) - Remove MCP integration

## Quick Start

### 1. Initial Setup
```bash
# Auto-configure MCP for detected AI IDEs
wheels mcp setup
```

### 2. Verify Installation
```bash
# Check integration status
wheels mcp status
```

### 3. Test Connection
```bash
# Test MCP functionality
wheels mcp test
```

## Supported AI IDEs

| IDE | Status | Configuration |
|-----|--------|---------------|
| **Claude Code** | ✅ Fully Supported | Auto-configured |
| **Cursor** | ✅ Fully Supported | Auto-configured |
| **Continue** | ✅ Fully Supported | Auto-configured |
| **Windsurf** | ✅ Fully Supported | Auto-configured |

## MCP Server Architecture

### Native CFML Implementation
Wheels includes a built-in MCP server that:
- **Runs in CFML**: No external dependencies or Node.js required
- **Integrated**: Uses your application's existing security and configuration
- **Performant**: Direct execution within your Wheels application
- **Secure**: Respects your application's authentication and authorization

### Server Endpoint
```
http://localhost:[port]/wheels/mcp
```

### Available Resources
- `wheels://api/documentation` - Complete Wheels API documentation
- `wheels://guides/all` - Framework guides and tutorials
- `wheels://project/context` - Current project structure and configuration
- `wheels://patterns/common` - Common Wheels patterns and best practices

### Available Tools
- `wheels_generate` - Generate models, controllers, views, migrations
- `wheels_migrate` - Database migration operations (up, down, latest, reset)
- `wheels_test` - Run Wheels tests and validation
- `wheels_server` - Server management (start, stop, restart, status)

## Common Workflows

### Development Setup
```bash
# Initial project setup with MCP
wheels g app myproject
cd myproject
wheels mcp setup
```

### Team Development
```bash
# Setup MCP for all team members
wheels mcp setup --all

# Check team integration status
wheels mcp status --json
```

### CI/CD Integration
```bash
# Test MCP in automated pipelines
wheels mcp test || exit 1
```

## Configuration Examples

### Claude Code Configuration
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

### Environment-Specific Setup
```bash
# Development environment
wheels mcp setup --port=8080

# Testing environment
wheels mcp setup --port=8081 --ide=cursor
```

## Security Considerations

### Development Only
MCP integration is designed for development environments:
- **Local Access**: Default configuration allows localhost only
- **Authentication**: Uses your Wheels application's security model
- **Firewall**: Ensure development server is not exposed externally

### Best Practices
1. **Use in Development**: Don't enable MCP in production environments
2. **Secure Networks**: Only use on trusted development networks
3. **Regular Updates**: Keep MCP configuration updated
4. **Team Awareness**: Ensure team understands MCP functionality

## Troubleshooting

### Common Issues

**MCP Server Not Found**
- Ensure Wheels development server is running
- Check port configuration with `wheels server status`
- Verify MCP endpoint: `curl http://localhost:port/wheels/mcp`

**IDE Connection Failed**
- Check IDE configuration files
- Restart AI IDE after configuration changes
- Test connection with `wheels mcp test --ide=specific`

**Resource Access Denied**
- Verify Wheels application is properly initialized
- Check file permissions
- Ensure database is accessible

### Getting Help

1. **Check Status**: `wheels mcp status --verbose`
2. **Test Connection**: `wheels mcp test --all --verbose`
3. **Review Logs**: Check Wheels application logs
4. **Reconfigure**: `wheels mcp setup --force`

## Advanced Usage

### Custom MCP Configuration
```cfm
// /config/settings.cfm - Customize MCP behavior
set(mcpEnabled=true);
set(mcpPort=8080);
set(mcpAllowedOrigins="localhost,127.0.0.1");
set(mcpSessionTimeout=3600);
set(mcpDebugMode=false);
```

### Multiple Environment Setup
```bash
# Development
wheels mcp setup --port=8080 --ide=claude

# Testing
wheels mcp setup --port=8081 --ide=cursor

# Integration
wheels mcp setup --port=8082 --ide=continue
```

### Team Configuration Management
```bash
# Export team configuration
wheels mcp status --json > mcp-config.json

# Apply team configuration
wheels mcp setup --config=mcp-config.json
```

## Integration Benefits

### For Developers
- **Faster Development**: AI-assisted code generation
- **Better Documentation**: Contextual help and examples
- **Consistent Patterns**: AI suggests Wheels best practices
- **Reduced Errors**: AI validates against framework conventions

### For Teams
- **Standardization**: Consistent code patterns across team
- **Knowledge Sharing**: AI democratizes framework expertise
- **Onboarding**: New developers get AI assistance
- **Code Quality**: AI suggests improvements and optimizations

### For Projects
- **Productivity**: Faster feature development
- **Maintainability**: Consistent, well-documented code
- **Best Practices**: AI enforces framework conventions
- **Evolution**: Easy to adopt new framework features

## Future Enhancements

The MCP integration continues to evolve with:
- **Enhanced Resource Types**: More project context and documentation
- **Advanced Tools**: Additional CLI command integration
- **IDE-Specific Features**: Optimized integrations for each AI IDE
- **Team Collaboration**: Shared MCP configurations and resources

## Related Documentation

- [Wheels CLI Overview](../README.md)
- [AI Integration Guide](../../../AI_INTEGRATION_GUIDE.md)
- [Development Server](../core/server.md)
- [Code Generation](../generate/README.md)