/**
 * withAdvisoryLock(transaction = true) pins acquire + callback + release to one connection by
 * running them in a transaction, so the lock genuinely covers the callback's queries and, on
 * PostgreSQL / SQL Server, auto-releases at transaction end (4198). MySQL's GET_LOCK is
 * session-scoped and is released explicitly before the transaction closes. CockroachDB, SQLite,
 * H2 and Oracle do not support it, so an opt-in transaction = true throws rather than silently
 * running session-scoped.
 *
 * Exclusion is verified uniformly (a holder thread keeps a second caller out until it finishes);
 * DB-level acquire and auto-release are asserted precisely on PostgreSQL / MySQL, whose advisory
 * locks are visible from another pooled connection (pg_locks / IS_USED_LOCK).
 */
component extends="wheels.WheelsTest" {

	function beforeAll() {
		variables.g = application.wo;
		variables.ds = variables.g.get("dataSourceName");
		variables.adapterName = variables.g.get("adapterName");
		// Databases whose adapter supports the transaction-scoped path.
		variables.applies = ListFindNoCase("PostgreSQLModel,MySQLModel,MicrosoftSQLServerModel", variables.adapterName) > 0;
		// Databases whose advisory lock is visible from another pooled connection, so isHeld() works.
		variables.introspectable = ListFindNoCase("PostgreSQLModel,MySQLModel", variables.adapterName) > 0;
	}

	function lockName() {
		return "wheels_txlock_" & Replace(CreateUUID(), "-", "", "all");
	}

	// A separate adapter instance on the test datasource, so a second-session acquire never touches
	// the model's own adapter (mirrors advisoryLockExclusionSpec).
	function freshAdapter() {
		var classData = variables.g.model("author").$classData();
		var folder = Left(variables.adapterName, Len(variables.adapterName) - 5);
		return CreateObject("component", "wheels.databaseAdapters.#folder#.#variables.adapterName#").$init(
			dataSource = classData.dataSource,
			username = classData.username,
			password = classData.password
		);
	}

	// Attempts the transaction-scoped acquire on a FRESH adapter/connection, bypassing the app-server
	// cflock, so this is a genuine second-DB-session attempt. Returns {ok, type}: ok=true if the lock
	// was taken (and then released + rolled back so nothing leaks), false (with the error type) if it
	// timed out while another session held it.
	function tryAcquireFresh(required string name, required numeric timeoutSecs) {
		var a = freshAdapter();
		var r = {ok = false, type = ""};
		transaction {
			try {
				a.$acquireAdvisoryLockTransactional(name = arguments.name, timeout = arguments.timeoutSecs);
				r.ok = true;
			} catch (any e) {
				r.type = e.type;
			}
			// Clean up a session-scoped lock we took; a transaction-scoped one (PG) auto-releases on
			// the rollback below.
			if (r.ok && a.$transactionalAdvisoryLockIsSessionScoped()) {
				a.$releaseAdvisoryLockTransactional(name = arguments.name);
			}
			transaction action="rollback";
		}
		return r;
	}

	// True when any session holds the named lock, read straight from the database on a pooled
	// connection separate from the holder's pinned one (PostgreSQL / MySQL only).
	function isHeld(required string name) {
		if (variables.adapterName == "PostgreSQLModel") {
			var q = QueryExecute(
				"SELECT COUNT(*) AS n FROM pg_locks WHERE locktype = 'advisory' AND granted AND objid = CAST((CAST(hashtext(?) AS bigint) & 4294967295) AS oid)",
				[arguments.name],
				{datasource = variables.ds}
			);
			return q.n > 0;
		}
		var m = QueryExecute("SELECT IS_USED_LOCK(?) AS id", [arguments.name], {datasource = variables.ds});
		return !IsNull(m.id) && Len(m.id) > 0;
	}

	// Starts a thread that holds the transaction-scoped lock for holdMs inside
	// withAdvisoryLock(transaction = true); returns the (unique) thread name. When fail is true the
	// callback throws after signalling, so the transaction rolls back.
	function startTxHolder(required string name, required numeric holdMs, boolean fail = false) {
		var threadName = "advisoryLockTxHolder" & Replace(CreateUUID(), "-", "", "all");
		application.advisoryLockTxSpec = {started = false, done = false, error = ""};
		thread name="#threadName#" action="run" lockName="#arguments.name#" holdMs="#arguments.holdMs#" shouldFail="#arguments.fail#" {
			try {
				var holdFor = attributes.holdMs;
				var throwAtEnd = attributes.shouldFail;
				var body = function() {
					application.advisoryLockTxSpec.started = true;
					sleep(holdFor);
					if (throwAtEnd) {
						Throw(type = "Wheels.SpecHolderFailure", message = "holder callback failed on purpose");
					}
					return true;
				};
				application.wo.model("author").withAdvisoryLock(name = attributes.lockName, timeout = 10, callback = body, transaction = true);
			} catch (any e) {
				application.advisoryLockTxSpec.error = e.type & ": " & e.message;
			}
			application.advisoryLockTxSpec.done = true;
		}
		var waited = 0;
		while (!application.advisoryLockTxSpec.started && waited < 10000) {
			sleep(50);
			waited += 50;
		}
		return threadName;
	}

	function run() {

		describe("$supportsTransactionalAdvisoryLock capability", () => {

			it("is implemented on the current model adapter and returns a boolean", () => {
				var adapter = variables.g.model("author").$classData().adapter;
				expect(IsBoolean(adapter.$supportsTransactionalAdvisoryLock())).toBeTrue();
			});

			it("reports a boolean for whether the lock is session-scoped", () => {
				var adapter = variables.g.model("author").$classData().adapter;
				expect(IsBoolean(adapter.$transactionalAdvisoryLockIsSessionScoped())).toBeTrue();
			});

		});

		describe("withAdvisoryLock(transaction = true) on a supported database", () => {

			beforeEach(() => {
				if (!variables.applies) {
					skip("Transaction-scoped advisory locks: PostgreSQL, MySQL, SQL Server.");
				}
			});

			it("runs the callback and returns its result", () => {
				var result = variables.g.model("author").withAdvisoryLock(name = lockName(), transaction = true, callback = function() {
					return 42;
				});
				expect(result).toBe(42);
			});

			it("holds the lock at the database during the callback and frees it afterwards", () => {
				if (!variables.introspectable) {
					skip("DB-level lock introspection: PostgreSQL, MySQL.");
				}
				var name = lockName();
				var holder = startTxHolder(name, 2000);
				expect(application.advisoryLockTxSpec.started).toBeTrue();
				// Read from a separate pooled connection while the holder's transaction is open.
				expect(isHeld(name)).toBeTrue("the transaction-scoped lock must be held at the database during the callback");
				thread action="join" name="#holder#" timeout="15000";
				expect(application.advisoryLockTxSpec.error).toBe("");
				expect(isHeld(name)).toBeFalse("the lock must be released when the transaction ends");
			});

			it("frees the lock after the callback throws (transaction rolls back)", () => {
				if (!variables.introspectable) {
					skip("DB-level lock introspection: PostgreSQL, MySQL.");
				}
				var name = lockName();
				var holder = startTxHolder(name, 500, true);
				thread action="join" name="#holder#" timeout="15000";
				expect(application.advisoryLockTxSpec.error).toInclude("Wheels.SpecHolderFailure");
				expect(isHeld(name)).toBeFalse("the lock must be released when the transaction rolls back");
			});

			it("keeps a second caller out while the first holds the lock", () => {
				var name = lockName();
				var state = {entered = false, type = ""};
				var second = function() {
					state.entered = true;
					return true;
				};
				var holder = startTxHolder(name, 3000);
				expect(application.advisoryLockTxSpec.started).toBeTrue();
				try {
					variables.g.model("author").withAdvisoryLock(name = name, timeout = 1, callback = second, transaction = true);
				} catch (any e) {
					state.type = e.type;
				}
				thread action="join" name="#holder#" timeout="15000";
				expect(state.entered).toBeFalse("a second caller must not enter while the first holds the lock");
				expect(state.type).toBe("Wheels.AdvisoryLockTimeout");
			});

			it("frees the lock for the next caller once the first has finished", () => {
				var name = lockName();
				var holder = startTxHolder(name, 500);
				thread action="join" name="#holder#" timeout="15000";
				var result = variables.g.model("author").withAdvisoryLock(name = name, timeout = 2, callback = function() {
					return "next";
				}, transaction = true);
				expect(result).toBe("next");
			});

		});

		describe("withAdvisoryLock(transaction = true) on an unsupported database", () => {

			it("throws Wheels.AdvisoryLockNotSupported rather than falling back silently", () => {
				if (variables.applies) {
					skip("This database supports the transaction-scoped path.");
				}
				var state = {entered = false, type = ""};
				try {
					variables.g.model("author").withAdvisoryLock(name = lockName(), transaction = true, callback = function() {
						state.entered = true;
						return true;
					});
				} catch (any e) {
					state.type = e.type;
				}
				expect(state.entered).toBeFalse("an unsupported opt-in must not run the callback");
				expect(state.type).toBe("Wheels.AdvisoryLockNotSupported");
			});

		});

		describe("withAdvisoryLock(transaction = true) inside an already-open transaction", () => {

			beforeEach(() => {
				if (!variables.introspectable) {
					skip("Outer-transaction join is asserted on PostgreSQL / MySQL (DB-level introspection).");
				}
			});

			// A transaction-scoped lock (PostgreSQL) joins the outer transaction and is held until the
			// OUTER transaction ends, not when the call returns. MySQL's session-scoped lock is released
			// at call end, so this assertion is PostgreSQL-only.
			it("holds a transaction-scoped lock until the outer transaction ends", () => {
				if (variables.adapterName != "PostgreSQLModel") {
					skip("Transaction-scoped (outer-held) release is PostgreSQL here; MySQL is session-scoped.");
				}
				var name = lockName();
				var author = variables.g.model("author");
				var ctx = {heldDuringCall = false};
				transaction {
					author.withAdvisoryLock(name = name, transaction = true, callback = function() {
						return true;
					});
					// Still inside the OUTER transaction: the lock must still be held.
					ctx.heldDuringCall = isHeld(name);
				}
				// Outer transaction has ended: the lock must now be free.
				expect(ctx.heldDuringCall).toBeTrue("the lock must be held until the outer transaction ends, not when the call returns");
				expect(isHeld(name)).toBeFalse("the lock must be released once the outer transaction ends");
			});

			// The session-scoped contrast: MySQL releases its lock at CALL end, so inside the outer
			// transaction the lock is already free after the call returns (SQL Server shares this
			// session-scoped code path; it is not introspectable here, so it is asserted on MySQL).
			it("releases a session-scoped lock at call end, before the outer transaction ends", () => {
				if (variables.adapterName != "MySQLModel") {
					skip("Session-scoped call-end release is introspectable on MySQL; PostgreSQL is tx-scoped.");
				}
				var name = lockName();
				var author = variables.g.model("author");
				var ctx = {heldAfterCall = true};
				transaction {
					author.withAdvisoryLock(name = name, transaction = true, callback = function() {
						return true;
					});
					// Still inside the OUTER transaction, but the session lock is released at call end.
					ctx.heldAfterCall = isHeld(name);
				}
				expect(ctx.heldAfterCall).toBeFalse("a session-scoped lock must be released at call end, not held to the outer transaction");
			});

		});

		describe("two-session exclusion at the database (4195-style, cflock-bypassing)", () => {

			beforeEach(() => {
				if (!variables.applies) {
					skip("Transaction-scoped advisory locks: PostgreSQL, MySQL, SQL Server.");
				}
			});

			// A genuine second DB session (freshAdapter, no app-server cflock) is blocked while the
			// first holds the lock and can acquire once it is released. Uniform across PG/MySQL/MSSQL.
			it("blocks a second session while held and lets it acquire after release", () => {
				var name = lockName();
				var holder = startTxHolder(name, 3000);
				expect(application.advisoryLockTxSpec.started).toBeTrue();
				var blocked = tryAcquireFresh(name, 1);
				thread action="join" name="#holder#" timeout="15000";
				expect(application.advisoryLockTxSpec.error).toBe("");
				expect(blocked.ok).toBeFalse("a second DB session must be blocked while the lock is held");
				expect(blocked.type).toBe("Wheels.AdvisoryLockTimeout");
				var acquired = tryAcquireFresh(name, 2);
				expect(acquired.ok).toBeTrue("a second DB session must acquire once the first has released");
			});

		});

		describe("re-entrancy: a nested same-name lock on the same session", () => {

			// Session locks (MySQL GET_LOCK, SQL Server sp_getapplock) and the PG xact lock all count
			// up/down on one session, and the app-server cflock is re-entrant for the same thread, so a
			// nested same-name call runs its inner callback and leaves the lock fully released.
			it("runs the nested callback and fully releases on the transaction path", () => {
				if (!variables.applies) {
					skip("Transaction-scoped advisory locks: PostgreSQL, MySQL, SQL Server.");
				}
				var name = lockName();
				var author = variables.g.model("author");
				var ctx = {inner = false};
				author.withAdvisoryLock(name = name, timeout = 5, transaction = true, callback = function() {
					author.withAdvisoryLock(name = name, timeout = 5, transaction = true, callback = function() {
						ctx.inner = true;
						return true;
					});
					return true;
				});
				expect(ctx.inner).toBeTrue("the nested same-name callback must run");
				if (variables.introspectable) {
					expect(isHeld(name)).toBeFalse("both levels must release, leaving the lock free");
				}
			});

			// The default (#4200) path uses the same app-server lock, so nesting must work there too;
			// if an engine's cflock is not re-entrant, this is a #4200 behaviour, not #4198.
			it("runs the nested callback and fully releases on the default path", () => {
				if (!variables.g.model("author").$classData().adapter.$supportsAdvisoryLocks()) {
					skip("Default-path advisory locks need standalone support: PostgreSQL, MySQL.");
				}
				var name = lockName();
				var author = variables.g.model("author");
				var ctx = {inner = false};
				author.withAdvisoryLock(name = name, timeout = 5, callback = function() {
					author.withAdvisoryLock(name = name, timeout = 5, callback = function() {
						ctx.inner = true;
						return true;
					});
					return true;
				});
				expect(ctx.inner).toBeTrue("the nested same-name callback must run on the default path");
				if (variables.introspectable) {
					expect(isHeld(name)).toBeFalse("both levels must release on the default path");
				}
			});

		});

	}

}
