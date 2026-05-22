# Orphan Migration Detection Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Resolve issue #2780 — when the `wheels_migrator_versions` tracking table records a version that has no corresponding migration file in the current checkout (shared dev DB / peer-in-flight migration), `wheels migrate latest` must not silently no-op while emitting misleading "Migrating from X down to Y" output. Detect orphans, fix directional logic, surface them in `wheels migrate info`, and ship a documentation page on the shared-DB pattern.

**Architecture:** Add a private `$getOrphanVersions()` helper to `vendor/wheels/Migrator.cfc` that diffs `$getVersionsPreviouslyMigrated()` against `getAvailableMigrations()`. In `migrateTo()`, branch on "orphan-at-top" before the existing direction check at line 48: when `currentVersion > target` but the only versions in that gap are orphans, skip the down branch entirely and fall through to the up branch (which applies any pending local files) with a clear warning. In `vendor/wheels/public/views/cli.cfm`'s `info` handler, append orphan rows to the migration list with a `[?]` marker and `********** NO FILE **********` annotation (Rails-style). Add a new doc page under `web/sites/guides/src/content/docs/v4-0-0/database/`.

**Tech Stack:** CFML (Lucee 6/7, Adobe CF 2018/2021/2023/2025, BoxLang), WheelsTest BDD specs, MDX docs.

---

## File Structure

**New files:**
- `vendor/wheels/tests/specs/migrator/OrphanDetectionSpec.cfc` — BDD spec for `$getOrphanVersions()` and the directional fix
- `vendor/wheels/tests/specs/migrator/MigratorInfoSpec.cfc` — BDD spec for the `info` view's orphan rendering
- `web/sites/guides/src/content/docs/v4-0-0/database-migrations/shared-development-databases.mdx` — user-facing doc

**Modified files:**
- `vendor/wheels/Migrator.cfc` — add `$getOrphanVersions()`, rewire direction check in `migrateTo()`
- `vendor/wheels/public/views/cli.cfm` — append orphan rows to `info` output
- `.ai/wheels/troubleshooting/shared-dev-databases.md` — AI-side reference (short)

**Out of scope for this plan (folded into Plan 2 or 3):**
- New CLI commands (`migrate doctor` / `forget` / `pretend`) — Plan 2
- Schema changes to `wheels_migrator_versions` — Plan 3
- Changes to `migrateIndividual()` or `redoMigration()`

---

## Cross-Engine Compatibility Notes

Every change here runs through cross-engine matrix CI. Watch these CLAUDE.md rules:

1. **#3 Closure `this` captures the declaring scope.** When iterating arrays/structs with closures (e.g., `.map()`, `.filter()`), share state via `{ref: obj}`.
2. **#7 Private mixin functions are not integrated.** All new helpers in `Migrator.cfc` must be `public` with `$` prefix (Migrator.cfc is its own component, not mixed in — confirm by reading top of file, but defensively use `$` prefix anyway since this is framework code).
3. **#10 Reserved scope names.** Don't name a variable `version` alone in a function that takes `arguments.version` — use `local.version` consistently. The existing code does this.
4. **Anti-pattern #12 Empty `whereIn`.** Not applicable here — we're not querying.
5. **Anti-pattern #14 Strip CFML comments before source-scanning.** Not applicable here — we're not scanning source.

---

## Task 1: Add `$getOrphanVersions()` private helper

**Files:**
- Create: `vendor/wheels/tests/specs/migrator/OrphanDetectionSpec.cfc`
- Modify: `vendor/wheels/Migrator.cfc` — add new private method after `$getVersionsPreviouslyMigrated()` (after line 533)

- [ ] **Step 1: Write the failing test**

Create `vendor/wheels/tests/specs/migrator/OrphanDetectionSpec.cfc`:

```cfm
component extends="wheels.WheelsTest" {

	include "helperFunctions.cfm"

	function beforeAll() {
		migration = CreateObject("component", "wheels.migrator.Migration").init();
		migrator = CreateObject("component", "wheels.Migrator").init(
			migratePath = "/wheels/tests/_assets/migrator/migrations/",
			sqlPath = "/wheels/tests/_assets/migrator/sql/"
		);
	}

	function run() {

		var _isCockroachDB = CreateObject("component", "wheels.migrator.Migration").init().adapter.adapterName() == "CockroachDB";

		describe("$getOrphanVersions", () => {

			beforeEach(() => {
				for (local.table in ["c_o_r_e_bunyips", "c_o_r_e_dropbears", "c_o_r_e_hoopsnakes"]) {
					try { migration.dropTable(local.table); } catch (any e) {}
				}
				deleteMigratorVersions(2);
				$cleanSqlDirectory();
			});

			afterEach(() => {
				deleteMigratorVersions(2);
				$cleanSqlDirectory();
			});

			it("returns empty array when DB and files match", () => {
				if (_isCockroachDB) return;
				migrator.migrateTo("001");
				var orphans = migrator.$getOrphanVersions();
				expect(orphans).toBeArray();
				expect(ArrayLen(orphans)).toBe(0);
			});

			it("returns the orphan when DB has a version with no matching file", () => {
				if (_isCockroachDB) return;
				migrator.migrateTo("001");
				// Manually insert a version with no matching file
				queryExecute(
					"INSERT INTO #application.wheels.migratorTableName# (version, core_level) VALUES ('999', #application.wheels.migrationLevel#)",
					{},
					{ datasource = application.wheels.dataSourceName }
				);
				var orphans = migrator.$getOrphanVersions();
				expect(ArrayLen(orphans)).toBe(1);
				expect(orphans[1]).toBe("999");
			});

			it("returns multiple orphans sorted ascending", () => {
				if (_isCockroachDB) return;
				migrator.migrateTo("001");
				for (var v in ["998", "999"]) {
					queryExecute(
						"INSERT INTO #application.wheels.migratorTableName# (version, core_level) VALUES ('#v#', #application.wheels.migrationLevel#)",
						{},
						{ datasource = application.wheels.dataSourceName }
					);
				}
				var orphans = migrator.$getOrphanVersions();
				expect(ArrayLen(orphans)).toBe(2);
				expect(orphans[1]).toBe("998");
				expect(orphans[2]).toBe("999");
			});

			it("ignores the sentinel '0' returned by empty tracking table", () => {
				if (_isCockroachDB) return;
				// No migrations applied yet — $getVersionsPreviouslyMigrated returns "0"
				var orphans = migrator.$getOrphanVersions();
				expect(ArrayLen(orphans)).toBe(0);
			});

		});

	}

}
```

- [ ] **Step 2: Run the test to verify it fails**

```bash
bash tools/test-local.sh migrator
```

Expected: `OrphanDetectionSpec` fails with "Component [wheels.Migrator] has no function with name [$getOrphanVersions]" or similar.

- [ ] **Step 3: Implement `$getOrphanVersions()` in `vendor/wheels/Migrator.cfc`**

Add the following method after line 533 (after the close of `$getVersionsPreviouslyMigrated()`):

```cfm
/**
 * Returns versions recorded in the tracking table that have no matching
 * migration file in the current checkout. Used to detect the "shared dev
 * database" case where a peer has applied a migration whose file isn't
 * yet in the local branch. See issue #2780.
 *
 * Result is sorted ascending. The sentinel "0" returned by
 * $getVersionsPreviouslyMigrated() on an empty tracking table is excluded.
 *
 * [section: Migrator]
 * [category: General Functions]
 */
public array function $getOrphanVersions() {
	local.appliedList = ListToArray($getVersionsPreviouslyMigrated());
	local.fileVersions = [];
	for (local.m in getAvailableMigrations()) {
		ArrayAppend(local.fileVersions, local.m.version);
	}
	local.orphans = [];
	for (local.v in local.appliedList) {
		if (Len(local.v) && local.v != "0" && !ArrayFind(local.fileVersions, local.v)) {
			ArrayAppend(local.orphans, local.v);
		}
	}
	ArraySort(local.orphans, function(a, b) {
		return Compare(a, b);
	});
	return local.orphans;
}
```

- [ ] **Step 4: Run the test to verify it passes**

```bash
bash tools/test-local.sh migrator
```

Expected: all `OrphanDetectionSpec` tests pass. Existing `migratorSpec` tests still pass.

- [ ] **Step 5: Commit**

```bash
git add vendor/wheels/Migrator.cfc vendor/wheels/tests/specs/migrator/OrphanDetectionSpec.cfc
git commit -m "feat(migrator): add \$getOrphanVersions() helper

Detects versions in wheels_migrator_versions that have no matching
file in app/migrator/migrations/. First step toward fixing the shared
dev DB scenario described in #2780 where 'wheels migrate latest' takes
a misleading down-branch when a peer's migration is recorded but the
file isn't in the local branch yet.

Refs #2780"
```

---

## Task 2: Wire orphan handling into `migrateTo()` (the bug fix)

**Files:**
- Modify: `vendor/wheels/Migrator.cfc:27-130` — update `migrateTo()` to handle orphan-at-top
- Modify: `vendor/wheels/tests/specs/migrator/OrphanDetectionSpec.cfc` — add directional-fix tests

- [ ] **Step 1: Write the failing test (extend OrphanDetectionSpec)**

Append to the `run()` function of `OrphanDetectionSpec.cfc`, after the `$getOrphanVersions` describe block:

```cfm
describe("migrateTo with orphan-at-top", () => {

	beforeEach(() => {
		for (local.table in ["c_o_r_e_bunyips", "c_o_r_e_dropbears", "c_o_r_e_hoopsnakes"]) {
			try { migration.dropTable(local.table); } catch (any e) {}
		}
		deleteMigratorVersions(2);
		$cleanSqlDirectory();
	});

	afterEach(() => {
		for (local.table in ["c_o_r_e_bunyips", "c_o_r_e_dropbears", "c_o_r_e_hoopsnakes"]) {
			try { migration.dropTable(local.table); } catch (any e) {}
		}
		deleteMigratorVersions(2);
		$cleanSqlDirectory();
	});

	it("does not take the down branch when only orphans separate current from target", () => {
		if (_isCockroachDB) return;
		// Apply 001 normally
		migrator.migrateTo("001");
		// Insert a fake "peer" version with no local file
		queryExecute(
			"INSERT INTO #application.wheels.migratorTableName# (version, core_level) VALUES ('999', #application.wheels.migrationLevel#)",
			{},
			{ datasource = application.wheels.dataSourceName }
		);
		// migrateTo("003") should NOT print "Migrating from 999 down to 003."
		var output = migrator.migrateTo("003");
		expect(output).notToInclude("down to 003");
	});

	it("applies pending local migrations when only orphans separate current from target", () => {
		if (_isCockroachDB) return;
		// Apply 001
		migrator.migrateTo("001");
		// Insert orphan
		queryExecute(
			"INSERT INTO #application.wheels.migratorTableName# (version, core_level) VALUES ('999', #application.wheels.migrationLevel#)",
			{},
			{ datasource = application.wheels.dataSourceName }
		);
		// migrateTo("003") should apply 002 and 003
		migrator.migrateTo("003");
		var info = application.wo.$dbinfo(datasource = application.wheels.dataSourceName, type = "tables", pattern = "c_o_r_e_dropbears");
		expect(ListFindNoCase(ValueList(info.table_name), "c_o_r_e_dropbears")).toBeTrue();
		var info2 = application.wo.$dbinfo(datasource = application.wheels.dataSourceName, type = "tables", pattern = "c_o_r_e_hoopsnakes");
		expect(ListFindNoCase(ValueList(info2.table_name), "c_o_r_e_hoopsnakes")).toBeTrue();
	});

	it("emits a warning naming the orphan version(s)", () => {
		if (_isCockroachDB) return;
		migrator.migrateTo("001");
		queryExecute(
			"INSERT INTO #application.wheels.migratorTableName# (version, core_level) VALUES ('999', #application.wheels.migrationLevel#)",
			{},
			{ datasource = application.wheels.dataSourceName }
		);
		var output = migrator.migrateTo("003");
		expect(output).toInclude("999");
		expect(output).toInclude("no matching file");
	});

	it("prints a clear nothing-to-do message when no pending local migrations exist", () => {
		if (_isCockroachDB) return;
		// Apply all three local files
		migrator.migrateTo("003");
		// Insert orphan higher than the last local file
		queryExecute(
			"INSERT INTO #application.wheels.migratorTableName# (version, core_level) VALUES ('999', #application.wheels.migrationLevel#)",
			{},
			{ datasource = application.wheels.dataSourceName }
		);
		// migrateToLatest aims at "003" but current is "999" — pure orphan-at-top, nothing pending
		var output = migrator.migrateToLatest();
		expect(output).notToInclude("down to");
		expect(output).toInclude("999");
		expect(output).toInclude("Nothing to do");
	});

	it("still allows legitimate down-migration when down target has a local file", () => {
		if (_isCockroachDB) return;
		// Apply 001 and 002
		migrator.migrateTo("002");
		// migrateTo("001") should genuinely roll back 002
		var output = migrator.migrateTo("001");
		expect(output).toInclude("down to 001");
		var info = application.wo.$dbinfo(datasource = application.wheels.dataSourceName, type = "tables", pattern = "c_o_r_e_dropbears");
		expect(ListFindNoCase(ValueList(info.table_name), "c_o_r_e_dropbears")).toBeFalse();
	});

});
```

- [ ] **Step 2: Run the test to verify it fails**

```bash
bash tools/test-local.sh migrator
```

Expected: the new specs in `OrphanDetectionSpec > migrateTo with orphan-at-top` fail because the orphan-handling logic isn't in `migrateTo()` yet.

- [ ] **Step 3: Implement the orphan-handling branch in `migrateTo()`**

Modify `vendor/wheels/Migrator.cfc:27-130`. Replace the function body with:

```cfm
public string function migrateTo(string version = "", boolean missingMigFlag = false) {
	local.rv = "";
	local.currentVersion = getCurrentMigrationVersion();
	local.appKey = $appKey();

	// Load migrations early to detect unapplied "gap" migrations before short-circuiting
	local.migrations = getAvailableMigrations();
	local.hasPendingMigrations = false;
	for (local.m in local.migrations) {
		if (local.m.status != "migrated" && local.m.version <= arguments.version) {
			local.hasPendingMigrations = true;
			break;
		}
	}

	// Detect orphan versions: DB rows whose timestamp has no matching local
	// file. Common in shared dev DBs when a peer applied a migration whose
	// file isn't yet in this branch. See issue #2780.
	local.orphans = $getOrphanVersions();
	local.orphansAboveTarget = [];
	for (local.v in local.orphans) {
		if (local.v > arguments.version) {
			ArrayAppend(local.orphansAboveTarget, local.v);
		}
	}

	// "Orphan-at-top" detection: would we take the down branch (currentVersion
	// > target) ONLY because of orphans? If so, skip the down branch entirely
	// — we cannot run down() on a file that doesn't exist. Fall through to
	// the up branch (which applies any pending local files) or emit a clear
	// nothing-to-do message.
	local.isOrphanAtTop = (
		local.currentVersion > arguments.version
		&& ArrayLen(local.orphansAboveTarget)
		&& !arguments.missingMigFlag
	);
	if (local.isOrphanAtTop) {
		// Verify that every DB version > target is an orphan. If even one
		// has a local file, the down branch is legitimate (the user has a
		// file to run down() on) — but we should still warn about the
		// orphans before delegating to it.
		local.dbVersionsAboveTarget = [];
		for (local.v in ListToArray($getVersionsPreviouslyMigrated())) {
			if (Len(local.v) && local.v != "0" && local.v > arguments.version) {
				ArrayAppend(local.dbVersionsAboveTarget, local.v);
			}
		}
		local.allOrphans = ArrayLen(local.dbVersionsAboveTarget) == ArrayLen(local.orphansAboveTarget);
		if (local.allOrphans) {
			local.rv = "Note: database tracks version(s) " & ArrayToList(local.orphansAboveTarget, ", ")
				& " with no matching file in app/migrator/migrations/. "
				& "This usually means a peer applied a migration whose file isn't yet "
				& "in your branch.#Chr(13) & Chr(10)#";
			if (!local.hasPendingMigrations) {
				local.rv &= "Nothing to do. Your latest local migration ("
					& arguments.version & ") is older than the database's current "
					& "version (" & local.currentVersion & ").#Chr(13) & Chr(10)#";
				return local.rv;
			}
			// Fall through into the up-branch logic below (we synthetically
			// flip the condition so it routes into the else branch).
			local.currentVersion = arguments.version;  // suppress down branch
		} else {
			// Mixed case: some DB versions > target have local files (legit
			// down candidates) and some are orphans. Warn but proceed.
			local.rv = "Note: database tracks version(s) " & ArrayToList(local.orphansAboveTarget, ", ")
				& " with no matching file. These will be skipped during rollback.#Chr(13) & Chr(10)#";
		}
	}

	if (local.currentVersion == arguments.version && !local.hasPendingMigrations) {
		local.rv &= "Database is currently at version #arguments.version#. No migration required.#Chr(13) & Chr(10)#";
	} else {
		if (!DirectoryExists(this.paths.sql) && application[local.appKey].writeMigratorSQLFiles) {
			DirectoryCreate(this.paths.sql);
		}
		if (local.currentVersion > arguments.version && arguments.missingMigFlag == false) {
			local.rv &= "Migrating from #local.currentVersion# down to #arguments.version#.#Chr(13) & Chr(10)#";
			for (local.i = ArrayLen(local.migrations); local.i >= 1; local.i--) {
				local.migration = local.migrations[local.i];
				if (local.migration.version <= arguments.version) {
					break;
				}
				if (local.migration.status == "migrated" && application[local.appKey].allowMigrationDown) {
					transaction action="begin" {
						try {
							if (structKeyExists(server, "boxlang")) {
								$query(datasource = application[local.appKey].dataSourceName, sql = "SELECT 1 as test");
							}
							local.rv &= "#Chr(13) & Chr(10)#------- " & local.migration.cfcfile & " #RepeatString("-", Max(5, 50 - Len(local.migration.cfcfile)))##Chr(13) & Chr(10)#";
							request.$wheelsMigrationOutput = "";
							request.$wheelsMigrationSQLFile = "#this.paths.sql#/#local.migration.cfcfile#_down.sql";
							if (application[local.appKey].writeMigratorSQLFiles) {
								$writeMigrationFile(request.$wheelsMigrationSQLFile, "");
							}
							local.migration.cfc.down();
							local.rv &= request.$wheelsMigrationOutput;
							$removeVersionAsMigrated(local.migration.version);
						} catch (any e) {
							local.rv &= "Error migrating to #local.migration.version#.#Chr(13) & Chr(10)##e.message##Chr(13) & Chr(10)##e.detail##Chr(13) & Chr(10)#";
							transaction action="rollback";
							break;
						}
						transaction action="commit";
					}
				}
			}
		} else {
			if (arguments.missingMigFlag) {
				local.rv &= "Migrating remaining migrations till #arguments.version#.#Chr(13) & Chr(10)#";
				$removeVersionAsMigrated(local.currentVersion);
			} else if (local.currentVersion gte arguments.version && local.hasPendingMigrations) {
				local.rv &= "Applying pending migration(s) up to #arguments.version#.#Chr(13) & Chr(10)#";
			} else {
				local.rv &= "Migrating from #local.currentVersion# up to #arguments.version#.#Chr(13) & Chr(10)#";
			}
			for (local.migration in local.migrations) {
				if (local.migration.version <= arguments.version && local.migration.status != "migrated") {
					transaction {
						try {
							if (structKeyExists(server, "boxlang")) {
								$query(datasource = application[local.appKey].dataSourceName, sql = "SELECT 1 as test");
							}
							local.rv &= "#Chr(13) & Chr(10)#-------- " & local.migration.cfcfile & " #RepeatString("-", Max(5, 50 - Len(local.migration.cfcfile)))##Chr(13) & Chr(10)#";
							request.$wheelsMigrationOutput = "";
							request.$wheelsMigrationSQLFile = "#this.paths.sql#/#local.migration.cfcfile#_up.sql";
							if (application[local.appKey].writeMigratorSQLFiles) {
								$writeMigrationFile(request.$wheelsMigrationSQLFile, "");
							}
							local.migration.cfc.up();
							local.rv &= request.$wheelsMigrationOutput;
							$setVersionAsMigrated(local.migration.version);
						} catch (any e) {
							local.rv &= "Error migrating to #local.migration.version#.#Chr(13) & Chr(10)##e.message##Chr(13) & Chr(10)##e.detail##Chr(13) & Chr(10)#";
							transaction action="rollback";
							break;
						}
						transaction action="commit";
					}
				} else if (local.migration.version > arguments.version) {
					break;
				}
			};
			if (arguments.missingMigFlag) {
				$setVersionAsMigrated(local.currentVersion);
			}
		}
	}
	return local.rv;
}
```

Key changes from the original:
- Computes `local.orphans` and `local.orphansAboveTarget` after the pending-migrations scan.
- Adds the `local.isOrphanAtTop` branch BEFORE the existing direction check.
- When all DB versions > target are orphans, either emits "Nothing to do" (no pending) or rewrites `currentVersion` so the function falls into the up branch.
- When SOME orphans + SOME legitimate down candidates exist, emits a warning header and proceeds with the existing down branch.
- Uses `&=` consistently for output accumulation (preserves the warning header).

- [ ] **Step 4: Run the test to verify it passes**

```bash
bash tools/test-local.sh migrator
```

Expected: all `OrphanDetectionSpec` tests pass. Existing `migratorSpec` tests still pass. If `migratorSpec` regresses, the bug is in the new branch's interaction with one of:
- F16 "out of order pending" (line 84-92 original) — verify it still triggers when `currentVersion >= target && hasPendingMigrations` AND orphan logic didn't fire.
- The `missingMigFlag` path (line 81-83 original) — verify untouched.

- [ ] **Step 5: Cross-engine check (Adobe CF + Lucee)**

The closure-free design here avoids the Adobe-CF gotchas, but the change is in `Migrator.cfc` which is widely exercised. Run the cross-engine matrix on the lightest combo:

```bash
tools/test-matrix.sh lucee7 sqlite
tools/test-matrix.sh adobe2023 sqlite
```

Expected: all migrator specs pass on both engines.

- [ ] **Step 6: Commit**

```bash
git add vendor/wheels/Migrator.cfc vendor/wheels/tests/specs/migrator/OrphanDetectionSpec.cfc
git commit -m "fix(migrator): handle orphan versions in shared dev databases

When wheels_migrator_versions records a version with no matching local
file (peer's migration applied to a shared dev DB but file not yet in
this branch), migrateTo() no longer takes a misleading 'down' branch
that silently no-ops. Instead it:

  1. Emits a clear warning naming the orphan version(s)
  2. Applies any pending local migrations (the up branch)
  3. Prints 'Nothing to do' explicitly when nothing is pending

Fixes the confusing 'Migrating from X down to Y' output that was
reported in issue #2780 surfaced during DataPAI Phase 0 against a
shared MSSQL dev database.

Fixes #2780"
```

---

## Task 3: Surface orphans in `wheels migrate info` output

**Files:**
- Create: `vendor/wheels/tests/specs/migrator/MigratorInfoSpec.cfc`
- Modify: `vendor/wheels/public/views/cli.cfm:159-189` — extend the `info` case

- [ ] **Step 1: Write the failing test**

Create `vendor/wheels/tests/specs/migrator/MigratorInfoSpec.cfc`:

```cfm
component extends="wheels.WheelsTest" {

	include "helperFunctions.cfm"

	function beforeAll() {
		migration = CreateObject("component", "wheels.migrator.Migration").init();
		migrator = CreateObject("component", "wheels.Migrator").init(
			migratePath = "/wheels/tests/_assets/migrator/migrations/",
			sqlPath = "/wheels/tests/_assets/migrator/sql/"
		);
	}

	function run() {

		var _isCockroachDB = CreateObject("component", "wheels.migrator.Migration").init().adapter.adapterName() == "CockroachDB";

		describe("Migrator info output", () => {

			beforeEach(() => {
				for (local.table in ["c_o_r_e_bunyips", "c_o_r_e_dropbears", "c_o_r_e_hoopsnakes"]) {
					try { migration.dropTable(local.table); } catch (any e) {}
				}
				deleteMigratorVersions(2);
			});

			afterEach(() => {
				for (local.table in ["c_o_r_e_bunyips", "c_o_r_e_dropbears", "c_o_r_e_hoopsnakes"]) {
					try { migration.dropTable(local.table); } catch (any e) {}
				}
				deleteMigratorVersions(2);
			});

			it("$buildInfoOutput returns expected lines for a clean state", () => {
				if (_isCockroachDB) return;
				migrator.migrateTo("002");
				var lines = migrator.$buildInfoOutput();
				expect(lines).toBeArray();
				var joined = ArrayToList(lines, Chr(10));
				expect(joined).toInclude("Current version:");
				expect(joined).toInclude("[x] 001");
				expect(joined).toInclude("[x] 002");
				expect(joined).toInclude("[ ] 003");
			});

			it("$buildInfoOutput marks orphan versions with [?] and NO FILE", () => {
				if (_isCockroachDB) return;
				migrator.migrateTo("001");
				queryExecute(
					"INSERT INTO #application.wheels.migratorTableName# (version, core_level) VALUES ('999', #application.wheels.migrationLevel#)",
					{},
					{ datasource = application.wheels.dataSourceName }
				);
				var lines = migrator.$buildInfoOutput();
				var joined = ArrayToList(lines, Chr(10));
				expect(joined).toInclude("[?] 999");
				expect(joined).toInclude("NO FILE");
			});

			it("$buildInfoOutput summary counts orphans separately", () => {
				if (_isCockroachDB) return;
				migrator.migrateTo("001");
				queryExecute(
					"INSERT INTO #application.wheels.migratorTableName# (version, core_level) VALUES ('999', #application.wheels.migrationLevel#)",
					{},
					{ datasource = application.wheels.dataSourceName }
				);
				var lines = migrator.$buildInfoOutput();
				var joined = ArrayToList(lines, Chr(10));
				expect(joined).toInclude("orphan: 1");
			});

		});

	}

}
```

- [ ] **Step 2: Run the test to verify it fails**

```bash
bash tools/test-local.sh migrator
```

Expected: `MigratorInfoSpec` fails with "Component [wheels.Migrator] has no function with name [$buildInfoOutput]".

- [ ] **Step 3: Implement `$buildInfoOutput()` in `vendor/wheels/Migrator.cfc`**

Add this method after `$getOrphanVersions()` (which Task 1 added):

```cfm
/**
 * Builds the human-readable info output for `wheels migrate info`. Returns
 * an array of lines (caller joins with newlines). Extracted from cli.cfm's
 * info handler so the rendering can be unit-tested without exercising the
 * HTTP dispatcher. Includes orphan rows (DB versions with no matching
 * local file) marked with [?] and "********** NO FILE **********".
 *
 * [section: Migrator]
 * [category: General Functions]
 */
public array function $buildInfoOutput() {
	local.lines = [];
	local.migrations = getAvailableMigrations();
	local.currentVersion = getCurrentMigrationVersion();
	local.orphans = $getOrphanVersions();
	local.applied = 0;
	local.pending = 0;
	for (local.m in local.migrations) {
		if (local.m.status == "migrated") {
			local.applied++;
		} else {
			local.pending++;
		}
	}
	ArrayAppend(local.lines, "Current version: " & (Len(local.currentVersion) ? local.currentVersion : "0"));
	ArrayAppend(local.lines, "Total migrations: " & ArrayLen(local.migrations));
	if (ArrayLen(local.migrations) || ArrayLen(local.orphans)) {
		ArrayAppend(local.lines, "  applied: " & local.applied);
		ArrayAppend(local.lines, "  pending: " & local.pending);
		if (ArrayLen(local.orphans)) {
			ArrayAppend(local.lines, "  orphan: " & ArrayLen(local.orphans));
		}
		ArrayAppend(local.lines, "");
		ArrayAppend(local.lines, "Migrations (newest last):");
		// Merge files + orphans into a single chronological list
		local.combined = [];
		for (local.m in local.migrations) {
			ArrayAppend(local.combined, {
				version: local.m.version,
				name: local.m.name,
				marker: local.m.status == "migrated" ? "[x]" : "[ ]",
				isOrphan: false
			});
		}
		for (local.v in local.orphans) {
			ArrayAppend(local.combined, {
				version: local.v,
				name: "********** NO FILE **********",
				marker: "[?]",
				isOrphan: true
			});
		}
		ArraySort(local.combined, function(a, b) {
			return Compare(a.version, b.version);
		});
		for (local.row in local.combined) {
			ArrayAppend(local.lines, "  " & local.row.marker & " " & local.row.version & " " & local.row.name);
		}
		if (ArrayLen(local.orphans)) {
			ArrayAppend(local.lines, "");
			ArrayAppend(local.lines, "Orphan versions are recorded in the database but have no");
			ArrayAppend(local.lines, "matching file in app/migrator/migrations/. This usually means");
			ArrayAppend(local.lines, "a peer applied a migration whose file isn't yet in your branch.");
		}
	}
	return local.lines;
}
```

- [ ] **Step 4: Run the test to verify it passes**

```bash
bash tools/test-local.sh migrator
```

Expected: all `MigratorInfoSpec` tests pass.

- [ ] **Step 5: Wire the helper into `cli.cfm`**

In `vendor/wheels/public/views/cli.cfm:159-189`, replace the `case "info":` body with a call to the new helper. Replace lines 159-189 with:

```cfm
case "info":
	// Build a human-readable status block. Logic lives in
	// Migrator.cfc::$buildInfoOutput so it can be unit-tested without
	// exercising the HTTP dispatcher. Issue #2780 surfaced orphan
	// versions (DB rows with no matching file) — those are now rendered
	// with a [?] marker and a clear warning footer.
	local.lines = [];
	ArrayAppend(local.lines, "Datasource: " & data.datasource);
	ArrayAppend(local.lines, "Database type: " & data.databaseType);
	for (local.line in migrator.$buildInfoOutput()) {
		ArrayAppend(local.lines, local.line);
	}
	data.message = ArrayToList(local.lines, Chr(10));
	break;
```

(The Datasource and Database type lines stay in `cli.cfm` because they come from `data.datasource` / `data.databaseType` populated earlier in the same view, not from the migrator object.)

- [ ] **Step 6: Run tests one more time to confirm no regressions**

```bash
bash tools/test-local.sh migrator
bash tools/test-local.sh dispatch
```

Expected: all pass.

- [ ] **Step 7: Commit**

```bash
git add vendor/wheels/Migrator.cfc vendor/wheels/public/views/cli.cfm vendor/wheels/tests/specs/migrator/MigratorInfoSpec.cfc
git commit -m "feat(migrator): surface orphan versions in 'wheels migrate info'

Adds Rails-style [?] marker and '********** NO FILE **********'
annotation for any version recorded in wheels_migrator_versions that
has no matching file in app/migrator/migrations/. Includes a footer
explaining the shared-dev-DB cause.

Extracts the info-rendering logic into Migrator.\$buildInfoOutput()
so it's unit-testable without the HTTP dispatcher round trip.

Refs #2780"
```

---

## Task 4: Documentation page

**Files:**
- Create: `web/sites/guides/src/content/docs/v4-0-0/database-migrations/shared-development-databases.mdx`
- Create: `.ai/wheels/troubleshooting/shared-dev-databases.md`

- [ ] **Step 1: Find the existing migration docs nav structure**

```bash
ls web/sites/guides/src/content/docs/v4-0-0/database-migrations/ 2>/dev/null || \
  find web/sites/guides -name "*migration*" -type f 2>/dev/null | head -10
```

Expected: returns the existing migrations doc directory. If `database-migrations/` doesn't exist as a subdirectory, look at what's nearby and use the same flat structure.

- [ ] **Step 2: Create the doc page**

Path depends on Step 1 result. The most likely target is `web/sites/guides/src/content/docs/v4-0-0/database-migrations.mdx` (single file) or a new file in the migrations subdirectory.

If single file exists: append a new section. If subdirectory exists: create a new `shared-development-databases.mdx`. Content:

```mdx
---
title: Shared Development Databases
description: How Wheels handles the case where multiple developers share a single dev database and a peer's migration is recorded before their file lands in your branch.
sidebar:
  order: 80
---

When several developers share a single development database, the migration
tracking table (`wheels_migrator_versions`) can record a version whose
migration file is not yet in your branch — a teammate ran `wheels migrate
latest` against the shared DB before their migration was merged.

Wheels detects this case and behaves transparently:

## What you'll see

Running `wheels migrate info`:

```
Current version: 20260521120100
Total migrations: 3
  applied: 2
  pending: 1
  orphan: 1

Migrations (newest last):
  [x] 20260520091823 create_users
  [x] 20260521090300 add_email_to_users
  [?] 20260521120100 ********** NO FILE **********
  [ ] 20260521131000 add_phone_to_users

Orphan versions are recorded in the database but have no matching file in
app/migrator/migrations/. This usually means a peer applied a migration
whose file isn't yet in your branch.
```

The `[?]` row is the orphan — recorded as applied, but the file isn't on
disk in this checkout.

Running `wheels migrate latest`:

```
Running migration: latest...
Note: database tracks version(s) 20260521120100 with no matching file in
app/migrator/migrations/. This usually means a peer applied a migration
whose file isn't yet in your branch.
Migrating from 20260521131000 up to 20260521131000.

-------- 20260521131000_add_phone_to_users ----------------
…
```

Your pending local migration still applies. The orphan row stays in the
tracking table.

## Resolving an orphan

Pick the option that matches what actually happened:

### The peer's migration is legitimate; pull their file

```bash
git pull
wheels migrate info    # confirm the file is now present and marked [x]
```

The orphan row stops being an orphan once the file lands.

### The peer rolled back their migration

If the peer reverted their work but the tracking row remains, you can
remove it manually:

```sql
DELETE FROM wheels_migrator_versions WHERE version = '20260521120100';
```

A future release will ship `wheels migrate forget <version>` for this
workflow.

### You need to add a new migration

If you create a new migration today, give it a timestamp newer than the
orphan so it sorts after — Wheels' timestamp generation already does
this since it uses `Now()`. No action needed.

## Recommendation: avoid shared dev databases

A shared dev database trades schema isolation for "less environment to
set up". When two developers diverge on schema, the symptoms surface
exactly when you don't want them: mid-feature, with someone else's WIP
already applied. Consider:

- **Per-developer schemas** (MSSQL, Postgres) — same physical DB, one
  schema per developer. `config/environment.cfm` switches schema.
- **Per-developer databases** (MySQL, Postgres) — separate logical DBs
  on the same instance.
- **Local-only databases** — SQLite for dev, the shared instance only
  for staging/production. Wheels supports SQLite first-class.

If a shared dev DB is unavoidable for organisational reasons (e.g., a
team relying on production-like data), accept that orphan handling will
fire periodically and design your workflow around `git pull` + `wheels
migrate info` checks.
```

- [ ] **Step 3: Create the AI-side reference**

Create `.ai/wheels/troubleshooting/shared-dev-databases.md`:

```markdown
# Shared Development Databases

Short reference for the orphan-migration case. User-facing version lives at
`web/sites/guides/src/content/docs/v4-0-0/database-migrations/shared-development-databases.mdx`.

## What's an orphan?

A row in `wheels_migrator_versions` whose `version` timestamp has no
matching file in `app/migrator/migrations/`. Common cause: shared dev DB,
peer ran their migration first.

## Detection

`Migrator.cfc::$getOrphanVersions()` — returns an array of orphan version
strings, sorted ascending. Excludes the sentinel `"0"` returned when the
tracking table is empty.

## Display

`wheels migrate info` marks orphan rows with `[?]` and the literal
`********** NO FILE **********` (Rails-style). Includes a footer
explaining the cause.

## Behavior in `migrateTo()`

If `currentVersion > target` ONLY because of orphans (no local file with
version > target marked migrated), the down branch is skipped. Either:
- Pending local migrations exist → fall through to up branch with warning
- Nothing pending → emit "Nothing to do" with current vs target named

If SOME DB versions > target are orphans and SOME have local files, the
down branch runs as usual but emits a warning naming the orphans (they
get skipped by the existing loop since it iterates files only).

## Related

- Issue #2780 (the original report)
- `vendor/wheels/Migrator.cfc::$getOrphanVersions()`
- `vendor/wheels/Migrator.cfc::$buildInfoOutput()`
- `vendor/wheels/tests/specs/migrator/OrphanDetectionSpec.cfc`
- `vendor/wheels/tests/specs/migrator/MigratorInfoSpec.cfc`
```

- [ ] **Step 4: Commit**

```bash
git add web/sites/guides/src/content/docs/v4-0-0/database-migrations .ai/wheels/troubleshooting/shared-dev-databases.md
git commit -m "docs(migrator): document shared dev database orphan handling

Adds a user-facing guide page covering what orphan versions are, what
they look like in 'wheels migrate info' output, and how to resolve them.
Includes a recommendation against shared dev DBs and alternatives.

AI-side reference at .ai/wheels/troubleshooting/shared-dev-databases.md
points back to the user-facing page.

Refs #2780"
```

---

## Task 5: Verify cross-engine and open PR

- [ ] **Step 1: Run full local test suite**

```bash
bash tools/test-local.sh
```

Expected: full pass. If anything regresses, debug before pushing.

- [ ] **Step 2: Run cross-engine smoke test**

```bash
tools/test-matrix.sh lucee7 sqlite
tools/test-matrix.sh adobe2023 mysql
```

Expected: both pass. If Adobe 2023 fails, check anti-pattern #5 (inline closure as constructor arg — none in our changes) and #10 (Adobe 2023/2025 attributeCollection — none in our changes).

- [ ] **Step 3: Push branch**

```bash
git push -u origin claude/exciting-matsumoto-43179e
```

- [ ] **Step 4: Open PR**

```bash
gh pr create --title "fix(migrator): handle orphan versions in shared dev databases (#2780)" --body "$(cat <<'EOF'
## Summary

Resolves #2780 — when `wheels_migrator_versions` records a version whose
file isn't in the current checkout (shared dev DB / peer migration not
yet pulled), `wheels migrate latest` no longer takes a misleading "down"
branch and silently no-op.

## What changed

- **Detect**: `Migrator.\$getOrphanVersions()` returns versions tracked
  in the DB but missing from disk.
- **Fix the bug**: `migrateTo()` now branches on orphan-at-top before
  the directional check. When all DB versions > target are orphans:
  applies pending local migrations (the up branch) with a clear
  warning, OR emits "Nothing to do" naming current vs target.
- **Surface in info**: `wheels migrate info` shows orphan rows with
  `[?] <version> ********** NO FILE **********` (Rails-style) and a
  footer explaining the cause.
- **Docs**: New guide page at
  `web/sites/guides/.../shared-development-databases.mdx` covering
  detection, resolution, and the recommendation to avoid shared dev
  DBs where possible.

## Test plan

- [x] `bash tools/test-local.sh migrator` — passes (new `OrphanDetectionSpec`, `MigratorInfoSpec`, existing `migratorSpec`)
- [x] `bash tools/test-local.sh` — full local suite passes
- [x] `tools/test-matrix.sh lucee7 sqlite` — passes
- [x] `tools/test-matrix.sh adobe2023 mysql` — passes
- [ ] Manual repro from issue: create a fake high-version row + a new local file with earlier timestamp; confirm `wheels migrate latest` applies the new file (was silently no-op before this PR)

## Follow-up

Plans 2 and 3 (separate PRs):
- `wheels migrate doctor` / `forget` / `pretend` for manual reconciliation
- Schema enrichment of `wheels_migrator_versions` (name + applied_at columns) for richer info output

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

- [ ] **Step 5: Update tasks**

Mark Plan 1 execution task complete in the task list.

---

## Self-Review Checklist

**Spec coverage:**
- ✅ Proposal A (detect orphans, refuse "down", warn) → Tasks 1-2
- ✅ Proposal B (Rails-style `[?]` / NO FILE in info) → Task 3
- ✅ Proposal E (documentation) → Task 4
- ✅ Cross-engine verification → Task 5

**Placeholder scan:**
- No TBDs, no "implement later", no "similar to Task N", no "add error handling" without specifics.
- Every code step includes actual code; every test step has actual assertions.

**Type consistency:**
- `$getOrphanVersions()` returns `array` everywhere it's referenced.
- `$buildInfoOutput()` returns `array` everywhere it's referenced.
- `migrateTo(version, missingMigFlag)` signature unchanged from original.
- `local.orphans` / `local.orphansAboveTarget` / `local.isOrphanAtTop` named consistently within Task 2.

## Open questions to resolve during execution

1. **Adobe CF 2023 `attributeCollection` (anti-pattern #10):** None of our changes touch `cfheader`/`cfcache`/etc., but `cli.cfm` is the HTTP-facing view and runs through framework-cached paths. Verify Adobe 2023 matrix passes before merging — if it fails on `cli.cfm`, the culprit is likely a pre-existing issue, not ours.
2. **`Migrator.cfc` is `extends="wheels.Global"` (line 1):** Confirm that `$getOrphanVersions()` doesn't shadow a method on Global. Quick grep before implementing: `grep -n "getOrphanVersions" vendor/wheels/Global.cfc`. Expected: no match.
3. **The `data` struct in `cli.cfm`:** `data.datasource` and `data.databaseType` are populated by earlier code in the same view. Confirm they exist at line 159 before the `case "info"` branch — they do per the original code (lines 165-166).
