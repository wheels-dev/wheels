---
description: >-
  Configure Wheels MCP tools for Claude Code, Cursor, and VS Code. Covers both
  LuCLI stdio transport and HTTP server transport with auto-discovered tools.
---

# MCP Configuration Guide

## Overview

Wheels exposes its development tools through the [Model Context Protocol (MCP)](https://modelcontextprotocol.io/), giving AI coding assistants direct access to code generation, database migrations, testing, project analysis, and framework documentation. This guide covers configuring MCP for the three most popular AI-enabled editors.

### Two Transport Modes

Wheels supports two MCP transports. Choose the one that fits your setup:

| Transport | Command | Requires Running Server | Best For |
|-----------|---------|------------------------|----------|
| **stdio (LuCLI)** | `lucli mcp wheels` | No (for tool discovery) | LuCLI users, simpler config |
| **HTTP** | `http://localhost:[port]/wheels/mcp` | Yes | CommandBox users, existing setups |

**stdio (recommended)**: LuCLI auto-discovers every public command in the Wheels module as an MCP tool. The AI assistant launches `lucli` as a subprocess — no separate server process to manage.

**HTTP**: The Wheels application includes a native CFML MCP server. Your development server must be running for the AI assistant to connect.

## Quick Start

### Option A: LuCLI stdio (recommended)

```bash
# Install LuCLI and the Wheels module
brew install lucli
lucli modules install wheels

# Verify MCP tools are discoverable
lucli mcp wheels
```

Then add the configuration for your IDE (see sections below).

### Option B: HTTP server

```bash
# From your Wheels project root
wheels mcp setup

# This creates .mcp.json and .opencode.json in your project
```

Or start your server and point your IDE at the endpoint:
```
http://localhost:[port]/wheels/mcp
```

## Claude Code

### stdio transport (LuCLI)

Create or edit `.mcp.json` in your project root:

```json
{
  "mcpServers": {
    "wheels": {
      "command": "lucli",
      "args": ["mcp", "wheels"]
    }
  }
}
```

### HTTP transport

Create or edit `.mcp.json` in your project root:

```json
{
  "mcpServers": {
    "wheels": {
      "url": "http://localhost:3000/wheels/mcp",
      "type": "http"
    }
  }
}
```

Replace `3000` with your development server port.

### Verify in Claude Code

After adding the configuration, restart Claude Code and look for the Wheels MCP tools in the tool list. You can verify by asking Claude to list available MCP tools, or run:

```bash
wheels mcp test
```

## Cursor

### stdio transport (LuCLI)

Create or edit `.cursor/mcp.json` in your project root:

```json
{
  "mcpServers": {
    "wheels": {
      "command": "lucli",
      "args": ["mcp", "wheels"]
    }
  }
}
```

### HTTP transport

```json
{
  "mcpServers": {
    "wheels": {
      "url": "http://localhost:3000/wheels/mcp",
      "type": "http"
    }
  }
}
```

### Verify in Cursor

Open Cursor Settings > MCP to confirm the Wheels server appears and shows a green status indicator. Cursor auto-detects `.cursor/mcp.json` on startup.

## VS Code

VS Code supports MCP through extensions. The most common options:

### GitHub Copilot (built-in MCP support)

VS Code 1.99+ with GitHub Copilot supports MCP servers natively. Add to your `.vscode/settings.json`:

```json
{
  "mcp": {
    "servers": {
      "wheels": {
        "command": "lucli",
        "args": ["mcp", "wheels"]
      }
    }
  }
}
```

Or for HTTP transport:

```json
{
  "mcp": {
    "servers": {
      "wheels": {
        "url": "http://localhost:3000/wheels/mcp",
        "type": "http"
      }
    }
  }
}
```

### Continue extension

If using the [Continue](https://continue.dev/) extension, create `.continue/config.json`:

```json
{
  "mcpServers": {
    "wheels": {
      "command": "lucli",
      "args": ["mcp", "wheels"]
    }
  }
}
```

### Cline extension

For [Cline](https://github.com/cline/cline), add to Cline's MCP settings:

```json
{
  "mcpServers": {
    "wheels": {
      "command": "lucli",
      "args": ["mcp", "wheels"]
    }
  }
}
```

## Available MCP Tools

LuCLI auto-discovers all public commands in the Wheels module. Every public function in the module becomes an MCP tool prefixed with `wheels_`. The following tools are available:

### Code Generation

| Tool | Description | Key Parameters |
|------|-------------|---------------|
| `generate` | Generate Wheels components | `type` (model, controller, view, migration, scaffold, mailer, job, test, helper), `name`, `attributes` |
| `develop` | End-to-end workflow: analyze, plan, implement, test, validate | `task` (natural language description) |

**Example**: Ask your AI assistant to "generate a User model with name, email, and role fields" — it calls the `generate` tool with `type=model`, `name=User`, `attributes=name:string,email:string,role:string`.

### Database

| Tool | Description | Key Parameters |
|------|-------------|---------------|
| `migrate` | Run database migrations | `action` (latest, up, down, reset, info) |
| `validate` | Validate models and database schema | `model` (model name or "all") |

### Testing & Analysis

| Tool | Description | Key Parameters |
|------|-------------|---------------|
| `test` | Run Wheels tests | `target` (optional filter), `verbose` |
| `analyze` | Analyze project structure | `target` (models, controllers, routes, migrations, tests, all) |

### Server Management

| Tool | Description | Key Parameters |
|------|-------------|---------------|
| `server` | Manage development server | `action` (start, stop, restart, status) |
| `reload` | Reload the Wheels application | `password` (if required) |

## Available MCP Resources

The HTTP MCP server exposes documentation and project context as readable resources:

### Documentation

| Resource URI | Description |
|-------------|-------------|
| `wheels://docs/manifest` | Documentation index |
| `wheels://docs/models` | Model CRUD, validations, associations |
| `wheels://docs/controllers` | Actions, filters, rendering |
| `wheels://docs/views` | Helpers, form builders, templating |
| `wheels://docs/migrations` | Schema management, migration functions |
| `wheels://docs/routing` | URL routing, RESTful resources |
| `wheels://docs/testing` | TestBox integration, testing utilities |
| `wheels://docs/cli` | CLI commands and generators |
| `wheels://docs/patterns` | Best practices, common patterns |

### Project Context

| Resource URI | Description |
|-------------|-------------|
| `wheels://project/context` | Project structure, models, controllers, config |
| `wheels://project/routes` | All configured application routes |
| `wheels://project/migrations` | Migration status and history |
| `wheels://project/plugins` | Installed plugins and configuration |
| `wheels://project/info` | Wheels version, environment, settings |

### Reference

| Resource URI | Description |
|-------------|-------------|
| `wheels://api/full` | Complete API documentation |
| `wheels://guides/all` | Framework guides and tutorials |
| `wheels://.ai/overview` | AI documentation structure overview |
| `wheels://.ai/cfml/syntax` | CFML language fundamentals |
| `wheels://.ai/wheels/models` | Model development patterns |
| `wheels://.ai/wheels/controllers` | Controller patterns |
| `wheels://.ai/wheels/views` | View and template patterns |
| `wheels://.ai/wheels/patterns` | Common development patterns |

## MCP Prompts

The MCP server provides prompt templates that guide AI assistants through common workflows:

| Prompt | Description |
|--------|-------------|
| `develop` | Complete development workflow with natural language task |
| `generate` | Component generation with type, name, attributes |
| `migrate` | Database migration operations |
| `test` | Test execution with target filtering |
| `server` | Server management |
| `reload` | Application reload |
| `analyze` | Project analysis |
| `model-help` | Contextual help for model development |
| `controller-help` | Contextual help for controller development |
| `migration-help` | Contextual help for writing migrations |

## How Auto-Discovery Works

LuCLI's MCP support automatically discovers tools from installed modules. When you run `lucli mcp wheels`, LuCLI:

1. **Scans the Wheels module** — reads all `public` functions from `Module.cfc`
2. **Generates tool definitions** — each function's name, hint, and parameters become the MCP tool schema
3. **Prefixes with module name** — `generate` becomes `wheels_generate`, `migrate` becomes `wheels_migrate`
4. **Serves via stdio** — the AI editor launches `lucli mcp wheels` as a subprocess and communicates over stdin/stdout using JSON-RPC 2.0

This means any new commands added to the Wheels LuCLI module are automatically available as MCP tools without additional configuration.

## Configuration Examples

### Full-Stack Development Setup

A typical `.mcp.json` combining Wheels with a browser testing tool:

```json
{
  "mcpServers": {
    "wheels": {
      "command": "lucli",
      "args": ["mcp", "wheels"]
    },
    "browsermcp": {
      "command": "npx",
      "args": ["@browsermcp/mcp@latest"]
    }
  }
}
```

### Team Configuration

Commit `.mcp.json` to your repository so all team members get the same MCP setup:

```bash
# .mcp.json is safe to commit — it contains no secrets
git add .mcp.json
git commit -m "Add MCP configuration for AI IDE integration"
```

### Multiple Projects

Each Wheels project has its own `.mcp.json`. When you open a project in your AI editor, it picks up that project's MCP configuration automatically.

For the HTTP transport, each project needs its own port:

```json
{
  "mcpServers": {
    "wheels": {
      "url": "http://localhost:3000/wheels/mcp",
      "type": "http"
    }
  }
}
```

The stdio transport handles this automatically — LuCLI detects the project context from the working directory.

## Security

- **Development only** — do not expose MCP endpoints in production
- **Localhost** — the HTTP server binds to localhost by default
- **No secrets in config** — `.mcp.json` contains only the transport configuration
- **Reload password** — the `reload` tool respects your application's reload password setting

### Settings

Customize MCP behavior in `config/settings.cfm`:

```cfm
set(mcpEnabled=true);
set(mcpAllowedOrigins="localhost,127.0.0.1");
set(mcpSessionTimeout=3600);
```

## Troubleshooting

### LuCLI not found

```
Error: command not found: lucli
```

Install LuCLI via Homebrew (`brew install lucli`) or from [lucli.dev](https://lucli.dev). Ensure it's in your PATH.

### Tools not appearing in IDE

1. Restart your AI editor after adding `.mcp.json`
2. Check the config file is in the correct location (project root for Claude Code, `.cursor/` for Cursor, `.vscode/settings.json` for VS Code)
3. Verify LuCLI can find the Wheels module: `lucli modules list`

### HTTP connection refused

```
Error: Connection refused on localhost:3000
```

Your Wheels development server must be running for HTTP transport. Start it with `wheels server start` or `server start` (CommandBox).

### Tool execution fails

Some tools (migrate, test, reload) proxy HTTP calls to the running Wheels server. Ensure your development server is running even when using stdio transport for these server-dependent tools.

Run diagnostics:
```bash
wheels mcp test --verbose
```

### Wrong port

If your server runs on a non-default port, update `.mcp.json`:
```bash
wheels mcp setup --port=8080 --force
```

Or edit `.mcp.json` manually and replace the port number.

## Related Commands

- [`wheels mcp setup`](./mcp-setup.md) — Auto-generate MCP configuration files
- [`wheels mcp status`](./mcp-status.md) — Check current integration status
- [`wheels mcp test`](./mcp-test.md) — Test MCP connection and tools
- [`wheels mcp update`](./mcp-update.md) — Update existing configuration
- [`wheels mcp remove`](./mcp-remove.md) — Remove MCP integration
