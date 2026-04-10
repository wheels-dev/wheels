# Phase 4: In-Process Everything — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** All `wheels` commands run in-process via LuCLI's `LuceeScriptEngine`, sharing the same JVM context as the app. No HTTP round-trips. Commands like `wheels dbmigrate` and `wheels test` work without a running server.

**Architecture:** LuCLI's `LuceeScriptEngine` is a singleton Lucee instance that can execute CFML expressions. The Wheels CLI module loads the application context into the script engine, then executes commands directly against the model/service layer. The HTTP-based approach from Phase 2-3 becomes the fallback for when a server is already running.

**Tech Stack:** Java (LuceeScriptEngine integration), CFML (Wheels app context loading)

**Prerequisites:** Phase 1-3 complete. LuCLI profile system merged.

**Repo:** `/Users/peter/GitHub/wheels-dev/wheels`

---

### Task 1: In-process test runner

Replace the HTTP-based test execution with direct TestBox invocation via `LuceeScriptEngine`.

**Files:**
- Modify: `cli/lucli/Module.cfc` — `runTests()` function
- Create: `cli/lucli/services/TestRunner.cfc` — in-process test execution

**Approach:**
The `LuceeScriptEngine` can execute CFML code directly within the CLI's JVM. We can:

1. Load the Wheels application context by processing the Application.cfc
2. Call the test runner directly: `application.testbox.run(directory="wheels.tests.specs", reporter="json")`
3. Parse the result in the CLI and display it

**Steps:**
- [ ] Research how TestBox can be invoked programmatically without HTTP
- [ ] Create `TestRunner.cfc` that initializes Wheels app context and runs TestBox
- [ ] Modify `runTests()` to try in-process first, fall back to HTTP
- [ ] Handle classpath: ensure the script engine can find `vendor/wheels/` and `tests/`
- [ ] Commit

---

### Task 2: In-process migrations

Replace HTTP calls to `/wheels/dbmigrate` with direct migration execution.

**Files:**
- Modify: `cli/lucli/Module.cfc` — `migrate()` function

**Approach:**
```cfml
// Direct migration execution
var migrator = application.wheels.migrator;
migrator.migrate("latest");
```

**Steps:**
- [ ] Load app context via ScriptEngine
- [ ] Access `application.wheels.migrator` directly
- [ ] Execute migration commands (latest, up, down, info)
- [ ] Report migration output to CLI
- [ ] Commit

---

### Task 3: In-process generators

Ensure generators work without a running server.

**Files:**
- Modify: `cli/lucli/Module.cfc` — `generate()` function

**Approach:**
Generators already work without HTTP in the current module (they use `services/CodeGen.cfc` and `services/Templates.cfc` to write files directly). This task is about ensuring they work seamlessly with the in-process app context for:
- Validating model/controller names against existing code
- Generating migrations that match the current database schema
- Auto-routing new resources

**Steps:**
- [ ] Verify generators work without a running server
- [ ] Add schema introspection for `generate property` (reads current table columns)
- [ ] Commit

---

### Task 4: Interactive console with full app context

Enhance the REPL so `model("User").findAll()` works directly.

**Files:**
- Modify: `cli/lucli/Module.cfc` — `console()` function

**Approach:**
The console already uses a Java-based REPL loop. We enhance it to:
1. Initialize the Wheels application context on startup
2. Provide `model()`, `service()`, `get()`, `set()` as top-level functions
3. Format query results as tables
4. Format struct/array results as pretty JSON

**Steps:**
- [ ] Load Application.cfc context on console startup
- [ ] Register Wheels helper functions in the script engine scope
- [ ] Add query result formatting (tabular display)
- [ ] Add `/models` command to list available models
- [ ] Add `/routes` command to list routes
- [ ] Commit

---

### Task 5: Server monitor

Wire LuCLI's JMX monitoring into `wheels server monitor`.

**Files:**
- Modify: `cli/lucli/Module.cfc` — add `monitor()` function

**Steps:**
- [ ] Delegate to LuCLI's monitor command with Wheels formatting
- [ ] Add Wheels-specific metrics (model cache size, route count)
- [ ] Commit

---

### Task 6: MCP server via LuCLI stdio

Replace the HTTP-based MCP endpoint with LuCLI's native stdio MCP transport.

**Files:**
- Create: `cli/lucli/services/MCP.cfc` — MCP tool implementations
- Modify: `cli/lucli/Module.cfc` — `mcp()` function

**Approach:**
LuCLI's `McpCommand` provides JSON-RPC over stdio. We implement the Wheels MCP tools as a LuCLI module:

```bash
# Instead of configuring HTTP MCP endpoint:
wheels mcp
# Starts stdio MCP server that Claude Code connects to directly
```

Tools: `wheels_generate`, `wheels_migrate`, `wheels_test`, `wheels_reload`, `wheels_analyze`, `wheels_routes`

**Steps:**
- [ ] Implement each MCP tool as a CFML function in `MCP.cfc`
- [ ] Register tools with LuCLI's MCP command infrastructure
- [ ] Test with Claude Code MCP configuration
- [ ] Document `.mcp.json` configuration for Wheels projects
- [ ] Commit

---

## Validation Criteria

Phase 4 is complete when:
1. `wheels test` works without `wheels server start` running
2. `wheels dbmigrate latest` works without a server
3. `wheels console` provides `model()`, `service()` with live app context
4. `wheels server monitor` shows live metrics
5. `wheels mcp` connects to Claude Code without HTTP configuration
6. All commands are faster than their HTTP-based equivalents
