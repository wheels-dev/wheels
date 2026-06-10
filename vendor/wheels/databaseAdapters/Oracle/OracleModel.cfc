component extends="wheels.databaseAdapters.Base" output=false {

	/**
	 * Oracle reports unquoted identifiers in uppercase, so lowercase
	 * auto-derived property names — otherwise models expose `FIRSTNAME`
	 * instead of `firstname`. See Base.$lowerCaseColumnNames().
	 */
	public boolean function $lowerCaseColumnNames() {
		return true;
	}

	/**
	 * Map database types to the ones used in CFML.
	 */
	public string function $getType(required string type, string scale, string details) {
		switch (arguments.type) {
			case "blob":
			case "bfile":
				local.rv = "cf_sql_binary";
				break;
			case "char":
			case "nchar":
				local.rv = "cf_sql_char";
				break;
			case "date":
			case "timestamp":
			case "datetime":
				local.rv = "cf_sql_timestamp";
				break;
			case "decimal":
			case "dec":
				local.rv = "cf_sql_decimal";
				break;
			case "integer":
			case "int":
				local.rv = "cf_sql_integer";
				break;
			case "numeric":
				local.rv = "cf_sql_numeric";
				break;
			case "number":
				if (arguments.scale EQ 0) {
					local.rv = "cf_sql_integer";
				} else {
					local.rv = "cf_sql_numeric";
				}
				break;
			case "real":
			case "binary_float":
			case "binary_double":
			case "double":
			case "precision":
			case "float":
				local.rv = "cf_sql_real";
				break;
			case "smallint":
				local.rv = "cf_sql_smallint";
				break;
			case "long":
			case "clob":
			case "nclob":
				local.rv = "cf_sql_longvarchar";
				break;
			case "time":
				local.rv = "cf_sql_time";
				break;
			case "varchar":
			case "varchar2":
			case "rowid":
				local.rv = "cf_sql_varchar";
				break;
		}
		return local.rv;
	}

	/**
	 * Oracle advisory locks require DBMS_LOCK package setup which is not available by default.
	 */
	public void function $acquireAdvisoryLock(required string name, numeric timeout = 10) {
		Throw(
			type = "Wheels.AdvisoryLockNotSupported",
			message = "Oracle advisory locks require DBMS_LOCK package setup.",
			extendedInfo = "Oracle supports advisory locks via the DBMS_LOCK package, but this requires DBA-level setup and is not supported by Wheels out of the box. Use forUpdate() for row-level locking instead."
		);
	}

	/**
	 * Oracle advisory locks require DBMS_LOCK package setup.
	 */
	public void function $releaseAdvisoryLock(required string name) {
		Throw(
			type = "Wheels.AdvisoryLockNotSupported",
			message = "Oracle advisory locks require DBMS_LOCK package setup.",
			extendedInfo = "Oracle supports advisory locks via the DBMS_LOCK package, but this requires DBA-level setup and is not supported by Wheels out of the box."
		);
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
	 * Override Base adapter's function.
	 */
	public any function $identitySelect(
		required struct queryAttributes,
		required struct result,
		required string primaryKey,
		any returningIdentity = ""
	) {
		var query = {};
		local.sql = Trim(arguments.result.sql);
		if (Left(local.sql, 11) == "INSERT INTO" && !StructKeyExists(arguments.result, $generatedKey())) {
			local.startPar = Find("(", local.sql) + 1;
			local.endPar = Find(")", local.sql);
			local.columnList = "";
			if (local.endPar) {
				local.rawColumns = Mid(local.sql, local.startPar, (local.endPar - local.startPar));

				// BoxLang compatibility fix - ReplaceList behaves differently
				if (StructKeyExists(server, "boxlang")) {
					// For BoxLang, use regex to properly parse column names
					local.columnList = REReplace(local.rawColumns, "\s*,\s*", ",", "all");
					local.columnList = REReplace(local.columnList, "[\r\n]", "", "all");
					local.columnList = Trim(local.columnList);
				} else {
					// Original Lucee/ACF behavior
					local.columnList = ReplaceList(
						local.rawColumns,
						"#Chr(10)#,#Chr(13)#, ",
						",,"
					);
				}
			}
			// Strip identifier quotes from column list for comparison
			local.columnList = $stripIdentifierQuotes(local.columnList);
			if (!ListFindNoCase(local.columnList, ListFirst(arguments.primaryKey))) {
				local.rv = {};
				local.tbl = SpanExcluding(Right(local.sql, Len(local.sql) - 12), " ");

				// Resolve a driver-supplied key first. CFML engines set
				// Statement.RETURN_GENERATED_KEYS on INSERTs (see $bulkInsertSQL), so the
				// Oracle JDBC driver returns the inserted row's ROWID. Lucee surfaces it
				// as result.generatedKey (StructKeyExists is case-insensitive so the
				// lowercase `generatedkey` key matches); ACF surfaces it as result.rowid.
				// ListFirst because multi-row inserts can return a list.
				local.generated = "";
				if (StructKeyExists(arguments.result, "generatedKey") && Len(arguments.result.generatedKey)) {
					local.generated = ListFirst(arguments.result.generatedKey);
				} else if (StructKeyExists(arguments.result, "rowid") && Len(arguments.result.rowid)) {
					local.generated = arguments.result.rowid;
				}
				if (Len(local.generated)) {
					// Some driver/engine combos return the identity value itself.
					if (IsNumeric(local.generated)) {
						local.rv[$generatedKey()] = local.generated;
						return local.rv;
					}
					// Standard extended ROWID: 18 base-64 chars. The value originates from
					// the JDBC driver — not user input — but $query has no parameter
					// binding, so gate strictly before interpolating; UROWIDs and anything
					// unexpected fall through to the legacy query below. This exact-row
					// lookup targets OUR insert, so it is race-free under concurrent
					// inserts (unlike MAX(ROWID)).
					if (REFind("^[A-Za-z0-9/+]{18}$", local.generated) == 1) {
						query = $query(
							sql = "SELECT #arguments.primaryKey# AS lastId FROM #local.tbl# WHERE ROWID = CHARTOROWID('#local.generated#')",
							argumentCollection = arguments.queryAttributes
						);
						if (query.recordCount && Len(query.lastId)) {
							local.rv[$generatedKey()] = query.lastId;
							return local.rv;
						}
					}
				}

				// Legacy heuristic, kept only for engines that surface no generated key
				// (e.g. current BoxLang). ROWID is physical location, not insertion order,
				// so MAX(ROWID) races under concurrent inserts and can return another
				// session's row. Replacing this with CURRVAL on the identity sequence is
				// tracked in a follow-up issue.
				query = $query(
					sql = "SELECT #arguments.primaryKey# AS lastId FROM #local.tbl# WHERE ROWID = (SELECT MAX(ROWID) FROM #local.tbl#)",
					argumentCollection = arguments.queryAttributes
				);
				local.rv[$generatedKey()] = query.lastId;
				return local.rv;
			}
		}
	}

	/**
	 * Override Base adapter's function.
	 */
	public string function $randomOrder() {
		return "RANDOM()";
	}

	/**
	 * Override Base adapter's function.
	 */
	public string function $defaultValues() {
		return "(#arguments.$primaryKey#) VALUES(DEFAULT)";
	}

	/**
	 * Set a default for the table alias string (e.g. "users AS users2").
	 * Individual database adapters will override when necessary.
	 */
	public string function $tableAlias(required string table, required string alias) {
		return arguments.table & " " & arguments.alias;
	}

	/**
	 * Override Base adapter's function.
	 * Oracle uses double-quotes to quote identifiers.
	 */
	public string function $quoteIdentifier(required string name) {
		// Oracle folds unquoted identifiers to uppercase, so we must uppercase
		// before quoting to match the actual stored name
		return """#UCase(arguments.name)#""";
	}

	/**
	 * Oracle bulk insert using `INSERT ALL INTO ... SELECT 1 FROM dual`.
	 *
	 * The default Base adapter shape — `INSERT INTO t (cols) VALUES (?,?), (?,?), ...`
	 * (SQL standard table value constructor) — was rejected on Oracle 23 with
	 * `ORA: returning clause is not allowed with INSERT and Table Value Constructor`.
	 * The CFML engine's `cfquery` for INSERT statements implicitly sets
	 * `Statement.RETURN_GENERATED_KEYS`, which the Oracle JDBC driver translates into a
	 * RETURNING clause — and Oracle 23 does not permit RETURNING with multi-row VALUES.
	 *
	 * `INSERT ALL` is the Oracle-idiomatic multi-row insert form, doesn't trigger the
	 * RETURNING-clause expansion, and works on every Oracle version Wheels targets.
	 * Uses parameterized values via `$buildBulkParam` — never interpolates user data
	 * into SQL.
	 */
	public array function $bulkInsertSQL(
		required string tableName,
		required array columns,
		required array validProperties,
		required array records,
		required numeric batchStart,
		required numeric batchEnd,
		required struct propertyInfo
	) {
		local.sql = [];

		local.colList = "";
		for (local.col in arguments.columns) {
			if (Len(local.colList)) {
				local.colList &= ", ";
			}
			local.colList &= $quoteIdentifier(local.col);
		}

		ArrayAppend(local.sql, "INSERT ALL");

		local.propCount = ArrayLen(arguments.validProperties);
		for (local.r = arguments.batchStart; local.r <= arguments.batchEnd; local.r++) {
			ArrayAppend(local.sql, " INTO #arguments.tableName# (#local.colList#) VALUES (");
			for (local.p = 1; local.p <= local.propCount; local.p++) {
				if (local.p > 1) {
					ArrayAppend(local.sql, ", ");
				}
				local.propName = arguments.validProperties[local.p];
				local.val = StructKeyExists(arguments.records[local.r], local.propName) ? arguments.records[local.r][local.propName] : "";
				ArrayAppend(local.sql, $buildBulkParam(
					value = local.val,
					propName = local.propName,
					propertyInfo = arguments.propertyInfo
				));
			}
			ArrayAppend(local.sql, ")");
		}

		ArrayAppend(local.sql, " SELECT 1 FROM dual");

		return local.sql;
	}

	/**
	 * Oracle upsert using MERGE with USING (SELECT ... FROM dual UNION ALL ...) source.
	 * Uses parameterized values via $buildBulkParam — never interpolates user data into SQL.
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

		ArrayAppend(local.sql, "MERGE INTO #arguments.tableName# target USING (");

		// Build USING subquery: SELECT ? AS col1, ? AS col2 FROM dual UNION ALL SELECT ?, ? FROM dual ...
		for (local.r = arguments.batchStart; local.r <= arguments.batchEnd; local.r++) {
			if (local.r > arguments.batchStart) {
				ArrayAppend(local.sql, " UNION ALL ");
			}
			ArrayAppend(local.sql, "SELECT ");
			for (local.p = 1; local.p <= ArrayLen(arguments.validProperties); local.p++) {
				if (local.p > 1) ArrayAppend(local.sql, ", ");
				local.propName = arguments.validProperties[local.p];
				local.val = StructKeyExists(arguments.records[local.r], local.propName) ? arguments.records[local.r][local.propName] : "";
				ArrayAppend(local.sql, $buildBulkParam(value=local.val, propName=local.propName, propertyInfo=arguments.propertyInfo));
				// Only the first row needs column aliases; subsequent rows in UNION ALL inherit them.
				if (local.r == arguments.batchStart) {
					ArrayAppend(local.sql, " AS " & $quoteIdentifier(arguments.columns[local.p]));
				}
			}
			ArrayAppend(local.sql, " FROM dual");
		}

		ArrayAppend(local.sql, ") source ON (");

		// ON clause.
		local.onClause = "";
		for (local.u in arguments.uniqueBy) {
			if (Len(local.onClause)) local.onClause &= " AND ";
			local.onClause &= "target." & $quoteIdentifier(local.u) & " = source." & $quoteIdentifier(local.u);
		}
		ArrayAppend(local.sql, local.onClause & ")");

		// WHEN MATCHED THEN UPDATE.
		if (ArrayLen(arguments.updateColumns)) {
			local.setClause = "";
			for (local.uc in arguments.updateColumns) {
				if (Len(local.setClause)) local.setClause &= ", ";
				local.setClause &= "target." & $quoteIdentifier(local.uc) & " = source." & $quoteIdentifier(local.uc);
			}
			ArrayAppend(local.sql, " WHEN MATCHED THEN UPDATE SET #local.setClause#");
		}

		// WHEN NOT MATCHED THEN INSERT.
		local.colList = "";
		local.valList = "";
		for (local.c = 1; local.c <= ArrayLen(arguments.columns); local.c++) {
			if (Len(local.colList)) {
				local.colList &= ", ";
				local.valList &= ", ";
			}
			local.colList &= $quoteIdentifier(arguments.columns[local.c]);
			local.valList &= "source." & $quoteIdentifier(arguments.columns[local.c]);
		}
		ArrayAppend(local.sql, " WHEN NOT MATCHED THEN INSERT (#local.colList#) VALUES (#local.valList#)");

		return local.sql;
	}

}
