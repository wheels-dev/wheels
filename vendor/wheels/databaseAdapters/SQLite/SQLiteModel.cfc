component extends="wheels.databaseAdapters.Base" output=false {

	/**
	 * Map SQLite types to CFML types.
	 */
	public string function $getType(required string type, string scale, string details) {
		switch (LCase(arguments.type)) {
			case "integer":
			case "int":
			case "bigint":
			case "mediumint":
			case "smallint":
			case "tinyint":
				local.rv = "cf_sql_integer";
				break;

			case "real":
			case "double":
			case "double precision":
			case "float":
				local.rv = "cf_sql_float";
				break;

			case "numeric":
			case "decimal":
				local.rv = "cf_sql_decimal";
				break;

			case "text":
			case "varchar":
			case "char":
			case "clob":
				local.rv = "cf_sql_varchar";
				break;

			case "blob":
				local.rv = "cf_sql_blob";
				break;

			case "boolean":
				local.rv = "cf_sql_bit";
				break;

			case "date":
				local.rv = "cf_sql_date";
				break;

			case "datetime":
			case "timestamp":
				// SQLite stores datetimes as TEXT (see SQLiteMigrator's
				// sqlTypes mapping). Bind as varchar; date objects are
				// pre-formatted to ISO-8601 in $buildQueryParamValues
				// before they reach the bind layer.
				local.rv = "cf_sql_varchar";
				break;

			case "time":
				local.rv = "cf_sql_time";
				break;

			default:
				// SQLite is dynamically typed, so fallback to text if unknown.
				local.rv = "cf_sql_varchar";
				break;
		}

		return local.rv;
	}

	/**
	 * Prepare query arguments before execution (SQLite has simpler syntax).
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
		$moveAggregateToHaving(args = arguments);
		return $performQuery(argumentCollection = arguments);
	}

    public any function $identitySelect(
        required struct queryAttributes,
        required struct result,
        required string primaryKey,
        any returningIdentity = ""
    ) {
        var query = {};
        var local = {};

        // Trim SQL of the executed statement
        local.sql = Trim(arguments.result.sql);

        // Only run if it was an INSERT statement and no generated key is already present
        if (Left(local.sql, 11) == "INSERT INTO" && !StructKeyExists(arguments.result, $generatedKey())) {

            // Extract columns list if present
            local.startPar = Find("(", local.sql) + 1;
            local.endPar = Find(")", local.sql);
            local.columnList = "";
            if (local.startPar > 1 && local.endPar > local.startPar) {
                local.columnList = ReplaceList(
                    Mid(local.sql, local.startPar, (local.endPar - local.startPar)),
                    "#Chr(10)#,#Chr(13)#, ",
                    ",,"
                );
            }
            
            // Strip identifier quotes from column list for comparison
            local.columnList = $stripIdentifierQuotes(local.columnList);
            // If the primary key column wasn't part of the INSERT, we fetch last inserted ID
            if (!ListFindNoCase(local.columnList, ListFirst(arguments.primaryKey))) {
                local.rv = {};
                query = $query(
                    sql = "SELECT last_insert_rowid() AS lastId",
                    argumentCollection = arguments.queryAttributes
                );
                local.rv[$generatedKey()] = query.lastId;
                return local.rv;
            }
        }
    }


	/**
	 * SQLite uses file-level locking and does not support advisory locks.
	 * This is a no-op to allow code that uses advisory locks to run without errors on SQLite.
	 */
	public void function $acquireAdvisoryLock(required string name, numeric timeout = 10) {
		// No-op: SQLite has file-level locking only.
		// Advisory locks are not meaningful for SQLite.
	}

	/**
	 * No-op release for SQLite.
	 */
	public void function $releaseAdvisoryLock(required string name) {
		// No-op
	}

	/**
	 * SQLite does not support SELECT ... FOR UPDATE.
	 * Returns empty string to no-op.
	 */
	public string function $forUpdateClause() {
		return "";
	}

	/**
	 * Default VALUES syntax (same as MySQL).
	 */
	public string function $defaultValues() {
		return " DEFAULT VALUES";
	}

	/**
	 * Override Base adapter's function.
	 * SQLite uses double-quotes to quote identifiers (ANSI SQL standard).
	 */
	public string function $quoteIdentifier(required string name) {
		return """#arguments.name#""";
	}

	/**
	 * SQLite upsert using ON CONFLICT ... DO UPDATE SET syntax.
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
				local.setClause &= $quoteIdentifier(local.uc) & " = excluded." & $quoteIdentifier(local.uc);
			}
			ArrayAppend(local.sql, " ON CONFLICT (#local.uniqueList#) DO UPDATE SET #local.setClause#");
		} else {
			ArrayAppend(local.sql, " ON CONFLICT (#local.uniqueList#) DO NOTHING");
		}

		return local.sql;
	}

}
