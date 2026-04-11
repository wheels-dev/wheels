# CLI Tier 1 Porting — LuCLI Module Commands

## Goal

Port the 8 highest-value Wheels CLI commands from the CommandBox-based CLI to the LuCLI module, closing the feature gap for developers migrating to the new `wheels` binary.

## Scope Decisions

These decisions were made during design review:

| Decision | Choice | Rationale |
|----------|--------|-----------|
| `db create/drop` | **Skip** | SQLite/H2 auto-create; other DBs are pre-existing in real projects |
| `db reset` | **Migrate + seed only** | No drop/create step — resets data, not schema |
| `generate admin` | **HTTP introspection** | Models derive schema from DB, not CFC source; static parsing would miss most fields |
| `upgrade` | **Check-only, no mechanical upgrade** | `brew upgrade` and `lucli modules update` handle the mechanics; value is in breaking changes detection |
| `destroy` migrations | **Generate but don't auto-run** | Safer; user reviews migration before applying |
| New service files | **Service-per-feature in services/** | Follows existing pattern (Analysis.cfc, Scaffold.cfc); keeps Module.cfc as thin dispatch |

## Architecture

```
cli/lucli/
├── Module.cfc                      # +~200 lines: 8 thin public dispatch functions
├── services/
│   ├── Destroy.cfc                 # NEW: file deletion, route cleanup, migration gen
│   ├── Doctor.cfc                  # NEW: health checks
│   ├── Stats.cfc                   # NEW: code statistics + notes extraction
│   ├── Admin.cfc                   # NEW: admin CRUD generation via server introspection
│   ├── Analysis.cfc                # existing
│   ├── CodeGen.cfc                 # existing
│   ├── Helpers.cfc                 # existing
│   ├── MCP.cfc                     # existing
│   ├── MigrationRunner.cfc         # existing
│   ├── Scaffold.cfc                # existing
│   ├── Templates.cfc               # existing
│   └── TestRunner.cfc              # existing
└── templates/
    ├── admin/                      # NEW: 6 admin generation templates
    │   ├── controller.txt
    │   ├── index.txt
    │   ├── show.txt
    │   ├── new.txt
    │   ├── edit.txt
    │   └── _form.txt
    └── migrations/
        └── remove_table.txt        # NEW: drop table migration template
```

All new services follow the existing pattern:
- Constructor receives dependencies (`helpers`, `projectRoot`, etc.)
- Lazy-instantiated via `getService()` in Module.cfc
- Return structs with `{success, error, ...}` shape
- No CommandBox dependencies — pure CFML

---

## Command 1: `wheels destroy`

### Syntax

```
wheels destroy <name> [type]
wheels d <name> [type]              # alias
```

**Arguments:**
- `name` (required): Component name (e.g., "User", "Products", "products/index")
- `type` (optional, default: "resource"): One of `resource`, `model`, `controller`, `view`

**Flags:**
- `--force`: Skip confirmation prompt

### Service: `Destroy.cfc`

**Constructor:** `init(helpers, projectRoot)`

**Public methods:**
- `destroyResource(name, force)` — delete model + controller + views + tests + route + generate migration
- `destroyModel(name, force)` — delete model + test + generate migration
- `destroyController(name, force)` — delete controller + test
- `destroyView(name, force)` — delete view dir (or single file if name contains "/")

### Behavior Matrix

| Type | Files Removed | Route Cleanup | Migration Generated |
|------|--------------|---------------|-------------------|
| `resource` | model CFC, controller CFC, views dir, model test, controller test, view tests dir | Remove `.resources("plural")` line | `dropTable(tableName="plural")` |
| `model` | model CFC, model test | No | `dropTable(tableName="plural")` |
| `controller` | controller CFC, controller test | No | No |
| `view <name>` | views dir + view tests dir | No | No |
| `view <name>/<file>` | single view `.cfm` file | No | No |

### File Path Resolution

Uses `Helpers.cfc` singularize/pluralize for name variants:

| Input | Singular | Plural | Singular Cap | Plural Cap |
|-------|----------|--------|-------------|------------|
| `user` | user | users | User | Users |
| `Products` | product | products | Product | Products |

File paths derived:
- Model: `app/models/{SingularCap}.cfc`
- Controller: `app/controllers/{PluralCap}.cfc`
- Views: `app/views/{plural}/`
- Model test: `tests/specs/models/{SingularCap}Spec.cfc`
- Controller test: `tests/specs/controllers/{PluralCap}Spec.cfc`
- View tests: `tests/specs/views/{plural}/`

### Route Cleanup

1. Read `config/routes.cfm`
2. Find line containing `.resources("{plural}")` (case-insensitive)
3. Remove that line (including trailing newline)
4. Write file back

### Migration Generation

Generate timestamped migration at `app/migrator/migrations/{timestamp}_remove_{plural}_table.cfc`:

```cfml
component extends="wheels.migrator.Migration" {
    function up() {
        dropTable(tableName="{plural}");
    }
    function down() {
        // Recreate table manually if needed
    }
}
```

Do NOT auto-execute. Output message: "Migration generated. Run `wheels migrate latest` to apply."

### Confirmation

Unless `--force`, display file list and prompt:
```
The following will be deleted:
  app/models/Product.cfc
  app/controllers/Products.cfc
  app/views/products/
  tests/specs/models/ProductSpec.cfc
  tests/specs/controllers/ProductsSpec.cfc
  Route: .resources("products") from config/routes.cfm
  Migration will be generated to drop table: products

Proceed? [y/n]
```

### Error Handling

- File doesn't exist: warn and continue (partial destroys are fine)
- Route line not found: warn, skip route cleanup
- Directory doesn't exist: warn, skip

---

## Command 2: `wheels doctor`

### Syntax

```
wheels doctor [--verbose]
```

### Service: `Doctor.cfc`

**Constructor:** `init(projectRoot)`

**Public methods:**
- `runChecks(verbose)` — returns `{issues: [], warnings: [], passed: [], status: "CRITICAL|WARNING|HEALTHY"}`

### Health Checks

**No running server required — all local file operations.**

#### 1. Required Directories (Critical)

Check existence of:
- `app/`
- `app/controllers/`
- `app/models/`
- `app/views/`
- `config/`
- `public/`

Missing = critical issue.

#### 2. Recommended Directories (Warning)

Check existence of:
- `tests/`
- `tests/specs/`
- `app/migrator/migrations/`

Missing = warning.

#### 3. Required Files (Critical)

Check existence of:
- `config/routes.cfm`
- `config/settings.cfm`

Missing = critical issue.

#### 4. Configuration Validation (Warning)

- `config/routes.cfm` has content (length > 10 chars)
- `config/settings.cfm` is parseable (not empty)

#### 5. Write Permissions (Warning)

Test write access on:
- `app/migrator/migrations/`
- `public/files/` (if exists)

Mechanism: create `.write_test_<uuid>` file, delete it. Failure = warning.

#### 6. Database Configuration (Warning)

- Scan `config/settings.cfm` for `datasource` or `dataSourceName`
- Scan `.env` for `DATABASE` or `DB_` prefix
- Count `.cfc` files in `app/migrator/migrations/`
- No datasource config found = warning
- No migrations found = warning

#### 7. Test Coverage (Warning)

- Count `.cfc` files in `tests/specs/` recursively
- Zero test files = warning

### Output Format

```
Wheels Health Check
═══════════════════

✗ Issues (N):
  {description}

⚠ Warnings (N):
  {description}

✓ Passed (N):                ← only with --verbose or when no issues/warnings
  {description}

Status: {CRITICAL|WARNING|HEALTHY}

Recommendations:
  • {context-aware suggestion}
```

### Recommendations Logic

| Condition | Recommendation |
|-----------|---------------|
| No datasource config | "Configure your datasource in config/settings.cfm or .env" |
| No migrations | "Run 'wheels generate migration' to create your first migration" |
| No tests | "Run 'wheels generate test' to add test coverage" |
| Missing dirs | "Run 'wheels new' to scaffold a complete project structure" |

---

## Command 3: `wheels stats`

### Syntax

```
wheels stats [--verbose]
```

### Service: `Stats.cfc`

**Constructor:** `init(helpers, projectRoot)`

**Public methods:**
- `getStats(verbose)` — returns `{categories: [...], totals: {}, topFiles: []}`
- `getNotes(annotations, custom)` — returns `{annotations: {...}, total: N}`

### Directory Scanning

| Category | Path | Extensions |
|----------|------|-----------|
| Controllers | `app/controllers/` | `.cfc` |
| Models | `app/models/` | `.cfc` |
| Views | `app/views/` | `.cfm` |
| Helpers | `app/helpers/` | `.cfc` |
| Tests | `tests/specs/` | `.cfc` |
| Migrations | `app/migrator/migrations/` | `.cfc` |
| Config | `config/` | `.cfm` |

### Line Classification

For each file, classify every line:

- **Code:** Non-blank, non-comment lines
- **Comment:** Lines inside `<!--- --->`, `/* */`, or starting with `//` (after trim)
- **Blank:** Empty or whitespace-only

Multiline comment tracking via boolean state flag.

### Output

```
Code Statistics
═══════════════
Category       Files    LOC    Comments    Blanks    Total
Controllers       12    450          80        60      590
Models             8    320          45        40      405
Views             35   1200          30        90     1320
Helpers            3     85          20        10      115
Tests             15    600          40        50      690
Migrations        10    200          15        25      240
Config             4     80          30        10      120
─────────────────────────────────────────────────────────
Total             87   2935         260       285     3480

Code-to-test ratio: 1:0.28
Average lines/file: 40
```

**Verbose:** Appends "Top 10 Largest Files" list with paths and line counts.

---

## Command 4: `wheels notes`

### Syntax

```
wheels notes [--annotations=TODO,FIXME,OPTIMIZE] [--custom=HACK,REVIEW]
```

### Service

Uses `Stats.cfc.getNotes()` (same service — related file-scanning concern).

### Scan Directories

- `app/`
- `config/`
- `tests/`
- `app/migrator/migrations/`

### Pattern Matching

Search for annotation keywords at the start of comment content (after comment delimiter):
- `// TODO: ...`
- `<!--- FIXME: ... --->`
- `/* OPTIMIZE: ... */`

Extract: annotation type, file path (relative to project root), line number, text after the colon.

### Output

```
TODO (3):
  app/models/User.cfc:45 — implement email validation
  app/controllers/Orders.cfc:12 — add pagination
  config/routes.cfm:8 — add API versioning

FIXME (1):
  app/views/products/index.cfm:22 — query returns duplicates

Summary: 4 annotations (3 TODO, 1 FIXME)
```

---

## Command 5: `wheels generate admin`

### Syntax

```
wheels generate admin <modelName> [--force] [--no-routes]
```

### Service: `Admin.cfc`

**Constructor:** `init(helpers, templateService, projectRoot)`

**Public methods:**
- `generateAdmin(modelName, force, noRoutes, serverPort)` — returns `{success, files: [], error}`

### Requires Running Server

Uses HTTP introspection to get model schema. Fails with clear message if server not running.

### Server Endpoint

**Request:** `GET http://localhost:<port>/wheels/cli?command=introspect&model=<modelName>`

**Response:**
```json
{
    "model": "Product",
    "tableName": "products",
    "primaryKey": "id",
    "columns": [
        {"name": "id", "type": "integer", "primaryKey": true},
        {"name": "name", "type": "string", "maxLength": 255},
        {"name": "price", "type": "decimal"},
        {"name": "categoryId", "type": "integer", "foreignKey": true, "referencedModel": "Category"},
        {"name": "active", "type": "boolean"},
        {"name": "description", "type": "text"},
        {"name": "createdAt", "type": "datetime"},
        {"name": "updatedAt", "type": "datetime"}
    ],
    "associations": [
        {"type": "belongsTo", "name": "category", "modelName": "Category"}
    ]
}
```

**This endpoint must be added to Wheels core** — a new handler in the existing CLI bridge. ~50 lines.

### Files Generated

| File | Description |
|------|-------------|
| `app/controllers/admin/{PluralCap}.cfc` | Controller with index (search + pagination), show, new, edit, create, update, delete |
| `app/views/admin/{plural}/index.cfm` | Table listing with search form |
| `app/views/admin/{plural}/show.cfm` | Detail view |
| `app/views/admin/{plural}/new.cfm` | New record form |
| `app/views/admin/{plural}/edit.cfm` | Edit record form |
| `app/views/admin/{plural}/_form.cfm` | Shared form partial |

### Controller Features

- `index`: Pagination via `findAll(page=params.page, perPage=25)`, search WHERE clause built from string/text columns
- `show/edit`: `findByKey(params.key)` with 404 handling
- `create/update`: Mass assignment via `params.{singular}` struct, redirect on success, render form on validation failure
- `delete`: `findByKey` + `delete()`, redirect to index
- `protectsFromForgery()` in config
- Private `loadCategories()` (etc.) for each `belongsTo` association — loads related records for `<select>` dropdowns

### Form Field Type Mapping

| Column Type | Form Helper |
|------------|-------------|
| `string`, `varchar` | `textField()` |
| `text` | `textArea()` |
| `boolean`, `bit` | `checkBox()` |
| `integer`, `numeric` | `numberField()` |
| `decimal`, `float` | `numberField(step="0.01")` |
| `date` | `dateField()` |
| `datetime` | `dateTimeLocalField()` |
| `email` (by column name) | `emailField()` |
| `url` / `website` (by name) | `urlField()` |
| `phone` / `tel` (by name) | `telField()` |

Columns named `id`, `createdAt`, `updatedAt` are excluded from forms.

### Route Injection

Adds to `config/routes.cfm`:

```cfml
.scope(path="admin", package="admin")
    .resources("{plural}")
.end()
```

If an existing `.scope(path="admin"` block is detected, appends `.resources("{plural}")` inside it rather than creating a duplicate scope.

Skipped if `--no-routes` flag set.

### Template Files

6 new templates in `cli/lucli/templates/admin/`:

- `controller.txt` — admin controller with `{{PluralCap}}`, `{{SingularCap}}`, `{{singular}}`, `{{plural}}`, `{{ForeignKeyLoaders}}`, `{{SearchWhereClause}}`, `{{BeforeFilters}}` placeholders
- `index.txt` — table with `{{columns}}` loop placeholder
- `show.txt` — detail display with `{{fields}}` placeholder
- `new.txt` — new form wrapper
- `edit.txt` — edit form wrapper
- `_form.txt` — form fields with `{{formFields}}` placeholder

Templates use the same `{{placeholder}}` substitution as existing `Templates.cfc`.

---

## Command 6: `wheels db reset`

### Syntax

```
wheels db reset [--skip-seed] [--force]
```

### Implementation

Inline private function in Module.cfc. No dedicated service.

**Requires running server.**

### Flow

1. Confirm: "Reset database? This will run pending migrations and reseed. [y/n]" (unless `--force`)
2. Call `migrate("latest")` — runs any pending migrations via existing module migrate command
3. Unless `--skip-seed`: call `seed()` — delegates to existing module seed command
4. Output: "Database reset complete."

### Error Handling

- Server not running: "Start the server first with `wheels start`"
- Migration fails: Show migration error, stop before seeding
- Seed fails: Show seed error, note that migrations were applied successfully

---

## Command 7: `wheels db status` / `wheels db version`

### Syntax

```
wheels db status [--pending]
wheels db version [--detailed]
```

### Implementation

Inline private functions in Module.cfc. No dedicated service.

**Requires running server.**

### db status

HTTP GET to `http://localhost:<port>/wheels/cli?command=dbStatus`

**Output:**
```
Migration Status
════════════════
Version          Description              Status     Applied
20260101120000   Create users table       Applied    2026-01-01 12:05
20260115080000   Add email to users       Applied    2026-01-15 08:12
20260201090000   Create products table    Pending    —

Total: 3 | Applied: 2 | Pending: 1
```

With `--pending`: filter to show only rows with Pending status.

### db version

HTTP GET to `http://localhost:<port>/wheels/cli?command=dbVersion`

**Default output:**
```
Database version: 20260115080000
```

**With `--detailed`:**
```
Database version: 20260115080000
Last migration:   Add email to users (applied 2026-01-15 08:12)
Total migrations: 3
Pending:          1
Next:             20260201090000 — Create products table
```

### Server Endpoints

`dbStatus` and `dbVersion` already exist in the Wheels CLI bridge — used by CommandBox CLI today. No core changes needed.

---

## Command 8: `wheels upgrade check`

### Syntax

```
wheels upgrade check [--to=<version>]
```

### Implementation

Inline private function in Module.cfc (~80 lines). No dedicated service.

**No running server required — pure file scanning + optional GitHub API call.**

### Flow

1. Read current version from `vendor/wheels/box.json` → `version` field
2. If `--to` not provided: HTTP GET `https://api.github.com/repos/wheels-dev/wheels/releases/latest` → extract tag name. If the API call fails (offline, rate-limited), prompt user to provide `--to` manually.
3. Compare major versions of current vs target
4. If major version differs, scan app code for known breaking patterns
5. Output results

### Breaking Changes Database

Hardcoded struct in the function, keyed by version transition:

**2.x → 3.x:**
- `plugins/` directory exists → "Migrate to packages/ + vendor/ system"
- `extends="wheels.Test"` in test files → "Change to `wheels.WheelsTest`"
- Old route syntax patterns → "Update to mapper() callback syntax"

**3.x → 4.x:**
- `plugins/` directory exists → "Plugin system deprecated, use packages"
- `application.wirebox` references → "DI container API changed"
- Missing `app/middleware/` patterns → "Middleware system available"

### App Scanning

For each breaking change pattern:
1. Glob for relevant files (e.g., `tests/specs/**/*.cfc`)
2. Grep for the old pattern
3. Collect file paths + line numbers for matches

### Output

```
Current version: 3.1.0
Latest version:  4.0.0

Breaking Changes (2 found):
  ⚠ Legacy plugin detected: app/plugins/MyPlugin/
    → Migrate to packages/ system

  ⚠ Old test base class in 3 files:
    tests/specs/models/UserSpec.cfc:1
    tests/specs/models/OrderSpec.cfc:1
    → Change to extends="wheels.WheelsTest"

All Clear (3 checks):
  ✓ Route syntax is current
  ✓ DI container usage is current
  ✓ No deprecated functions found

Upgrade with: brew upgrade wheels
```

---

## Wheels Core Change

### Model Introspection Endpoint

Add `introspect` command handler to the existing CLI bridge at the endpoint that handles `/wheels/cli?command=...` requests.

**Input:** `command=introspect&model=<modelName>`

**Logic:**
1. Call `model(modelName)` to get model instance
2. Use `$classData()` or equivalent to extract: columns (name, type, maxLength, primaryKey), associations (type, name, modelName), table name, primary key name
3. Serialize as JSON response

**Output:** JSON object as specified in Command 5 above.

**Location:** Alongside existing `migrate`, `seed`, `dbStatus`, `dbVersion` handlers in the CLI bridge code.

**Size:** ~50 lines.

---

## MCP Integration

New commands auto-register as MCP tools via existing module discovery:

| MCP Tool | Maps To |
|----------|---------|
| `wheels_destroy` | `destroy()` |
| `wheels_doctor` | `doctor()` |
| `wheels_stats` | `stats()` |
| `wheels_notes` | `notes()` |
| `wheels_db` | `db()` (reset/status/version subcommands) |
| `wheels_upgrade_check` | `upgradeCheck()` |
| `wheels_generate` | existing — `admin` added as new subcommand |

MCP tool schemas added to `services/MCP.cfc` `getToolSchemas()` method.

---

## Summary

| Component | New Files | Lines (est.) | Server Required |
|-----------|----------|-------------|-----------------|
| Destroy.cfc | 1 service + 1 template | ~220 | No |
| Doctor.cfc | 1 service | ~250 | No |
| Stats.cfc | 1 service | ~300 | No |
| Admin.cfc | 1 service + 6 templates | ~400 | Yes |
| Module.cfc dispatch | — (modifications) | ~200 | — |
| Core introspect endpoint | 1 handler | ~50 | — |
| **Total** | **4 services, 8 templates, 1 core handler** | **~1,420** | — |
