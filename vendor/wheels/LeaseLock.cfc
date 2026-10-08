/**
 * A named, cross-process lease lock backed by one database table: one row per held lock,
 * (lockname PK, lockowner, lockhost, acquiredat, expiresat), with the times as epoch
 * milliseconds so every database compares them as plain numbers.
 *
 * A caller takes a lock by inserting its row, or by taking over a row whose lease has expired;
 * it extends the lease while it works, and deletes the row when done. Every change after the
 * insert is fenced on the owner id, so an instance whose lease was taken over can neither
 * extend nor release the new holder's lock.
 *
 * The statement builders are used by the Migrator, which runs them through its own query
 * function (its datasource credentials and test seams). The execution methods run them
 * against `datasource` and are used by background jobs (`this.exclusive`, `concurrencyKey`).
 *
 * Lease times come from the app host's clock, so the hosts sharing a lock table need
 * synchronised clocks (NTP): skew between two hosts shortens or lengthens a lease by as much.
 */
component {

	/**
	 * @table The lock table's name.
	 * @datasource The datasource the execution methods use.
	 */
	public any function init(required string table, string datasource = "") {
		variables.table = arguments.table;
		variables.datasource = arguments.datasource;
		return this;
	}

	/**
	 * The DDL for the lock table, portable across the supported databases.
	 */
	public string function createTableSql() {
		return "CREATE TABLE #variables.table# (lockname VARCHAR(100) NOT NULL PRIMARY KEY, lockowner VARCHAR(64) NOT NULL, lockhost VARCHAR(255), acquiredat DECIMAL(15,0) NOT NULL, expiresat DECIMAL(15,0) NOT NULL)";
	}

	/**
	 * Reads the owner of a lock.
	 */
	public struct function ownerStatement(required string name) {
		return {
			sql = "SELECT lockowner FROM #variables.table# WHERE lockname = :lockName",
			params = {lockName = text(arguments.name)}
		};
	}

	/**
	 * Reads a lock's whole row.
	 */
	public struct function readStatement(required string name) {
		return {
			sql = "SELECT lockowner, lockhost, acquiredat, expiresat FROM #variables.table# WHERE lockname = :lockName",
			params = {lockName = text(arguments.name)}
		};
	}

	/**
	 * Takes a free lock: fails on the primary key when another owner inserted it first.
	 */
	public struct function insertStatement(
		required string name,
		required string owner,
		required string host,
		required numeric acquiredAt,
		required numeric expiresAt
	) {
		return {
			sql = "INSERT INTO #variables.table# (lockname, lockowner, lockhost, acquiredat, expiresat) VALUES (:lockName, :owner, :host, :acquiredAt, :expiresAt)",
			params = {
				lockName = text(arguments.name),
				owner = text(arguments.owner),
				host = text(arguments.host),
				acquiredAt = ms(arguments.acquiredAt),
				expiresAt = ms(arguments.expiresAt)
			}
		};
	}

	/**
	 * Takes over a lock whose lease expired before `now`. The WHERE makes it atomic; reading the
	 * owner back tells whether this caller won.
	 */
	public struct function takeOverStatement(
		required string name,
		required string owner,
		required string host,
		required numeric now,
		required numeric expiresAt
	) {
		return {
			sql = "UPDATE #variables.table# SET lockowner = :owner, lockhost = :host, acquiredat = :now, expiresat = :expiresAt WHERE lockname = :lockName AND expiresat < :now",
			params = {
				owner = text(arguments.owner),
				host = text(arguments.host),
				now = ms(arguments.now),
				expiresAt = ms(arguments.expiresAt),
				lockName = text(arguments.name)
			}
		};
	}

	/**
	 * Extends the lease, only while `owner` still holds the lock.
	 */
	public struct function renewStatement(required string name, required string owner, required numeric expiresAt) {
		return {
			sql = "UPDATE #variables.table# SET expiresat = :expiresAt WHERE lockname = :lockName AND lockowner = :owner",
			params = {
				expiresAt = ms(arguments.expiresAt),
				lockName = text(arguments.name),
				owner = text(arguments.owner)
			}
		};
	}

	/**
	 * Deletes the lock while `owner` holds it; with `expiredBefore`, only when its lease expired
	 * before that time.
	 */
	public struct function releaseStatement(required string name, required string owner, any expiredBefore = "") {
		local.rv = {
			sql = "DELETE FROM #variables.table# WHERE lockname = :lockName AND lockowner = :owner",
			params = {lockName = text(arguments.name), owner = text(arguments.owner)}
		};
		if (IsNumeric(arguments.expiredBefore)) {
			local.rv.sql &= " AND expiresat < :now";
			local.rv.params.now = ms(arguments.expiredBefore);
		}
		return local.rv;
	}

	/**
	 * An epoch-milliseconds value as a typed query parameter: an untyped one binds as text, which
	 * PostgreSQL won't compare with the numeric columns. Not through Int(), which Lucee truncates
	 * to 32 bits.
	 */
	public struct function ms(required numeric value) {
		return {value = arguments.value, cfsqltype = "cf_sql_bigint"};
	}

	/**
	 * A text value as a typed query parameter.
	 */
	public struct function text(required string value) {
		return {value = arguments.value, cfsqltype = "cf_sql_varchar"};
	}

	/**
	 * The current time in epoch milliseconds, from the JVM's wall clock. GetTickCount() is only a
	 * fallback for an engine without java.lang.System.
	 */
	public numeric function nowMs() {
		try {
			return CreateObject("java", "java.lang.System").currentTimeMillis();
		} catch (any e) {
			return GetTickCount();
		}
	}

	/**
	 * Runs a statement against `datasource`. Returns `rows` (a query, empty for DML) and `count`,
	 * the rows a DML statement changed, read through the result option: Adobe 2023 returns
	 * nothing at all from QueryExecute for an UPDATE or DELETE.
	 */
	public struct function executeStatement(required struct statement) {
		local.rows = QueryExecute(
			arguments.statement.sql,
			arguments.statement.params,
			{datasource = variables.datasource, result = "local.info"}
		);
		return {
			rows = (StructKeyExists(local, "rows") && IsQuery(local.rows)) ? local.rows : QueryNew(""),
			count = StructKeyExists(local, "info") ? Val(local.info.recordCount ?: 0) : 0
		};
	}

	/**
	 * The owner id holding the lock, or "" when it is free.
	 */
	public string function ownerOf(required string name) {
		local.rows = executeStatement(ownerStatement(arguments.name)).rows;
		return local.rows.recordCount ? local.rows.lockowner : "";
	}

	/**
	 * The lock's row: `held`, `owner`, `host`, `acquiredAt` and `expiresAt` (epoch ms).
	 */
	public struct function read(required string name) {
		local.rows = executeStatement(readStatement(arguments.name)).rows;
		if (!local.rows.recordCount) {
			return {held = false, owner = "", host = "", acquiredAt = 0, expiresAt = 0};
		}
		return {
			held = true,
			owner = local.rows.lockowner,
			host = local.rows.lockhost,
			acquiredAt = Val(local.rows.acquiredat),
			expiresAt = Val(local.rows.expiresat)
		};
	}

	/**
	 * One attempt to take the lock for `owner` until `expiresAt`: insert its row, or take it over
	 * when the lease expired. True when `owner` now holds it.
	 */
	public boolean function tryAcquire(
		required string name,
		required string owner,
		required string host,
		required numeric now,
		required numeric expiresAt
	) {
		// Insert only when no row exists, so the duplicate-key path (which aborts an enclosing
		// PostgreSQL transaction) is left to two callers inserting at the same moment.
		if (Len(ownerOf(arguments.name))) {
			return $takeOver(argumentCollection = arguments);
		}
		try {
			executeStatement(
				insertStatement(
					name = arguments.name,
					owner = arguments.owner,
					host = arguments.host,
					acquiredAt = arguments.now,
					expiresAt = arguments.expiresAt
				)
			);
			return true;
		} catch (any e) {
			// No row even now: the INSERT failed for another reason (a missing table, a lost
			// connection), so report it.
			if (!Len(ownerOf(arguments.name))) {
				rethrow;
			}
		}
		// Another caller inserted it first: take it over only if its lease has expired.
		return $takeOver(argumentCollection = arguments);
	}

	/**
	 * Extends the lease to `expiresAt`. True while `owner` still holds the lock; false once it
	 * expired and another owner took it over (or it was removed).
	 */
	public boolean function renew(required string name, required string owner, required numeric expiresAt) {
		return executeStatement(renewStatement(name = arguments.name, owner = arguments.owner, expiresAt = arguments.expiresAt)).count > 0;
	}

	/**
	 * Deletes the lock while `owner` holds it. True when it did; false when the lease had already
	 * been taken over or removed.
	 */
	public boolean function release(required string name, required string owner) {
		return executeStatement(releaseStatement(name = arguments.name, owner = arguments.owner)).count > 0;
	}

	/**
	 * Internal: the owner-fenced takeover of an expired lease, then the read-back.
	 */
	public boolean function $takeOver(
		required string name,
		required string owner,
		required string host,
		required numeric now,
		required numeric expiresAt
	) {
		executeStatement(
			takeOverStatement(
				name = arguments.name,
				owner = arguments.owner,
				host = arguments.host,
				now = arguments.now,
				expiresAt = arguments.expiresAt
			)
		);
		return ownerOf(arguments.name) == arguments.owner;
	}

}
