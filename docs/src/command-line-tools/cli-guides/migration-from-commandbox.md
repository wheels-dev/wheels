# Migrating from CommandBox to LuCLI

This guide helps existing Wheels developers transition from CommandBox to LuCLI — the new Lucee-native CLI shipping with Wheels 3.1. CommandBox continues to work; LuCLI is an alternative, not a replacement.

## Why LuCLI?

| | CommandBox | LuCLI |
|---|---|---|
| Runtime | Java + CFML engine | Native Lucee |
| Install size | ~200 MB | ~40 MB |
| Startup time | 3–5 s | < 1 s |
| MCP support | No | Built-in (AI editors) |
| Package manager | ForgeBox | Lucee modules |
| Config file | `box.json` / `server.json` | `lucee.json` |
| Wheels module | `wheels-cli` (ForgeBox) | `wheels` (bundled) |

LuCLI is faster, lighter, and includes native MCP support for AI-assisted development with Claude Code, Cursor, and VS Code Copilot.

## Installation

### Remove CommandBox (optional)

You can keep both installed side-by-side. If you want to remove CommandBox:

```bash
# macOS
brew uninstall commandbox

# Windows
choco uninstall commandbox
```

### Install LuCLI

```bash
# macOS
brew install lucli

# Windows
choco install lucli

# Manual (any OS)
# Download from https://github.com/cybersonic/LuCLI/releases
```

### Install the Wheels module

```bash
lucli modules install wheels
```

After installation, the `wheels` command works identically to before:

```bash
wheels new myapp
wheels generate model User
wheels test
```

## Command Mapping

### Core Commands

| Task | CommandBox | LuCLI | Notes |
|------|-----------|-------|-------|
| Create new app | `wheels new myapp` | `wheels new myapp` | Same syntax. LuCLI uses `lucee.json` instead of `box.json` |
| Start server | `box server start` | `wheels start` | LuCLI delegates to its own server command |
| Stop server | `box server stop` | `wheels stop` | |
| Reload app | `wheels reload` | `wheels reload` | Both detect reload password from `.env` |
| Show info | `wheels info` | `wheels info` | LuCLI also shows model count and route count |
| List routes | `wheels routes` | `wheels routes` | Both query the running server |

### Code Generation

Code generation commands are identical between CommandBox and LuCLI. Both share the same templates from `cli/src/templates/`.

| Task | CommandBox | LuCLI |
|------|-----------|-------|
| Model | `wheels generate model User name email` | `wheels generate model User name email` |
| Controller | `wheels generate controller Users index show` | `wheels generate controller Users index show` |
| View | `wheels generate view users index` | `wheels generate view users index` |
| Migration | `wheels generate migration CreateUsers` | `wheels generate migration CreateUsers` |
| Scaffold | `wheels generate scaffold Post title body:text` | `wheels generate scaffold Post title body:text` |
| API resource | `wheels generate api-resource Product name price:decimal` | `wheels generate api-resource Product name price:decimal` |
| Route | `wheels generate route posts` | `wheels generate route posts` |
| Test | `wheels generate test model User` | `wheels generate test model User` |
| Property | `wheels generate property User email:string` | `wheels generate property User email:string` |

**Shorthand aliases** work in LuCLI: `m` (model), `c` (controller), `v` (view), `s` (scaffold), `api` (api-resource), `r` (route), `prop` (property), `h` (helper).

```bash
# These are equivalent:
wheels generate model User name email
wheels generate m User name email
```

### Database Migrations

| Task | CommandBox | LuCLI | Notes |
|------|-----------|-------|-------|
| Migrate to latest | `wheels dbmigrate latest` | `wheels migrate latest` | Command renamed |
| Migrate up one | `wheels dbmigrate up` | `wheels migrate up` | |
| Migrate down one | `wheels dbmigrate down` | `wheels migrate down` | |
| Migration info | `wheels dbmigrate info` | `wheels migrate info` | |

**Key difference**: CommandBox uses `dbmigrate`, LuCLI uses `migrate`.

### Testing

| Task | CommandBox | LuCLI | Notes |
|------|-----------|-------|-------|
| Run all tests | `wheels test run` | `wheels test` | |
| Filter tests | `wheels test run --filter=models` | `wheels test --filter=models` | |
| Verbose output | `wheels test run --debug` | `wheels test --verbose` | Flag renamed |

### Code Analysis

| Task | CommandBox | LuCLI |
|------|-----------|-------|
| Analyze all code | `wheels analyze code` | `wheels analyze` |
| Validate code | `wheels validate` | `wheels validate` |

### MCP (AI Editor Integration)

This is new in LuCLI — CommandBox has no equivalent.

```bash
# Start MCP server for AI editors
lucli mcp wheels
```

Configure in Claude Code (`.claude/claude_project_config.json`):
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

All LuCLI commands are auto-discovered as MCP tools (`wheels_generate`, `wheels_migrate`, `wheels_test`, etc.).

## Configuration Changes

### Project Config: `box.json` → `lucee.json`

CommandBox projects use `box.json` and `server.json`. LuCLI projects use `lucee.json`.

**CommandBox (`box.json` + `server.json`):**
```json
// box.json
{
  "name": "myapp",
  "dependencies": {
    "wheels": "^3.0.0"
  }
}
// server.json
{
  "app": { "cfengine": "lucee@5" },
  "web": {
    "http": { "port": 8080 },
    "webroot": "public/"
  }
}
```

**LuCLI (`lucee.json`):**
```json
{
  "name": "myapp",
  "version": "7.0.2.101",
  "port": 8080,
  "webroot": "./public",
  "openBrowser": true,
  "jvm": {
    "maxMemory": "512m",
    "minMemory": "128m"
  },
  "urlRewrite": {
    "enabled": true,
    "routerFile": "index.cfm"
  },
  "configuration": {
    "datasources": {},
    "mappings": {
      "/wheels": "../vendor/wheels",
      "/app": "../app",
      "/config": "../config",
      "/tests": "../tests"
    }
  }
}
```

**Key differences:**
- Server config and app config merged into one file
- Lucee mappings defined directly (no need for `Application.cfc` mappings)
- JVM settings configured in `lucee.json` instead of CommandBox's admin
- URL rewriting configured declaratively

### Converting an Existing Project

To add LuCLI support to an existing CommandBox project:

1. **Create `lucee.json`** in your project root (alongside `box.json`):

```bash
# LuCLI creates this automatically for new projects, but for existing ones:
cat > lucee.json << 'EOF'
{
  "name": "myapp",
  "port": 8080,
  "webroot": "./public",
  "openBrowser": true,
  "urlRewrite": {
    "enabled": true,
    "routerFile": "index.cfm"
  },
  "configuration": {
    "mappings": {
      "/wheels": "../vendor/wheels",
      "/app": "../app",
      "/config": "../config",
      "/tests": "../tests"
    }
  }
}
EOF
```

2. **Copy your port** from `server.json` into `lucee.json`

3. **Copy datasource mappings** if you defined them in CommandBox's admin — put them in `lucee.json`'s `configuration.datasources`

4. **Keep `box.json`** — both CLIs can coexist. Team members using CommandBox won't be affected.

## What Still Requires CommandBox

Some features are CommandBox-only (LuCLI equivalents are planned for future releases):

| Feature | CommandBox Command | LuCLI Status |
|---------|-------------------|-------------|
| ForgeBox packages | `box install <package>` | Not available — use Lucee modules |
| Interactive console/REPL | `box repl` | `wheels console` (HTTP-backed, requires running server) |
| Plugin management | `wheels plugins install` | Planned |
| Environment switching | `wheels env switch production` | Planned |
| Security scanning | `wheels security scan` | Planned |
| Database shell | `wheels db shell` | Not planned |
| Database backup/restore | `wheels db dump` / `wheels db restore` | Not planned |
| Asset precompilation | `wheels assets precompile` | Not planned |
| Deployment commands | `wheels deploy *` | Not planned |
| Cache/log management | `wheels cache clear` / `wheels log tail` | Not planned |
| Docker integration | `wheels docker *` | Not planned |
| Configuration management | `wheels config *` | Not planned |
| Maintenance mode | `wheels maintenance *` | Not planned |
| Job worker daemon | `wheels jobs work` | Not planned |

**Recommendation**: Keep CommandBox installed alongside LuCLI for these features. Use LuCLI for your daily development loop (generate → migrate → test → reload) and CommandBox for specialized operations.

## Side-by-Side Usage

Both CLIs can coexist in the same project. A typical setup:

```bash
# Daily development — LuCLI (fast startup, MCP support)
wheels new myapp          # Scaffold
wheels generate model User name email
wheels migrate latest
wheels test
wheels start              # Dev server

# Specialized tasks — CommandBox
box install cbsecurity    # ForgeBox packages
wheels db shell           # Database access
wheels deploy push        # Deployment
wheels security scan      # Security audit
```

Both CLIs read from the same `app/`, `config/`, and `tests/` directories. Generated code is identical because they share templates.

## Workflow Comparison

### CommandBox Workflow (before)
```bash
brew install commandbox
box install wheels-cli
wheels new myapp
cd myapp
box server start          # Starts embedded Lucee/Adobe server
wheels generate scaffold Post title body:text
wheels dbmigrate latest
wheels test run
```

### LuCLI Workflow (after)
```bash
brew install lucli
lucli modules install wheels
wheels new myapp
cd myapp
wheels start              # Starts embedded Lucee server
wheels generate scaffold Post title body:text
wheels migrate latest
wheels test
```

The daily workflow is nearly identical. The differences are:
1. **Install**: `commandbox` + `wheels-cli` → `lucli` + `wheels` module
2. **Server**: `box server start` → `wheels start`
3. **Migrations**: `wheels dbmigrate` → `wheels migrate`
4. **Tests**: `wheels test run` → `wheels test`

## Troubleshooting

### "wheels: command not found"

The Wheels module isn't installed:
```bash
lucli modules install wheels
```

### Server won't start

Check that `lucee.json` exists and has a valid `webroot`:
```bash
wheels info    # Shows project detection status
cat lucee.json # Verify config
```

### Migrations fail

LuCLI migrations require a running server (they work via HTTP):
```bash
wheels start   # Start server first
wheels migrate latest
```

### Templates not found

LuCLI reads templates from `vendor/wheels/cli/src/templates/`. Ensure Wheels is vendored:
```bash
ls vendor/wheels/cli/src/templates/
```

### CommandBox commands fail after installing LuCLI

They should work independently. If the `wheels` command resolves to LuCLI instead of CommandBox, use the explicit prefix:
```bash
box wheels dbmigrate latest    # Force CommandBox
lucli wheels migrate latest    # Force LuCLI
```

## Further Reading

- [CLI Overview](../cli-overview.md) — Full CLI documentation
- [Quick Start Guide](../quick-start.md) — Getting started from scratch
- [Template System](template-system.md) — Customize code generation
- [Testing Guide](testing.md) — Write and run tests
