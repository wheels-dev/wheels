# Wheels MCP Server

Wheels ships an MCP (Model Context Protocol) server so AI coding agents — Claude Code, Cursor, OpenCode, Continue, Windsurf — can call the CLI's generators, runners, and introspection tools directly. The canonical surface is the LuCLI stdio MCP server, invoked as `wheels mcp wheels`.

## Architecture

The Wheels CLI binary (`wheels`) is a renamed LuCLI. When an AI IDE is configured with `.mcp.json`, it launches `wheels mcp wheels` as a stdio subprocess on demand. LuCLI's `McpCommand` handles the JSON-RPC transport; tools are auto-discovered from the public functions in `cli/lucli/Module.cfc`.

```
AI IDE (Claude Code / Cursor / ...)
        │
        ▼  stdio subprocess (JSON-RPC)
  wheels mcp wheels
        │
        ▼
  LuCLI McpCommand.java
        │
        ▼  getComponentMetadata("modules.wheels.Module")
  cli/lucli/Module.cfc   ← tool inventory + schemas
```

**Key properties:**

- **No port**, no dev server required for tool discovery or invocation
- **Auto-discovered schemas**: LuCLI reads each public function's parameter metadata (name, type, hint, default, required) and emits JSONSchema per tool
- **Curated surface**: `mcpHiddenTools()` returns a list of public functions to hide from MCP `tools/list` (stateful, interactive, or meta commands stay CLI-only)
- **Dev server bridge**: tools that inspect live app state (`routes`, `info`, `reload`) HTTP-bridge to a running Wheels dev server. Tools that operate on the filesystem (`generate`, `stats`, `notes`) run in-process without a server

## Tool inventory (16 MCP-exposed)

| Tool | What it does |
|---|---|
| `wheels_generate` | Scaffold components (model, controller, view, migration, scaffold, api-resource, route, test, property, helper, snippets, admin) |
| `wheels_migrate` | Run database migrations (latest / up / down / info) |
| `wheels_seed` | Run convention-based or generated seeds |
| `wheels_test` | Run the WheelsTest suite (optional filter + reporter + db) |
| `wheels_reload` | Reload the running Wheels app |
| `wheels_analyze` | Static analysis for anti-patterns, complexity, code smells |
| `wheels_validate` | Validate app structure for common errors |
| `wheels_routes` | List configured routes (method, path, controller#action) |
| `wheels_info` | Framework version, environment, config summary |
| `wheels_destroy` | Remove generated components (inverse of generate) |
| `wheels_doctor` | Health checks (directories, files, config, permissions, database) |
| `wheels_stats` | Code statistics (files, LOC, comments) |
| `wheels_notes` | Extract TODO / FIXME / OPTIMIZE annotations |
| `wheels_db` | Database management (reset, status, version) |
| `wheels_upgrade` | Pre-upgrade breaking-change check |
| `wheels_create` | Create application components (`create app <name>`) |

## Tools hidden from MCP

These remain CLI-only via `mcpHiddenTools()`:

- `mcp` — meta command (shows MCP setup instructions)
- `d` — alias for `destroy` (avoids duplicate surface)
- `new` — scaffolds a whole new Wheels project (too destructive for an agent to do unprompted)
- `console` — interactive CFML REPL (not usable over stdio JSON-RPC)
- `start` / `stop` — dev server process lifecycle (stateful, side-effectful)
- `browser` — multi-step browser testing flow

All are reachable as CLI subcommands (`wheels start`, `wheels new myapp`, etc.) — this filter is purely about which tools an AI agent sees.

## Auto-discovery: how schemas are generated

LuCLI walks each public function's parameter metadata and emits a JSONSchema. Example:

```cfm
/**
 * hint: Generate Wheels components (model, controller, view, ...)
 * @type Component type
 * @name Component name
 * @attributes Space-separated attributes
 */
public string function generate(
    string type = "",
    string name = "",
    string attributes = ""
) { ... }
```

becomes:

```json
{
  "name": "generate",
  "description": "Generate Wheels components (model, controller, view, ...)",
  "inputSchema": {
    "type": "object",
    "properties": {
      "type": {"type": "string", "description": "Component type"},
      "name": {"type": "string", "description": "Component name"},
      "attributes": {"type": "string", "description": "Space-separated attributes"}
    },
    "additionalProperties": false
  }
}
```

Required parameters (CFML `required` attribute) appear in the `required` array. Defaults appear as `default` on each property.

## Transport details

- **Stdio JSON-RPC**: one message per line, newline-delimited. Server must never emit non-protocol data to stdout.
- **Output capture**: LuCLI redirects `System.out` / `System.err` / its own `StringOutput` streams to a buffer during each tool call. `BaseModule.out()` writes via dynamic `createObject("java","java.lang.System").out.println(...)` so the capture sees the output.
- **Initialize handshake**: protocol version `2024-11-05`; server advertises `tools` capability only (no `resources` or `prompts`).

## Legacy HTTP MCP (deprecated)

A legacy HTTP endpoint at `http://localhost:<port>/wheels/mcp` still exists for backward compatibility but is deprecated. It emits a one-time warning to the `wheels_mcp` log on first request and advertises `deprecated: true` in its `serverInfo` handshake. Use `wheels mcp setup --force` to migrate projects from HTTP to stdio config.

## See also

- [setup.md](setup.md) — configure `.mcp.json` / `.opencode.json` for your AI IDE
- [tool-reference.md](tool-reference.md) — quick reference for each of the 16 tools
- [../../docs/command-line-tools/commands/mcp/mcp-configuration-guide.md](../../../docs/src/command-line-tools/commands/mcp/mcp-configuration-guide.md) — per-IDE configuration details
