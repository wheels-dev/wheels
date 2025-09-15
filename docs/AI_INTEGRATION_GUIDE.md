# AI Integration Guide for Wheels Framework

This guide explains how to integrate AI coding assistants with the Wheels framework for enhanced development productivity.

## Table of Contents
- [Overview](#overview)
- [Available Endpoints](#available-endpoints)
- [MCP Server Setup](#mcp-server-setup)
- [Tool-Specific Integration](#tool-specific-integration)
- [Best Practices](#best-practices)
- [Troubleshooting](#troubleshooting)

## Overview

Wheels provides multiple integration points for AI coding assistants:

1. **JSON API Endpoints** - RESTful endpoints serving documentation in JSON format
2. **MCP Server** - Model Context Protocol server for deep IDE integration
3. **CLAUDE.md Files** - Static documentation automatically loaded by Claude Code
4. **Project Context API** - Dynamic project analysis endpoints

## Available Endpoints

All endpoints require the Wheels development server to be running (`wheels server start`).

### Core Documentation Endpoints

#### 1. AI-Optimized Documentation
```
GET /wheels/ai
```
Returns comprehensive documentation optimized for AI consumption.

**Parameters:**
- `context` - Filter documentation by context (all, model, controller, view, migration, routing, testing)
- `format` - Response format (json)

**Example:**
```bash
curl http://localhost:60000/wheels/ai?context=model
```

#### 2. Documentation Manifest
```
GET /wheels/ai?mode=manifest
```
Returns a manifest of available documentation chunks with descriptions and endpoints.

**Example Response:**
```json
{
  "chunks": [
    {
      "id": "models",
      "name": "Model Documentation",
      "endpoint": "/wheels/ai?mode=chunk&id=models",
      "contexts": ["model", "database", "validation"]
    }
  ]
}
```

#### 3. Project Context
```
GET /wheels/ai?mode=project
```
Analyzes and returns current project structure including:
- Existing models and controllers
- Database configuration
- Migration status
- Installed plugins
- Detected conventions

#### 4. Documentation Chunks
```
GET /wheels/ai?mode=chunk&id={chunkId}
```
Returns specific documentation chunks for focused assistance.

**Available Chunk IDs:**
- `models` - Model documentation and patterns
- `controllers` - Controller documentation and RESTful patterns
- `views` - View helpers and templating
- `migrations` - Database migration documentation
- `routing` - URL routing and resources
- `testing` - Testing framework documentation
- `cli` - Command-line interface reference
- `patterns` - Common implementation patterns

#### 5. System Information
```
GET /wheels/ai?mode=info
```
Returns comprehensive system configuration including:
- Server and framework versions
- Environment settings
- CSRF and CORS configuration
- Database configuration
- Framework settings

#### 6. Routes Information
```
GET /wheels/ai?mode=routes
```
Returns complete routing table including:
- Application routes
- Internal framework routes
- Route patterns and methods
- Named routes and RESTful resources

#### 7. Migration Status
```
GET /wheels/ai?mode=migrations
```
Returns database migration information:
- Current migration version
- Available migrations
- Migration status (migrated/pending)
- Migration files and details

#### 8. Plugin Information
```
GET /wheels/ai?mode=plugins
```
Returns plugin ecosystem details:
- Loaded plugins and metadata
- Incompatible plugins
- Plugin dependencies
- Plugin configuration

### Development Server Endpoints with JSON Support

These endpoints now support JSON format for AI consumption:

```
GET /wheels/info?format=json       # System configuration
GET /wheels/routes?format=json     # Application routes
GET /wheels/migrator?format=json   # Migration status
GET /wheels/plugins?format=json    # Plugin information
GET /wheels/tests/{type}?format=json # Test results (type: app|core)
```

### Legacy Endpoints

These endpoints are also available for compatibility:

```
GET /wheels/api?format=json       # Full API documentation
GET /wheels/guides?format=json    # Framework guides
```

## MCP Server Setup

The Model Context Protocol (MCP) server enables deep integration with AI-powered IDEs.

### Installation

1. **Install Dependencies:**
   ```bash
   cd /path/to/wheels
   npm install @modelcontextprotocol/sdk
   ```

2. **Configure Your IDE:**

   #### Claude Code
   Add to your Claude Code settings:
   ```json
   {
     "mcpServers": {
       "wheels": {
         "command": "node",
         "args": ["/path/to/wheels/mcp-server.js"],
         "env": {
           "WHEELS_PROJECT_PATH": "${workspaceFolder}",
           "WHEELS_DEV_SERVER": "http://localhost:60000"
         }
       }
     }
   }
   ```

   #### Cursor
   Add to `.cursor/mcp.json`:
   ```json
   {
     "servers": {
       "wheels": {
         "command": "node",
         "args": ["mcp-server.js"],
         "cwd": "/path/to/wheels"
       }
     }
   }
   ```

   #### Continue
   Add to `.continue/config.json`:
   ```json
   {
     "mcpServers": [
       {
         "name": "wheels",
         "command": "node /path/to/wheels/mcp-server.js"
       }
     ]
   }
   ```

### Available MCP Resources

Once configured, the following resources are available:

- `wheels://api/documentation` - Complete API documentation
- `wheels://guides/all` - All framework guides
- `wheels://project/context` - Current project analysis
- `wheels://patterns/common` - Common patterns and examples

### Available MCP Tools

The MCP server provides these tools:

**Code Generation & Management:**
- `wheels_generate` - Generate models, controllers, scaffolds, migrations
- `wheels_migrate` - Run database migrations
- `wheels_test` - Execute tests
- `wheels_server` - Manage development server
- `wheels_reload` - Reload the application

**Information & Analysis:**
- `wheels_info` - Get system configuration and environment details
- `wheels_routes` - Inspect application routes and URL patterns
- `wheels_plugins` - List and analyze installed plugins
- `wheels_test_status` - Check test execution results

## Tool-Specific Integration

### Claude Code

Claude Code automatically loads `CLAUDE.md` files in your project root. The file includes:
- Quick start commands
- Framework architecture overview
- Common patterns and examples
- Links to live documentation endpoints

**Best Practices:**
1. Keep dev server running for live documentation
2. Use focused contexts when asking for help
3. Reference specific files using `path:line` format

### GitHub Copilot

1. **Add Comments with Wheels Patterns:**
   ```cfm
   // Wheels Model with validations and associations
   component extends="Model" {
   ```

2. **Reference Documentation in Comments:**
   ```cfm
   // See: /wheels/ai?mode=chunk&id=models
   ```

3. **Use Consistent Naming:**
   - Models: Singular (User, Product)
   - Controllers: Plural (Users, Products)
   - Tables: Plural lowercase (users, products)

### Cursor / Windsurf

1. Configure MCP server (see MCP Server Setup)
2. Use `@wheels` to reference documentation
3. Enable "Include project context" for better suggestions

### Custom AI Tools

For custom integrations, use the JSON endpoints directly:

```python
import requests
import json

# Get project context
response = requests.get('http://localhost:60000/wheels/ai?mode=project')
project = response.json()

# Get specific documentation
response = requests.get('http://localhost:60000/wheels/ai?mode=chunk&id=models')
model_docs = response.json()

# Use with your AI provider
from openai import OpenAI
client = OpenAI()

completion = client.chat.completions.create(
    model="gpt-4",
    messages=[
        {"role": "system", "content": f"You are helping with a Wheels project: {json.dumps(project)}"},
        {"role": "user", "content": "Help me create a User model"}
    ]
)
```

## Best Practices

### 1. Context Management

**DO:**
- Start sessions by fetching project context
- Use focused documentation chunks for specific tasks
- Reference the manifest to discover available resources

**DON'T:**
- Load all documentation at once (wastes context)
- Ignore project-specific conventions
- Generate code without understanding existing patterns

### 2. Code Generation

**DO:**
- Use Wheels CLI generators when possible
- Follow detected naming conventions
- Test generated code immediately

**DON'T:**
- Create files manually when generators exist
- Ignore existing code style
- Skip validation and testing

### 3. Documentation Usage

**Efficient Context Usage:**
```javascript
// Good - Focused request
GET /wheels/ai?context=model

// Bad - Loading everything
GET /wheels/api?format=json  // Too much data
```

**Task-Based Loading:**
- Working on models? Load: `/wheels/ai?mode=chunk&id=models`
- Building APIs? Load: `/wheels/ai?context=controller`
- Writing migrations? Load: `/wheels/ai?mode=chunk&id=migrations`

### 4. Development Workflow

1. **Start Development Server:**
   ```bash
   wheels server start
   ```

2. **Check Project Context:**
   ```bash
   curl http://localhost:60000/wheels/ai?mode=project
   ```

3. **Load Relevant Documentation:**
   ```bash
   curl http://localhost:60000/wheels/ai?mode=manifest
   # Then load specific chunks as needed
   ```

4. **Generate Code:**
   ```bash
   wheels g model User name:string,email:string
   ```

5. **Test Changes:**
   ```bash
   wheels test run
   ```

## Troubleshooting

### Common Issues

#### 1. Endpoints Return 404
**Solution:** Ensure dev server is running: `wheels server start`

#### 2. MCP Server Not Connecting
**Solution:** Check Node.js version (>= 16) and install dependencies:
```bash
npm install @modelcontextprotocol/sdk
```

#### 3. Project Context Empty
**Solution:** Verify you're in a Wheels project directory with proper structure

#### 4. Documentation Out of Date
**Solution:** Reload the application:
```bash
curl "http://localhost:60000/?reload=true&password=yourpassword"
```

### Debug Mode

Enable debug output for troubleshooting:

```bash
# For endpoints
curl http://localhost:60000/wheels/ai?debug=true

# For MCP server
DEBUG=* node mcp-server.js
```

### Getting Help

1. Check the main documentation: `/wheels/guides?format=json`
2. Review common patterns: `/wheels/ai?mode=chunk&id=patterns`
3. Analyze your project: `/wheels/ai?mode=project`
4. Consult the Wheels community forums

## Advanced Integration

### Creating Custom Documentation Chunks

Add custom chunks by extending the AI endpoint:

```cfm
// In your app/controllers/Wheels.cfc
function ai() {
    super.ai();

    // Add custom chunk
    if (request.wheels.params.id == "custom") {
        local.customDocs = {
            "patterns": getCustomPatterns(),
            "helpers": getCustomHelpers()
        };
        writeOutput(serializeJSON(local.customDocs));
        abort;
    }
}
```

### Webhook Integration

For CI/CD integration, create webhooks that notify AI tools of changes:

```cfm
// app/controllers/Webhooks.cfc
function aiNotify() {
    local.changes = analyzeGitChanges();
    local.notification = {
        "event": "code_change",
        "changes": local.changes,
        "documentation": "/wheels/ai?mode=project"
    };

    // Notify AI service
    http url="https://ai-service.example.com/webhook"
         method="post"
         body=serializeJSON(local.notification);
}
```

### Performance Optimization

For large projects, implement caching:

```cfm
// Cache documentation for 5 minutes
function getCachedDocs(context) {
    local.cacheKey = "ai_docs_#arguments.context#";

    if (!cacheKeyExists(local.cacheKey)) {
        local.docs = generateDocs(arguments.context);
        cachePut(local.cacheKey, local.docs, createTimeSpan(0,0,5,0));
    }

    return cacheGet(local.cacheKey);
}
```

## Contributing

To improve AI integration for Wheels:

1. Test with different AI tools and report issues
2. Contribute patterns and examples
3. Suggest new documentation chunks
4. Share integration configurations

Submit contributions to: https://github.com/wheels-dev/wheels

## Version History

- **1.0.0** - Initial AI integration with JSON endpoints
- **1.1.0** - Added MCP server support
- **1.2.0** - Enhanced chunking and project context
- **1.3.0** - Added pattern library and examples

---

*Last Updated: [Current Date]*
*Wheels Version: 3.0.0+*