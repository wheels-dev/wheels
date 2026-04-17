# MCP Tool Reference

Quick reference for the 16 MCP-exposed tools. Tool names are prefixed with the module name: `wheels_` + function name.

> **Note:** rich JSONSchema (types, defaults, required flags, descriptions) is auto-discovered from each function's typed parameters. This reference summarizes each tool's contract; run `tools/list` against a live `wheels mcp wheels` session for the exact current schemas.

## Code generation

### `wheels_generate`
Scaffold Wheels components.

| Param | Type | Required | Description |
|---|---|---|---|
| `type` | string | yes | model \| controller \| view \| migration \| scaffold \| api-resource \| route \| test \| property \| helper \| snippets \| admin |
| `name` | string | yes | Component name (PascalCase for models/controllers) |
| `attributes` | string | no | Space-separated attributes: `name email:string active:boolean` |

Variadic attributes: additional positional args beyond `attributes` are collected as extra attributes.

### `wheels_destroy`
Remove a generated component.

| Param | Type | Required | Description |
|---|---|---|---|
| `name` | string | yes | Component name to destroy |
| `type` | string | no | `resource` (default), `model`, `controller`, `view` |

### `wheels_create`
Create a new application component (typically `create app <name>`).

## Database

### `wheels_migrate`
Run database migrations.

| Param | Type | Required | Description |
|---|---|---|---|
| `action` | string | no | `latest` (default), `up`, `down`, `info` |

### `wheels_seed`
Run database seeds.

| Param | Type | Required | Description |
|---|---|---|---|
| `mode` | string | no | `auto` (default), `convention`, `generate` |
| `environment` | string | no | Target environment (defaults to current) |
| `generate` | boolean | no | Shortcut for `mode=generate` |

### `wheels_db`
Database management.

| Param | Type | Required | Description |
|---|---|---|---|
| `action` | string | yes | `reset`, `status`, `version` |
| `skipSeed` | boolean | no | Skip seeding when `action=reset` |
| `pending` | boolean | no | Show only pending migrations (for `status`) |
| `detailed` | boolean | no | Show detailed version info |

## Testing & validation

### `wheels_test`
Run the test suite.

| Param | Type | Required | Description |
|---|---|---|---|
| `filter` | string | no | Test directory or spec path |
| `reporter` | string | no | `simple` (default), `json`, `junit` |
| `db` | string | no | Database to test against (default: `sqlite`) |
| `verbose` | boolean | no | Verbose output |
| `ci` | boolean | no | CI mode (exit code reflects failures) |
| `core` | boolean | no | Run framework core tests instead of app tests |

### `wheels_validate`
Validate app structure for common errors.

| Param | Type | Required | Description |
|---|---|---|---|
| `target` | string | no | What to validate (default: `all`) |
| `strict` | boolean | no | Fail on warnings |

### `wheels_analyze`
Static analysis: anti-patterns, complexity, code smells.

| Param | Type | Required | Description |
|---|---|---|---|
| `target` | string | no | `all` (default), `models`, `controllers`, `routes`, `config` |

## Project introspection

### `wheels_routes`
List configured routes.

No parameters. Returns method / path / controller#action for every registered route.

### `wheels_info`
Framework version, environment, configuration.

No parameters.

### `wheels_doctor`
Health checks.

| Param | Type | Required | Description |
|---|---|---|---|
| `verbose` | boolean | no | Show all passed checks (default shows only issues) |

### `wheels_stats`
Code statistics.

| Param | Type | Required | Description |
|---|---|---|---|
| `verbose` | boolean | no | Include top 10 largest files |

### `wheels_notes`
Extract annotations (TODO, FIXME, OPTIMIZE).

| Param | Type | Required | Description |
|---|---|---|---|
| `annotations` | string | no | Comma-separated types (default: `TODO,FIXME,OPTIMIZE`) |
| `custom` | string | no | Additional annotation types |

## Operational

### `wheels_reload`
Reload the running Wheels application.

| Param | Type | Required | Description |
|---|---|---|---|
| `password` | string | no | Reload password (auto-resolved from `.env` if omitted) |

### `wheels_upgrade`
Pre-upgrade breaking-change check.

| Param | Type | Required | Description |
|---|---|---|---|
| `to` | string | no | Target version (defaults to latest release) |

## Calling conventions

**MCP invocation** (named args):

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "method": "tools/call",
  "params": {
    "name": "generate",
    "arguments": {"type": "model", "name": "User", "attributes": "email:string active:boolean"}
  }
}
```

**CLI invocation** (positional args; LuCLI auto-binds to typed params):

```bash
wheels generate model User email:string active:boolean
```

Both paths reach the same function body with `arguments.type = "model"`, `arguments.name = "User"`, `arguments.attributes = "email:string active:boolean"`.

## See also

- [overview.md](overview.md) — architecture, auto-discovery, tool surface curation
- [setup.md](setup.md) — IDE configuration
