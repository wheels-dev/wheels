# Shared Development Databases

Short reference for the orphan-migration case. User-facing version lives at
`web/sites/guides/src/content/docs/v4-0-0/basics/shared-development-databases.mdx`.

## What's an orphan?

A row in `wheels_migrator_versions` whose `version` timestamp has no matching
file in `app/migrator/migrations/`. Common cause: shared dev DB, peer ran
their migration first against the shared DB before their file was merged.

## Detection

`Migrator.cfc::$getOrphanVersions()` — returns an array of orphan version
strings, sorted ascending. Excludes the sentinel `"0"` returned when the
tracking table is empty.

## Display

`wheels migrate info` marks orphan rows with `[?]` and the literal
`********** NO FILE **********` (Rails-style). Includes a footer
explaining the cause. Rendering logic lives in
`Migrator.cfc::$buildInfoOutput()` so it's unit-testable without the HTTP
dispatcher.

## Behavior in `migrateTo()`

If `currentVersion > target` ONLY because of orphans (no local file with
version > target marked migrated), the down branch is skipped. Either:

- Pending local migrations exist → fall through to up branch with a
  warning naming the orphans
- Nothing pending → emit "Nothing to do" naming current vs target and
  return immediately

If SOME DB versions > target are orphans and SOME have local files, the
down branch runs as usual but emits a warning naming the orphans (they
get skipped by the existing loop because it iterates files only).

## Reconciliation commands

Three CLI subcommands for manual reconciliation against the tracking
table (Flyway `validate` / `repair` / `SkipExecutingMigrations`
analogues):

- `wheels migrate doctor` — comprehensive health report. Reads
  `Migrator.doctor()`. Pure read; no mutation. Reports orphans,
  pending, and applied counts with a human-readable summary.
- `wheels migrate forget <version> --yes` — removes a single row
  from `wheels_migrator_versions`. Requires `--yes`. Refuses if the
  version has a matching local file (use `migrate down` instead) or
  if it's not in the tracking table.
- `wheels migrate pretend <version> --yes` — inserts a row without
  running `up()`. Requires `--yes`. Refuses if already applied or
  if no local file matches.

Implementation:
- `Migrator.cfc::doctor()`, `forgetVersion()`, `pretendVersion()`
- `cli.cfm` cases: `doctor`, `forgetVersion`, `pretendVersion`
- `Module.cfc::runForgetOrPretend()` handles `--yes` gating
- Tests: `vendor/wheels/tests/specs/migrator/MigratorReconciliationSpec.cfc`

## Related

- Issue #2780 (the original report)
- PR #2798 (orphan detection + info display + docs, merged 2026-05-22)
- `vendor/wheels/Migrator.cfc::$getOrphanVersions()`
- `vendor/wheels/Migrator.cfc::$buildInfoOutput()`
- `vendor/wheels/Migrator.cfc::doctor()`
- `vendor/wheels/Migrator.cfc::forgetVersion()`
- `vendor/wheels/Migrator.cfc::pretendVersion()`
- `vendor/wheels/tests/specs/migrator/OrphanDetectionSpec.cfc`
- `vendor/wheels/tests/specs/migrator/MigratorInfoSpec.cfc`
- `vendor/wheels/tests/specs/migrator/MigratorReconciliationSpec.cfc`
- Follow-up work (separate PR):
  - Schema enrichment of `wheels_migrator_versions` (add `name` and `applied_at` columns)
