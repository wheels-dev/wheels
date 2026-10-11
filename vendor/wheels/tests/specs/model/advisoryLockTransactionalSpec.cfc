/**
 * withAdvisoryLock(transaction = true) pins acquire + callback + release to one connection by
 * running them in a Wheels-owned transaction, so the lock genuinely covers the callback's queries
 * (4198). On PostgreSQL the lock is transaction-scoped (pg_advisory_xact_lock) and auto-releases at
 * transaction end; on MySQL (GET_LOCK) and SQL Server (sp_getapplock @LockOwner = 'Session') it is
 * session-scoped and released explicitly, after the commit, before the transaction block closes.
 * CockroachDB, SQLite, H2 and Oracle do not support it, so an opt-in transaction = true throws
 * rather than silently running session-scoped.
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
				if (!variables.applies) {
					skip("Transaction-scoped advisory locks: PostgreSQL, MySQL, SQL Server.");
				}
			});

			// PostgreSQL: the transaction-scoped lock joins the outer transaction and is held until the
			// OUTER transaction ends, not when the call returns.
			it("holds a PostgreSQL transaction-scoped lock until the outer transaction ends", () => {
				if (variables.adapterName != "PostgreSQLModel") {
					skip("Transaction-scoped (outer-held) join is PostgreSQL; session-scoped adapters throw.");
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

			// Session-scoped adapters (MySQL / SQL Server) cannot release before the outer transaction
			// commits without exposing pre-commit state, so transaction = true inside an existing
			// transaction is unsupported and throws (rather than releasing early).
			it("throws for a session-scoped adapter inside an existing transaction", () => {
				if (!ListFindNoCase("MySQLModel,MicrosoftSQLServerModel", variables.adapterName)) {
					skip("Session-scoped throw-inside-outer-tx is MySQL / SQL Server; PostgreSQL joins.");
				}
				var name = lockName();
				var author = variables.g.model("author");
				var state = {entered = false, type = ""};
				transaction {
					try {
						author.withAdvisoryLock(name = name, transaction = true, callback = function() {
							state.entered = true;
							return true;
						});
					} catch (any e) {
						state.type = e.type;
					}
				}
				expect(state.entered).toBeFalse("the lock body must not run inside an existing transaction on a session-scoped adapter");
				expect(state.type).toBe("Wheels.AdvisoryLockNotSupported");
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

		describe("connection pinning: the lock holder is the model's own connection", () => {

			beforeEach(() => {
				if (!variables.applies) {
					skip("Transaction-scoped advisory locks: PostgreSQL, MySQL, SQL Server.");
				}
			});

			// The guarantee the whole feature rests on: inside the lock transaction, the session that
			// HOLDS the lock is the SAME session the model's own queries run on. Read the model's
			// session id through a real model query (findAll) and the lock owner's session id through a
			// database view, and assert they are equal. This fails if the lock's connection args ever
			// drift from the model's query path (the Adobe bug where the lock used explicit empty creds
			// and the model omitted them, landing on different pooled connections).
			it("holds the lock on the same session the model queries use", () => {
				var author = variables.g.model("author");
				var ds = variables.g.get("dataSourceName");
				var name = lockName();
				var ctx = {modelSid = "", ownerSid = ""};
				author.withAdvisoryLock(name = name, transaction = true, callback = function() {
					if (variables.adapterName == "MySQLModel") {
						ctx.modelSid = author.findAll(select = "CONNECTION_ID() AS cid", maxRows = 1, reload = true).cid;
						var o = queryExecute("SELECT IS_USED_LOCK(?) AS sid", [name], {datasource = ds});
						ctx.ownerSid = IsNull(o.sid) ? "" : o.sid;
					} else if (variables.adapterName == "PostgreSQLModel") {
						ctx.modelSid = author.findAll(select = "pg_backend_pid() AS cid", maxRows = 1, reload = true).cid;
						var o = queryExecute(
							"SELECT pid AS sid FROM pg_locks WHERE locktype = 'advisory' AND granted AND objid = CAST((CAST(hashtext(?) AS bigint) & 4294967295) AS oid) LIMIT 1",
							[name],
							{datasource = ds}
						);
						ctx.ownerSid = o.recordCount ? o.sid : "";
					} else {
						ctx.modelSid = author.findAll(select = "@@SPID AS cid", maxRows = 1, reload = true).cid;
						// Match the SQL Server application lock by its hashed resource name.
						var o = queryExecute(
							"SELECT request_session_id AS sid FROM sys.dm_tran_locks WHERE resource_type = 'APPLICATION' AND request_status = 'GRANT' AND resource_description LIKE ?",
							[{value = "%" & LCase(Hash(name, "SHA")) & "%", cfsqltype = "cf_sql_varchar"}],
							{datasource = ds}
						);
						// Fall back to the single granted application lock when the hash form differs.
						if (!o.recordCount) {
							o = queryExecute("SELECT request_session_id AS sid FROM sys.dm_tran_locks WHERE resource_type = 'APPLICATION' AND request_status = 'GRANT'", [], {datasource = ds});
						}
						ctx.ownerSid = o.recordCount ? o.sid : "";
					}
					return true;
				});
				expect(Len(ctx.modelSid)).toBeGT(0, "could not read the model's session id");
				expect(Len(ctx.ownerSid)).toBeGT(0, "could not read the lock owner's session id");
				expect(ToString(ctx.modelSid)).toBe(ToString(ctx.ownerSid), "the lock must be held on the model's own connection (pinned)");
			});

		});

		describe("tenant datasource routing: the lock follows the model's effective datasource", () => {

			// The lock connection must resolve its datasource through $effectiveDataSource() exactly as
			// the model's query path ($performQuery) does. Otherwise, in a multi-tenant request, a
			// non-shared model's lock is taken on the DEFAULT datasource while its writes go to the
			// TENANT datasource — the same split-connection bug as the Adobe one, and lock names would
			// also collide across tenants in the default database. Pure datasource-routing assertions,
			// so they run on every adapter (no live lock needed).
			it("a non-shared (tenant) model takes the lock on its tenant datasource", () => {
				var a = freshAdapter();
				var saved = IsDefined("request.wheels.tenant") ? Duplicate(request.wheels.tenant) : "";
				request.wheels.tenant = {dataSource = "wheels_tenant_probe_ds"};
				try {
					expect(a.$effectiveDataSource()).toBe("wheels_tenant_probe_ds", "a non-shared model must route to the tenant datasource");
					expect(a.$advisoryLockConnection().datasource).toBe(a.$effectiveDataSource(), "the lock datasource must equal the model's effective (tenant) datasource");
				} finally {
					if (IsStruct(saved)) {
						request.wheels.tenant = saved;
					} else {
						StructDelete(request.wheels, "tenant");
					}
				}
			});

			it("a shared model takes the lock on the default datasource, ignoring the tenant", () => {
				var a = freshAdapter();
				a.$setSharedModel(true);
				var saved = IsDefined("request.wheels.tenant") ? Duplicate(request.wheels.tenant) : "";
				request.wheels.tenant = {dataSource = "wheels_tenant_probe_ds"};
				try {
					expect(a.$effectiveDataSource()).notToBe("wheels_tenant_probe_ds", "a shared model must ignore the tenant datasource");
					expect(a.$advisoryLockConnection().datasource).toBe(a.$effectiveDataSource(), "the lock datasource must equal the default datasource for a shared model");
				} finally {
					if (IsStruct(saved)) {
						request.wheels.tenant = saved;
					} else {
						StructDelete(request.wheels, "tenant");
					}
				}
			});

		});

		describe("re-entrancy: a nested same-name lock on the same session", () => {

			// A nested transaction = true runs inside the OUTER lock's Wheels-owned transaction, so it
			// takes the join path: PostgreSQL's transaction-scoped lock joins and the inner runs (both
			// released when the outer transaction ends); a session-scoped adapter (MySQL / SQL Server)
			// throws, because the inner could not release before the outer commits.
			it("nested transaction = true: PostgreSQL joins and runs; session-scoped throws", () => {
				if (!variables.applies) {
					skip("Transaction-scoped advisory locks: PostgreSQL, MySQL, SQL Server.");
				}
				var name = lockName();
				var author = variables.g.model("author");
				if (variables.adapterName == "PostgreSQLModel") {
					var ctx = {inner = false};
					author.withAdvisoryLock(name = name, timeout = 5, transaction = true, callback = function() {
						author.withAdvisoryLock(name = name, timeout = 5, transaction = true, callback = function() {
							ctx.inner = true;
							return true;
						});
						return true;
					});
					expect(ctx.inner).toBeTrue("PostgreSQL nested transaction = true joins the outer and runs the inner");
					expect(isHeld(name)).toBeFalse("both levels are released once the outer transaction ends");
				} else {
					var ctx = {inner = false, type = ""};
					try {
						author.withAdvisoryLock(name = name, timeout = 5, transaction = true, callback = function() {
							author.withAdvisoryLock(name = name, timeout = 5, transaction = true, callback = function() {
								ctx.inner = true;
								return true;
							});
							return true;
						});
					} catch (any e) {
						ctx.type = e.type;
					}
					expect(ctx.inner).toBeFalse("a session-scoped nested transaction = true must not run the inner");
					expect(ctx.type).toBe("Wheels.AdvisoryLockNotSupported");
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

		// The lock transaction is a Wheels-OWNED transaction, so a model saved inside the callback
		// joins it (same connection args) and its afterCommit/afterRollback callbacks resolve once at
		// the lock transaction's outcome — not suppressed as a "foreign" raw transaction would be, and
		// not fired early. The callback's writes are committed before the lock releases (data visible).
		describe("model saved inside the lock transaction resolves its callbacks (owner bookkeeping)", () => {

			beforeEach(() => {
				if (!variables.applies) {
					skip("Transaction-scoped advisory locks: PostgreSQL, MySQL, SQL Server.");
				}
				request.$acLog = [];
				if (StructKeyExists(request, "wheels") && StructKeyExists(request.wheels, "$txnForeignWarned")) {
					StructDelete(request.wheels, "$txnForeignWarned");
				}
				variables.g.model("tag").$registerCallback(type = "afterCommit", methods = "recordAfterCommit");
				variables.g.model("tag").$registerCallback(type = "afterRollback", methods = "recordAfterRollback");
			});

			afterEach(() => {
				variables.g.model("tag").$clearCallbacks(type = "afterCommit");
				variables.g.model("tag").$clearCallbacks(type = "afterRollback");
				variables.g.model("tag").deleteAll(
					where = "name LIKE 'txncb-lock-%'",
					instantiate = false,
					callbacks = false,
					transaction = "commit"
				);
			});

			it("fires afterCommit exactly once and commits the write (visible after release)", () => {
				var name = lockName();
				variables.g.model("author").withAdvisoryLock(name = name, transaction = true, callback = function() {
					variables.g.model("tag").new(name = "txncb-lock-commit").save();
					return true;
				});
				expect(ArrayLen(request.$acLog)).toBe(1, "afterCommit must fire exactly once at the lock transaction's outcome");
				expect(request.$acLog[1]).toBe("commit:txncb-lock-commit");
				// commit-before-release: the write is committed and visible once the lock has released.
				expect(variables.g.model("tag").count(where = "name = 'txncb-lock-commit'")).toBe(1, "the callback's write must be committed when the lock releases");
			});

			it("fires afterRollback exactly once (not afterCommit) when the callback throws, and the write is rolled back", () => {
				var name = lockName();
				var state = {type = ""};
				try {
					variables.g.model("author").withAdvisoryLock(name = name, transaction = true, callback = function() {
						variables.g.model("tag").new(name = "txncb-lock-rb").save();
						Throw(type = "Wheels.SpecCallbackFailure", message = "fail after the save");
					});
				} catch (any e) {
					state.type = e.type;
				}
				expect(state.type).toBe("Wheels.SpecCallbackFailure");
				expect(ArrayLen(request.$acLog)).toBe(1, "exactly one callback must fire");
				expect(request.$acLog[1]).toBe("rollback:txncb-lock-rb", "afterRollback fires, not afterCommit");
				expect(variables.g.model("tag").count(where = "name = 'txncb-lock-rb'")).toBe(0, "the write must be rolled back");
			});

			it("cleans up the owner marker so a later write in the same request still commits", () => {
				var name = lockName();
				variables.g.model("author").withAdvisoryLock(name = name, transaction = true, callback = function() {
					variables.g.model("tag").new(name = "txncb-lock-first").save();
					return true;
				});
				// A later independent write must still commit (the open-transaction marker was cleared).
				variables.g.model("tag").new(name = "txncb-lock-second").save(transaction = "commit");
				expect(variables.g.model("tag").count(where = "name = 'txncb-lock-second'")).toBe(1, "a later write must commit after the lock transaction cleaned up");
			});

			// A release failure AFTER a successful commit must preserve the committed outcome (the write
			// stays committed, afterCommit fires once — not afterRollback) and still surface the release
			// error, rather than letting invokeWithTransaction fire afterRollback on committed data.
			// Session-scoped only: PostgreSQL's release step is a no-op (the xact lock auto-released).
			//
			// The failure is produced WITHOUT a mock and WITHOUT leaking the lock: the callback releases
			// the lock itself on the pinned connection, so the body's own release then runs against an
			// already-released lock and fails naturally (a non-success result), which is the real
			// post-commit release-failure path. The lock is genuinely free afterwards.
			it("surfaces a release failure after commit but keeps the committed outcome and afterCommit", () => {
				if (!ListFindNoCase("MySQLModel,MicrosoftSQLServerModel", variables.adapterName)) {
					skip("A release step that can fail is session-scoped: MySQL, SQL Server.");
				}
				var adapter = variables.g.model("author").$classData().adapter;
				var name = lockName();
				var state = {type = ""};
				try {
					variables.g.model("author").withAdvisoryLock(name = name, transaction = true, callback = function() {
						variables.g.model("tag").new(name = "txncb-lock-relfail").save();
						// Release the lock early on the pinned connection, so the body's own release then
						// fails naturally (RELEASE returns a non-success result) — no mock, no leak.
						adapter.$releaseAdvisoryLockTransactional(name = name);
						return true;
					});
				} catch (any e) {
					state.type = e.type;
				}
				expect(state.type).toBe("Wheels.AdvisoryLockReleaseFailed", "the release failure must surface after the wrapper completes");
				// The committed outcome is preserved despite the release failure.
				expect(variables.g.model("tag").count(where = "name = 'txncb-lock-relfail'")).toBe(1, "the write must stay committed despite the release failure");
				expect(ArrayLen(request.$acLog)).toBe(1, "afterCommit must fire once, not afterRollback");
				expect(request.$acLog[1]).toBe("commit:txncb-lock-relfail", "the committed callback fires afterCommit, not afterRollback");
			});

		});

	}

}
