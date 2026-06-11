# Cross-Engine Compatibility Guide

Wheels runs on multiple CFML engines (Lucee 5/6/7, Adobe CF 2018-2025, BoxLang) and databases (H2, MySQL, PostgreSQL, SQL Server, CockroachDB). Each engine has runtime differences that can cause code to pass on one engine but fail on another. This guide documents the known gotchas.

**RustCFML (best-effort, experimental):** [RustCFML](https://github.com/RustCFML/RustCFML) — a young, JVM-free CFML interpreter written in Rust — is recognized as a first-class engine in the adapter layer (`server.coldfusion.productName == "RustCFML"` → `RustCFMLAdapter`), but it is NOT yet part of the CI matrix and cannot fully boot the framework today. The confirmed divergence handled in-framework is the **missing `cfcache` built-in** (the cfcache-backed cache degrades to a no-op via the adapter's `supportsCfcache()=false`). Remaining blockers are tracked upstream — chiefly an argument-scope-fidelity gap (undeclared/`argumentCollection`-forwarded named args lose their names) and no Query-of-Queries — so treat RustCFML support as in-progress.

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

### Method Reference Extraction Loses Receiver (BoxLang)

BoxLang implements method dispatch with JavaScript-style semantics: pulling a method off an object into a local variable produces a bare function reference with no bound receiver. Calling that local then runs the function in an empty context, and any in-component call inside (helpers prefixed with `$`, `this.x()`, etc.) fails to resolve. The lookup-and-call **must** stay in a single expression for BoxLang to bind the receiver.

```cfm
// WRONG — drops the receiver on BoxLang, so $helper() throws
//          "Function [$helper] not found" when publicMethod runs
local.method = arguments.object[arguments.methodName];
local.method();

// RIGHT — single-expression bracket-call binds the receiver
arguments.object[arguments.methodName]();
```

**Why**: BoxLang treats `obj["method"]` as a property access that returns a callable, not a bound method. Only an immediate invocation `obj["method"]()` lets BoxLang's call dispatcher know which object is the receiver. Lucee and Adobe CF preserve the receiver across both forms, so this trap only fires on BoxLang.

**On `invoke()`**: The `invoke()` BIF is the Lucee/Adobe path via `Base.cfc` and preserves the receiver on those engines. Whether it preserves the receiver on BoxLang has **not** been verified — the `invokeMethod` override in `BoxLangAdapter.cfc` exists precisely because earlier BoxLang versions had `invoke()` parity gaps. Until a BoxLang run confirms the BIF binds the receiver, prefer the single-expression bracket-call on BoxLang. If a future audit confirms parity, the override can be deleted entirely.

**Reference example**: `vendor/wheels/engineAdapters/BoxLang/BoxLangAdapter.cfc::invokeMethod`. The original two-statement form silently worked until #2241 added `$blockInProduction()` calls inside every `Public.cfc` handler — at which point every internal Wheels route (`/wheels/info`, `/wheels/routes`, ...) started 500-ing on BoxLang. Regression test: `vendor/wheels/tests/specs/dispatch/InvokeMethodSpec.cfc` (issue #2646).

### Inline Closure as Constructor Named Argument (Adobe CF)

Passing a function literal directly as a named argument to a `new Component(...)` call crashes Adobe CF's bytecode generator with `java.lang.ArrayStoreException: coldfusion.compiler.ASTcffunction`. The compile error fires from `getComponentMetadata()` and crashes the **entire** TestBox bundle for the engine — not just the one spec — because Adobe CF eagerly compiles every CFC in the bundle directory before any test runs.

```cfm
// WRONG — crashes Adobe CF at compile time
var mw = new wheels.middleware.RateLimiter(
    maxRequests = 5,
    keyFunction = function(req) { return "client-1"; }
);

// RIGHT — hoist the closure into a local var first
var keyFn = function(req) { return "client-1"; };
var mw = new wheels.middleware.RateLimiter(
    maxRequests = 5,
    keyFunction = keyFn
);
```

**Why**: Adobe CF's `ExprAssembler.invokeNew` (called via `generateSetVarCode` → `assignStatement`) tries to store the function AST node into a typed array that doesn't accept `ASTcffunction` entries. The bug only manifests when the function literal appears in the argument list of `new` (not bare function calls).

**Reference examples**: `vendor/wheels/tests/specs/middleware/RateLimiterSpec.cfc` (12 sites) and the original `SessionStrategySpec.cfc` workaround. Lucee and BoxLang compile both forms identically — there is no behavior change from hoisting, only better cross-engine portability.

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

### `createDynamicProxy` Requires a CFC on Lucee 7

Lucee 6 accepted a CFML struct with named function entries as the first argument to `createDynamicProxy` — Lucee wired struct keys to interface methods. Lucee 7 tightened the signature to require a Component instance. Passing a struct fails with a misleading error: `"Can't cast Complex Object Type Struct to String"` — Lucee 7 is trying the CFC-path-string overload and choking on the struct argument.

```cfm
// WRONG — works on Lucee 6, fails on Lucee 7
var handler = {
    accept: function(dialog) {
        dialog.accept();
    }
};
createDynamicProxy(handler, ["java.util.function.Consumer"]);

// RIGHT — CFC instance, works on Lucee 6 AND Lucee 7
component MyConsumer {
    public any function init(required struct state) {
        variables.state = arguments.state;
        return this;
    }
    public void function accept(required any dialog) {
        variables.state.value = dialog.message();
        dialog.accept();
    }
}

var consumer = new MyConsumer(state={value: ""});
createDynamicProxy(consumer, ["java.util.function.Consumer"]);
```

**Why**: Lucee 7 adds overload dispatch prefers the `createDynamicProxy(cfcPathString, interfaces)` signature and rejects struct arguments at the cast step. The struct-argument legacy path was removed.

**Reference example**: [`vendor/wheels/wheelstest/DialogConsumer.cfc`](../../vendor/wheels/wheelstest/DialogConsumer.cfc) shows the CFC-based pattern used by `BrowserClient` to proxy Playwright's `Consumer<Dialog>`. The probe in `$requireDialogSupport` mirrors the real call shape so engine compatibility is verified on the same code path.

### `for` Loops Inside `finally` Blocks Miscompile on Lucee 7

Lucee 7.0.1+100 throws `variable [local] doesn't exist` at runtime when a `for` loop declares or iterates `local`-/`var`-scoped variables inside a `finally` block. Both loop forms are affected — `for (init; cond; step)` and `for (item in collection)`. Isolated with minimal probes: bare assignments and function calls inside `finally` compile and run fine; loops do not. One probe shape even produced a JVM `Expecting a stackmap frame` bytecode-verifier error, pointing at a codegen bug in Lucee's `finally`-block compilation.

```cfm
// WRONG — crashes at runtime on Lucee 7
try {
    doWork();
} finally {
    for (local.key in local.savedState) {
        variables[local.key] = local.savedState[local.key];
    }
}

// RIGHT — hoist the loop into a helper; the finally body is just a call
try {
    doWork();
} finally {
    $restoreState(local.savedState);
}
```

**Why**: Lucee 7's bytecode generation for `finally` blocks mishandles the `local` scope frame for loop constructs. Adobe CF and BoxLang are unaffected.

**Reference example**: `$restoreEmailViewVariables()` in [`vendor/wheels/controller/miscellaneous.cfc`](../../vendor/wheels/controller/miscellaneous.cfc) — the `sendEmail` variables-scope restore runs from `finally` via a `public` `$`-prefixed helper (mixin invariant: helpers must be public). Found while addressing review on [#2922](https://github.com/wheels-dev/wheels/pull/2922).

### `DirectoryCreate()` Second Argument Is Lucee-Only

Lucee accepts `DirectoryCreate(path, createPath, mode)` and recurses parent directories when `createPath=true`. Adobe CF's signature varies by version and at least some Adobe builds reject any second argument with `"The function takes 1 parameter"` (issue #2567).

```cfm
// WRONG — crashes on Adobe CF
DirectoryCreate(path, true);

// RIGHT — engine-agnostic recursive mkdir via Java NIO
if (!DirectoryExists(path)) {
    CreateObject("java", "java.io.File").init(path).mkdirs();
}
```

**Why**: `java.io.File.mkdirs()` is part of the JDK on every CFML engine and recurses parents the same way on Lucee, Adobe CF, and BoxLang. Reach for it whenever a path's parents may be missing — relying on the BIF's `createPath` extension is a portability trap.

### Binary Data Representation (BoxLang / Lucee 6 vs Lucee 7 / Adobe)

`FileReadBinary()` and multipart-upload byte content are surfaced differently across engines:

| Engine | `IsArray(bytes)` | `IsBinary(bytes)` | Shape |
|--------|-----------------|-------------------|-------|
| Lucee 7, Adobe CF | `false` | `true` | `byte[]` Java array |
| BoxLang, Lucee 6 (some configs) | `true` | `false` | CFML array of integers |

Both shapes are valid representations that the JDBC driver accepts when binding a `cf_sql_blob` / `cf_sql_varbinary` parameter. Wheels' model property setter (`$setProperty`) is aware of this: the scalar-column type guard exempts binary columns so the array shape passes through to the JDBC layer unchanged (fix: #2660).

```cfm
// Works on all engines — the model exempts blob/longblob/bytea columns from
// the array-rejection guard regardless of which shape the engine produces.
local.bytes = FileReadBinary(expandPath("/uploads/tmp/") & cffile.serverFile);
local.photo = model("Photo").new(filename="avatar.png", fileData=local.bytes);
local.photo.save();
```

**When this matters**: only for columns whose `cf_sql_*` type resolves to `validationtype == "binary"` — blob, longblob, bytea, varbinary, and clob. (Note: `clob` stores character data, not bytes — it's grouped here only because Wheels' internal `$getValidationType` maps `CF_SQL_CLOB` to `"binary"` for guard-exemption purposes.) All other scalar columns (varchar, integer, datetime, ...) still reject array/struct values; structs bound to *any* column, including binary ones, also still throw — the exemption is array-shape-only.

### `getMetadata().type` Returns FQN on BoxLang

`getMetadata(obj).type` returns the literal string `"component"` on Lucee and Adobe CF, but returns the fully-qualified class name (e.g. `wheels.tests._assets.models.BulkItem`) on BoxLang. Test assertions that hardcode the string `"component"` silently pass on Lucee/Adobe and silently fail on BoxLang.

```cfm
// WRONG — passes on Lucee/Adobe, fails on BoxLang
expect(found).toBeInstanceOf("component");

// RIGHT — asserts against the Model base class via IsInstanceOf (all engines)
expect(found).toBeWheelsModel();
```

**Why**: `IsInstanceOf(obj, "Model")` walks the inheritance chain identically on Lucee, Adobe CF, and BoxLang. `toBeWheelsModel()` is a wrapper on `wheels.wheelstest.system.Expectation` that routes through `toBeInstanceOf("Model")`.

**Reference**: `vendor/wheels/wheelstest/system/Expectation.cfc::toBeWheelsModel`, issue #2662.

### `local.X = ...` Inside `catch` Doesn't Persist (BoxLang)

Writes to the `local` scope inside a `catch` block don't survive past the block on BoxLang. The catch body apparently runs under a nested `local` that gets discarded when control leaves; on Lucee and Adobe CF the catch shares the enclosing function's `local`, so the assignment sticks.

```cfm
// WRONG — passes on Lucee/Adobe, fails on BoxLang
local.caught = false;
try {
    Throw(type = "TestException", message = "boom");
} catch (TestException e) {
    local.caught = true;   // discarded when catch exits on BoxLang
}
expect(local.caught).toBeTrue();   // reads outer local — still false

// RIGHT — struct field assignment targets a heap object (all engines)
var state = {caught = false};
try {
    Throw(type = "TestException", message = "boom");
} catch (TestException e) {
    state.caught = true;
}
expect(state.caught).toBeTrue();

// ALSO RIGHT — var-declared name without `local.` prefix
var caught = false;
try {
    Throw(type = "TestException", message = "boom");
} catch (TestException e) {
    caught = true;
}
expect(caught).toBeTrue();
```

**Why the bare-`var` form survives**: BoxLang's catch-scoped local only shadows keys written via explicit `local.X = ...`; an unscoped write to a `var`-declared name appears to resolve through the var-declaration slot and escapes the catch-scope shadow. Prefer the struct-field form anyway — it's cleaner, mirrors the prior-art `TenantResolverSpec` pattern, and doesn't rely on this behaviour being preserved across BoxLang releases.

**Why this fires only in specs**: production code rarely needs a catch to flip a boolean for a later read in the same function — typical catch blocks rethrow, log, or assign struct fields. Specs that use `try/catch` to *assert* exception propagation are the natural trap, since they need the post-catch flag.

**Reference**: issue #2744, regression test `vendor/wheels/tests/specs/model/lockingSpec.cfc :: "releases lock even when callback throws an exception"`. The same pattern works in `vendor/wheels/tests/specs/middleware/TenantResolverSpec.cfc` because it tracks state via `var result = {threw = false}; result.threw = true`.

### Private View Helpers Not Integrated

`$integrateComponents()` only copies `public` methods into controllers. Private helper functions in view CFCs are never available.

```cfm
// WRONG — private function won't be integrated
private string function myHelper() { ... }

// RIGHT — use public access with $ prefix for internal helpers
public string function $myHelper() { ... }
```

### `attributeCollection` with the `arguments` Scope (Adobe CF 2023/2025)

Adobe CF 2023 and 2025 reject the raw `arguments` scope when passed as `attributeCollection` to *any* built-in CFML tag, throwing engine-specific errors (`cfheader` reports `"Failed to add HTML header"`) and aborting the request. Lucee 6/7, BoxLang, and Adobe CF 2018/2021 all accept the `arguments` scope without complaint. Both the string-interpolated form (`attributeCollection = "#arguments#"`) and the CFScript direct-struct form (`attributeCollection = arguments`) are affected.

```cfm
// WRONG — crashes Adobe CF 2023 and 2025
cfheader(attributeCollection = "#arguments#");
cfimage(attributeCollection = arguments);

// RIGHT — copy to a plain struct first; either invocation form works once
// `local.args` is a plain struct (the engine's stricter check only objects
// to the special `arguments` scope object, not to the form of the call).
local.args = {};
for (local.key in arguments) {
    local.args[local.key] = arguments[local.key];
}
cfheader(attributeCollection = "#local.args#");
cfimage(attributeCollection = local.args);
```

**Why**: Adobe CF 2023 and 2025 impose a stricter type check on `attributeCollection` and require a plain CFML struct, not the special `arguments` scope object. The struct-copy pattern is safe and idiomatic across all engines. `$header()` is the dispatch-path blocker (runs on every request) — the others surface as soon as the corresponding helper is called.

**Reference fix**: [#2750](https://github.com/wheels-dev/wheels/pull/2750) (closes #2741) — patches all 13 affected wrappers in `vendor/wheels/Global.cfc` uniformly: `$header`, `$cache`, `$content`, `$mail`, `$directory`, `$file`, `$location`, `$htmlhead`, `$image`, `$dbinfo`, `$invoke`, `$wddx`, `$zip`. `$dbinfo()` rebuilds the local copy before each of its four `cfdbinfo` calls because the catch path mutates `arguments` between calls — a useful pattern when a helper writes through `arguments` between tag invocations.

### `cfheader` / `cfcontent` on a Committed Response (Adobe CF 2023/2025)

Adobe CF 2023/2025 throws `InvalidHeaderException: Failed to add HTML header` from `cfheader`, and a similar exception from `cfcontent`, once the servlet response has been committed (the output buffer flushed). This bites hardest inside `onError` handlers, where partial view output has typically already flushed before the handler runs — the secondary `cfheader` failure then replaces the original exception in the response. Lucee and BoxLang tolerate the same call as a no-op.

Use the canonical `$responseCommitted()` probe — `public boolean function $responseCommitted()` in `vendor/wheels/Global.cfc` — to short-circuit defensively. Wrap the actual tag call in `try/catch` and re-probe in the catch to rethrow only when the response is still uncommitted (a genuine caller bug):

```cfm
public void function $myTagWrapper() {
    local.args = {};
    for (local.key in arguments) local.args[local.key] = arguments[local.key];
    if ($responseCommitted()) return;
    try {
        cfheader(attributeCollection = "#local.args#");
    } catch (any e) {
        if (!$responseCommitted()) rethrow;
    }
}
```

`$header()` and `$content()` already adopt this shape. Future tag wrappers (`$location`, `$cache`, `$htmlhead`, `$mail`, …) should pick up `$responseCommitted()` rather than reinventing the probe.

**Reference fix**: [#2756](https://github.com/wheels-dev/wheels/pull/2756) — adds `$responseCommitted()` and applies the defensive shape to `$header()` and `$content()`.

### Bare `cfabort;` in Script Context (All Adobe CF Versions)

Adobe CF (2018, 2021, 2023, 2025) does not recognize `cfabort` as a CFScript keyword. Instead it resolves it as a variable name, throwing `Variable CFABORT is undefined` at runtime. Lucee accepts the bare form without error.

```cfm
// WRONG — crashes every Adobe CF version
cfabort;

// RIGHT — portable script keyword (all engines)
abort;

// ALSO RIGHT — parenthesized tag-in-script form
cfabort();
```

**Why**: Adobe's CFScript parser distinguishes between a handful of registered script keywords (`abort`, `exit`, `throw`, `rethrow`, …) and user variable names. `cfabort` was never a registered script keyword on Adobe — it was only ever the CFML tag name. Lucee is more permissive and accepts the bare form. Use the script keyword `abort;` everywhere in `vendor/wheels/` CFScript code.

**Detection**: the structural guard in `vendor/wheels/tests/specs/dispatch/BareCfabortStatementSpec.cfc` scans the framework source (comments stripped per Anti-Pattern #14) and fails the dispatch test suite if any bare `cfabort;` statement reappears.

**Reference fix**: [#3029](https://github.com/wheels-dev/wheels/issues/3029) / [#3032](https://github.com/wheels-dev/wheels/pull/3032) — the single occurrence in `vendor/wheels/Dispatch.cfc` (the public-component 404 branch) caused every Adobe install with `enablePublicComponent=false` to return a 500 error instead of the intended clean 404.

## Database-Specific Gotchas

### H2 Database (Test Default)

H2 is the embedded database used by default in tests. Key differences:
- Case-sensitive by default for identifiers
- `NOW()` is supported (Wheels normalizes this)
- Some MySQL-specific functions (e.g., `GROUP_CONCAT`) not available
- Simpler locking model than production databases

### Auto-Derived Property Casing — `$lowerCaseColumnNames()` Adapter Capability

When a model declares no `property()` mappings, Wheels infers its properties from `cfdbinfo` column metadata. The reported column casing varies by database, so the adapter layer carries a capability flag — `$lowerCaseColumnNames()` on `Base.cfc` — that controls whether the derived property name keeps the reported case or is forced to lowercase. Adapters override this when their database folds unquoted identifiers to a non-meaningful default that would otherwise leak into Wheels-side property names.

| Database | Folding behavior | `$lowerCaseColumnNames()` | Resulting property for column `isHidden` |
|----------|------------------|---------------------------|-------------------------------------------|
| SQL Server, MySQL, SQLite | Preserves declared case | `false` (Base default) | `isHidden` |
| PostgreSQL, CockroachDB | Folds unquoted identifiers to lowercase | `false` (Base default) | `ishidden` (database-reported) |
| Oracle | Folds unquoted identifiers to UPPERCASE | `true` (override) | `ishidden` (lowercased from `ISHIDDEN`) |
| H2 | Folds unquoted identifiers to UPPERCASE | `true` (override) | `ishidden` (lowercased from `ISHIDDEN`) |

```cfm
// vendor/wheels/databaseAdapters/Base.cfc
public boolean function $lowerCaseColumnNames() {
    return false;   // preserve reported case by default
}

// vendor/wheels/databaseAdapters/Oracle/OracleModel.cfc — override
public boolean function $lowerCaseColumnNames() {
    return true;    // ISHIDDEN → ishidden (Oracle folds to UPPERCASE)
}

// vendor/wheels/databaseAdapters/H2/H2Model.cfc — override
public boolean function $lowerCaseColumnNames() {
    return true;    // ISHIDDEN → ishidden (H2 folds to UPPERCASE)
}
```

**When adding a new database adapter**: check whether the database's unquoted-identifier folding rule produces case the Wheels developer actually declared. If it folds to UPPERCASE (Oracle/H2 family), override `$lowerCaseColumnNames()` to return `true`. If it preserves case (SQL Server/MySQL/SQLite) or folds to lowercase (PostgreSQL/CockroachDB), keep the Base default — the reported name is already the right property name.

**Explicit `property(name=..., column=...)` declarations bypass this entirely** — they always win, regardless of the adapter flag. The capability only affects the auto-derived path.

**Reference**: `vendor/wheels/Model.cfc` (auto-derivation site), `vendor/wheels/databaseAdapters/Base.cfc::$lowerCaseColumnNames`, regression spec `vendor/wheels/tests/specs/model/propertyCasePreservationSpec.cfc`, [#2852](https://github.com/wheels-dev/wheels/pull/2852).

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

### PostgreSQL / CockroachDB — Migration DDL Differences

`PostgreSQLMigrator.addColumnOptions` (shared by `CockroachDBMigrator`) diverges from `Abstract.addColumnOptions` in two intentional ways:

- **Empty string defaults**: Abstract-based adapters (MySQL, SQLite, H2, Oracle, MSSQL) omit the `DEFAULT` clause entirely when `default=""` on string/text/char columns. The PostgreSQL family emits `DEFAULT ''` explicitly.
- **Boolean literals**: Abstract-based adapters serialize `true` as `1` / `false` as `0`. The PostgreSQL family emits `DEFAULT true` / `DEFAULT false`.

When writing migrator spec assertions that check generated DDL, branch on `adapter.adapterName()`:

```cfm
var name = adapter.adapterName();
var isPostgresFamily = (name == "PostgreSQL" || name == "CockroachDB");
if (isPostgresFamily) {
    expect(sql).toInclude("DEFAULT true");
} else {
    // Abstract-based adapters (MySQL, SQLite, H2, Oracle, MSSQL)
    expect(sql).toInclude("DEFAULT 1");
}
```

See `vendor/wheels/tests/specs/migrator/addColumnOptionsSpec.cfc` and `migrationSpec.cfc` for working examples of this branching idiom.

### MySQL — TEXT and FLOAT DEFAULT suppression

`MySQLMigrator.optionsIncludeDefault` returns `false` for `text`, `mediumtext`, `longtext`, and `float` columns. The inherited `Abstract.addColumnOptions` short-circuits the entire `DEFAULT` clause when `optionsIncludeDefault` returns false — meaning a non-empty `default="long body"` on a `text` column is silently dropped in the emitted DDL on MySQL. Rationale: pre-8.0.13 MySQL rejects `DEFAULT` on `TEXT`/`BLOB` columns outright.

When writing migrator spec assertions that involve TEXT-family columns with non-empty defaults, add an `isMySQLFamily` carve-out alongside the `isPostgresFamily` one:

```cfm
var name = adapter.adapterName();
var isPostgresFamily = (name == "PostgreSQL" || name == "CockroachDB");
var isMySQLFamily = (name == "MySQL");

if (isMySQLFamily) {
    // DEFAULT clause is suppressed entirely for text/float on MySQL
    expect(sql).notToInclude("DEFAULT");
} else {
    expect(sql).toInclude("DEFAULT");
    expect(sql).toInclude("'long body'");
}
```

### CockroachDB (Soft-Fail in CI)

CockroachDB is in CI but marked as soft-fail — test failures are logged as warnings, not build failures. Controlled by `SOFT_FAIL_DBS` in `.github/workflows/tests.yml`.

### Oracle — Multi-Row INSERT and RETURNING Incompatibility

Oracle 23 rejects `INSERT INTO t (cols) VALUES (?,?), (?,?), ...` (the SQL-standard table value constructor) when the JDBC driver also requests `RETURN_GENERATED_KEYS`. The Oracle JDBC driver translates `RETURN_GENERATED_KEYS` into a `RETURNING ROWID INTO` clause, and Oracle 23 does not permit `RETURNING` combined with multi-row VALUES.

`OracleModel` overrides `$bulkInsertSQL()` to emit `INSERT ALL INTO t (cols) VALUES (...) INTO t (cols) VALUES (...) SELECT 1 FROM dual` — Oracle's idiomatic multi-row form, which avoids both the table value constructor and the RETURNING expansion. This is transparent to framework users; `insertAll()` works the same on Oracle as on other databases.

If you write code that generates raw bulk-insert SQL for Oracle (or adds a new adapter), use `INSERT ALL ... SELECT 1 FROM dual` rather than multi-row VALUES. The canonical implementation is `vendor/wheels/databaseAdapters/Oracle/OracleModel.cfc::$bulkInsertSQL`.

### Oracle — DDL Auto-Commit and Transaction Wrapper

Oracle implicitly commits DDL statements (RENAME, CREATE, ALTER, DROP, …) and closes the JDBC statement as part of that commit. If the DDL is wrapped in `transaction action="begin" { ... commit }`, the subsequent `transaction action="commit"` runs against a closed statement and raises `ORA: Closed statement`. PostgreSQL and SQLite (via SAVEPOINT) honor the wrapper and will roll back DDL on error. MySQL DDL also causes an implicit commit (the wrapper is a no-op there), but MySQL's multi-rename form — `RENAME TABLE a TO a', b TO b'` — is itself a single atomic statement, so no partial-rename scenario arises. Oracle cannot use the wrapper at all.

If you write code that runs DDL inside a transaction block, branch on the adapter and run the DDL bare on Oracle. The canonical implementation is `vendor/wheels/Migrator.cfc::renameSystemTables`:

```cfm
if (FindNoCase("Oracle", dbType)) {
    for (var sql in rv.sql) {
        $query(datasource = dsn, sql = sql);
    }
} else {
    transaction action="begin" {
        try {
            for (var sql in rv.sql) {
                $query(datasource = dsn, sql = sql);
            }
            transaction action="commit";
        } catch (any e) {
            transaction action="rollback";
            rethrow;
        }
    }
}
```

There is no rollback to forfeit on Oracle — the implicit commit makes each DDL atomic on its own.

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
