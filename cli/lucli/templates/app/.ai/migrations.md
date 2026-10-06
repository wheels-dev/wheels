# Migrations & Seeding

Part of the Wheels application guide; start with `../CLAUDE.md`.

Column options are `allowNull`, `default`, `limit`, `precision`, `scale` (`null` is the deprecated pre-3.0 name for `allowNull`; write `allowNull`); with `strictArguments` on (development default), an unknown option such as `nullable=true` is logged instead of ignored.

## Shared Dev DB Reconciliation

`wheels_migrator_versions` can drift from on-disk files when several developers share a single dev database (peer applied a migration whose file isn't yet in your branch). Detected and surfaced automatically; reconciliation is explicit:

- `wheels migrate latest` — when a peer's tracked version sits above your latest local file, it applies pending local migrations and prints a warning.
- `wheels migrate info` — orphan rows render as `[?] <version> <name> (applied <timestamp>)` when the enriched `wheels_migrator_versions.name` / `.applied_at` columns are populated, or `[?] <version> ********** NO FILE **********` (Rails-style) for legacy rows.
- `wheels migrate doctor` — single-command health report. Lists orphans + pending; pure read.
- `wheels migrate forget <version> --yes` — delete a stale tracking row (refuses if a matching local file exists, refuses if version not in table).
- `wheels migrate pretend <version> --yes` — record a version as applied without running `up()` (refuses if already applied or no matching file).
- `wheels migrate unlock [--force]` — show who holds the cross-process migration lock (read-only; exits non-zero while a live instance holds it). `--force` removes it once that instance is gone.

Tracking-table schema: `wheels_migrator_versions(version, core_level, name, applied_at)`. The `name` and `applied_at` columns are additive (NULL for legacy rows) and added automatically via `$ensureTrackingColumns()` on first migrator call after upgrade. Both columns are populated by `$setVersionAsMigrated(version, migrationName)` going forward; existing rows stay NULL and display version-only.

Both `forget` and `pretend` are dry-run by default; `--yes` is required to mutate. Helpers live on `Migrator.cfc`: `$getOrphanVersions()`, `$getOrphanVersionsWithMeta()`, `doctor()`, `forgetVersion()`, `pretendVersion()`, `$buildInfoOutput()`, `$ensureTrackingColumns()`. Guide: https://guides.wheels.dev (Basics → Shared Development Databases).

## Auto-Migration

Generate migrations from model/DB schema diffs. Rename detection via explicit hints (authoritative) + heuristic suggestions (normalized-token + Levenshtein).

```cfm
var am = CreateObject("component", "wheels.migrator.AutoMigrator");
var d = am.diff("User");
var d = am.diff("User", {renames: {"full_name": "fullName"}});
var d = am.diff("User", {heuristicThreshold: 0.85});
var all = am.diffAll({hints: {"User": {renames: {"full_name": "fullName"}}}, heuristicThreshold: 0.7});
am.writeMigration(d, "rename_name_field");
```

A CLI wrapper exists too: `wheels migrate diff` (alias `dbmigrate diff`) previews the same AutoMigrator diffs and, with `--write`, emits migration files. `--rename OLD:NEW` (repeatable; `Model.OLD:NEW` when diffing all models) supplies rename hints, `--hints` takes JSON, `--model` limits the diff to one model, and `--name` names the written migration.

Result struct: `{modelName, tableName, addColumns, removeColumns, changeColumns, renameColumns, suggestedRenames}`. Limits: PK renames not detected; rename + type change requires separate migrations; calculated properties excluded. `writeMigration()` / `generateMigrationCFC()` honor `suggestedRenames` as `renameColumn` instead of destructive remove+add.

Announce-only `up()`/`down()` (the default "NOT IMPLEMENTED" stubs and the announce template) do not write `wheels_migrator_versions`. `announce()` plus ORM persist (`model().create()` / `save()` / `delete()` with no `$execute`) still marks or unmarks the version. `redoMigration()` fails closed when `allowMigrationDown` is false — the framework default stays `false` (development still opts in to `true`). Default FK names are `FK_<table>_<refTable>_<column>` so two FKs to the same reference table do not collide.

## Seeding

Convention-based, idempotent, CLI-supported.

```cfm
// app/db/seeds.cfm — shared (all environments)
seedOnce(modelName="Role", uniqueProperties="name", properties={
    name: "admin", description: "Administrator"
});

// app/db/seeds/development.cfm — dev-only (runs after seeds.cfm)
seedOnce(modelName="User", uniqueProperties="email", properties={
    firstName: "Dev", lastName: "User", email: "dev@example.com"
});
```

```bash
wheels seed                            # auto-detect env (canonical)
wheels seed --environment=production
wheels seed --generate                 # generated sample data
```

To scaffold seed templates, use: `wheels generate snippets seed-data` (writes `app/db/seeds.cfm` and `app/db/seeds/development.cfm`, where `wheels seed` reads them; existing files are kept unless you pass `--force`). There is no `wheels generate seed` generator.

`seedOnce()`: idempotent — checks `uniqueProperties` via `findOne()`, creates only if not found. Execution: `seeds.cfm` → `seeds/<environment>.cfm`, wrapped in a transaction. Programmatic: `application.wheels.seeder.runSeeds()`. (Note: `wheels db:seed` is NOT a valid command — it errors. Use `wheels seed`.)

Generated seeds resolve `belongsTo` references from real, non-soft-deleted parent rows, honoring conventional and custom foreign keys and `joinKey`. When both models are selected, the parent is generated first; a child-only run reuses existing parents without creating any. Programmatic selection: `application.wheels.seeder.generateSeeds(models="Comment,Post", count=10)`.

If an association has no usable parent, generation fails and rolls back the entire run instead of guessing IDs. Seed that parent first (including auth models that require hand-written seeds). Polymorphic associations and cycles without existing parents require `app/db/seeds.cfm`. Models whose generated records all fail validation are still skipped; partial saves or errors still roll back the run.
