<cfscript>

	/**
	 * Executes a callback while holding a database advisory lock.
	 * The lock is automatically released when the callback completes, even if an exception is thrown.
	 *
	 * Advisory locks are database-level locks that don't lock rows or tables. They are useful for
	 * coordinating exclusive access to shared resources across application instances.
	 *
	 * Callers in one application wait on an application-server lock first, so only one of them
	 * holds the database lock at a time. The release is verified: if it ran on a pooled database
	 * session other than the one holding the lock, it is retried for up to 5 seconds, then
	 * `Wheels.AdvisoryLockReleaseFailed` is thrown naming the lock.
	 *
	 * Support varies by database:
	 * - PostgreSQL: Full support via pg_advisory_lock/pg_advisory_unlock
	 * - MySQL: Full support via GET_LOCK/RELEASE_LOCK
	 * - SQL Server: Full support via sp_getapplock/sp_releaseapplock, owned by the database session, so
 *   no transaction is needed
	 * - SQLite: No-op (file-level locking only)
	 * - CockroachDB: Not supported (throws error, use forUpdate() instead)
	 * - H2: Not supported (throws error)
	 * - Oracle: Not supported by default (requires DBMS_LOCK package setup)
	 *
	 * [section: Model Class]
	 * [category: Locking Functions]
	 *
	 * @name A unique name for the lock. Different callers using the same name will contend for the same lock.
	 * @timeout Maximum number of seconds to wait for the lock in all: first for another caller in this application, then for the database lock with the time that is left (at least one second), so the wait is about `timeout` at most.
	 * @callback A function or closure to execute while holding the lock. Its return value is returned by this method.
	 * @transaction When `true`, acquire the lock, run the callback, and release the lock on one connection pinned by a transaction, so the lock genuinely covers the callback's own queries (#4198). On PostgreSQL the lock is transaction-scoped and auto-releases when the transaction ends; on MySQL and SQL Server it is a session lock released before the transaction closes. The callback then runs inside a transaction: its writes commit or roll back together, and a `transaction()` inside it nests. Recommended for short critical sections; avoid for long-running callbacks, which would hold their row locks and a pooled connection — and block PostgreSQL VACUUM — for the whole call. Supported on PostgreSQL, MySQL, and SQL Server; `true` on any other database throws. Defaults to `false` (the session-scoped behaviour).
	 *
	 * The lock is always released, including when the callback ends the request with `abort`, `redirectTo()` or `cflocation`: the release runs in a `finally`, which executes on those paths (measured on Lucee, Adobe and BoxLang). The one case not covered is a request killed without running its `finally` — the engine's request-timeout cutting the request off, or a JVM crash — after which a session-scoped lock (MySQL / SQL Server) frees only when its pooled connection is closed; a PostgreSQL transaction-scoped lock still frees when that connection's transaction is rolled back on return to the pool.
	 */
	public any function withAdvisoryLock(
		required string name,
		numeric timeout = 10,
		required any callback,
		boolean transaction = false
	) {
		// MySQL and PostgreSQL locks belong to the pooled session that took them, and a session can
		// take its own lock again. Without this named lock a second caller in this application could
		// borrow that idle session, get the lock too, and leave it held (#4197). The named lock is
		// kept on the transaction path too: it serialises in-app waiters so they don't each pin a
		// pooled connection while blocked in the database acquire loop (#4198).
		local.state = {entered = false};
		local.startedAt = GetTickCount();
		try {
			lock name="#$advisoryLockLocalName(arguments.name)#" type="exclusive" timeout="#arguments.timeout#" {
				local.state.entered = true;
				local.dbTimeout = $advisoryLockSecondsLeft(timeout = arguments.timeout, startedAt = local.startedAt);
				if (arguments.transaction) {
					local.result = $runWithAdvisoryLockTransactional(
						name = arguments.name,
						timeout = local.dbTimeout,
						callback = arguments.callback
					);
				} else {
					local.result = $runWithAdvisoryLock(
						name = arguments.name,
						timeout = local.dbTimeout,
						callback = arguments.callback
					);
				}
			}
		} catch (any e) {
			if (!local.state.entered) {
				Throw(
					type = "Wheels.AdvisoryLockTimeout",
					message = "Could not acquire advisory lock '#arguments.name#' within #arguments.timeout# seconds.",
					extendedInfo = "Another caller in this application holds the lock."
				);
			}
			rethrow;
		}
		if (StructKeyExists(local, "result")) {
			return local.result;
		}
	}

	/**
	 * Internal function. The application-server lock name that serialises withAdvisoryLock() callers
	 * for one database lock (#4197). It is keyed on the datasource the lock is taken on, the active
	 * tenant's for a tenant model (#4223): another tenant's datasource is another connection pool,
	 * which can't borrow the session holding this lock, so its callers needn't wait here.
	 */
	public string function $advisoryLockLocalName(required string name) {
		return "wheels_advisory_" & Hash(variables.wheels.class.adapter.$effectiveDataSource() & "|" & arguments.name);
	}

	/**
	 * Internal function. The whole seconds of `timeout` left since `startedAt` (a GetTickCount()
	 * value), at least 1, for the database wait after the wait for a caller in this application.
	 */
	public numeric function $advisoryLockSecondsLeft(required numeric timeout, required numeric startedAt) {
		return Max(1, Ceiling(arguments.timeout - (GetTickCount() - arguments.startedAt) / 1000));
	}

	/**
	 * Internal function. Acquires the database lock, runs the callback and releases the lock,
	 * verified free (#4197). A release that fails after the callback threw is logged, so it never
	 * replaces the callback's own error.
	 */
	public any function $runWithAdvisoryLock(required string name, required numeric timeout, required any callback) {
		local.adapter = variables.wheels.class.adapter;
		// The session recorded at acquire, so the release check looks at our holder only (#4197).
		local.holder = local.adapter.$acquireAdvisoryLockSession(name = arguments.name, timeout = arguments.timeout);
		local.state = {callbackFailed = true};
		try {
			local.result = arguments.callback();
			local.state.callbackFailed = false;
		} finally {
			$releaseAdvisoryLockAfterCallback(
				adapter = local.adapter,
				name = arguments.name,
				holder = local.holder,
				callbackFailed = local.state.callbackFailed
			);
		}
		if (StructKeyExists(local, "result")) {
			return local.result;
		}
	}

	/**
	 * Internal function. Releases the lock; a failure is thrown, unless the callback already failed,
	 * in which case it is logged and the callback's error propagates (#4197).
	 */
	public void function $releaseAdvisoryLockAfterCallback(
		required any adapter,
		required string name,
		required boolean callbackFailed,
		string holder = ""
	) {
		try {
			arguments.adapter.$releaseAdvisoryLockVerified(name = arguments.name, holder = arguments.holder);
		} catch (any e) {
			if (!arguments.callbackFailed) {
				rethrow;
			}
			WriteLog(type = "error", file = "wheels", text = "withAdvisoryLock: #e.message#");
		}
	}

	/**
	 * Internal function. The transaction-scoped path for withAdvisoryLock(transaction = true) (#4198).
	 * Pins acquire + callback + release to one connection by running them in a transaction, so the
	 * lock genuinely covers the callback's own queries. An unsupported database throws rather than
	 * falling back silently: the opt-in asks for a guarantee this adapter can't give.
	 *
	 * The new-transaction case runs through Wheels' own `invokeWithTransaction`, so the lock
	 * transaction is a fully Wheels-OWNED transaction: a model save inside the callback joins it (the
	 * open marker), its afterCommit/afterRollback callbacks queue and resolve once at the lock
	 * transaction's outcome, and the Adobe nested-isolation retry applies — none of which a raw
	 * `transaction {}` would get (a raw block is seen as foreign and its callbacks are suppressed).
	 *
	 * When a transaction is already open on this connection the lock joins it. A transaction-scoped
	 * lock (PostgreSQL) is held until that OUTER transaction ends — supported. A session-scoped lock
	 * (MySQL / SQL Server) would have to release at call end, before the outer transaction commits,
	 * exposing pre-commit state to the next holder (and deferring to the outer afterCommit releases on
	 * a pooled connection, not the holder) — so it is unsupported inside an existing transaction and
	 * throws. (A raw outer transaction is undetectable on RustCFML, which supports none of these
	 * adapters anyway.)
	 */
	public any function $runWithAdvisoryLockTransactional(required string name, required numeric timeout, required any callback) {
		local.adapter = variables.wheels.class.adapter;
		if (!local.adapter.$supportsTransactionalAdvisoryLock()) {
			Throw(
				type = "Wheels.AdvisoryLockNotSupported",
				message = "Transaction-scoped advisory locks (transaction = true) are not supported for this database.",
				extendedInfo = "Call withAdvisoryLock() without transaction = true to use the default behaviour, or use PostgreSQL, MySQL, or SQL Server."
			);
		}
		if ($transactionIsOpen($hashedConnectionArgs())) {
			if (local.adapter.$transactionalAdvisoryLockIsSessionScoped()) {
				Throw(
					type = "Wheels.AdvisoryLockNotSupported",
					message = "withAdvisoryLock(transaction = true) is not supported inside an existing transaction on this database.",
					extendedInfo = "A session-scoped advisory lock (MySQL, SQL Server) would release before the outer transaction commits, exposing pre-commit state. Take the lock outside the transaction, or use transaction = false. PostgreSQL supports this (its lock is held until the outer transaction ends)."
				);
			}
			return $runAdvisoryLockInOpenTransaction(
				adapter = local.adapter,
				name = arguments.name,
				timeout = arguments.timeout,
				callback = arguments.callback
			);
		}
		// Run the lock body as a Wheels-owned transaction. The body must return a boolean (the
		// transaction outcome is driven by throw / no-throw, not the callback's own return), so the
		// callback's actual result — and a release failure to surface — are carried back through the
		// shared `state` struct.
		local.state = {hasResult = false, result = ""};
		invokeWithTransaction(
			method = "$advisoryLockTransactionBody",
			name = arguments.name,
			timeout = arguments.timeout,
			callback = arguments.callback,
			state = local.state
		);
		// A release that failed AFTER a successful commit is surfaced here — once the wrapper has
		// committed, fired afterCommit, and cleared ownership — so the committed outcome is preserved
		// and the lock failure is still reported loudly (rev1-r2 / orch1).
		if (StructKeyExists(local.state, "releaseError")) {
			Throw(
				type = "Wheels.AdvisoryLockReleaseFailed",
				message = "Advisory lock '#arguments.name#' could not be released after its transaction committed.",
				extendedInfo = local.state.releaseError.message
			);
		}
		if (local.state.hasResult) {
			return local.state.result;
		}
	}

	/**
	 * Internal function. The body of the Wheels-owned lock transaction, run by invokeWithTransaction
	 * (#4198). Acquires the lock on the pinned connection, runs the callback, commits BEFORE the
	 * release so the committed writes are visible to the next holder (rev1-r1), then releases a
	 * session-scoped lock on the same pinned connection in a `finally` — which also runs on a callback
	 * that aborts / cflocations. PostgreSQL's transaction-scoped lock auto-releases at that commit, so
	 * its release step is a no-op.
	 *
	 * Returns `true` unconditionally: invokeWithTransaction rolls back on a `false` return, but here a
	 * `false` is a legitimate callback result, not a failure — a genuine failure (callback or commit)
	 * throws, and invokeWithTransaction then rolls back and fires afterRollback. The callback's real
	 * result is written into the shared `state` struct in the try body only (nothing written in a
	 * catch — BoxLang invariant 11). `committed` flips only after a clean commit.
	 *
	 * A release failure must never reach invokeWithTransaction's rollback handler (which would fire
	 * afterRollback on already-committed data and suppress afterCommit). So the release runs in its own
	 * try/catch inside the finally: after a successful commit the failure is captured and handed back
	 * through `state.releaseError` for the dispatcher to surface AFTER the wrapper has fired afterCommit
	 * and cleared ownership; on a failed callback or a failed commit the release failure is only logged,
	 * so the original (callback / commit) error stays the one that propagates.
	 */
	public boolean function $advisoryLockTransactionBody(required string name, required numeric timeout, required any callback, required struct state) {
		local.adapter = variables.wheels.class.adapter;
		local.committed = {flag = false};
		var release = {error = "", done = false};
		var threw = {flag = false};
		var cb = {done = false};
		local.adapter.$acquireAdvisoryLockTransactional(name = arguments.name, timeout = arguments.timeout);
		try {
			try {
				local.cbResult = arguments.callback();
				if (StructKeyExists(local, "cbResult")) {
					arguments.state.hasResult = true;
					arguments.state.result = local.cbResult;
				}
				cb.done = true;
			} finally {
				// This inner finally holds the lock RELEASE and contains NO transaction-action statement,
				// so BoxLang runs it even when the callback ends the request with `abort`: a `transaction
				// action="…"` inside a finally is skipped by BoxLang when an abort leaves the surrounding
				// cftransaction (#4219 — Lucee/Adobe run it either way). On an abnormal exit (abort or a
				// throw -> cb.done stays false) the lock is released HERE; on the normal path cb.done is
				// true and the commit-then-release below runs instead, preserving commit-before-release so
				// the next holder reads committed state. Unscoped struct writes persist past the catch on
				// BoxLang (invariant 11).
				if (!cb.done) {
					try {
						$releaseTransactionalAdvisoryLock(adapter = local.adapter, name = arguments.name);
					} catch (any releaseErr) {
						WriteLog(type = "error", file = "wheels", text = "withAdvisoryLock(transaction=true): release on the abnormal-exit path also failed: " & releaseErr.message);
					}
					release.done = true;
				}
			}
			// Normal path only (abort/throw skipped past this via the inner finally). Commit on the pinned
			// connection BEFORE the release, so the next holder reads committed state. `committed` flips
			// only AFTER a clean commit, so a failing commit takes the catch/finally path below.
			transaction action="commit";
			local.committed.flag = true;
			try {
				$releaseTransactionalAdvisoryLock(adapter = local.adapter, name = arguments.name);
			} catch (any releaseErr2) {
				release.error = releaseErr2;
			}
			release.done = true;
		} catch (any e) {
			// A caught throw (callback or commit). On a throw, invokeWithTransaction's own catch rolls the
			// transaction back after this method returns, so the finally does NOT roll back. Unscoped
			// struct write persists past the catch on BoxLang (invariant 11). The exception still
			// propagates to invokeWithTransaction.
			threw.flag = true;
			rethrow;
		} finally {
			// Roll back ONLY on the ABORT path — not committed, and not a caught throw. An aborting
			// callback is never caught, so invokeWithTransaction's catch never runs and the engine would
			// otherwise decide the open transaction's fate at block exit. This rollback is a
			// transaction-action, and BoxLang skips a finally that contains one when an abort leaves the
			// cftransaction; the LOCK release above sits in a separate finally with no transaction-action,
			// so it still runs on every engine on abort. Lucee/Adobe run this finally normally.
			if (!local.committed.flag && !threw.flag) {
				try {
					transaction action="rollback";
				} catch (any rollbackErr) {
					WriteLog(type = "error", file = "wheels", text = "withAdvisoryLock(transaction=true): rollback on the abort path failed: " & rollbackErr.message);
				}
			}
			// Safety net for a commit failure: a throw AFTER the inner finally leaves cb.done true (so the
			// inner finally did not release) and committed false (so the commit threw). A throw runs this
			// finally on every engine, so release here if it has not happened yet.
			if (!release.done) {
				try {
					$releaseTransactionalAdvisoryLock(adapter = local.adapter, name = arguments.name);
				} catch (any releaseErr3) {
					WriteLog(type = "error", file = "wheels", text = "withAdvisoryLock(transaction=true): release after a failed commit also failed: " & releaseErr3.message);
				}
				release.done = true;
			}
		}
		// Reached only on the committed path (a callback / commit failure propagates past here). Hand a
		// release failure to the dispatcher to surface AFTER invokeWithTransaction has fired afterCommit.
		if (!IsSimpleValue(release.error)) {
			arguments.state.releaseError = release.error;
		}
		return true;
	}

	/**
	 * Internal function. Acquires the lock on the connection of an already-open transaction and runs
	 * the callback without opening a second transaction (#4198). The release is in a `finally`, so a
	 * session-scoped lock (MySQL / SQL Server) is released at call end on every exit — normal return, a
	 * thrown error, or an abort / cflocation. A transaction-scoped lock (PostgreSQL) is NOT released
	 * here (the release step is a no-op for it): it belongs to the OUTER transaction and is held until
	 * that owner commits or rolls back. No catch is needed — an exception propagates to the outer
	 * owner, which manages its own rollback. The `failed` flag follows the same try-body-only rule as
	 * $runAdvisoryLockInNewTransaction so a release is loud only on success.
	 */
	public any function $runAdvisoryLockInOpenTransaction(required any adapter, required string name, required numeric timeout, required any callback) {
		arguments.adapter.$acquireAdvisoryLockTransactional(name = arguments.name, timeout = arguments.timeout);
		var state = {failed = true, hasResult = false, result = ""};
		try {
			local.cbResult = arguments.callback();
			state.failed = false;
			if (StructKeyExists(local, "cbResult")) {
				state.hasResult = true;
				state.result = local.cbResult;
			}
		} finally {
			if (state.failed) {
				$releaseTransactionalAdvisoryLockQuietly(adapter = arguments.adapter, name = arguments.name);
			} else {
				$releaseTransactionalAdvisoryLock(adapter = arguments.adapter, name = arguments.name);
			}
		}
		if (state.hasResult) {
			return state.result;
		}
	}

	/**
	 * Internal function. Releases a transaction-scoped advisory lock only when the adapter's lock is
	 * actually session-scoped (MySQL / SQL Server); a transaction-scoped lock (PostgreSQL) auto-releases
	 * at transaction end, so this is a no-op for it (#4198).
	 */
	public void function $releaseTransactionalAdvisoryLock(required any adapter, required string name) {
		if (arguments.adapter.$transactionalAdvisoryLockIsSessionScoped()) {
			arguments.adapter.$releaseAdvisoryLockTransactional(name = arguments.name);
		}
	}

	/**
	 * Internal function. Releases the lock as $releaseTransactionalAdvisoryLock() does, but after the
	 * callback has already failed: a release error is logged and swallowed so the callback's own error
	 * is the one that propagates (#4198).
	 */
	public void function $releaseTransactionalAdvisoryLockQuietly(required any adapter, required string name) {
		try {
			$releaseTransactionalAdvisoryLock(adapter = arguments.adapter, name = arguments.name);
		} catch (any e) {
			WriteLog(type = "error", file = "wheels", text = "withAdvisoryLock(transaction=true): #e.message#");
		}
	}
</cfscript>
