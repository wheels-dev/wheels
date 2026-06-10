# Migrator

CFML migration runtime. `Migrator.cfc` discovers files on disk; `Migration.cfc` is the per-file base class; `TableDefinition.cfc` is the in-memory builder used inside `up()` callbacks; adapters under `databaseAdapters/` translate to engine-specific DDL.

## Parameter naming conventions

Every column-adding helper in `TableDefinition.cfc` follows the same shape — match it when adding or modifying helpers here.

**Column name arguments use `$combineArguments` to accept both plural and singular forms.** The plural is canonical; the singular is the alias.

```cfm
public any function string(string columnNames, any limit, string default, boolean allowNull) {
    $combineArguments(args = arguments, combine = "columnNames,columnName", required = true);
    // ... iterate over the list internally
}
```

Callers can pass either `t.string(columnNames = "a,b,c")` or `t.string(columnName = "a")` — both resolve to `arguments.columnNames` for the function body. Drop the `required` keyword from the parameter declaration; `$combineArguments(required=true)` enforces it at runtime.

**`references()` and its command-version siblings carry back-compat aliases.** The legacy parameter names predate the `$combineArguments` convention; the modern ones are accepted as synonyms via the same helper. Each of these accepts the modern form going forward:

| Function | Legacy param | Modern alias(es) |
|---|---|---|
| `TableDefinition::primaryKey()` | `name` | `columnName`, `columnNames` |
| `TableDefinition::references()` | `referenceNames` | `columnNames` |
| `Migration::addReference()` | `referenceName` | `columnName`, `columnNames` |
| `Migration::dropReference()` | `referenceName` | `columnName`, `columnNames` |
| `Migration::addColumn()` / `changeColumn()` | `columnName` | `columnNames` |
| `Migration::removeColumn()` | `columnName` | `columnNames` |
| `Migration::addForeignKey()` | `column` | `columnName` |

Example (the `references()` form, [#2781](https://github.com/wheels-dev/wheels/issues/2781)):

```cfm
$combineArguments(args = arguments, combine = "referenceNames,columnNames", required = true);
```

New code should pass `columnNames`. Both keep working.

**Nullable flag is always `allowNull`** — never `null`. Every column helper agrees on this.

## Reference-column suffix flag

`t.references(columnNames="user")` produces either `userid` (legacy) or `user_id` (Rails-style) depending on the `useUnderscoreReferenceColumns` setting:

| Setting value | `t.references(columnNames="user")` produces | Polymorphic `user` produces |
|---|---|---|
| `false` (framework default) | `userid` | `userid`, `usertype` |
| `true` (new-app template default) | `user_id` | `user_id`, `user_type` |

The framework default is `false` so existing apps with applied migrations keep matching their database schemas. The `wheels new` template at `cli/lucli/templates/app/config/settings.cfm` opts new apps into `true` so they match Wheels model `belongsTo` defaults out of the box.

The flag is read via `$get("useUnderscoreReferenceColumns")` inside `references()` at runtime — apps can flip the setting in `config/settings.cfm` without reloading the framework. Migrations already applied to a real database are unaffected; only the column name the *next* migration produces changes.

## Anti-patterns to watch for in this directory

1. **Mixing helper-style and standalone-style argument names.** Both `t.references(columnNames=...)` (helper inside `createTable`) and `addReference(table=..., columnName=...)` (standalone Migration.cfc method) now accept the modern `columnNames` / `columnName` aliases via `$combineArguments`, alongside their legacy `referenceNames` / `referenceName` originals. Prefer the modern form in new code; the legacy names keep working.
2. **Hard-coding `& "id"` or `& "type"` concatenations.** All four sites in this directory resolve the reference-column suffix through `$get("useUnderscoreReferenceColumns")` — `TableDefinition.cfc::references()` (id + polymorphic type), `Migration.cfc::removeColumn` (referenceName branch), and `Migration.cfc::addReference`. If you add new code that builds a reference column name, route it through `$get` too rather than hard-coding `& "id"`.
3. **`required` on column-name parameters.** Use `$combineArguments(... required=true)` instead. Declaring CFML-level `required` blocks the alias path because validation runs before the function body.

## Internal caches

Two caches introduced in #2937 — know their scopes before adding probes:

- `application[appKey].$migratorAdapterNames` — application-scoped, keyed by datasource name. Memoized migrator adapter name, written by `Base.cfc::$getDBType()`. Survives requests; rebuilt on reload (a datasource's driver can't change without one).
- `request.$wheelsMigratorColumns` — request-scoped, keyed by `dsName|tableName` (table name VERBATIM — no case folding, since the `$dbinfo` probe uses original case and case-sensitive databases can host `Authors` and `authors` separately). Column list per table, written by `Base.cfc::$getColumns()`, dropped wholesale by `$execute()` so DDL in the same request is reflected on the next read.

## Tests

Specs live in `vendor/wheels/tests/specs/migrator/`. `referencesSpec.cfc` exercises `TableDefinition::references()` (the `columnNames` alias plus the suffix flag) at the unit layer — inspecting `t.columns` / `t.foreignKeys` directly without `t.create()` so the assertions are adapter-independent. `primaryKeySpec.cfc` mirrors that shape for `TableDefinition::primaryKey()` — the `columnName` / `columnNames` aliases plus precedence semantics (#2803). `migrationSpec.cfc` covers Migration.cfc command-version helpers via real DDL roundtrips — its "Tests addReference" describe block guards the `useUnderscoreReferenceColumns` path on `Migration.cfc::addReference()`. Most FK-related tests in `migrationSpec.cfc` skip on SQLite (which doesn't support altering CONSTRAINTS) but run on every other engine in CI.

Prefer TableDefinition-layer tests for argument plumbing and reach for `migrationSpec.cfc` patterns only when the assertion requires a real database (FK constraints, column existence after ALTER, etc.).

Smoke-test cross-adapter SQL via `bash tools/test-local.sh migrator` (Lucee 7 + SQLite) and the full matrix via `tools/test-matrix.sh` when touching the suffix flag or `$combineArguments` calls.
