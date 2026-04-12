# CLI Test Infrastructure Design

## Goal

Add a TestBox-based test suite for the LuCLI CLI module commands and services, runnable in CI alongside existing core framework tests using the same server instance.

## Scope Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Test location | `cli/lucli/tests/` with own runner | CLI module is a separate concern from framework core; tests ship with the module |
| Base class | `wheels.wheelstest.system.BaseSpec` | Pure TestBox BDD; services are independent of `application.wheels` |
| Project isolation | Copy project skeleton to temp dir | Single source of truth (no fixture maintenance); all tests use same copy |
| Server port | `PORT` env var, fallback 60007 | Matches CI convention in `run-tests.sh` |
| Integration test skip | Skip with message if no server | Suite stays green locally without a server running |
| REPL | Not used for test execution | HTTP tests verify actual endpoints; REPL is a debugging tool |

## Architecture

### Test Directory

```
cli/lucli/tests/
├── runner.cfm              # TestBox entry point
├── TestHelper.cfc          # Shared: temp project setup, HTTP helper, cleanup
└── specs/
    ├── services/
    │   ├── HelpersSpec.cfc
    │   ├── DestroySpec.cfc
    │   ├── DoctorSpec.cfc
    │   ├── StatsSpec.cfc
    │   ├── AdminSpec.cfc
    │   └── CodeGenSpec.cfc
    └── integration/
        ├── DbCommandsSpec.cfc
        └── IntrospectSpec.cfc
```

### Test Lifecycle

```
beforeAll():
  1. helper = new cli.lucli.tests.TestHelper()
  2. tempRoot = helper.scaffoldTempProject(expandPath("/"))
  3. Instantiate services with projectRoot = tempRoot, moduleRoot = expandPath("/cli/lucli/")

afterAll():
  1. helper.cleanupTempProject(tempRoot)
```

All CLI tests — unit and integration — run against the temp dir. No tests operate on the real project root.

### Temp Project Copy

**Copied from project root:**
- `app/` — controllers, models, views, helpers, migrator/migrations
- `config/` — routes.cfm, settings.cfm, environment.cfm
- `tests/specs/` — directory structure (for doctor/stats scanning)
- `public/` — directory structure
- `.env` (if exists)

**Not copied:**
- `vendor/`, `.git/`, `node_modules/`, `docs/`, `tools/`, `.claude/`, build artifacts

**Module root** points to the real `cli/lucli/` path — templates aren't project-specific and don't need copying.

## Test Categories

### Category A: Service Unit Tests

Direct CFC instantiation with real `Helpers.cfc` dependency and temp project root.

#### HelpersSpec.cfc — Pure Logic (no temp dir needed)

- `pluralize()`: user→users, person→people, sheep→sheep, child→children
- `singularize()`: users→user, people→person, mice→mouse
- `capitalize()`: user→User, empty string→empty string
- `stripSpecialChars()`: removes brackets, ampersands, etc.
- `generateMigrationTimestamp()`: returns 14-digit numeric string

#### DestroySpec.cfc

- Create a model file in temp, destroy model type → file gone + migration CFC created
- Create controller + test files, destroy controller type → only controller files removed, no migration
- Destroy resource type → all 6 file paths removed + route line removed from routes.cfm + migration generated
- Destroy view with "/" syntax → single .cfm file removed
- Destroy view without "/" → entire views dir + test views dir removed
- `previewDestroy()` returns array matching what actual destroy would delete
- Destroying non-existent files produces warnings array, not errors
- Route cleanup: `.resources("plural")` line removed, other lines preserved

#### DoctorSpec.cfc

- All required dirs/files present → status `HEALTHY`, zero issues
- Remove a required dir (e.g., `app/controllers/`) → status `CRITICAL`
- Remove recommended dir (`tests/`) → status `WARNING` with recommendation
- Write permission test passes on writable temp dir
- Empty routes.cfm (< 10 chars) → config validation warning
- No datasource keyword in settings.cfm → database config warning
- No .cfc files in tests/specs/ → test coverage warning
- Recommendations array populated based on detected issues

#### StatsSpec.cfc

- File counts per category match actual files in temp project
- LOC counting: pure code line classified as LOC, not comment or blank
- CFML block comment `<!--- ... --->` spanning multiple lines tracked correctly
- `//` line comment detected
- Blank lines detected
- `getNotes()` finds `// TODO: text` with correct file path and line number
- Custom annotation types (`--custom=HACK`) searched
- Annotation text extracted after colon, trailing delimiters stripped

#### AdminSpec.cfc

- `mapColumnToFormHelper()`: string→textField, boolean→checkBox, text→textArea, integer→numberField, date→dateField, datetime→dateTimeLocalField
- Name conventions: column named "email"→emailField, "phone"→telField, "website"→urlField
- `buildFormFields()` excludes columns named id, createdAt, updatedAt
- `buildForeignKeyLoaders()` generates private loader function per belongsTo association
- `injectAdminRoute()` creates `.scope(path="admin")` block in routes.cfm
- `injectAdminRoute()` appends to existing admin scope without duplicating
- `generateAdmin()` creates controller CFC + 5 view files in correct paths
- `generateAdmin()` with `force=false` errors when files already exist

#### CodeGenSpec.cfc

- `generateModel()` creates CFC in app/models/ with correct PascalCase name
- `generateController()` creates CFC in app/controllers/
- Properties parsed from attribute strings: `name` → `{name: "name", type: "string"}`, `price:decimal` → `{name: "price", type: "decimal"}`
- Route injection adds `.resources("plural")` to routes.cfm
- Generated model includes `config()` function with associations and validations

### Category B: Integration Tests

HTTP calls to the running server. Skip gracefully if no server is detected.

#### DbCommandsSpec.cfc

- `GET /wheels/cli?command=dbStatus&format=json` returns valid JSON with `success`, `migrations` array, `summary` struct
- `summary` contains `total`, `applied`, `pending` as non-negative integers
- `GET /wheels/cli?command=dbVersion&format=json` returns `success` and `version` string
- Each migration entry has `version`, `description`, `status` fields

#### IntrospectSpec.cfc

- `GET /wheels/cli?command=introspect&model=<testmodel>&format=json` returns column metadata
- Response has `success: true`, `model`, `tableName`, `primaryKey`, `columns` array, `associations` array
- Each column has `name` and `type` fields
- Missing model parameter → `success: false` with error message
- Non-existent model → `success: false` with error message
- Primary key column has `primaryKey: true`

**Test model:** Uses one of the existing test models in `vendor/wheels/tests/_assets/models/` that the core test suite already seeds (e.g., `Author` or `Post`). This avoids needing to create test-specific models.

### Skip Behavior for Integration Tests

Each integration spec checks for a running server in `beforeAll()`:

```cfml
variables.serverPort = helper.detectServerPort();
if (!variables.serverPort) {
    variables.skipIntegration = true;
}
```

Each `it()` block checks `if (variables.skipIntegration) return;` at the top. This keeps the tests discoverable (they show up in results) but they don't fail when no server is running.

## Test Runner

### runner.cfm

- Creates `TestBox` instance: `new wheels.wheelstest.system.TestBox(directory="cli.lucli.tests.specs")`
- Reads `url.format` (default: `json`)
- Uses `JSONReporter` for CI, `SimpleReporter` for browser
- Sets HTTP status 417 on failures, 200 on success (same convention as core tests)
- No framework initialization needed — specs use `BaseSpec`, not `WheelsTest`

### URL

```
http://localhost:<port>/cli/lucli/tests/runner.cfm?format=json
```

Served directly by the LuCLI web server since it serves the project root as webroot.

## CI Integration

### tools/ci/run-tests.sh Changes

After the existing core test execution block, add a CLI test block:

```bash
# CLI Module Tests
CLI_URL="${BASE_URL}/cli/lucli/tests/runner.cfm?format=json"
CLI_RESULT_FILE="${RESULT_DIR}/cli-test-results.json"
CLI_JUNIT_FILE="${JUNIT_DIR}/cli-junit.xml"
echo "Running CLI module tests..."
HTTP_CODE=$(curl -s -o "$CLI_RESULT_FILE" -w "%{http_code}" "$CLI_URL")
```

**Result capture requirements:**
- CLI test JSON results saved to `$RESULT_DIR/cli-test-results.json` — uploaded as artifact alongside core test results
- CLI JUnit XML generated at `$JUNIT_DIR/cli-junit.xml` — picked up by the existing JUnit artifact upload step
- Pass/fail/error counts printed to CI log with clear `[CLI Tests]` prefix to distinguish from core test output
- Non-zero exit code if any CLI tests fail — the script's overall exit code must reflect both core AND CLI test results
- If CLI test runner returns HTTP 417 (failures) or non-200, treat as failure

**CI log output format:**
```
[CLI Tests] 45 pass, 0 fail, 0 error
```
or on failure:
```
[CLI Tests] 42 pass, 2 fail, 1 error
[CLI Tests] FAILED — see cli-test-results.json for details
```

### Workflow Artifact Handling

The `snapshot.yml` workflow already uploads `$RESULT_DIR/` and `$JUNIT_DIR/` contents as artifacts. Since CLI results write to the same directories, they're captured automatically — no workflow file changes needed.

### Combined Exit Code

The script must track both core and CLI test outcomes. If either suite has failures, the script exits non-zero to fail the CI job:

```bash
CORE_OK=true   # set false if core tests fail
CLI_OK=true    # set false if CLI tests fail
# ... run both suites ...
if [ "$CORE_OK" = false ] || [ "$CLI_OK" = false ]; then
  exit 1
fi
```

## TestHelper.cfc

### Public Methods

- `scaffoldTempProject(sourceRoot)` — copies project skeleton to temp dir under system temp path, returns temp root path
- `cleanupTempProject(tempRoot)` — recursively deletes temp dir
- `detectServerPort()` — reads `PORT` env var → checks port 8080 → checks port 60007, returns port number or 0
- `httpGet(url)` — HTTP GET using `java.net.URL.openConnection()`, returns response string. Same pattern as Module.cfc's `makeHttpRequest()`.

### Debugging

The LuCLI REPL (`wheels console`) shares the running server's runtime context and can be used to interactively debug test failures — inspect `application.wheels`, call `model().$classData()`, verify server state.

## Files Summary

| File | Type | Description |
|------|------|-------------|
| `cli/lucli/tests/runner.cfm` | New | TestBox entry point |
| `cli/lucli/tests/TestHelper.cfc` | New | Temp project scaffolding, HTTP helper |
| `cli/lucli/tests/specs/services/HelpersSpec.cfc` | New | Helpers service tests |
| `cli/lucli/tests/specs/services/DestroySpec.cfc` | New | Destroy service tests |
| `cli/lucli/tests/specs/services/DoctorSpec.cfc` | New | Doctor service tests |
| `cli/lucli/tests/specs/services/StatsSpec.cfc` | New | Stats + notes service tests |
| `cli/lucli/tests/specs/services/AdminSpec.cfc` | New | Admin service tests |
| `cli/lucli/tests/specs/services/CodeGenSpec.cfc` | New | CodeGen service tests |
| `cli/lucli/tests/specs/integration/DbCommandsSpec.cfc` | New | DB endpoint integration tests |
| `cli/lucli/tests/specs/integration/IntrospectSpec.cfc` | New | Introspect endpoint integration tests |
| `tools/ci/run-tests.sh` | Modified | Add CLI test curl block |
