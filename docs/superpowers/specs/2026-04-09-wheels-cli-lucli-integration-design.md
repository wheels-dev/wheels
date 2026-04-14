# Wheels CLI + LuCLI Integration Design

**Date:** 2026-04-09 (updated 2026-04-10)
**Status:** Phase 1 complete, Phase 2 in validation
**Author:** Peter Amiri + Claude

## Problem

Wheels developers currently depend on CommandBox (a proprietary tool from Ortus Solutions) for local development, testing, and CLI commands. The framework has selected Lucee 7 + SQLite as its primary platform, but the local development experience requires manual setup: Docker containers, multiple config files, JDBC driver installation, and database creation. New developers face 10+ setup steps before running their first test.

Rails developers run `gem install rails && rails new myapp && cd myapp && rails server` and have a working app with SQLite in under a minute. Wheels should match this.

## Solution

Replace CommandBox with LuCLI as the underlying CLI engine, branded as `wheels`. A single `brew install wheels` gives developers the CLI, the Lucee 7 runtime, SQLite pre-wired, and the framework — all in one install. The `wheels` binary IS LuCLI, rebranded via a binary-name detection mechanism.

## Design Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| CLI identity | `wheels` (LuCLI fully hidden) | Developers never see "lucli" in commands, output, or docs. LuCLI is an implementation detail. |
| Framework distribution | Embedded in CLI binary/formula | `wheels new` copies from bundled template. Updates via `brew upgrade wheels`. Like Rails gems. |
| SQLite setup timing | Automatic on server start | Zero manual setup. Detect missing DB files, create them, wire datasource. Clone-and-run. |
| Binary mechanism | LuCLI binary name detection | LuCLI detects `argv[0]`. If invoked as `wheels`, loads Wheels command profile. One binary, zero symlinks. Small LuCLI PR. |
| Test runner | Auto-manage server | `wheels test` starts a temporary Lucee instance if none running, runs tests, prints results, exits. Like `rails test`. |

## The Developer Experience

### Install

```bash
brew install wheels          # macOS
choco install wheels         # Windows
```

This installs a single `wheels` binary (~15MB) that IS LuCLI with Wheels personality. Lucee 7 Express runtime is downloaded on first `wheels server start` and cached in `~/.wheels/`.

### New Project

```bash
wheels new myapp
cd myapp
wheels server start
# -> http://localhost:8080 running, SQLite ready
```

### Project Structure Created by `wheels new`

```
myapp/
  app/
    controllers/
    models/
    views/
    views/layout.cfm
  config/
    settings.cfm
    routes.cfm
    environment.cfm
  db/
    development.db            # created automatically
    test.db                   # created automatically
  public/
  tests/
    specs/
      models/
      controllers/
      functional/
  vendor/
    wheels/                   # framework, copied from embedded template
  lucee.json                  # pre-configured with SQLite datasources
  .env                        # RELOAD_PASSWORD=<random>, environment=development
```

### Testing

```bash
wheels test                           # run all tests
wheels test models                    # run tests/specs/models/**
wheels test tests/specs/models/UserSpec.cfc  # single spec
wheels test --ci --format=junit       # CI mode with JUnit output
```

## Command Set

### Core Commands

| Command | What it does | LuCLI mechanism |
|---------|-------------|-----------------|
| `wheels new myapp` | Scaffold new project | New command in Wheels profile |
| `wheels server start` | Start dev server (port 8080) | Maps to `lucli server run` |
| `wheels server stop` | Stop server | Maps to `lucli server stop` |
| `wheels server restart` | Restart with reload | Maps to `lucli server run --force` |
| `wheels server monitor` | Live performance dashboard | Maps to `lucli server monitor` (JMX) |
| `wheels test` | Run test suite | New command — auto-manages server |
| `wheels test [filter]` | Run filtered tests | Directory or file path filter |
| `wheels generate model User` | Generate model | HTTP call (Phase 2-3), in-process (Phase 4) |
| `wheels generate scaffold Post` | Full CRUD scaffold | HTTP call (Phase 2-3), in-process (Phase 4) |
| `wheels dbmigrate latest` | Run migrations | HTTP call (Phase 2-3), in-process (Phase 4) |
| `wheels db:seed` | Seed database | HTTP call (Phase 2-3), in-process (Phase 4) |
| `wheels console` | Interactive REPL | LuCLI `repl` with Wheels app context |
| `wheels cfml '<expr>'` | Evaluate CFML expression | LuCLI `cfml` command |
| `wheels version` | Show versions | Enhanced `lucli --version` |

### Command Routing

When the binary name is `wheels`, LuCLI loads the Wheels command profile:

- `wheels server *` -> LuCLI's native server commands with Wheels defaults (port 8080, SQLite auto-setup)
- `wheels test *` -> Test runner (built into Wheels profile)
- `wheels new *` -> Scaffold logic (built into Wheels profile)
- `wheels generate|dbmigrate|db:seed|console` -> HTTP calls to running app (Phase 2-3), in-process via LuceeScriptEngine (Phase 4)
- `wheels cfml|mcp|daemon` -> LuCLI native commands in Wheels context

**Architecture note:** HTTP calls to a running server are the pragmatic Phase 2-3 approach. The end-state (Phase 4) is all commands running in-process via LuCLI's `LuceeScriptEngine`, which shares the same JVM and Lucee context as the server. This eliminates the need for a running server for commands like migrations, generators, seeds, and testing — they execute directly against the application code and database.

## `wheels server start` First-Run Behavior

```
1. lucee.json exists?
   -> No: create from embedded template (SQLite datasources, port 8080)

2. db/development.db exists?
   -> No: create it (empty SQLite database)

3. db/test.db exists?
   -> No: create it (empty SQLite database)

4. lucli deps install
   -> Resolves lucee.json dependencies (sqlite-jdbc via Maven, etc.)

5. Start Lucee Express, print URL
   -> #project:path# placeholders in CFConfig resolved at startup
```

## `wheels test` Internals

```
wheels test [filter] [--db=sqlite] [--ci] [--format=text|json|junit]

1. Resolve test target:
   - No filter -> run all specs
   - Directory name -> tests/specs/<name>/ or vendor/wheels/tests/specs/<name>/
   - File path -> single spec

2. Detect context:
   - vendor/wheels/tests/ exists AND in framework repo -> core tests
   - tests/specs/ exists -> app tests
   - --core flag forces core tests, --app forces app tests

3. Resolve server:
   a. Server already running? (check .wheels/server.pid + port)
      -> Yes: use it, skip to step 5
   b. No server -> start temporary Lucee instance on random port

4. Ensure test database:
   - db/test.db exists? No -> create it
   - Run populate.cfm to set up test tables

5. Execute tests:
   - HTTP mode: GET /wheels/core/tests?db=sqlite&format=json&directory=<filter>
   - (Future: in-process mode via LuceeScriptEngine for speed)

6. Report results:
   --format=text (default):
     ✓ 2624 passed   ✗ 0 failed   ⊘ 0 errors   (12.3s)

     Failures:
       ✗ UserSpec > validates email uniqueness
         Expected true but got false
         at tests/specs/models/UserSpec.cfc:42

   --format=json: raw TestBox JSON
   --format=junit: JUnit XML (for CI)
   --ci: implies --format=junit, non-zero exit on failure

7. Cleanup:
   - If temp server was started, shut it down
   - Exit 0 (green) or 1 (failures)
```

## LuCLI Capabilities Leveraged

| LuCLI Feature | Wheels Use | Benefit |
|---|---|---|
| `LuceeScriptEngine` | `wheels console`, `wheels cfml` | In-process REPL with full app context. `model("User").findAll()` from terminal. |
| `ServerMonitorCommandImpl` | `wheels server monitor` | Live JMX dashboard: memory, threads, requests. |
| `DaemonCommand` | `wheels daemon` | IDE integration via JSON-RPC. Stable protocol for tooling. |
| `McpCommand` | `wheels mcp` | MCP server over stdio. Cleaner Claude Code integration. |
| Module system | Wheels command profile | Command definitions, server hooks, scaffold templates. |
| Secrets management | `.env` / `wheels secrets` | `#secret:NAME#` resolution in lucee.json. |
| `#project:path#` placeholder | Datasource paths | `jdbc:sqlite:#project:path#/db/development.db` resolves correctly. Follows `#env:VAR#` / `#secret:NAME#` convention. |

### CLI/Server Same Context

LuCLI's `LuceeScriptEngine` runs Lucee inside the CLI's JVM. This enables:

```bash
wheels console
wheels> model("User").findAll()        # runs in-process, not over HTTP
wheels> application.wheels.version     # direct app scope access
wheels> service("emailService")        # DI container access
```

For testing, this opens a future path to run tests in-process (no HTTP overhead, no port management). Phase 4 goal.

## Implementation: Repos and Changes

### 1. LuCLI (`cybersonic/LuCLI` -- PRs from Wheels team)

| Change | PR | Status | Description |
|--------|-----|--------|-------------|
| Binary name detection | #39 | **Merged** | `argv[0]` check via `-Dlucli.binary.name`. If `wheels`, prepends module name to args. |
| Fix integration tests | #40 | **Merged** | Fixed pre-existing test failures to unblock further PRs. |
| Wheels module in registry | #46 | **Merged** | Added wheels module to LuCLI's bundled module registry. |
| `#project:path#` placeholder | #48 | **Open** | Replaces `#project:path#` in CFConfig text values with absolute project dir. Follows `#env:VAR#` / `#secret:NAME#` convention. |
| Profile system (branding) | #49 | **Merged** | `CliProfile` interface with `DefaultProfile` and `WheelsProfile`. Controls home dir (`~/.wheels/`), banner, REPL prompt, backups dir. Binary name normalized (strips paths/extensions). |
| ~~JDBC driver auto-install~~ | #50 | **Closed** | Replaced by declaring SQLite JDBC as a `type: "java"` dependency in `lucee.json`. LuCLI's existing `lucli deps install` handles Maven downloads. |

### 2. Wheels Framework (`wheels-dev/wheels`)

| Change | Status | Description |
|--------|--------|-------------|
| `lucee.json` update | **Done** | SQLite datasources with `#project:path#` paths, sqlite-jdbc as `type: "java"` dependency. |
| `cli/lucli/Module.cfc` | **Done** | ~2,900 lines. All 14 commands implemented (new, generate, test, migrate, seed, reload, console, routes, info, analyze, validate, mcp, start, stop). |
| `cli/lucli/services/` | **Done** | CodeGen, Templates, Scaffold, Helpers, Analysis, MigrationRunner, TestRunner, MCP services. |
| Scaffold templates | **Done** | Full project skeleton in `cli/lucli/templates/app/`. |
| CI pipeline update | **Not started** | Need to add `wheels test --ci` as option alongside Docker. |
| End-to-end validation | **Not started** | Need to verify `wheels server start` works against this repo. |

### 3. Homebrew/Chocolatey (`wheels-dev/homebrew-wheels`, `wheels-dev/chocolatey-wheels`)

| Change | Status | Description |
|--------|--------|-------------|
| Formula rewrite | **Not started** | Install LuCLI binary as `wheels`. Remove CommandBox dependency. |
| Bundle framework template | **Not started** | Include Wheels framework files for `wheels new`. |
| ~~Bundle SQLite JDBC~~ | **N/A** | Handled by `lucee.json` dependency declaration — `lucli deps install` pulls from Maven. |

## Phasing

### Phase 1: Foundation (LuCLI PRs) — COMPLETE

**Goal:** The `wheels` binary works, SQLite datasources resolve.

- [x] Binary name detection + profile loading (PRs #39, #49 merged)
- [x] `#project:path#` placeholder resolution in CFConfig writer (PR #48 open, awaiting merge)
- [x] SQLite JDBC via `lucee.json` dependency declaration (PR #50 closed — existing `lucli deps install` handles it)
- [x] Wheels module registered in LuCLI's bundled registry (PR #46 merged)

**Validates:** Can a Wheels project start with `wheels server start` and have SQLite working?
**Status:** All LuCLI PRs accepted. Awaiting PR #48 merge for placeholder support. Need end-to-end validation.

### Phase 2: Core CLI (Wheels repo) — IN PROGRESS

**Goal:** Framework contributors can `wheels test` locally.

- [x] `wheels server start/stop` (thin wrappers with first-run auto-setup)
- [x] `wheels test` (HTTP-based, auto-manages temporary server)
- [x] `lucee.json` with SQLite out-of-box
- [x] `cli/lucli/Module.cfc` — all 14 commands implemented
- [x] `cli/lucli/services/` — CodeGen, Templates, Scaffold, Helpers, Analysis, MigrationRunner, TestRunner, MCP
- [ ] CI pipeline updated to use `wheels test --ci`
- [ ] End-to-end validation: `wheels server start` against framework repo

**Validates:** Does `git clone wheels && wheels test` pass 2600+ tests with zero setup?

**Migration note:** Existing framework contributors who have `wheelstestdb.db` files and Docker-based workflows continue to work. The `wheelstestdb_sqlite` datasource name is preserved for backward compatibility. The `db/development.db` / `db/test.db` convention is for new projects created by `wheels new`. Core framework tests continue to use `wheelstestdb_sqlite` as the datasource name.

### Phase 3: Scaffold & Distribution — NOT STARTED

**Goal:** New developers get the full Rails-like experience.

- [x] `wheels new myapp` (project scaffolding — implemented in Module.cfc)
- [x] `wheels generate/dbmigrate/db:seed/console` (implemented, HTTP-based)
- [ ] Homebrew/Chocolatey formula rewrite
- [ ] Documentation and getting-started guide

**Validates:** Can a new developer go from `brew install wheels` to running app in under 2 minutes?

### Phase 4: In-Process Everything — SERVICES WRITTEN, NOT WIRED

**Goal:** Eliminate HTTP round-trips. All commands run in the same JVM context as the app.

- [ ] Wire MigrationRunner.cfc for in-process execution (code exists, not connected)
- [ ] Wire TestRunner.cfc for in-process execution (code exists, not connected)
- [ ] `wheels console` with live app context (model/service/DI access)
- [ ] `wheels server monitor` (JMX dashboard)
- [ ] MCP server via LuCLI stdio transport

This is the architectural endgame: the CLI and the server share a single Lucee runtime. Commands like `wheels dbmigrate latest` don't need a running server — they load the app context, execute the migration, and exit. Like how `rails db:migrate` works without `rails server` running.

**Validates:** Can all `wheels` commands work without a running server? Is the development experience competitive with Rails/Laravel tooling?
