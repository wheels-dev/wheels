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

	// `params` is an array of plain values, or a struct of named typed values. Typed values go by
	// name: RustCFML binds a typed struct in a positional array as its text.
	function rawQuery(required string sql, any params = []) {
		var result = {};
		result.rows = QueryExecute(arguments.sql, arguments.params, {datasource = variables.ds});
		// Adobe 2023 returns nothing for an UPDATE or DELETE, which leaves the key unset.
		return StructKeyExists(result, "rows") && IsQuery(result.rows) ? result.rows : QueryNew("");
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
			"INSERT INTO #lockTable()# (lockname, lockowner, lockhost, acquiredat, expiresat) VALUES ('migrate', 'spec-other-instance', 'spec-host', :acquiredAt, :expiresAt)",
			{acquiredAt = ms(GetTickCount()), expiresAt = ms(GetTickCount() + arguments.expiresInMs)}
		);
	}

	// Another instance: a thread that holds the lease row for `holdMs`, then deletes it. Started
	// from a component method because a `thread` block can't sit inside a spec closure on Lucee.
	function startOtherInstanceThread(required numeric holdMs) {
		var threadName = "migrationLockSpecHolder" & Replace(CreateUUID(), "-", "", "all");
		thread name="#threadName#" action="run" table="#lockTable()#" ds="#variables.ds#" holdMs="#arguments.holdMs#" {
			QueryExecute(
				"INSERT INTO #attributes.table# (lockname, lockowner, lockhost, acquiredat, expiresat) VALUES ('migrate', 'spec-other-instance', 'spec-host', :acquiredAt, :expiresAt)",
				{
					acquiredAt = {value = GetTickCount(), cfsqltype = "cf_sql_bigint"},
					expiresAt = {value = GetTickCount() + 60000, cfsqltype = "cf_sql_bigint"}
				},
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
				if (!Len(variables.migrator.$migrationLockThreadId())) {
					skip("Re-entrancy needs a thread identity; this engine has none.");
				}
				var outer = variables.migrator.$acquireMigrationLock();
				var inner = variables.migrator.$acquireMigrationLock();
				expect(inner.reentered).toBeTrue();
				variables.migrator.$releaseMigrationLock(inner);
				expect(lockRows()).toBe(1);
				variables.migrator.$releaseMigrationLock(outer);
				expect(lockRows()).toBe(0);
			});

			// A JVM-free engine has no thread id, and a cfthread shares its parent's request scope:
			// a second caller must take the database lock, never count as re-entering the first's.
			it("doesn't re-enter another caller's lock without a thread identity", () => {
				application.wheels.migrationLockTimeout = 1;
				var m = CreateObject("component", "wheels.Migrator").init(
					migratePath = "/wheels/tests/_assets/migrator/migrations_4134/",
					sqlPath = "/wheels/tests/_assets/migrator/sql_4134/"
				);
				prepareMock(m);
				m.$("$migrationLockThreadId", "");
				var first = m.$acquireMigrationLock();
				var state = {type = "", renewType = ""};
				try {
					m.$acquireMigrationLock();
				} catch (any e) {
					state.type = e.type;
				}
				try {
					m.$renewMigrationLock();
				} catch (any e) {
					state.renewType = e.type;
				}
				m.$releaseMigrationLock(first);
				expect(first.reentered).toBeFalse();
				expect(state.type).toBe("Wheels.MigrationLockTimeout");
				expect(state.renewType).toBe("");
				expect(lockRows()).toBe(0);
			});

			it("tolerates a re-entered release after the outer lock was released", () => {
				if (!Len(variables.migrator.$migrationLockThreadId())) {
					skip("Re-entrancy needs a thread identity; this engine has none.");
				}
				var outer = variables.migrator.$acquireMigrationLock();
				var inner = variables.migrator.$acquireMigrationLock();
				variables.migrator.$releaseMigrationLock(outer);
				variables.migrator.$releaseMigrationLock(inner);
				expect(lockRows()).toBe(0);
			});

			it("reports a failed lease insert instead of waiting when no row exists", () => {
				var m = CreateObject("component", "wheels.Migrator").init(
					migratePath = "/wheels/tests/_assets/migrator/migrations_4134/",
					sqlPath = "/wheels/tests/_assets/migrator/sql_4134/"
				);
				prepareMock(m);
				m.$("$migrationLockOwner", "");
				m.$(method = "$migrationLockQuery", throwException = true, throwType = "Spec.LeaseInsertFailed", throwMessage = "insert failed");
				var state = {type = ""};
				try {
					m.$tryTakeMigrationLock({owner = "spec"});
				} catch (any e) {
					state.type = e.type;
				}
				expect(state.type).toBe("Spec.LeaseInsertFailed");
				// The INSERT's own error, and no takeover UPDATE after it found no row to take over.
				var statements = [];
				for (var call in m.$callLog()["$migrationLockQuery"]) {
					ArrayAppend(statements, Trim(ListFirst(call.sql, " ")));
				}
				expect(ArrayFind(statements, "INSERT")).toBeGT(0);
				expect(ArrayFindNoCase(statements, "UPDATE")).toBe(0);
			});

			it("takes no lock, and warns once, when createMigratorTable is off and the table is missing", () => {
				// Clear any earlier run's flag, or a second run in the same application passes vacuously.
				if (StructKeyExists(application.wheels, "$migrationLockWarned")) {
					StructDelete(application.wheels["$migrationLockWarned"], variables.ds);
				}
				var saved = {table = application.wheels.migratorLockTableName, create = application.wheels.createMigratorTable};
				application.wheels.migratorLockTableName = "wheels_spec_absent_locks";
				application.wheels.createMigratorTable = false;
				var state = {available = true, warned = false};
				try {
					state.available = variables.migrator.$migrationLockAvailable(variables.ds);
					state.warned = StructKeyExists(application.wheels, "$migrationLockWarned")
						&& StructKeyExists(application.wheels["$migrationLockWarned"], variables.ds);
				} finally {
					application.wheels.migratorLockTableName = saved.table;
					application.wheels.createMigratorTable = saved.create;
				}
				expect(state.available).toBeFalse();
				expect(state.warned).toBeTrue();
			});

			it("is not taken in SQL preview mode", () => {
				request.$wheelsDebugSQL = true;
				var held = variables.migrator.$acquireMigrationLock();
				StructDelete(request, "$wheelsDebugSQL");
				expect(held.active).toBeFalse();
				expect(lockRows()).toBe(0);
			});

		});

		describe("migrationLockStatus() and releaseMigrationLock()", () => {

			beforeEach(() => {
				resetState();
			});

			it("reports no lock when nothing holds it", () => {
				var status = variables.migrator.migrationLockStatus();
				expect(status.held).toBeFalse();
				expect(status.expired).toBeFalse();
				expect(status.owner).toBe("");
				expect(status.host).toBe("");
			});

			it("reports a live lock's holder, how long it has held it, and when its lease expires", () => {
				holdAsAnotherInstance(60000);
				var status = variables.migrator.migrationLockStatus();
				expect(status.held).toBeTrue();
				expect(status.expired).toBeFalse();
				expect(status.owner).toBe("spec-other-instance");
				expect(status.host).toBe("spec-host");
				expect(status.heldForSeconds).toBeGTE(0);
				expect(status.expiresInSeconds).toBeGT(50);
				expect(status.expiresInSeconds).toBeLTE(60);
			});

			it("reports an expired lease as held and expired", () => {
				holdAsAnotherInstance(-5000);
				var status = variables.migrator.migrationLockStatus();
				expect(status.held).toBeTrue();
				expect(status.expired).toBeTrue();
				expect(status.expiresInSeconds).toBeLT(0);
			});

			it("reports no lock when the lock table doesn't exist", () => {
				var saved = application.wheels.migratorLockTableName;
				application.wheels.migratorLockTableName = "wheels_spec_absent_locks";
				var state = {held = true};
				try {
					state.held = variables.migrator.migrationLockStatus().held;
				} finally {
					application.wheels.migratorLockTableName = saved;
				}
				expect(state.held).toBeFalse();
			});

			it("leaves a live lock in place without force", () => {
				holdAsAnotherInstance(60000);
				var result = variables.migrator.releaseMigrationLock();
				expect(result.released).toBeFalse();
				expect(result.heldBy).toBe("spec-other-instance");
				expect(result.lock.owner).toBe("spec-other-instance");
				expect(rawQuery("SELECT lockowner FROM #lockTable()#").lockowner).toBe("spec-other-instance");
			});

			it("removes an expired lease without force", () => {
				holdAsAnotherInstance(-5000);
				var result = variables.migrator.releaseMigrationLock();
				expect(result.released).toBeTrue();
				expect(lockRows()).toBe(0);
			});

			it("removes a live lock with force, returning what it removed", () => {
				holdAsAnotherInstance(60000);
				var result = variables.migrator.releaseMigrationLock(force = true);
				expect(result.released).toBeTrue();
				expect(result.heldBy).toBe("");
				expect(result.lock.owner).toBe("spec-other-instance");
				expect(result.lock.host).toBe("spec-host");
				expect(lockRows()).toBe(0);
			});

			// Another instance takes the lease between the read and the DELETE: the DELETE is keyed
			// on the owner read, so nothing of the new holder's is removed, and that isn't a release.
			it("doesn't report a release when the lock changed hands before the delete", () => {
				holdAsAnotherInstance(-5000);
				var m = CreateObject("component", "wheels.Migrator").init(
					migratePath = "/wheels/tests/_assets/migrator/migrations_4134/",
					sqlPath = "/wheels/tests/_assets/migrator/sql_4134/"
				);
				prepareMock(m);
				m.$("$migrationLockOwner", "spec-new-holder");
				var result = m.releaseMigrationLock(force = true);
				expect(result.released).toBeFalse();
				expect(result.lock.owner).toBe("spec-other-instance");
				expect(result.heldBy).toBe("spec-new-holder");
			});

			it("succeeds with force when nothing holds the lock", () => {
				var result = variables.migrator.releaseMigrationLock(force = true);
				expect(result.released).toBeFalse();
				expect(result.lock.held).toBeFalse();
			});

			it("makes a holder that lost its row fail its next renewal", () => {
				var held = variables.migrator.$acquireMigrationLock();
				variables.migrator.releaseMigrationLock(force = true);
				var state = {type = ""};
				try {
					variables.migrator.$renewMigrationLock();
				} catch (any e) {
					state.type = e.type;
				}
				variables.migrator.$releaseMigrationLock(held);
				expect(state.type).toBe("Wheels.MigrationLockLost");
			});

			it("points a lock timeout at wheels migrate unlock", () => {
				var saved = application.wheels.migrationLockTimeout;
				application.wheels.migrationLockTimeout = 1;
				holdAsAnotherInstance(60000);
				var state = {detail = ""};
				try {
					variables.migrator.migrateTo(variables.version);
				} catch (any e) {
					state.detail = e.extendedInfo;
				} finally {
					application.wheels.migrationLockTimeout = saved;
				}
				expect(state.detail).toInclude("wheels migrate unlock");
				expect(state.detail).toInclude("spec-host");
			});

		});

	}

}
