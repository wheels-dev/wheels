# Wheels LuCLI Module — Implementation Plan

## Status

**Phase 1: Complete** — Binary name detection PR ([cybersonic/LuCLI#39](https://github.com/cybersonic/LuCLI/pull/39)), `lucee.json`, module skeleton (`Module.cfc`, `module.json`, `services/Helpers.cfc`).

Phases 2–4 below cover the remaining work to ship LuCLI as the recommended CLI in Wheels 3.1.

---

## Phase 2: Build Out the Wheels Module

### 2A: Service Layer Extraction

The CommandBox CLI has 16 service CFCs in `cli/src/models/` that use WireBox DI (`property inject="..."`). The LuCLI module needs standalone versions that work without DI.

**Strategy**: Create `cli/lucli/services/` versions that instantiate dependencies directly. Reuse business logic; only change wiring.

| CommandBox Service | LuCLI Equivalent | Priority | Notes |
|---|---|---|---|
| `CodeGenerationService.cfc` | `services/CodeGen.cfc` | P1 | Template rendering, file creation |
| `TemplateService.cfc` | `services/Templates.cfc` | P1 | `{{variable}}` substitution from `cli/src/templates/` |
| `MigrationService.cfc` | (HTTP to server) | P1 | Already in Module.cfc via `makeHttpRequest()` |
| `TestService.cfc` | (HTTP to server) | P1 | Already in Module.cfc via `makeHttpRequest()` |
| `ScaffoldService.cfc` | `services/Scaffold.cfc` | P1 | Orchestrates model+controller+view+migration+route |
| `Helpers.cfc` | `services/Helpers.cfc` | Done | Pluralize/singularize, timestamps |
| `AnalysisService.cfc` | `services/Analysis.cfc` | P2 | Code analysis, anti-pattern detection |
| `MCPService.cfc` | `services/MCP.cfc` | P2 | MCP-over-stdio tool definitions |
| `EnvironmentService.cfc` | Defer | P3 | Environment switching |
| `SecurityService.cfc` | Defer | P3 | Security scanning |
| `OptimizationService.cfc` | Defer | P3 | Performance optimization |
| `PluginService.cfc` | Defer | P3 | Plugin management |
| `DetailOutputService.cfc` | Defer | P3 | Verbose output formatting |
| `SharedParameters.cfc` | Not needed | — | CommandBox-specific |
| `BaseCommand.cfc` | Not needed | — | CommandBox-specific |
| `TestMigrationService.cfc` | Not needed | — | Test helper |

**Key decisions**:
- Migration, test, reload, routes — stay HTTP-based (hit running server). No service extraction needed.
- Generate, scaffold, new — file-based. Need service extraction.
- Templates live in `cli/src/templates/` and are shared between CommandBox and LuCLI.

### 2B: Generator Commands (P1)

Complete the generator subcommands in `Module.cfc`. Current state: skeleton implementations exist for model, controller, view, migration, scaffold.

| Generator | Current State | Work Needed |
|---|---|---|
| `generate model` | Basic implementation | Wire to CodeGen service, use actual templates |
| `generate controller` | Basic implementation | Wire to CodeGen service, use actual templates |
| `generate view` | Basic implementation | Wire to CodeGen service, use actual templates |
| `generate migration` | Basic implementation | Wire to CodeGen service, timestamps |
| `generate scaffold` | Basic implementation | Orchestrate all generators + route |
| `generate app` | Not started | Scaffold full project structure with `lucee.json` |
| `generate route` | Not started | Append to `config/routes.cfm` |
| `generate test` | Not started | Create test spec file |
| `generate property` | Not started | Add property to existing model |
| `generate api-resource` | Not started | API-only controller + model |
| `generate helper` | Not started | App helper file |
| `generate snippets` | Not started | Copy snippet templates |

**Approach**: Start with model → controller → view → migration → scaffold (the happy path). These five generators cover 90% of usage. The rest are stretch goals.

### 2C: Server-Dependent Commands (P1)

These already work via HTTP in Module.cfc. Refinements needed:

- [ ] `migrate` — Test all actions (latest, up, down, info, reset). Improve error display.
- [ ] `test` — Parse JSON results into formatted terminal output. Support `--filter`, `--reporter`.
- [ ] `reload` — Verify reload password detection from `.env` / `config/settings.cfm`.
- [ ] `routes` — Format route table output for terminal.
- [ ] `info` — Show version, environment, datasource, LuCLI version.

### 2D: `new` Command (P1)

Scaffold a complete Wheels project:

```
wheels new myapp
```

Creates:
- `myapp/` directory structure matching Wheels conventions
- `lucee.json` (from template)
- `app/`, `config/`, `public/`, `tests/` directories
- `config/settings.cfm`, `config/routes.cfm`, `config/environment.cfm`
- `.env` with placeholder values
- `.gitignore`

**Source**: Port from `cli/src/commands/wheels/init.cfc` and `cli/src/commands/wheels/generate/app.cfc`.

### 2E: MCP-over-stdio (P2)

```
wheels mcp
```

Exposes Wheels tools as MCP over stdin/stdout for AI editors. This is the key differentiator.

**Tools to expose**:
- `wheels_generate` — All generators
- `wheels_migrate` — Migration actions
- `wheels_test` — Test runner
- `wheels_reload` — App reload
- `wheels_analyze` — Code analysis
- `wheels_routes` — Route listing
- `wheels_validate` — Code validation

**Approach**: LuCLI already has MCP module support (`McpCommand.java`). The Wheels module registers tool definitions that map to the existing subcommand functions.

### 2F: Console REPL (P3)

```
wheels console
```

Interactive CFML console with Wheels app context (`model()`, `service()`, etc.). Requires bootstrapping `application.cfc` within LuCLI's JSR223 engine.

**Blocked on**: Understanding Lucee JSR223 application lifecycle support. Coordinate with Mark Drew.

---

## Phase 3: Package Manager Swap

### 3A: Homebrew Formula Update

**Repo**: `wheels-dev/homebrew-wheels`

Current formula creates a bash wrapper that calls `box wheels "$@"`. Change to:

```ruby
depends_on "lucli"  # was: depends_on "commandbox"

# post_install: install wheels module
system bin/"lucli", "modules", "install", "wheels",
       "--url", "https://github.com/wheels-dev/wheels/archive/refs/heads/develop.tar.gz"
```

The `wheels` command stays identical for users.

### 3B: Chocolatey Package Update

**Repo**: `wheels-dev/chocolatey-wheels`

Same approach — swap `box wheels` wrapper for `lucli wheels` wrapper.

### 3C: Module Distribution

The Wheels LuCLI module (`cli/lucli/`) needs to be installable via:

```bash
lucli modules install wheels --url https://github.com/wheels-dev/wheels
```

LuCLI's module installer extracts from Git archives. Verify it can install from a subdirectory (`cli/lucli/`) of the monorepo, or provide a separate distribution archive.

**Fallback**: Dedicated `wheels-dev/wheels-cli-lucli` repo with just the module files, auto-published from the monorepo via GitHub Actions.

---

## Phase 4: Ship Wheels 3.1

### 4A: Documentation
- [ ] Migration guide: CommandBox → LuCLI (CommandBox still works)
- [ ] `lucee.json` reference documentation
- [ ] MCP configuration guide for Claude Code, Cursor, VS Code
- [ ] Updated getting started guide with `brew install wheels`

### 4B: Testing
- [ ] Test all generators end-to-end against a fresh Wheels project
- [ ] Test migrate/test/reload against running server
- [ ] Test `wheels new` project scaffolding
- [ ] Test Homebrew formula installation flow
- [ ] Test MCP tool integration with Claude Code

### 4C: Release
- [ ] Tag Wheels 3.1.0
- [ ] Publish updated Homebrew formula
- [ ] Publish updated Chocolatey package
- [ ] Announce: "Wheels 3.1 — AI-native development with LuCLI"

---

## Architecture Notes

### Template Sharing

Both CLIs share templates from `cli/src/templates/`:

```
cli/src/templates/
  ModelContent.txt          — Model CFC template
  ControllerContent.txt     — Controller CFC template
  ViewContent.txt           — View CFM template
  ViewAddContent.txt        — Add form view
  ViewEditContent.txt       — Edit form view
  ViewShowContent.txt       — Show view
  ViewListContent.txt       — List view
  MigrationContent.txt      — Migration CFC template
  ...
```

The LuCLI `services/Templates.cfc` reads these and substitutes `{{variableName}}` placeholders. No duplication needed.

### Module Installation Path

When installed as a LuCLI module, the Wheels module lives at:

```
~/.lucli/modules/wheels/
  Module.cfc
  module.json
  services/
    Helpers.cfc
    CodeGen.cfc
    Templates.cfc
    ...
```

The module needs to know where Wheels templates are. Options:
1. Bundle templates into the module distribution
2. Read templates from the project's `vendor/wheels/cli/src/templates/` at runtime
3. Download templates on first use

Option 2 is simplest — the project already has Wheels vendored.

### Shared Service Interface

Services should work identically whether called from CommandBox or LuCLI:

```
CommandBox CLI:
  Command.cfc → inject("CodeGenerationService@wheels-cli") → service method

LuCLI Module:
  Module.cfc → createObject("services.CodeGen") → same method signatures
```

Keep method signatures identical so business logic can be shared or ported easily.

---

## Immediate Next Steps

1. **Extract `services/CodeGen.cfc`** — Port from `cli/src/models/CodeGenerationService.cfc`, remove WireBox dependencies
2. **Extract `services/Templates.cfc`** — Port template rendering from `cli/src/models/TemplateService.cfc`
3. **Wire `generate model`** — First end-to-end generator using real templates
4. **Wire remaining generators** — controller, view, migration, scaffold
5. **Test against real project** — Create a Wheels app with `wheels new`, run generators, verify output
