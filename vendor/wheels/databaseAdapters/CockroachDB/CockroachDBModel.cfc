component extends="wheels.databaseAdapters.PostgreSQL.PostgreSQLModel" output=false {

	/**
	 * Map database types to the ones used in CFML.
	 * CockroachDB uses the PostgreSQL wire protocol but may report native type names
	 * in JDBC metadata (e.g. STRING instead of varchar, BYTES instead of bytea).
	 * Types not explicitly handled here delegate to the PostgreSQL adapter.
	 */
	public string function $getType(required string type, string scale, string details) {
		switch (arguments.type) {
			case "bool":
			case "boolean":
				local.rv = "cf_sql_bit";
				break;
			case "bit":
			case "varbit":
				local.rv = "cf_sql_bit";
				break;
			case "string":
				local.rv = "cf_sql_varchar";
				break;
			case "bytes":
				local.rv = "cf_sql_binary";
				break;
			case "int64":
				local.rv = "cf_sql_bigint";
				break;
			case "interval":
				local.rv = "cf_sql_varchar";
				break;
			case "geometry":
				local.rv = "cf_sql_other";
				break;
			default:
				local.rv = super.$getType(argumentCollection = arguments);
				break;
		}
		return local.rv;
	}

	/**
	 * CockroachDB lacks a pg_advisory_lock equivalent, so the parent PostgreSQL
	 * adapter's `true` would be wrong here. Reporting `false` lets the test
	 * suite skip the standalone advisory-lock specs (matching the H2 / SQL
	 * Server treatment from #2665) and lets capability-aware callers route
	 * around the missing primitive.
	 */
	public boolean function $supportsAdvisoryLocks() {
		return false;
	}

	/**
	 * CockroachDB does not support advisory locks.
	 * Use forUpdate() for row-level locking instead.
	 */
	public void function $acquireAdvisoryLock(required string name, numeric timeout = 10) {
		Throw(
			type = "Wheels.AdvisoryLockNotSupported",
			message = "CockroachDB does not support advisory locks.",
			extendedInfo = "Use forUpdate() for row-level locking instead. CockroachDB supports SELECT ... FOR UPDATE for pessimistic locking within transactions."
		);
	}

	/**
	 * CockroachDB does not support advisory locks.
	 */
	public void function $releaseAdvisoryLock(required string name) {
		Throw(
			type = "Wheels.AdvisoryLockNotSupported",
			message = "CockroachDB does not support advisory locks.",
			extendedInfo = "Use forUpdate() for row-level locking instead."
		);
	}

	/**
	 * Override query setup to append RETURNING clause to INSERTs.
	 * CockroachDB does not support pg_get_serial_sequence()/currval(),
	 * so the RETURNING clause is the correct way to retrieve generated keys.
	 *
	 * Skip the RETURNING append on bulk / upsert paths: bulk.cfc's insertAll
	 * and upsertAll call $querySetup without $primaryKey (default empty), and
	 * upsert statements already include ON CONFLICT clauses. In both cases,
	 * appending `RETURNING ` produces syntactically invalid SQL.
	 */
	public struct function $querySetup(
		required array sql,
		numeric limit = 0,
		numeric offset = 0,
		required boolean parameterize,
		string $primaryKey = ""
	) {
		if (Left(arguments.sql[1], 11) == "INSERT INTO") {
			local.shouldAppendReturning = Len(Trim(arguments.$primaryKey)) > 0;
			if (local.shouldAppendReturning) {
				for (local.chunk in arguments.sql) {
					if (IsSimpleValue(local.chunk) && ReFindNoCase("ON[[:space:]]+CONFLICT", local.chunk)) {
						local.shouldAppendReturning = false;
						break;
					}
				}
			}
			if (local.shouldAppendReturning) {
				ArrayAppend(arguments.sql, "RETURNING #arguments.$primaryKey#");
			}
		}
		$convertMaxRowsToLimit(args = arguments);
		$removeColumnAliasesInOrderClause(args = arguments);
		$addColumnsToSelectAndGroupBy(args = arguments);
		$moveAggregateToHaving(args = arguments);
		return $performQuery(argumentCollection = arguments);
	}

	/**
	 * Override generated key name.
	 */
	public string function $generatedKey() {
		return "lastId";
	}

	/**
	 * Retrieve the last inserted primary key value.
	 * Tries multiple strategies: result.generatedKey (Lucee), result.query (ACF),
	 * and the returningIdentity query result from the RETURNING clause.
	 */
	public any function $identitySelect(
		required struct queryAttributes,
		required struct result,
		required string primaryKey,
		any returningIdentity = ""
	) {
		var query = {};
		local.sql = Trim(arguments.result.sql);
		if (Left(local.sql, 11) != "INSERT INTO" || StructKeyExists(arguments.result, $generatedKey())) {
			return;
		}

		local.startPar = Find("(", local.sql) + 1;
		local.endPar = Find(")", local.sql);
		local.columnList = "";
		if (local.endPar) {
			local.rawColumns = Mid(local.sql, local.startPar, (local.endPar - local.startPar));
			if (StructKeyExists(server, "boxlang")) {
				local.columnList = REReplace(local.rawColumns, "\s*,\s*", ",", "all");
				local.columnList = REReplace(local.columnList, "[\r\n]", "", "all");
				local.columnList = Trim(local.columnList);
			} else {
				local.columnList = ReplaceList(local.rawColumns, "#Chr(10)#,#Chr(13)#, ", ",,");
			}
		}

		// Strip identifier quotes for comparison
		local.columnList = $stripIdentifierQuotes(local.columnList);

		if (!ListFindNoCase(local.columnList, ListFirst(arguments.primaryKey))) {
			local.rv = {};
			if (StructKeyExists(arguments.result, "generatedKey")) {
				query.id = ListFirst(arguments.result.generatedKey);
			} else if (IsQuery(arguments.returningIdentity) && arguments.returningIdentity.recordCount) {
				query.id = arguments.returningIdentity[arguments.primaryKey][1];
			}
			if (StructKeyExists(query, "id")) {
				local.rv[$generatedKey()] = query.id;
				return local.rv;
			}
		}
	}

}
