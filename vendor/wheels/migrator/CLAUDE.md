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

**`references()` carries a back-compat exception.** Its legacy parameter is `referenceNames`, with `columnNames` accepted as a synonym since the [#2781](https://github.com/wheels-dev/wheels/issues/2781) fix:

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

1. **Mixing helper-style and standalone-style argument names.** `t.references(columnNames=...)` (helper inside `createTable`) and `addReference(table=..., columnName=...)` (standalone Migration.cfc method) currently use slightly different parameter shapes — see [#2781](https://github.com/wheels-dev/wheels/issues/2781) for the open consistency follow-up. When in doubt, match what's already in the file.
2. **Hard-coding `& "id"` or `& "type"` concatenations.** `TableDefinition.cfc::references()`, `Migration.cfc::removeColumn(referenceName=...)`, and `Migration.cfc::addReference()` all resolve the suffix through `$get("useUnderscoreReferenceColumns")` ([#2781](https://github.com/wheels-dev/wheels/issues/2781)). If you add new code that builds a reference column name, route it through `$get` too.
3. **`required` on column-name parameters.** Use `$combineArguments(... required=true)` instead. Declaring CFML-level `required` blocks the alias path because validation runs before the function body.

## Tests

Specs live in `vendor/wheels/tests/specs/migrator/`. The `referencesSpec.cfc` and `migrationSpec.cfc` files exercise both `t.references()` and the broader column-adding helpers. Tests at the `TableDefinition` layer (inspect `t.columns` / `t.foreignKeys` directly without calling `t.create()`) are preferred over DB-roundtrip tests when verifying argument plumbing — they're adapter-independent.

Smoke-test cross-adapter SQL via `bash tools/test-local.sh migrator` (Lucee 7 + SQLite) and the full matrix via `tools/test-matrix.sh` when touching the suffix flag or `$combineArguments` calls.
