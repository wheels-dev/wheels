/**
 * The cross-process migration lock (#4134). Instances that share a database used to run
 * migrateTo() at the same time; a lease row in the migration lock table now makes them take
 * turns. "Another instance" here is a thread holding the lease row directly, which is exactly what
 * a second process looks like to the database.
 */
component extends="wheels.WheelsTest" {

	function beforeAll() {
		variables.migrator = CreateObject("component", "wheels.Migrator").init(
			migratePath = "/wheels/tests/_assets/migrator/migrations_4134/",
			sqlPath = "/wheels/tests/_assets/migrator/sql_4134/"
		);
		variables.version = "20991231000001";
		variables.ds = variables.migrator.$migratorDataSource();
		variables.raceVersion = "20991231000002";
		// Defaults keep the spec loadable where the lock doesn't exist yet (the RED run).
		variables.saved = {
			timeout = StructKeyExists(application.wheels, "migrationLockTimeout") ? application.wheels.migrationLockTimeout : 300,
			lease = StructKeyExists(application.wheels, "migrationLockLease") ? application.wheels.migrationLockLease : 3600
		};
		if (StructKeyExists(variables.migrator, "$migrationLockAvailable")) {
			variables.migrator.$migrationLockAvailable(variables.ds);
		}
	}

	function afterAll() {
		application.wheels.migrationLockTimeout = variables.saved.timeout;
		application.wheels.migrationLockLease = variables.saved.lease;
		resetState();
	}

	function lockTable() {
		return StructKeyExists(application.wheels, "migratorLockTableName") ? application.wheels.migratorLockTableName : "wheels_migrator_locks";
	}

	function rawQuery(required string sql, array params = []) {
		var rv = QueryExecute(arguments.sql, arguments.params, {datasource = variables.ds});
		return IsQuery(rv) ? rv : QueryNew("");
	}

	// An epoch-milliseconds query parameter, typed so PostgreSQL compares it as a number.
	function ms(required numeric value) {
		return {value = arguments.value, cfsqltype = "cf_sql_bigint"};
	}

	function lockRows() {
		try {
			return rawQuery("SELECT lockowner FROM #lockTable()#").recordCount;
		} catch (any e) {
			return 0;
		}
	}

	// The lease row another instance would hold, expiring `expiresInMs` from now.
	function holdAsAnotherInstance(required numeric expiresInMs) {
		rawQuery(
			"INSERT INTO #lockTable()# (lockname, lockowner, lockhost, acquiredat, expiresat) VALUES (?, ?, ?, ?, ?)",
			["migrate", "spec-other-instance", "spec-host", ms(GetTickCount()), ms(GetTickCount() + arguments.expiresInMs)]
		);
	}

	// Another instance: a thread that holds the lease row for `holdMs`, then deletes it. Started
	// from a component method because a `thread` block can't sit inside a spec closure on Lucee.
	function startOtherInstanceThread(required numeric holdMs) {
		var threadName = "migrationLockSpecHolder" & Replace(CreateUUID(), "-", "", "all");
		thread name="#threadName#" action="run" table="#lockTable()#" ds="#variables.ds#" holdMs="#arguments.holdMs#" {
			QueryExecute(
				"INSERT INTO #attributes.table# (lockname, lockowner, lockhost, acquiredat, expiresat) VALUES (?, ?, ?, ?, ?)",
				["migrate", "spec-other-instance", "spec-host", {value = GetTickCount(), cfsqltype = "cf_sql_bigint"}, {value = GetTickCount() + 60000, cfsqltype = "cf_sql_bigint"}],
				{datasource = attributes.ds}
			);
			sleep(attributes.holdMs);
			QueryExecute("DELETE FROM #attributes.table# WHERE lockowner = ?", ["spec-other-instance"], {datasource = attributes.ds});
		}
		return threadName;
	}

	// A second instance migrating at the same time: a thread running its own Migrator.
	function startRaceThread() {
		var threadName = "migrationLockSpecRace" & Replace(CreateUUID(), "-", "", "all");
		thread name="#threadName#" action="run" version="#variables.raceVersion#" {
			var other = CreateObject("component", "wheels.Migrator").init(
				migratePath = "/wheels/tests/_assets/migrator/migrations_4134_race/",
				sqlPath = "/wheels/tests/_assets/migrator/sql_4134/"
			);
			try {
				other.migrateTo(attributes.version);
			} catch (any e) {
				application.$migrationLockRaceThreadError = e.message;
			}
		}
		return threadName;
	}

	function resetState() {
		try {
			rawQuery("DELETE FROM #lockTable()#");
		} catch (any e) {
		}
		try {
			rawQuery("DELETE FROM #application.wheels.migratorTableName# WHERE version IN (?, ?)", [variables.version, variables.raceVersion]);
		} catch (any e) {
			// Another migrator spec may have dropped the versions table; migrateTo() recreates it.
		}
		application.$migrationLockSpecRuns = 0;
		application.$migrationLockRaceRuns = 0;
		application.$migrationLockRaceInside = false;
		application.$migrationLockRaceThreadError = "";
		StructDelete(request, "$wheelsDebugSQL");
		if (StructKeyExists(request, "wheels") && StructKeyExists(request.wheels, "migrationLocks")) {
			StructClear(request.wheels.migrationLocks);
		}
	}

	function run() {

		describe("The migration lock", () => {

			beforeEach(() => {
				resetState();
				application.wheels.migrationLockTimeout = variables.saved.timeout;
				application.wheels.migrationLockLease = variables.saved.lease;
			});

			it("is taken and released around migrateTo()", () => {
				variables.migrator.migrateTo(variables.version);
				expect(application.$migrationLockSpecRuns).toBe(1);
				expect(lockRows()).toBe(0);
			});

			it("runs a migration once when two instances migrate at the same time", () => {
				var raceThread = startRaceThread();
				var waited = 0;
				while (!application.$migrationLockRaceInside && waited < 15000) {
					sleep(50);
					waited += 50;
				}
				var second = CreateObject("component", "wheels.Migrator").init(
					migratePath = "/wheels/tests/_assets/migrator/migrations_4134_race/",
					sqlPath = "/wheels/tests/_assets/migrator/sql_4134/"
				);
				var state = {error = ""};
				try {
					second.migrateTo(variables.raceVersion);
				} catch (any e) {
					state.error = e.message;
				}
				thread action="join" name="#raceThread#" timeout="30000";
				expect(application.$migrationLockRaceInside).toBeTrue();
				expect(state.error).toBe("");
				expect(application.$migrationLockRaceThreadError).toBe("");
				expect(application.$migrationLockRaceRuns).toBe(1);
				expect(lockRows()).toBe(0);
			});

			it("makes migrateTo() wait for another instance holding it, then run each migration once", () => {
				application.wheels.migrationLockTimeout = 20;
				var threadName = startOtherInstanceThread(2500);
				var waited = 0;
				while (lockRows() == 0 && waited < 10000) {
					sleep(50);
					waited += 50;
				}
				var startedAt = GetTickCount();
				variables.migrator.migrateTo(variables.version);
				var tookMs = GetTickCount() - startedAt;
				thread action="join" name="#threadName#" timeout="20000";
				expect(tookMs).toBeGTE(1000);
				expect(application.$migrationLockSpecRuns).toBe(1);
				expect(lockRows()).toBe(0);
			});

			it("gives up after migrationLockTimeout, naming the holder, without running a migration", () => {
				application.wheels.migrationLockTimeout = 1;
				holdAsAnotherInstance(60000);
				var state = {type = "", detail = ""};
				try {
					variables.migrator.migrateTo(variables.version);
				} catch (any e) {
					state.type = e.type;
					state.detail = e.extendedInfo;
				}
				expect(state.type).toBe("Wheels.MigrationLockTimeout");
				expect(state.detail).toInclude("spec-host");
				expect(application.$migrationLockSpecRuns).toBe(0);
				expect(rawQuery("SELECT lockowner FROM #lockTable()#").lockowner).toBe("spec-other-instance");
			});

			it("takes over a lock whose lease has expired", () => {
				holdAsAnotherInstance(-1000);
				variables.migrator.migrateTo(variables.version);
				expect(application.$migrationLockSpecRuns).toBe(1);
				expect(lockRows()).toBe(0);
			});

			it("releases only its own lease row", () => {
				var held = variables.migrator.$acquireMigrationLock();
				rawQuery("UPDATE #lockTable()# SET lockowner = ?", ["spec-other-instance"]);
				variables.migrator.$releaseMigrationLock(held);
				expect(rawQuery("SELECT lockowner FROM #lockTable()#").lockowner).toBe("spec-other-instance");
			});

			it("stops with Wheels.MigrationLockLost once another instance took the lease over", () => {
				var held = variables.migrator.$acquireMigrationLock();
				rawQuery("UPDATE #lockTable()# SET lockowner = ?", ["spec-other-instance"]);
				var state = {type = ""};
				try {
					variables.migrator.$renewMigrationLock();
				} catch (any e) {
					state.type = e.type;
				}
				variables.migrator.$releaseMigrationLock(held);
				expect(state.type).toBe("Wheels.MigrationLockLost");
			});

			it("is re-entrant within a request", () => {
				var outer = variables.migrator.$acquireMigrationLock();
				var inner = variables.migrator.$acquireMigrationLock();
				expect(inner.reentered).toBeTrue();
				variables.migrator.$releaseMigrationLock(inner);
				expect(lockRows()).toBe(1);
				variables.migrator.$releaseMigrationLock(outer);
				expect(lockRows()).toBe(0);
			});

			it("is not taken in SQL preview mode", () => {
				request.$wheelsDebugSQL = true;
				var held = variables.migrator.$acquireMigrationLock();
				StructDelete(request, "$wheelsDebugSQL");
				expect(held.active).toBeFalse();
				expect(lockRows()).toBe(0);
			});

		});

	}

}
