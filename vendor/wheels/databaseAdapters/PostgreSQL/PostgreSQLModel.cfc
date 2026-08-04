component extends="wheels.databaseAdapters.Base" output=false {

	/**
	 * Map database types to the ones used in CFML.
	 * Using oid cols should probably be avoided, included here for completeness.
	 * PostgreSQL has deprecated the money type, included here for completeness.
	 */
	public string function $getType(required string type, string scale, string details) {
		switch (arguments.type) {
			case "bigint":
			case "int8":
			case "bigserial":
			case "serial8":
				local.rv = "cf_sql_bigint";
				break;
			case "bool":
			case "boolean":
			case "bit":
			case "varbit":
				local.rv = "cf_sql_bit";
				break;
			case "bytea":
				local.rv = "cf_sql_binary";
				break;
			case "char":
			case "character":
				local.rv = "cf_sql_char";
				break;
			case "date":
			case "datetime":
			case "timestamp":
			case "timestamptz":
				local.rv = "cf_sql_timestamp";
				break;
			case "decimal":
			case "double":
			case "precision":
			case "float":
			case "float4":
			case "float8":
				local.rv = "cf_sql_decimal";
				break;
			case "integer":
			case "int":
			case "int4":
			case "serial":
			case "oid":
				local.rv = "cf_sql_integer";
				break;
			case "numeric":
			case "smallmoney":
			case "money":
				local.rv = "cf_sql_numeric";
				break;
			case "real":
				local.rv = "cf_sql_real";
				break;
			case "smallint":
			case "smallserial":
			case "int2":
				local.rv = "cf_sql_smallint";
				break;
			case "json":
			case "jsonb":
			case "text":
			case "cidr":
			case "inet":
			case "xml":
				local.rv = "cf_sql_longvarchar";
				break;
			case "time":
			case "timetz":
				local.rv = "cf_sql_time";
				break;
			case "varchar":
			case "varying":
			case "bpchar":
			case "uuid":
			case "macaddr":
			case "macaddr8":
				local.rv = "cf_sql_varchar";
				break;
			case "point":
			case "line":
			case "lseg":
			case "box":
			case "path":
			case "polygon":
			case "circle":
			case "geography":
				local.rv = "cf_sql_other";
				break;
			default:
				// Without this branch `local.rv` is never assigned and the return throws
				// `key [RV] doesn't exist` — an error that names nothing useful and reads
				// like a framework bug. The classic source was catalog bleed: a table whose
				// name collides with an `information_schema` view picked up phantom columns
				// typed `"information_schema"."sql_identifier"` (issue #3349, fixed in
				// `$getColumnInfo()` below). Anything reaching here now is a genuinely
				// unmapped PostgreSQL type, so say so.
				Throw(
					type = "Wheels.UnknownColumnType",
					message = "The PostgreSQL column type `#arguments.type#` is not mapped to a CFML SQL type.",
					extendedInfo = "Add a case for `#arguments.type#` to `$getType()` in `vendor/wheels/databaseAdapters/PostgreSQL/PostgreSQLModel.cfc`. If the type name looks schema-qualified (e.g. `""information_schema"".""sql_identifier""`), the column is not yours — it came from a catalog view sharing your table's name."
				);
		}
		return local.rv;
	}

	/**
	 * Override Base adapter's function.
	 *
	 * `cfdbinfo(type="columns")` applies no schema restriction, so JDBC matches the table name
	 * across every schema on the connection. PostgreSQL and YugabyteDB both ship ANSI
	 * `information_schema` views named `sequences`, `tables`, `columns`, `views`, `triggers`
	 * and more, so an application table named `sequences` collected a second batch of columns
	 * from `information_schema.sequences` — typed `"information_schema"."sql_identifier"`,
	 * which nothing in `$getType()` matched (issue #3349). Via `CockroachDBModel`, the
	 * `crdb_internal` and `pg_extension` view names collide the same way.
	 *
	 * Filtering here rather than in `$getColumns()` keeps the work behind the
	 * `cacheDatabaseSchema` memo that `$getColumns()` wraps around this call — once per
	 * datasource+table per application lifetime instead of on every read.
	 */
	public query function $getColumnInfo(
		required string table,
		required string datasource,
		required string username,
		required string password
	) {
		return $excludeSystemSchemaRows(columns = super.$getColumnInfo(argumentCollection = arguments));
	}

	/**
	 * Call functions to make adapter specific changes to arguments before executing query.
	 */
	public struct function $querySetup(
		required array sql,
		numeric limit = 0,
		numeric offset = 0,
		required boolean parameterize,
		string $primaryKey = ""
	) {
		$convertMaxRowsToLimit(args = arguments);
		$removeColumnAliasesInOrderClause(args = arguments);
		$addColumnsToSelectAndGroupBy(args = arguments);
		$moveAggregateToHaving(args = arguments);
		return $performQuery(argumentCollection = arguments);
	}

	/**
	 * Override Base adapter's function.
	 */
	public string function $generatedKey() {
		return "lastId";
	}

	/**
	 * Override Base adapter's $identitySelect hook.
	 * Lucee/ACF doesn't support PostgreSQL natively when it comes to returning
	 * the primary key value of the last inserted record so we have to do it
	 * manually by using the sequence. (The bulk-path guard that previously
	 * lived here — skipping the lookup when no primary-key hint is passed —
	 * is enforced for all adapters by the Base $identitySelect template.)
	 */
	public any function $lastIdLookup(
		required struct queryAttributes,
		required struct result,
		required string primaryKey,
		any returningIdentity = "",
		required string insertSql
	) {
		local.tbl = SpanExcluding(Right(arguments.insertSql, Len(arguments.insertSql) - 12), " ");
		// Strip identifier quotes that may have been added by $quoteIdentifier
		local.tbl = ReReplace(local.tbl, '^"|"$', "", "all");
		local.query = $query(
			sql = "SELECT currval(pg_get_serial_sequence('#local.tbl#', '#ListFirst(arguments.primaryKey)#')) AS lastId",
			argumentCollection = arguments.queryAttributes
		);
		return local.query.lastId;
	}

	/**
	 * Override Base adapter's function.
	 */
	public string function $randomOrder() {
		return "random()";
	}

	/**
	 * Acquire a PostgreSQL session-level advisory lock by polling
	 * pg_try_advisory_lock until the timeout expires. The lock name is hashed
	 * to an integer using hashtext(). Throws `Wheels.AdvisoryLockTimeout` when
	 * the lock cannot be acquired in time, matching the MySQL adapter's
	 * contract (a blocking pg_advisory_lock would ignore the timeout and wait
	 * forever).
	 */
	public void function $acquireAdvisoryLock(required string name, numeric timeout = 10) {
		local.startedAt = GetTickCount();
		local.timeoutMs = arguments.timeout * 1000;
		while (true) {
			local.result = queryExecute(
				"SELECT pg_try_advisory_lock(hashtext(?)) AS lockresult",
				[arguments.name],
				{datasource: variables.dataSource, username: variables.username, password: variables.password}
			);
			if (IsQuery(local.result) && IsBoolean(local.result.lockresult) && local.result.lockresult) {
				return;
			}
			if (GetTickCount() - local.startedAt >= local.timeoutMs) {
				Throw(
					type = "Wheels.AdvisoryLockTimeout",
					message = "Could not acquire advisory lock '#arguments.name#' within #arguments.timeout# seconds.",
					extendedInfo = "The PostgreSQL pg_try_advisory_lock function kept returning false, indicating another session holds the lock."
				);
			}
			Sleep(250);
		}
	}

	/**
	 * Release a PostgreSQL advisory lock.
	 */
	public void function $releaseAdvisoryLock(required string name) {
		queryExecute(
			"SELECT pg_advisory_unlock(hashtext(?))",
			[arguments.name],
			{datasource: variables.dataSource, username: variables.username, password: variables.password}
		);
	}

	/**
	 * PostgreSQL implements advisory locks directly via pg_advisory_lock / pg_advisory_unlock
	 * and does not require an enclosing transaction.
	 */
	public boolean function $supportsAdvisoryLocks() {
		return true;
	}

	/**
	 * Override Base adapter's function.
	 * PostgreSQL uses double-quotes to quote identifiers (ANSI SQL standard).
	 */
	public string function $quoteIdentifier(required string name) {
		// PostgreSQL folds unquoted identifiers to lowercase, so we must lowercase
		// before quoting to match the actual stored name
		return """#LCase(arguments.name)#""";
	}

	/**
	 * PostgreSQL upsert using ON CONFLICT ... DO UPDATE SET col = EXCLUDED.col syntax.
	 */
	public array function $upsertSQL(
		required string tableName,
		required array columns,
		required array uniqueBy,
		required array updateColumns,
		required array validProperties,
		required array records,
		required numeric batchStart,
		required numeric batchEnd,
		required struct propertyInfo
	) {
		local.sql = [];

		// Build column list.
		local.colList = "";
		for (local.col in arguments.columns) {
			if (Len(local.colList)) local.colList &= ", ";
			local.colList &= $quoteIdentifier(local.col);
		}

		ArrayAppend(local.sql, "INSERT INTO #arguments.tableName# (#local.colList#) VALUES ");

		// Build value rows.
		for (local.r = arguments.batchStart; local.r <= arguments.batchEnd; local.r++) {
			if (local.r > arguments.batchStart) {
				ArrayAppend(local.sql, ", ");
			}
			ArrayAppend(local.sql, "(");
			for (local.p = 1; local.p <= ArrayLen(arguments.validProperties); local.p++) {
				if (local.p > 1) ArrayAppend(local.sql, ", ");
				local.propName = arguments.validProperties[local.p];
				local.val = StructKeyExists(arguments.records[local.r], local.propName) ? arguments.records[local.r][local.propName] : "";
				ArrayAppend(local.sql, $buildBulkParam(value=local.val, propName=local.propName, propertyInfo=arguments.propertyInfo));
			}
			ArrayAppend(local.sql, ")");
		}

		// ON CONFLICT clause.
		local.uniqueList = "";
		for (local.u in arguments.uniqueBy) {
			if (Len(local.uniqueList)) local.uniqueList &= ", ";
			local.uniqueList &= $quoteIdentifier(local.u);
		}

		if (ArrayLen(arguments.updateColumns)) {
			local.setClause = "";
			for (local.uc in arguments.updateColumns) {
				if (Len(local.setClause)) local.setClause &= ", ";
				local.setClause &= $quoteIdentifier(local.uc) & " = EXCLUDED." & $quoteIdentifier(local.uc);
			}
			ArrayAppend(local.sql, " ON CONFLICT (#local.uniqueList#) DO UPDATE SET #local.setClause#");
		} else {
			ArrayAppend(local.sql, " ON CONFLICT (#local.uniqueList#) DO NOTHING");
		}

		return local.sql;
	}

}
