# Issue #2106: Core Tests failing in CockroachDB

## Verdict
FIX NOW — `phase:1-stabilize`, blocks GA. All failures are isolated to two well-understood root causes; fixes are small and contained.

## Summary
Ten core-test failures against CockroachDB split into two distinct bugs: (1) `$upsertSQL` / bulk insert paths pass through `CockroachDBModel.$querySetup`, which unconditionally appends `RETURNING #arguments.$primaryKey#` to **every** `INSERT INTO …` — bulk.cfc never passes `$primaryKey`, yielding the malformed tail `RETURNING\n<EOF>` shown in the issue body; (2) `lockingSpec.cfc` calls `withAdvisoryLock(...)`, which CockroachDB's adapter throws `Wheels.AdvisoryLockNotSupported` for — the spec has no CockroachDB skip-shim like the other 8 specs that already opt out.

## Root cause

### Category A — `RETURNING <EOF>` in upsert/insert bulk paths (6 failures)
File: `vendor/wheels/databaseAdapters/CockroachDB/CockroachDBModel.cfc:69-84`
The override appends `RETURNING #arguments.$primaryKey#` whenever the first SQL chunk begins with `INSERT INTO`. It assumes `$primaryKey` is always populated, but:
- `vendor/wheels/model/bulk.cfc:143` (`upsertAll`) and `vendor/wheels/model/bulk.cfc:53` (`insertAll`) call `variables.wheels.class.adapter.$querySetup(parameterize=…, sql=local.sql)` **without** passing `$primaryKey`.
- Default value is `""`, so emitted SQL becomes `… ON CONFLICT (…) DO UPDATE SET … RETURNING `  (CockroachDB parser error: `at or near "EOF": syntax error` — exactly the error in the issue).
- Additionally, the upsert tail (`ON CONFLICT (code) DO UPDATE …`) means the regex `Left(sql[1], 11) == "INSERT INTO"` matches even though the adapter's RETURNING rewriting was designed for single-row INSERTs, not multi-row UPSERTs.

Failing specs in `vendor/wheels/tests/specs/model/bulkOperationsSpec.cfc`:
- `upsertAll > inserts new records when no conflict exists`
- `upsertAll > updates existing records on conflict`
- `insertAll > inserts multiple records in a single call`
- `insertAll > inserts records with auto timestamps`
- `insertAll > skips timestamps when timestamps argument is false`
- `insertAll > handles single record insertion`

(`returns zero count for empty records array` and the two negative-path tests short-circuit before SQL runs and still pass.)

### Category B — advisory locks not supported on CockroachDB (4 failures)
File: `vendor/wheels/tests/specs/model/lockingSpec.cfc`
The spec has no `_isCockroachDB` guard. `CockroachDBModel.$acquireAdvisoryLock` (`CockroachDBModel.cfc:45`) throws `Wheels.AdvisoryLockNotSupported` by design (matches Oracle/H2 behavior). Four `it()` blocks invoke `withAdvisoryLock()`:
- `executes callback and returns result`
- `releases lock even when callback throws an exception`
- `accepts a custom timeout argument`
- `safely handles lock names with single quotes`

Every other PostgreSQL-flavoured spec in `tests/specs/model/` already declares `var _isCockroachDB = CreateObject("component", "wheels.migrator.Migration").init().adapter.adapterName() == "CockroachDB";` and `if (_isCockroachDB) return;` at the top of each `it()` that hits an unsupported surface (see `transactionsSpec.cfc`, `crudSpec.cfc`, `callbacksSpec.cfc`, etc.). `lockingSpec.cfc` is simply missing the shim.

### Not a cause
- CLAUDE.md asserts "CockroachDB is soft-fail in CI". **That is stale** — `compat-matrix.yml:389` and `:519` both set `SOFT_FAIL_DBS=""` (empty). CockroachDB failures currently **do** block CI, which is why #2106 is filed as `phase:1-stabilize`.
- `SERIAL` → `unique_rowid()` (CockroachDB's 64-bit pseudo-monotonic IDs) is already handled by `populate.cfm:52-57` and `CockroachDBMigrator.addPrimaryKeyOptions`. Not a cause of current failures.

## Files to change

1. `vendor/wheels/databaseAdapters/CockroachDB/CockroachDBModel.cfc`
   - Harden `$querySetup` to skip the RETURNING append when either (a) `$primaryKey` is empty / whitespace, or (b) the statement is an UPSERT (i.e. the SQL array already contains an `ON CONFLICT` chunk). This preserves the single-row INSERT behavior `$identitySelect` relies on while making the function safe for bulk paths that don't need (or want) RETURNING.
   - Recommended shape (prose, not code): early-return before the `ArrayAppend` when `Len(Trim(arguments.$primaryKey)) == 0` OR any element of `arguments.sql` matches `/ON CONFLICT/i`.

2. `vendor/wheels/tests/specs/model/lockingSpec.cfc`
   - Add the standard `_isCockroachDB` guard at the top of `run()` and `if (_isCockroachDB) return;` inside each of the four `withAdvisoryLock`-touching `it()` blocks. Leave the `forUpdate` describes untouched — CockroachDB supports `SELECT … FOR UPDATE`.
   - Pattern to copy: `vendor/wheels/tests/specs/model/transactionsSpec.cfc:6,19`.

3. `.github/workflows/compat-matrix.yml` (**post-fix, separate commit**)
   - `SOFT_FAIL_DBS` is already `""` — no change needed to "remove soft-fail". Instead, leave it empty so CockroachDB stays gating. Verify matrix green on `cockroachdb` column across all supported engines before declaring fix complete.
   - Update CLAUDE.md (`CLAUDE.md`, section "CI soft-fail databases") to reflect reality: SOFT_FAIL_DBS is currently empty; the paragraph claiming CockroachDB is soft-fail is outdated.

## Implementation steps

1. Patch `CockroachDBModel.$querySetup` to guard the RETURNING append:
   - If `Len(Trim(arguments.$primaryKey)) == 0`, skip append.
   - If any element of `arguments.sql` contains `ON CONFLICT` (case-insensitive), skip append (upserts already reshape the statement; RETURNING has no callers on that path).
   - Keep all the other `$convertMaxRowsToLimit` / `$removeColumnAliasesInOrderClause` / `$addColumnsToSelectAndGroupBy` / `$moveAggregateToHaving` calls untouched.

2. Add skip shim to `lockingSpec.cfc`:
   - At top of `run()`, add: `var _isCockroachDB = CreateObject("component", "wheels.migrator.Migration").init().adapter.adapterName() == "CockroachDB";`
   - Inside each of the four `withAdvisoryLock` `it()` blocks, add `if (_isCockroachDB) return;` as the first line (before the `local.result = ...` call).

3. Run the CockroachDB core test suite locally (see Testing).

4. Verify PostgreSQL still returns `lastId` for single-row inserts (regression check for step 1 — that path has a non-empty `$primaryKey`, so the guard should be a no-op there).

5. Verify `insertAll` / `upsertAll` still report correct counts on CockroachDB, MySQL, SQLite, H2, PostgreSQL, MSSQL.

6. Update `CLAUDE.md` "CI soft-fail databases" paragraph to reflect empty `SOFT_FAIL_DBS`.

7. Commit under scope `model` for bulk/upsert (#1) and `test` for the lockingSpec skip (#2). Per CLAUDE.md scope rules: `fix(model): guard cockroachdb returning append on bulk and upsert paths`, `test(model): skip advisory lock spec on cockroachdb`.

## Testing

### Local repro (Docker — CockroachDB is not in the LuCLI path)

```bash
cd /Users/peter/GitHub/wheels-dev/wheels/rig
docker compose up -d lucee7 cockroachdb cockroachdb-init

# wait for init
timeout 60 bash -c 'while [ "$(docker inspect --format="{{.State.Status}}" wheels-cockroachdb-init-1 2>/dev/null)" != "exited" ]; do sleep 2; done'

# reload + run suite
curl -s "http://localhost:60007/?reload=true&password=wheels" > /dev/null
curl -sL -o /tmp/crdb-before.json "http://localhost:60007/wheels/core/tests?db=cockroachdb&format=json"
python3 -c "import json; d=json.load(open('/tmp/crdb-before.json')); print(d['totalPass'],'pass',d['totalFail'],'fail',d['totalError'],'error')"
```

Baseline should show 10 failures. After the patch, re-run; expect 0 failures, 0 errors.

### Targeted run (fast feedback)

```bash
curl -sL "http://localhost:60007/wheels/core/tests?db=cockroachdb&format=json&directory=tests.specs.model.bulkOperationsSpec" \
  | python3 -c "import json,sys; d=json.load(sys.stdin); print(d['totalPass'],'pass',d['totalFail'],'fail')"

curl -sL "http://localhost:60007/wheels/core/tests?db=cockroachdb&format=json&directory=tests.specs.model.lockingSpec" \
  | python3 -c "import json,sys; d=json.load(sys.stdin); print(d['totalPass'],'pass',d['totalFail'],'fail')"
```

### Regression checks (ensure we didn't break non-CockroachDB paths)

```bash
# SQLite (fastest) — must stay green
bash tools/test-local.sh model

# Docker multi-DB — lucee7 × {sqlite, mysql, postgres, h2, sqlserver}
cd rig && docker compose up -d lucee7 mysql postgres sqlserver
for db in sqlite mysql postgres sqlserver h2; do
  curl -sL -o "/tmp/${db}.json" "http://localhost:60007/wheels/core/tests?db=${db}&format=json&directory=tests.specs.model.bulkOperationsSpec"
  python3 -c "import json; d=json.load(open('/tmp/${db}.json')); print('${db}:',d['totalPass'],'pass',d['totalFail'],'fail')"
done
```

Specifically confirm PostgreSQL's `$identitySelect` still returns a populated `lastId` for single-row INSERT (the currval() fallback path) — the guard only fires when `$primaryKey` is empty or when the SQL is an UPSERT, neither of which applies to PG single-row inserts.

### Cross-engine (before merge)

```bash
cd rig && docker compose up -d lucee6 lucee7 adobe2023 adobe2025 boxlang cockroachdb cockroachdb-init
for engine in 60006 60007 62023 62025 60001; do
  curl -sL "http://localhost:${engine}/wheels/core/tests?db=cockroachdb&format=json" \
    -o "/tmp/crdb-${engine}.json"
  python3 -c "import json; d=json.load(open('/tmp/crdb-${engine}.json')); print('${engine}:',d['totalPass'],'pass',d['totalFail'],'fail',d['totalError'],'error')"
done
```

All five should report 0 fail / 0 error after patches.

## Risk & dependencies

- **Related issue #2110** (core tests failing across all databases): broader regression claim with a screenshot but no adapter-specific trace. Likely a separate story — #2110 touches all adapters, #2106 is CockroachDB-only and has a concrete repro. Do **not** fold them; fix #2106 standalone, then re-check #2110 against a clean baseline (the screenshot in #2110 may simply reflect the same CockroachDB failures bleeding through the matrix column before soft-fail was disabled).
- **Soft-fail status** (CLAUDE.md claim): stale. `SOFT_FAIL_DBS=""` is already empty in `compat-matrix.yml:389,519`. No workflow edit needed; just correct the CLAUDE.md paragraph. Once the fix lands, CockroachDB becomes hard-gating without any workflow change.
- **Backwards compat**:
  - PostgreSQL: unchanged (guard only fires on empty `$primaryKey` or `ON CONFLICT`; neither applies to PG's single-row INSERT path).
  - MySQL / MSSQL / Oracle / H2 / SQLite: don't inherit from CockroachDBModel; untouched.
  - BoxLang: `CockroachDBModel.$identitySelect` has an existing BoxLang branch at line 115 — test on boxlang:60001 to make sure RETURNING suppression doesn't break BoxLang's generatedKey path.
- **`unique_rowid()` / `SERIAL`** (not in scope but worth noting): CockroachDB's `SERIAL` produces 64-bit values (~19 digits). No currently-failing spec asserts small monotonic IDs, but if a future spec does, use CockroachDB's `GENERATED ALWAYS AS IDENTITY` or introduce a sequence. Leave alone for this issue.
- **Advisory locks on CockroachDB long-term**: the skip-shim is pragmatic parity with Oracle/H2. Follow-up ticket (non-blocking): implement `withAdvisoryLock` on CockroachDB via a `_wheels_advisory_locks` table + row-level `FOR UPDATE` (what ActiveRecord does on `with_advisory_lock` gem's CRDB adapter). Not GA-blocking.

## Effort estimate
S — two surgical patches (~6 lines in `CockroachDBModel.cfc`, ~5 lines across `lockingSpec.cfc`), one CLAUDE.md doc correction. Test cycle on the rig is the bulk of the time (~15 min for full cockroachdb × 5-engine matrix).
