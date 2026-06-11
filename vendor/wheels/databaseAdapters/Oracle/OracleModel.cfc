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
	 * Oracle does not support LIMIT/OFFSET — use the OFFSET/FETCH syntax (12c+) instead.
	 */
	public string function $limitOffsetClause(required numeric limit, required numeric offset) {
		if (arguments.offset) {
			return "OFFSET " & arguments.offset & " ROWS" & Chr(13) & Chr(10) & "FETCH NEXT " & arguments.limit & " ROWS ONLY";
		}
		return "FETCH FIRST " & arguments.limit & " ROWS ONLY";
	}

	/**
	 * Override Base adapter's function.
	 */
	public string function $generatedKey() {
		return "lastId";
	}

	/**
	 * Resolve the system-generated sequence backing an identity column (Oracle
	 * 12c+) via the user_tab_identity_cols catalog view. Returns an empty string
	 * when the column is not identity-backed, the catalog view is unavailable
	 * (pre-12c), or any resolved name fails the identifier whitelist.
	 * Not memoized on purpose: the schema can be reset out-of-band, and this
	 * path only runs on engines that surface no driver generated key.
	 */
	public string function $identitySequenceName(
		required string tableName,
		required string columnName,
		required struct queryAttributes
	) {
		local.seq = "";
		local.tbl = UCase(ReReplace(arguments.tableName, '^"|"$', "", "all"));
		local.col = UCase(ReReplace(arguments.columnName, '^"|"$', "", "all"));
		// $query has no parameter binding — whitelist identifiers before interpolating.
		// (## is the CFML escape for a literal # — Oracle identifiers may contain it.)
		if (!REFind("^[A-Z][A-Z0-9_$##]*$", local.tbl) || !REFind("^[A-Z][A-Z0-9_$##]*$", local.col)) {
			return "";
		}
		try {
			local.q = $query(
				sql = "SELECT sequence_name FROM user_tab_identity_cols WHERE table_name = '#local.tbl#' AND column_name = '#local.col#'",
				argumentCollection = arguments.queryAttributes
			);
			if (local.q.recordCount && Len(local.q.sequence_name)) {
				local.seq = local.q.sequence_name;
			}
		} catch (any e) {
			// Catalog view absent (pre-12c) — fall through to the legacy lookup.
			// Deliberately no local assignments in here (BoxLang catch-scope invariant).
		}
		if (Len(local.seq) && !REFind("^[A-Za-z][A-Za-z0-9_$##]*$", local.seq)) {
			return "";
		}
		return local.seq;
	}

	/**
	 * Override Base adapter's $identitySelect hook.
	 */
	public any function $lastIdLookup(
		required struct queryAttributes,
		required struct result,
		required string primaryKey,
		any returningIdentity = "",
		required string insertSql
	) {
		local.tbl = SpanExcluding(Right(arguments.insertSql, Len(arguments.insertSql) - 12), " ");

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
				return local.generated;
			}
			// Standard extended ROWID: 18 base-64 chars. The value originates from
			// the JDBC driver — not user input — but $query has no parameter
			// binding, so gate strictly before interpolating; UROWIDs and anything
			// unexpected fall through to the fallbacks below. This exact-row
			// lookup targets OUR insert, so it is race-free under concurrent
			// inserts (unlike MAX(ROWID)).
			if (REFind("^[A-Za-z0-9/+]{18}$", local.generated) == 1) {
				local.query = $query(
					sql = "SELECT #arguments.primaryKey# AS lastId FROM #local.tbl# WHERE ROWID = CHARTOROWID('#local.generated#')",
					argumentCollection = arguments.queryAttributes
				);
				if (local.query.recordCount && Len(local.query.lastId)) {
					return local.query.lastId;
				}
			}
		}

		// No usable driver key (e.g. current BoxLang): read CURRVAL on the identity
		// column's backing sequence. CURRVAL is session-scoped, so unlike MAX(ROWID)
		// it cannot return another session's key under concurrent inserts.
		local.seq = $identitySequenceName(
			tableName = local.tbl,
			columnName = ListFirst(arguments.primaryKey),
			queryAttributes = arguments.queryAttributes
		);
		if (Len(local.seq)) {
			local.query = $query(
				sql = "SELECT #local.seq#.CURRVAL AS lastId FROM DUAL",
				argumentCollection = arguments.queryAttributes
			);
			if (local.query.recordCount && Len(local.query.lastId)) {
				return local.query.lastId;
			}
		}

		// Legacy heuristic, kept only for pre-12c schemas with no discoverable
		// identity sequence. ROWID is physical location, not insertion order, so
		// MAX(ROWID) races under concurrent inserts and can return another
		// session's row.
		local.query = $query(
			sql = "SELECT #arguments.primaryKey# AS lastId FROM #local.tbl# WHERE ROWID = (SELECT MAX(ROWID) FROM #local.tbl#)",
			argumentCollection = arguments.queryAttributes
		);
		return local.query.lastId;
	}

	/**
	 * Override Base adapter's function.
	 * RANDOM() is not an Oracle function (ORA-00904) — DBMS_RANDOM.VALUE is the
	 * Oracle-native ORDER BY expression for findAll(order="random").
	 */
	public string function $randomOrder() {
		return "DBMS_RANDOM.VALUE";
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
