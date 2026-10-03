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
	 * - SQL Server: Full support via sp_getapplock/sp_releaseapplock
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
	 * for one database lock (#4197).
	 */
	public string function $advisoryLockLocalName(required string name) {
		return "wheels_advisory_" & Hash(variables.wheels.class.dataSource & "|" & arguments.name);
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
	 * falling back silently: the opt-in asks for a guarantee this adapter can't give. When a
	 * transaction is already open on this connection the lock joins it (no second transaction), so a
	 * transaction-scoped lock is held until that OUTER transaction ends.
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
			return $runAdvisoryLockInOpenTransaction(
				adapter = local.adapter,
				name = arguments.name,
				timeout = arguments.timeout,
				callback = arguments.callback
			);
		}
		return $runAdvisoryLockInNewTransaction(
			adapter = local.adapter,
			name = arguments.name,
			timeout = arguments.timeout,
			callback = arguments.callback
		);
	}

	/**
	 * Internal function. Opens a transaction, acquires the lock on its pinned connection, runs the
	 * callback and releases the lock in a `finally` INSIDE the transaction block, so the release runs
	 * before the transaction closes on every exit — normal return, a thrown error, AND a callback that
	 * ends the request via abort / cflocation (a `finally` runs on abort and cflocation on Lucee,
	 * Adobe and BoxLang — measured). A session-scoped lock (MySQL / SQL Server) is released there; a
	 * transaction-scoped lock (PostgreSQL) auto-releases at transaction end, so its release step is a
	 * no-op (#4198).
	 *
	 * The `failed` flag defaults to true and is set false only in the try body after the callback
	 * returns, so nothing is written in a catch (a catch-scope write would not persist on BoxLang —
	 * invariant 11). A release is loud only on success; on a callback failure or abort it is quiet, so
	 * it never masks the callback's own error and never throws during an abort.
	 */
	public any function $runAdvisoryLockInNewTransaction(required any adapter, required string name, required numeric timeout, required any callback) {
		var state = {failed = true, hasResult = false, result = ""};
		transaction {
			arguments.adapter.$acquireAdvisoryLockTransactional(name = arguments.name, timeout = arguments.timeout);
			try {
				local.cbResult = arguments.callback();
				state.failed = false;
				if (StructKeyExists(local, "cbResult")) {
					state.hasResult = true;
					state.result = local.cbResult;
				}
			} catch (any e) {
				transaction action="rollback";
				rethrow;
			} finally {
				if (state.failed) {
					$releaseTransactionalAdvisoryLockQuietly(adapter = arguments.adapter, name = arguments.name);
				} else {
					$releaseTransactionalAdvisoryLock(adapter = arguments.adapter, name = arguments.name);
				}
			}
		}
		if (state.hasResult) {
			return state.result;
		}
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
	 * actually session-scoped (MySQL); transaction-scoped locks (PostgreSQL / SQL Server) auto-release
	 * at transaction end, so this is a no-op for them (#4198).
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
