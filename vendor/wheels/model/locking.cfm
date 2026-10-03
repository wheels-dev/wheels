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
	 * @transaction When `true`, acquire the lock, run the callback, and release the lock on one connection pinned by a transaction, so the lock genuinely covers the callback's own queries and (on PostgreSQL / SQL Server) auto-releases at transaction end (#4198). The callback then runs inside a transaction: its writes commit or roll back together, and a `transaction()` inside it nests. Recommended for short critical sections; avoid for long-running callbacks, which would hold their row locks and a pooled connection — and block PostgreSQL VACUUM — for the whole call. Supported on PostgreSQL, MySQL, and SQL Server; `true` on any other database throws. Defaults to `false` (the session-scoped behaviour).
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
	 * callback and releases the lock (#4198). A session-scoped lock (MySQL) is released explicitly in
	 * a finally-style step before the block commits or rolls back; a transaction-scoped lock
	 * (PostgreSQL / SQL Server) auto-releases at transaction end, so its release step is a no-op. A
	 * callback failure rolls the transaction back and rethrows; a release that fails during that
	 * failure is logged, never allowed to replace the callback's own error.
	 */
	public any function $runAdvisoryLockInNewTransaction(required any adapter, required string name, required numeric timeout, required any callback) {
		local.ctx = {hasResult = false, result = ""};
		transaction {
			arguments.adapter.$acquireAdvisoryLockTransactional(name = arguments.name, timeout = arguments.timeout);
			try {
				local.cbResult = arguments.callback();
				if (StructKeyExists(local, "cbResult")) {
					local.ctx.hasResult = true;
					local.ctx.result = local.cbResult;
				}
			} catch (any e) {
				$releaseTransactionalAdvisoryLockQuietly(adapter = arguments.adapter, name = arguments.name);
				transaction action="rollback";
				rethrow;
			}
			$releaseTransactionalAdvisoryLock(adapter = arguments.adapter, name = arguments.name);
		}
		if (local.ctx.hasResult) {
			return local.ctx.result;
		}
	}

	/**
	 * Internal function. Acquires the lock on the connection of an already-open transaction and runs
	 * the callback without opening a second transaction (#4198). A transaction-scoped lock
	 * (PostgreSQL / SQL Server) is NOT released here: it belongs to the OUTER transaction and is held
	 * until that owner commits or rolls back. A session-scoped lock (MySQL) is released at call end,
	 * since the outer transaction keeps running. A callback failure rethrows; the session-scoped lock
	 * is released first (logged on failure) so it is not leaked onto the still-open outer transaction.
	 */
	public any function $runAdvisoryLockInOpenTransaction(required any adapter, required string name, required numeric timeout, required any callback) {
		arguments.adapter.$acquireAdvisoryLockTransactional(name = arguments.name, timeout = arguments.timeout);
		local.ctx = {hasResult = false, result = ""};
		try {
			local.cbResult = arguments.callback();
			if (StructKeyExists(local, "cbResult")) {
				local.ctx.hasResult = true;
				local.ctx.result = local.cbResult;
			}
		} catch (any e) {
			$releaseTransactionalAdvisoryLockQuietly(adapter = arguments.adapter, name = arguments.name);
			rethrow;
		}
		$releaseTransactionalAdvisoryLock(adapter = arguments.adapter, name = arguments.name);
		if (local.ctx.hasResult) {
			return local.ctx.result;
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
