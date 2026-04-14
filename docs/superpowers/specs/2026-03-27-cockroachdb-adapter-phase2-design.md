# CockroachDB Adapter Improvements (Phase 2)

**Issues**: #1972, #1974
**Goal**: Fix CockroachDB test failures and remove from SOFT_FAIL_DBS in CI

## Context

CockroachDB is marked as soft-fail in CI (`SOFT_FAIL_DBS="cockroachdb"` in `.github/workflows/tests.yml`). Tests run but failures don't block the build. Current results on Lucee 6: **2217 pass, 31 fail, 38 error** out of 507 suites.

Phase 1 (already merged) established the CockroachDB adapter: `CockroachDBModel.cfc` (type mapping, RETURNING clause identity select) and `CockroachDBMigrator.cfc` (native sqlTypes, unique_rowid() PK generation), plus unit and integration tests.

Phase 2 fixes the remaining test failures so CockroachDB becomes a first-class CI target.

## Root Causes

### 1. Missing CockroachDB in adapter name checks (9 SQL errors + ~20 cascading failures)

The SQL generation layer in `model/update.cfc` and `model/sql.cfc` uses hardcoded adapter name lists like `ListFind('PostgreSQL,H2,Oracle,SQLite', adapterName())`. CockroachDB returns `"CockroachDB"` for `adapterName()` and matches **none** of these branches.

The critical failure: `update.cfc:108` — the `UPDATE table SET` prefix is never generated for CockroachDB, producing SQL like `"authorid" = ` (no table, no SET keyword). This causes 9 direct SQL syntax errors and cascading failures in tests that depend on UPDATE operations.

**Locations to fix** (add `CockroachDB` alongside `PostgreSQL`):

| File | Line | Current List |
|------|------|-------------|
| `vendor/wheels/model/update.cfc` | 108 | `PostgreSQL,H2,Oracle,SQLite` |
| `vendor/wheels/model/sql.cfc` | 653 | `PostgreSQL,H2,MicrosoftSQLServer,Oracle,SQLite` |
| `vendor/wheels/model/sql.cfc` | 664 | `PostgreSQL` |
| `vendor/wheels/model/sql.cfc` | 701 | `PostgreSQL,H2` |

### 2. unique_rowid() generates large INT8 IDs (3-5 test failures)

CockroachDB's SERIAL uses `unique_rowid()` producing large non-sequential INT8 values (e.g., `1161774559250219009`). Core tests that hardcode `Expected [1]` or `Expected [5]` fail.

Affected tests:
- `readSpec > findfirst > works` — expects id=1
- `readSpec > findLastOne > works` — expects id=5
- `crudSpec > order > is working with maxrows and calculated property` — ID in expected string
- `sqlSpec > works with numeric operators` — expects cf_sql_integer (gets cf_sql_bigint)
- `migrationSpec > is changing column` — expects limit 50 (gets 2147483647)

### 3. Transaction behavior differences (12 failures in transactionsSpec)

CockroachDB uses SERIALIZABLE isolation by default and has different SAVEPOINT semantics. Several transaction tests assume READ COMMITTED behavior or specific savepoint rollback mechanics.

## Design

### Part 1: Fix adapter name checks

Mechanical change: add `CockroachDB` to each `ListFind()` call that currently includes `PostgreSQL` in `update.cfc` and `sql.cfc`. CockroachDB uses the PostgreSQL wire protocol and should receive identical SQL generation treatment.

### Part 2: Adapter-specific test suites

**Strategy**: Guard core tests that have CockroachDB-incompatible assumptions, then provide equivalent coverage through CockroachDB-specific test specs.

**Guard pattern** (in core spec files):
```cfm
it("expects sequential IDs", () => {
    if ($isCockroachDB()) return; // covered by CockroachDBCrudSpec
    // ... test with hardcoded IDs
});
```

The `$isCockroachDB()` helper checks the current adapter name. This is the pattern already used in `CockroachDBIntegrationSpec.cfc`.

**New test files** (in `vendor/wheels/tests/specs/database/`):

1. **CockroachDBCrudSpec.cfc** — CRUD lifecycle with non-sequential ID assertions:
   - Create returns numeric key > 0
   - Sequential creates produce unique increasing keys
   - findFirst/findLast work without assuming specific ID values
   - findAll with maxrows works with large IDs

2. **CockroachDBTransactionSpec.cfc** — Transaction behavior under SERIALIZABLE isolation:
   - Basic transaction commit/rollback
   - invokeWithTransaction callback behavior
   - Nested transaction semantics
   - deleteAll/updateAll within transactions

3. **CockroachDBTypeSpec.cfc** — Type introspection for CockroachDB-specific types:
   - SERIAL columns report as cf_sql_bigint (INT8)
   - STRING type maps correctly
   - Column metadata returns expected limits

### Part 3: Remove from SOFT_FAIL_DBS

After all fixes verified locally on Lucee 6 + Adobe 2025:
- Remove `cockroachdb` from `SOFT_FAIL_DBS` on lines 390 and 520 of `.github/workflows/tests.yml`

## Files to modify

| File | Change |
|------|--------|
| `vendor/wheels/model/update.cfc` | Add CockroachDB to adapter name list (line 108) |
| `vendor/wheels/model/sql.cfc` | Add CockroachDB to adapter name lists (lines 653, 664, 701) |
| `vendor/wheels/tests/specs/model/readSpec.cfc` | Guard CockroachDB-incompatible ID tests |
| `vendor/wheels/tests/specs/model/crudSpec.cfc` | Guard CockroachDB-incompatible ID/order tests |
| `vendor/wheels/tests/specs/model/sqlSpec.cfc` | Guard CockroachDB type expectation test |
| `vendor/wheels/tests/specs/migrator/migrationSpec.cfc` | Guard CockroachDB column limit test |
| `vendor/wheels/tests/specs/model/transactionsSpec.cfc` | Guard CockroachDB-incompatible transaction tests |
| `vendor/wheels/tests/specs/database/CockroachDBCrudSpec.cfc` | **New** — CRUD with non-sequential IDs |
| `vendor/wheels/tests/specs/database/CockroachDBTransactionSpec.cfc` | **New** — SERIALIZABLE transaction tests |
| `vendor/wheels/tests/specs/database/CockroachDBTypeSpec.cfc` | **New** — Type introspection tests |
| `.github/workflows/tests.yml` | Remove cockroachdb from SOFT_FAIL_DBS |

## Verification

1. Run Lucee 6 + CockroachDB locally: `curl "http://localhost:60006/wheels/core/tests?db=cockroachdb&format=json"`
2. Run Adobe 2025 + CockroachDB locally: `curl "http://localhost:62025/wheels/core/tests?db=cockroachdb&format=json"`
3. Confirm 0 fail, 0 error for CockroachDB across both engines
4. Run Lucee 6 + H2 to verify no regressions: `curl "http://localhost:60006/wheels/core/tests?db=h2&format=json"`
5. Push and verify CI passes with CockroachDB as a blocking database

## Open questions

- Some transaction failures may be fixable in the framework (not just test expectations) — investigate after fixing SQL generation to see which persist
- IN clause failures (`works with IN operator with spaces`) may be a separate SQL generation or CockroachDB dialect issue — investigate after main fix
- Guard pattern: use inline `adapterName() != "CockroachDB"` check (matches existing pattern in CockroachDBIntegrationSpec.cfc) rather than adding a new base class helper — keeps change minimal
