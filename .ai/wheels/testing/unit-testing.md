# Unit & Integration Testing in Wheels

## Two Test Frameworks

Wheels has two test frameworks. **All new tests must use TestBox.**

| | TestBox (current) | RocketUnit (legacy) |
|---|---|---|
| **Syntax** | `describe`/`it`/`expect` (BDD) | `test_methodName()` + `assert()` |
| **Base class** | `wheels.WheelsTest` | `wheels.tests.Test` |
| **Location** | `tests/specs/` | `vendor/wheels/tests/` |
| **Runner URL** | `/wheels/app/tests` | `/wheels/tests/core` |
| **Status** | Active, all new tests | Legacy, backwards-compat only |

## TestBox Test Structure

### File Layout

```
tests/
  _assets/
    models/         <- Test-only model CFCs (not app models)
      Model.cfc     <- Base model (extends wheels.Model)
      Author.cfc    <- Test model with table() override
      Post.cfc
  specs/
    models/          <- Model specs
      BatchProcessingSpec.cfc
      QueryBuilderSpec.cfc
    controllers/     <- Controller specs
    functional/      <- End-to-end specs
  populate.cfm       <- Creates/seeds test tables (runs before every test suite)
  runner.cfm         <- TestBox runner (web entry point)
```

### Writing a Spec

```cfm
component extends="wheels.WheelsTest" {
    function run() {
        describe("Feature Name", () => {

            it("does something specific", () => {
                var result = model("author").findAll();
                expect(result.recordcount).toBeGT(0);
            });

            it("returns a model object", () => {
                var obj = model("author").findOne(order="id");
                expect(IsObject(obj)).toBeTrue();
                expect(obj.firstName).toBe("Per");
            });

        });
    }
}
```

### Key Points

- **Extend `wheels.WheelsTest`** — this injects all `application.wo` methods (like `model()`) into the test scope automatically.
- **Use `function run()`** — TestBox calls this to discover specs. Not `init()`, not `config()`.
- **Arrow functions work** — `() => {}` is fine for `describe`/`it`/`beforeEach`.

## Test Models

Test models live in `tests/_assets/models/` and extend the local `Model.cfc` (which extends `wheels.Model`). They use `table()` to map to test tables created by `populate.cfm`.

```cfm
// tests/_assets/models/Author.cfc
component extends="Model" {
    function config() {
        table("c_o_r_e_authors");
        hasMany("posts");
    }
}
```

The test environment sets `modelPath` to `tests/_assets/models/` so `model("author")` resolves to your test model, not an app model.

## Test Data (populate.cfm)

`tests/populate.cfm` runs before every test suite invocation. It creates tables and seeds data.

**Always use DROP + CREATE, never IF NOT EXISTS:**

```cfm
<!--- DROP first — IF NOT EXISTS misses schema changes --->
<cftry>
    <cfquery datasource="#application.wheels.dataSourceName#">
        DROP TABLE IF EXISTS c_o_r_e_posts
    </cfquery>
    <cfcatch></cfcatch>
</cftry>

<!--- Then CREATE --->
<cfquery datasource="#application.wheels.dataSourceName#">
CREATE TABLE c_o_r_e_posts (
    id #local.identityColumnType#,
    title varchar(250) NOT NULL,
    ...
    PRIMARY KEY(id)
) #local.storageEngine#
</cfquery>
```

**Why not IF NOT EXISTS?** If you add a column (like `status`) to a table that already exists from a previous test run, IF NOT EXISTS skips the CREATE and the column is missing. DROP + CREATE guarantees a clean schema every time.

## Running Tests

### Via URL (most reliable)

```
# All specs in a directory
/wheels/app/tests?format=json&directory=tests.specs.models

# Single spec bundle
/wheels/app/tests?format=json&bundles=tests.specs.models.BatchProcessingSpec

# HTML output (for browser)
/wheels/app/tests?format=html&directory=tests.specs.models

# Force model cache reload (needed after adding new model CFCs)
/wheels/app/tests?format=json&directory=tests.specs.models&reload=true
```

### Via curl + node (for CLI parsing)

```bash
curl -sL "http://localhost:60006/wheels/app/tests?format=json&directory=tests.specs.models&reload=true" \
  > /tmp/testbox_results.json && node -e "
const j = JSON.parse(require('fs').readFileSync('/tmp/testbox_results.json', 'utf8'));
console.log('Passed:', j.totalPass, '| Failed:', j.totalFail, '| Errors:', j.totalError);
for (const b of j.bundleStats) {
  console.log('\n' + b.name + ' (' + b.totalPass + '/' + b.totalSpecs + ')');
  function printSuite(s, indent) {
    for (const sp of (s.specStats || [])) {
      if (sp.status !== 'Passed') console.log(indent + '[FAIL] ' + sp.name + ': ' + sp.failMessage);
    }
    for (const ns of (s.suiteStats || [])) printSuite(ns, indent + '  ');
  }
  for (const s of b.suiteStats) printSuite(s, '  ');
}
"
```

**Why node instead of jq?** The Wheels TestBox JSON response contains unquoted `true`/`false` booleans that break strict JSON parsers. Node's `JSON.parse` handles them.

## Common Gotchas

### 1. CFML Closure Scoping

Closures in CFML have their own `local` scope. You **cannot** read/write outer `local` variables from inside a closure.

```cfm
// WRONG — `local.count` inside the closure is a DIFFERENT variable
var count = 0;
model("author").findEach(callback = function(author) {
    count++; // This modifies the closure's local.count, not the outer one
});
expect(count).toBe(10); // FAILS — count is still 0

// RIGHT — use a shared struct (structs are passed by reference)
var result = {count: 0};
model("author").findEach(callback = function(author) {
    result.count++; // Modifies the shared struct
});
expect(result.count).toBe(10); // PASSES
```

### 2. Model Cache After Adding New CFCs

After adding a new model CFC to `tests/_assets/models/`, the first test run may fail with errors like `table 'authorscopeds' not found` — Wheels is using default table name conventions because it hasn't loaded your `config()` yet.

**Fix:** Add `&reload=true` to the test runner URL to clear the model cache.

### 3. Table Naming in Test Models

Always call `table()` in your test model's `config()` to map to the test table name. Without it, Wheels pluralizes the model name (e.g., `AuthorScoped` -> `authorscopeds`).

```cfm
component extends="Model" {
    function config() {
        table("c_o_r_e_authors"); // Explicit table name
    }
}
```

### 4. Drop Order for Foreign Keys

Drop child tables before parent tables in `populate.cfm`:

```cfm
DROP TABLE IF EXISTS c_o_r_e_posts   <!--- child (has authorid FK) --->
DROP TABLE IF EXISTS c_o_r_e_authors <!--- parent --->
```

### 5. Pre-existing Test Failures

The `vendor/wheels/tests/` RocketUnit suite has some pre-existing failures (e.g., in `model.errors`). Don't chase these — they're known issues in the legacy suite. Focus on making your TestBox specs green.
