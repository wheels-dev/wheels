/**
 * Provides advisory lock and pessimistic row locking support for Wheels models.
 *
 * Advisory locks are database-level, application-coordinated locks that don't lock any rows or tables.
 * They are useful for coordinating exclusive access to shared resources (e.g., preventing duplicate
 * background job processing, serializing access to external APIs).
 *
 * Pessimistic row locking (SELECT ... FOR UPDATE) is handled via the QueryBuilder's `forUpdate()` method.
 */
component {

	/**
	 * Executes a callback while holding a database advisory lock.
	 * The lock is automatically released when the callback completes, even if an exception is thrown.
	 *
	 * Advisory locks are database-level locks that don't lock rows or tables. They are useful for
	 * coordinating exclusive access to shared resources across application instances.
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
		local.adapter = variables.wheels.class.adapter;
		local.adapter.$acquireAdvisoryLock(name = arguments.name, timeout = arguments.timeout);
		try {
			local.result = arguments.callback();
		} finally {
			local.adapter.$releaseAdvisoryLock(name = arguments.name);
		}
		if (StructKeyExists(local, "result")) {
			return local.result;
		}
	}

}
