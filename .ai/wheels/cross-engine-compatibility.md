# Cross-Engine Compatibility Guide

Wheels runs on multiple CFML engines (Lucee 5/6/7, Adobe CF 2018-2025, BoxLang) and databases (H2, MySQL, PostgreSQL, SQL Server, CockroachDB). Each engine has runtime differences that can cause code to pass on one engine but fail on another. This guide documents the known gotchas.

## Engine-Specific Gotchas

### struct.map() Collision (Lucee + Adobe)

Lucee and Adobe resolve `obj.map()` as the built-in struct member function, not the CFC method. This affects the DI container's `map()` method.

```cfm
// WRONG — triggers struct.map(callback) on Lucee/Adobe
arguments.container.map("myService").to("path").asSingleton();

// RIGHT — use the alias that avoids the collision
arguments.container.mapInstance("myService").to("path").asSingleton();
```

**Why**: When a CFC is typed as `any` or passed generically, the engine's native struct member function takes precedence over the CFC's own `map()` method.

### Application Scope Function Members (Adobe CF)

Adobe CF's `application` scope is a special Java-backed struct that doesn't reliably store closures or function references.

```cfm
// WRONG — works on Lucee, breaks on Adobe
application.registerMiddleware = function() { ... };

// RIGHT — use a plain struct context
var context = Duplicate(application);
context.registerMiddleware = function() { ... };
plugin.onPluginLoad(context);
```

**Why**: Adobe's application scope is implemented differently from a regular CFML struct. Function members get lost or throw errors during serialization.

### Closure `this` Captures Declaring Scope

CFML closures bind `this` to the component where they are DEFINED, not where they are ASSIGNED. This trips up test code that dynamically adds methods.

```cfm
// WRONG — this.renderText() calls renderText on the TEST spec, not the controller
_controller.myAction = function() {
    this.renderText("hello");  // ERROR: method not found
};

// RIGHT — capture the reference in a shared struct
var ctx = {ctrl: _controller};
_controller.myAction = function() {
    ctx.ctrl.renderText("hello");  // works
};
```

### Bracket-Notation Function Calls (Adobe CF 2021/2023)

`obj["key"]()` crashes the Adobe CF parser when used inside closures.

```cfm
// WRONG — crashes Adobe CF 2021/2023 inside closures
var result = obj["dynamicMethod"]();

// RIGHT — split into two statements
var fn = obj["dynamicMethod"];
var result = fn();
```

### Array By-Value in Struct Literals (Adobe CF)

Adobe CF copies arrays by value when they appear in struct literal syntax. Closures that append to the copy won't affect the original.

```cfm
// WRONG — myArray is copied by value into the struct
var config = {arr: myArray};
// Closures that modify config.arr don't affect myArray

// RIGHT — reference via parent struct
var parent = {arr: myArray};
var config = {owner: parent};
// config.owner.arr is a reference, not a copy
```

### `$appKey()` Returns `"$wheels"` (All Engines)

The `$appKey()` function returns `"$wheels"` when `application.$wheels` exists. Test setup must set defaults in BOTH scopes.

```cfm
// WRONG — only sets one scope
application.wheels.myNewSetting = "value";

// RIGHT — set both (CI app reloads can break the struct reference)
application.$wheels.myNewSetting = "value";
application.wheels.myNewSetting = "value";
```

### Private View Helpers Not Integrated

`$integrateComponents()` only copies `public` methods into controllers. Private helper functions in view CFCs are never available.

```cfm
// WRONG — private function won't be integrated
private string function myHelper() { ... }

// RIGHT — use public access with $ prefix for internal helpers
public string function $myHelper() { ... }
```

## Database-Specific Gotchas

### H2 Database (Test Default)

H2 is the embedded database used by default in tests. Key differences:
- Case-sensitive by default for identifiers
- `NOW()` is supported (Wheels normalizes this)
- Some MySQL-specific functions (e.g., `GROUP_CONCAT`) not available
- Simpler locking model than production databases

### Migration Date Functions

Use `NOW()` for cross-database compatibility in migrations:

```cfm
// WRONG — database-specific
execute("INSERT INTO users (name, createdAt) VALUES ('Admin', CURRENT_TIMESTAMP)");

// RIGHT — NOW() works across MySQL, PostgreSQL, SQL Server, H2
execute("INSERT INTO users (name, createdAt, updatedAt) VALUES ('Admin', NOW(), NOW())");
```

### Parameter Binding in Migrations

Direct SQL with `execute()` is more reliable than parameter binding for seed data:

```cfm
// WRONG — parameter binding unreliable in migrations
execute(sql="INSERT INTO roles (name) VALUES (?)", parameters=[{value="admin"}]);

// RIGHT — direct SQL
execute("INSERT INTO roles (name, createdAt, updatedAt) VALUES ('admin', NOW(), NOW())");
```

### CockroachDB (Soft-Fail in CI)

CockroachDB is in CI but marked as soft-fail — test failures are logged as warnings, not build failures. Controlled by `SOFT_FAIL_DBS` in `.github/workflows/tests.yml`.

## Testing Across Engines

### Local Test Procedure

Always test on at least TWO engines before pushing — Lucee and Adobe catch different bugs:

```bash
cd /path/to/wheels/rig    # repo root with compose.yml

docker compose up -d lucee6 adobe2025

# Wait ~60s, then test both with SQLite (works on ALL engines — H2 is Lucee-only)
curl -s "http://localhost:60006/wheels/core/tests?db=sqlite&format=json" > /tmp/lucee6.json
curl -s "http://localhost:62025/wheels/core/tests?db=sqlite&format=json" > /tmp/adobe2025.json
```

### Engine Ports

| Engine | Port |
|--------|------|
| lucee5 | 60005 |
| lucee6 | 60006 |
| lucee7 | 60007 |
| adobe2018 | 62018 |
| adobe2021 | 62021 |
| adobe2023 | 62023 |
| adobe2025 | 62025 |
| boxlang | 60001 |

### Why Both Engines Matter

- "It passed on Lucee" is not sufficient — Adobe CF has different struct member functions, application scope handling, and closure behavior
- "It's just a docs change" can still break test discovery if file naming affects CFC compilation
- CI runs take 20+ minutes across all matrix combinations; catching failures locally saves everyone time
