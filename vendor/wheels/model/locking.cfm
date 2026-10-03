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
	 * @timeout Maximum number of seconds to wait when acquiring the lock (supported by MySQL and SQL Server).
	 * @callback A function or closure to execute while holding the lock. Its return value is returned by this method.
	 */
	public any function withAdvisoryLock(
		required string name,
		numeric timeout = 10,
		required any callback
	) {
		// MySQL and PostgreSQL locks belong to the pooled session that took them, and a session can
		// take its own lock again. Without this named lock a second caller in this application could
		// borrow that idle session, get the lock too, and leave it held (#4197).
		local.state = {entered = false};
		try {
			lock name="#$advisoryLockLocalName(arguments.name)#" type="exclusive" timeout="#arguments.timeout#" {
				local.state.entered = true;
				local.result = $runWithAdvisoryLock(name = arguments.name, timeout = arguments.timeout, callback = arguments.callback);
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
	 * Internal function. Acquires the database lock, runs the callback and releases the lock,
	 * verified free (#4197). A release that fails after the callback threw is logged, so it never
	 * replaces the callback's own error.
	 */
	public any function $runWithAdvisoryLock(required string name, required numeric timeout, required any callback) {
		local.adapter = variables.wheels.class.adapter;
		local.adapter.$acquireAdvisoryLock(name = arguments.name, timeout = arguments.timeout);
		local.state = {callbackFailed = true};
		try {
			local.result = arguments.callback();
			local.state.callbackFailed = false;
		} finally {
			$releaseAdvisoryLockAfterCallback(adapter = local.adapter, name = arguments.name, callbackFailed = local.state.callbackFailed);
		}
		if (StructKeyExists(local, "result")) {
			return local.result;
		}
	}

	/**
	 * Internal function. Releases the lock; a failure is thrown, unless the callback already failed,
	 * in which case it is logged and the callback's error propagates (#4197).
	 */
	public void function $releaseAdvisoryLockAfterCallback(required any adapter, required string name, required boolean callbackFailed) {
		try {
			arguments.adapter.$releaseAdvisoryLockVerified(name = arguments.name);
		} catch (any e) {
			if (!arguments.callbackFailed) {
				rethrow;
			}
			WriteLog(type = "error", file = "wheels", text = "withAdvisoryLock: #e.message#");
		}
	}
</cfscript>
