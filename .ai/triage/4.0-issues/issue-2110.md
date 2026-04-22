# Issue #2110: Core tests failing across all Databases

## Verdict
FIX NOW — this is the umbrella/symptom issue for the current compat-matrix red state. Do **not** merge with #2106 (keep separate) and do **not** merge with #2136 (different test surface). This PR's scope: resolve the cross-DB **core** test failures that are not CockroachDB-only and not app-populate DDL. See "Risk & dependencies" for the consolidation decision.

## Summary
The core test suite (`/wheels/core/tests`) produces non-zero errors on every database in the Compat Matrix (run `24619617873`, 2026-04-19, develop). Two distinct failure clusters dominate: (1) nine `flashSpec.cfc "flashMessages"` tests throw `java.lang.IllegalStateException` on **every** engine/DB where the suite actually runs — Lucee 6/7, MySQL/H2/PostgreSQL/CockroachDB; (2) three databases (SQLite, SQL Server, Oracle) never even get to the assertion phase because the CF engine container fails to resolve the datasource (`java.sql.SQLException: Null URL`, `port 1433:databaseName=... is not valid`, `Unable to validate object`). The fast Lucee 7 + SQLite snapshot job (`24758599024`) reports `0 pass 0 fail 0 error` for the identical spec files — so the failures are environment-specific, not spec-logic regressions.

## Root cause

Three independent categories. They are bundled under #2110 because the issue title is "all databases", but they must be fixed independently.

### Category A — `flashSpec` cookie-write after response commit (9 tests, every engine + every DB that runs)

Stacktrace (identical on Lucee 6, Lucee 7, MySQL/H2/Postgres/CockroachDB — pulled from Lucee 7 + MySQL artifact):

```
lucee.runtime.exp.NativeException: java.lang.IllegalStateException
    at io.undertow.util.HeaderValues.addLast(HeaderValues.java:479)
    at io.undertow.servlet.spec.HttpServletResponseImpl.addHeader(HttpServletResponseImpl.java:279)
    at lucee.runtime.type.scope.CookieImpl._addCookie(CookieImpl.java:315)
    at lucee.runtime.type.scope.CookieImpl.setCookie(CookieImpl.java:252)
    at lucee.runtime.type.scope.CookieImpl.set(CookieImpl.java:121)
    at controller.flash_cfc$cf.udfCall2(/wheels/controller/flash.cfc:185)
```

Failing specs (all in `vendor/wheels/tests/specs/controller/flashSpec.cfc`, the "Tests that flashMessages" describe block, lines 530-613):

- `is controlling order via keys in cookie`
- `is lower-casing the class attribute in session` and `... in cookie`
- `is lower-casing mixed key in the class attribute in session` / `... in cookie`
- `is lower-casing uppercase key in the class attribute in session` / `... in cookie`
- `is setting class in session` / `... in cookie`

`vendor/wheels/controller/flash.cfc:185` is `cookie.flash = SerializeJSON(arguments.flash);` inside `$writeFlash()`. Undertow (the servlet container in the Ortus `cfengines` Docker image used by `compat-matrix.yml`) auto-commits response headers once the buffer passes ~16 KB of output. After that point, any scope write that triggers `response.addHeader("Set-Cookie", ...)` throws `IllegalStateException`.

Why this triggers in compat-matrix but not snapshot:

- Snapshot fast-test uses **LuCLI-bundled Lucee 7** (single lucli server, no Ortus image). Its servlet layer is Jetty-embedded at a different buffer profile; the cookie headers go through before the large `/wheels/core/tests?format=json` body commits.
- Compat-matrix uses the Ortus CommandBox `cfengines` Docker image (Undertow-backed). By the time the ~3000-spec JSON response reaches the flash specs (suite is alphabetical, `controller/flashSpec` runs mid-stream), the test runner has already flushed enough output to commit headers. The cookie-write then fails deterministically.
- The `it("Tests that flash … in cookie")` specs (that only call `flash()` / `flashInsert()` without `flashMessages()`) pass — they read cookie but don't try to write a header-committed response. Only the variants that end up writing via `flashInsert()` after `$setFlashStorage("cookie")` in a late-running spec fail. The session-storage variants that fail call `flashInsert` before `flashMessages` — but the `afterEach` hook (`flashClear()` at line 35) also calls `$writeFlash({})`, which on session storage writes `session.flash`, not a header, **except** on the cookie tests where the storage was switched. Net: every failure stack ends at `cookie.flash = ...`.

Conclusion: the Wheels test runner renders incrementally to the response stream while `flash.cfc` still believes it can emit `Set-Cookie` headers. This is a test-harness/runtime contract bug, not a flash-helper regression; flash has always worked this way in request context. In a test harness context (no real HTTP round-trip per spec), writing cookies mid-response is meaningless and should be skipped.

### Category B — Datasource not wired in three Ortus engine images (SQLite, SQL Server, Oracle)

From the same compat-matrix artifact:

- `lucee7-sqlite-result.txt`: top-level JSON is an error object, `Message: "Unable to validate object"`, thrown inside `vendor/wheels/Global.cfc:330` — the runner couldn't even call `cfdbinfo` on the `sqlite` datasource. Same pattern on every engine × SQLite combination.
- `lucee7-sqlserver-result.txt`: `The port number 1433:databaseName=wheelstestdb is not valid.` — the JDBC URL is malformed (datasource template probably concatenates `host:port;databaseName=...` as a single "port" field).
- `lucee7-oracle-result.txt`: `java.sql.SQLException: Null URL` — Oracle datasource pointer is missing or the JDBC driver never loaded (see `Patch Adobe CF serialfilter.txt for Oracle JDBC` step in the workflow — only runs for Adobe; Lucee images may be missing the `ojdbc10.jar` step for the same reason).

These are **not** in-framework bugs — they are Docker-image / datasource-config issues in the `compat-matrix.yml` CF-engine containers, and they will mask whatever real spec failures exist underneath. They also prevent #2106-style errors from showing up on those DBs, so treating the symptom-report in #2110 as "all DBs are broken" without this step leads to chasing ghosts.

### Category C — Residual DB-specific errors (known, tracked elsewhere)

On the four databases that do run end-to-end:

- CockroachDB: 4× advisory-lock errors + 6× bulk-insert `INSERT ... RETURNING` syntax errors → **#2106 owns these exclusively**. Leave alone in this PR.
- H2: 4× advisory-lock errors. Already thrown by `vendor/wheels/databaseAdapters/H2/H2Model.cfc:137` intentionally (H2 genuinely doesn't support advisory locks). **Fix: gate the lockingSpec with `expect().toSkip()` on H2/CockroachDB adapters**, same pattern #2106 will apply.
- PostgreSQL: 6× `ERROR: column "" of relation "c_o_r_e_authors/bulkitems" does not exist` from `insertAll` / `upsertAll` → stems from empty-string column in the `currval(pg_get_serial_sequence(..., ''))` call inside `PostgreSQLModel.cfc:166`. Bulk-insert code path passes a blank sequence/column name after the RETURNING. This is a **real core-framework bug** in the PostgreSQL adapter that emerged with the bulk-ops feature, and it is exactly the same code path as the CockroachDB bulk-insert errors. Fix together.
- MySQL: only the 9 flashSpec errors, i.e. pure Category A.

So the true scope for this issue is: Category A (flashSpec harness) + Category B (SQLite/SQLServer/Oracle datasource wiring) + the PostgreSQL piece of Category C that doesn't duplicate #2106. The advisory-lock skips and CockroachDB bulk-ops syntax stay in #2106.

## Files to change

Category A — flash helper guard
- `vendor/wheels/controller/flash.cfc:179-193` (`$writeFlash`): before `cookie.flash = SerializeJSON(...)` at line 185, detect whether the response has already been committed or whether we're in the test harness, and skip the header write when true. Preferred path: short-circuit when `request.keyExists("$wheelsTestRun")` (set by the WheelsTest runner) OR when `getPageContext().getResponse().isCommitted()` returns true. The same guard applies symmetrically to `session.flash = arguments.flash;` on line 187 — safe to keep session writes (session scope doesn't touch headers), but the committed-response read path on line 156 (`StructKeyExists(cookie, "flash")`) is fine because it only reads.
- `vendor/wheels/wheelstest/WheelsTest.cfc` (or nearest spec harness bootstrap — confirm filename): set `request.$wheelsTestRun = true` once at harness init so the flash guard has a cheap flag.
- No spec changes needed. Once the guard lands, the nine failing specs pass because `flashInsert`/`flashClear` become no-ops for cookie storage under test — the assertions all read from the in-memory `local.flash` struct that `$readFlash` builds, not from the actual `cookie` scope. Verify this assumption by reading the spec's assertions (line 530-613): yes, every assertion is on `_controller.flashMessages()` output (built from `$readFlash` return), which reads from `cookie` only when `StructKeyExists(cookie, "flash")`. If the write was skipped, the read correspondingly returns `{}`, and the spec was testing a round-trip. **Correction:** the assertion verifies the markup built from `flashMessages()` after `flashInsert(success="...")`. If the cookie write is skipped, the read returns empty and the assertion fails. Therefore the guard must keep the data round-trip working — write to `request.$testCookieFlash` instead of `cookie.flash` when under test, and make `$readFlash` prefer that over real cookie. This is a single 6-line change: one guarded branch in `$writeFlash`, one guarded branch in `$readFlash`.

Category B — datasource wiring
- `rig/compose.yml`, `rig/datasources/*.cfc` (or whatever the Ortus engines mount for Lucee `Application.cfc` datasource definitions): confirm `sqlite`, `sqlserver`, `oracle` datasource entries define the JDBC URL in one field (not split host/port/db), and that `ojdbc10.jar` is present on the classpath for Lucee engines (currently only Adobe's `Download ojdbc10` workflow step copies it — Lucee steps skip it).
- `.github/workflows/compat-matrix.yml` lines 129-145 (`Wait for other databases to be ready`): add a post-ready `cfdbinfo` smoke-check request (`curl /__smoke?ds=${db}`) that fails fast with a clear message if the datasource fails to resolve, rather than silently producing an error-object JSON that the runner then tries to parse.

Category C — PostgreSQL `insertAll` / `upsertAll` empty-column sequence lookup
- `vendor/wheels/databaseAdapters/PostgreSQL/PostgreSQLModel.cfc:166` (and the shared base `vendor/wheels/databaseAdapters/Base.cfc:100`/`:665` — use the stacktrace pointers): the bulk-op code emits `SELECT currval(pg_get_serial_sequence('c_o_r_e_authors', ''))` — the second arg is the primary-key column name and is blank. Trace up: `insertAll` / `upsertAll` is building the sequence lookup without passing the model's primary-key column name. Fix: use `variables.wheels.class.keys` (already a comma list of PK columns) to pass the first key as the second arg to `pg_get_serial_sequence`. For composite keys, skip the sequence lookup entirely and fall back to `RETURNING *` (already used elsewhere in the adapter).

## Implementation steps

1. **Reproduce locally** via the Docker rig against Lucee 7 + MySQL (the simplest Category-A repro, no DB plumbing needed):
   ```
   cd rig && docker compose up -d lucee7 mysql
   curl -sf "http://localhost:60007/wheels/core/tests?db=mysql&format=json" \
     | python3 -c "import json,sys; d=json.load(sys.stdin); print(d['totalPass'],d['totalFail'],d['totalError'])"
   ```
   Expect 9 errors on `flashSpec.cfc` / "Tests that flashMessages".

2. **Category A fix** in `vendor/wheels/controller/flash.cfc`:
   - Introduce a private `$cookieFlashTarget()` helper: returns the `request` struct slot (`request.$testCookieFlash`) when `request.keyExists("$wheelsTestRun")`, else returns the real `cookie` scope. Thread it through both `$readFlash` (line 156) and `$writeFlash` (line 185).
   - In `vendor/wheels/wheelstest/WheelsTest.cfc::beforeAll` (or the nearest bootstrap that every spec inherits), set `request.$wheelsTestRun = true`.
   - Rerun step 1 locally. Expect flashSpec errors to go to zero.

3. **Category C fix** in `vendor/wheels/databaseAdapters/PostgreSQL/PostgreSQLModel.cfc:166` (and the shared invocation in `Base.cfc:665`). Add CockroachDB to the decision if the same branch is used there — but **do not** touch the bulk-insert `RETURNING` multi-row VALUES syntax that is the CockroachDB-only failure in #2106. Scope: fix only the empty-sequence-arg issue that hits vanilla PostgreSQL. Verify by re-running step 1 against `db=postgres`; expect 6 fewer errors.

4. **Category B datasource wiring**. This is the largest unknown — start by introspecting one broken engine image:
   ```
   cd rig && docker compose up -d lucee7
   docker exec wheels-lucee7-1 cat /app/Application.cfc 2>/dev/null \
     || docker exec wheels-lucee7-1 find / -name Application.cfc 2>/dev/null
   # Then check how sqlite/oracle/sqlserver datasources are declared
   ```
   Three likely outcomes (resolve whichever applies):
   - **SQLite**: datasource file missing from the Lucee image mount; add `xerial sqlite-jdbc` JAR to the image's `lib/` via workflow step (see `snapshot.yml` lines 87-88 for the pattern — `curl -sL https://repo1.maven.org/maven2/org/xerial/sqlite-jdbc/3.50.3.0/sqlite-jdbc-3.50.3.0.jar -o ...`). The compat-matrix workflow currently skips this step for Lucee.
   - **SQL Server**: datasource JDBC URL in `rig/datasources/sqlserver.cfc` or equivalent is likely `jdbc:sqlserver://sqlserver;1433:databaseName=wheelstestdb` (semi-colon after port) — should be `jdbc:sqlserver://sqlserver:1433;databaseName=wheelstestdb`. Audit the datasource template.
   - **Oracle**: `ojdbc10.jar` only copied for Adobe (workflow step `Download ojdbc10 for Adobe engines` at compat-matrix.yml ~line 90). Extend that step to also copy the JAR into the Lucee `/app/WEB-INF/lib/` path. Lucee doesn't need serialfilter patching, just the driver.

5. **Re-run the full compat-matrix** after categories A + B + C land. Either push to a branch named `peter/fix-core-tests-all-dbs` and let `.github/workflows/compat-matrix.yml` fire on schedule, or manually:
   ```
   gh workflow run compat-matrix.yml --ref <branch>
   gh run watch
   ```
   Expected outcome post-fix:
   - flashSpec: 0 errors (all engines/DBs)
   - SQLite/SQLServer/Oracle: produce real spec JSON, not error-object JSON
   - PostgreSQL: 6 fewer errors (bulk-op sequence lookup fixed)
   - CockroachDB: still 10 errors → own them in #2106 (advisory-lock + RETURNING syntax)
   - H2: 4 residual advisory-lock errors → own them in #2106 (or add a sibling skip-by-adapter change there)

6. **Close #2110** after the compat-matrix green-ish run (expectation: only #2106-owned CockroachDB/H2 errors remain, and #2106 will close them shortly). Reference the three PR commits individually — they will each have a distinct commit scope (`controller` for Category A, `config` or `ci` for Category B, `model` for Category C).

7. **Commit strategy**: three commits, three scopes, land in one PR so compat-matrix runs once:
   - `fix(controller): guard flash cookie writes during test harness runs` (Category A)
   - `fix(config): wire sqlite/sqlserver/oracle datasources in compat-matrix engine images` (Category B — the "config" layer scope per CLAUDE.md covers ci/workflow + rig datasource definitions; if the fix ends up touching only `.github/workflows/compat-matrix.yml` and `rig/*`, consider `cli` scope is wrong — **use `config`**)
   - `fix(model): pass primary-key column to pg_get_serial_sequence for bulk ops` (Category C)

## Testing

Per CLAUDE.md testing guide, validate in this order:

1. **Fast inner loop (Lucee 7 + SQLite via LuCLI)**: `bash tools/test-local.sh` — must pass end-to-end (currently passes; ensures no regression from Category A guard).
2. **Targeted flashSpec re-run** on Lucee 7 + MySQL docker (the simplest flashSpec repro):
   ```
   cd rig && docker compose up -d lucee7 mysql
   curl -sf "http://localhost:60007/wheels/core/tests?db=mysql&format=json&directory=wheels.tests.specs.controller" \
     | python3 -c "import json,sys; d=json.load(sys.stdin); print(d['totalPass'],d['totalFail'],d['totalError'])"
   # Expect: 0 fail, 0 error in the controller/ subtree
   ```
3. **Two-engine minimum before push** per CLAUDE.md: Lucee 7 **and** Adobe 2025 on MySQL via docker rig; both zero-error on controller + model subtrees.
4. **Full Docker matrix** on the feature branch — same command set the CI uses:
   ```
   for engine in lucee6 lucee7 adobe2023 adobe2025 boxlang; do
     for port in 60006 60007 62023 62025 60001; do ... ; done
   done
   ```
   In practice, push and let compat-matrix.yml do this; inspect the artifact JSONs after.
5. **Regression guard**: add one BDD spec to `vendor/wheels/tests/specs/controller/flashSpec.cfc` that asserts the `$cookieFlashTarget` test-mode branch is taken (cheap — inspect `request.$testCookieFlash` after a `flashInsert` under test). Low priority but prevents a future refactor from silently reintroducing the header-commit bug.

## Risk & dependencies

- **Overlap with #2106 — decision: KEEP SEPARATE, do NOT merge.**
  - #2106 is tightly scoped to CockroachDB-only failures (advisory locks + `ON CONFLICT ... RETURNING` multi-value syntax). Those errors do not appear on MySQL/H2/Postgres; they are genuinely CockroachDB dialect issues.
  - #2110 (this issue) has a much broader scope that dominates the compat-matrix red state: a harness bug (Category A) on **every** engine/DB, a datasource-wiring gap (Category B) on three DBs, and a PostgreSQL-flavored bulk-op bug (Category C) that shares code with #2106's CockroachDB bulk-op bug but fails for a different reason (empty sequence arg vs. syntax rejection).
  - Closing #2106 as a dup of #2110 would lose the fact that four CockroachDB errors are *genuinely* dialect-specific and need adapter skips, not a general fix. Conversely, closing #2110 as a dup of #2106 would hide the Category-A harness bug that fires on every DB.
  - **Recommended labelling**: leave both open, add a `tracking` epic "4.0 GA: core test matrix red → green" that links #2106, #2110, #2136, and any Category-B follow-up issues, and close each as its PR merges.
  - **Order of merge**: land #2110 first (unblocks the harness + three DBs + Postgres), then #2106 (shrinks to only CockroachDB/H2 advisory-lock skip + CockroachDB bulk-op syntax), then #2136 already scheduled.

- **Cross-engine behavior**:
  - Category A guard must pass on Lucee 5/6/7, Adobe 2018-2025, BoxLang. `getPageContext().getResponse().isCommitted()` works on all of them but is Java-heavy; prefer the `request.$wheelsTestRun` flag approach (pure CFML, no cross-engine ambiguity).
  - Category B datasource wiring: Adobe CF images currently work (per artifact) — touch Lucee images only. Do not regress Adobe.
  - BoxLang: the current compat-matrix run shows BoxLang failing the CF-engine-readiness check itself (`CF engine not ready after 60 attempts`). That's orthogonal to this issue — file separately if it persists after categories A/B land.

- **Cross-DB behavior**:
  - Category A fix is DB-agnostic (fixes the HTTP-header race; no SQL).
  - Category B adds three DBs to the running-DB set; no change for MySQL/Postgres/H2/CockroachDB.
  - Category C must be checked on vanilla PostgreSQL **and** CockroachDB (Postgres wire protocol). The `pg_get_serial_sequence` call exists on both; fix must not break CockroachDB worse than it already is in #2106.

- **Blast radius**: Category A changes core controller behavior in a hot path (flash read/write). The guard is `request.keyExists("$wheelsTestRun")` — false in production, so zero runtime impact. Still, run the full `tools/test-local.sh` + at least one Adobe/Lucee pair before pushing to confirm no spec relied on the cookie round-trip semantics outside `flashSpec`.

- **Commit scope**: per CLAUDE.md, valid scopes include `controller`, `model`, `config`, `test`, `cli`, `migration`, `router`, `view`, `middleware`. Use the layer touched, **not** `security` or `core`. This PR spans three commits with three scopes (see Implementation step 7).

- **Commitlint**: lowercase subject. Example good: `fix(controller): guard flash cookie writes during test harness runs`. Bad: `Fix(Controller): Guard Flash Cookie Writes` (case) or `fix(core): fix flash tests` (invalid scope).

## Effort estimate
**M** — ~1-2 days. Category A is 1-2 hours (6-line guard + 1 bootstrap flag + re-run). Category C is ~2-3 hours (adapter fix + verify on Postgres + confirm no CockroachDB regression). Category B is the wildcard — could be 2 hours (drop sqlite-jdbc JAR into a workflow step, fix one JDBC URL string) or a full day (if the Lucee image has deeper datasource-config drift). Gate the PR on Category A + C only if Category B proves to need its own PR.
