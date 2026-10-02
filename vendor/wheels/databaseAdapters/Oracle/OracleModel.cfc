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
			// Native BOOLEAN (Oracle 23ai+), which the migrator emits for t.boolean() (#3897).
			case "boolean":
				local.rv = "cf_sql_bit";
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
			default:
				$throwUnknownColumnType(arguments.type);
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
		local.rv = $performQuery(argumentCollection = arguments);
		// Every engine: BoxLang and Adobe 2023 both hand Oracle TIMESTAMP columns
		// back as raw driver objects (#3719). Engines that already return dates
		// pay one class-name check per column.
		if (StructKeyExists(local.rv, "query")) {
			local.rv.query = $normalizeOracleTemporalResult(local.rv.query);
		}
		return local.rv;
	}

	/**
	 * Normalize whatever shape the finder returned: a query, or the native
	 * `returnType="array"` (an array of row structs) / `returnType="struct"`
	 * (a struct of row structs) results that finders can ask cfquery for.
	 */
	public any function $normalizeOracleTemporalResult(required any result) {
		if (IsQuery(arguments.result)) {
			return $normalizeOracleTemporalColumns(arguments.result);
		}
		if (IsArray(arguments.result)) {
			for (local.i = 1; local.i <= ArrayLen(arguments.result); local.i++) {
				if (IsStruct(arguments.result[local.i])) {
					$normalizeOracleTemporalRow(arguments.result[local.i]);
				}
			}
			return arguments.result;
		}
		if (IsStruct(arguments.result)) {
			for (local.key in arguments.result) {
				if (IsNull(arguments.result[local.key])) {
					continue;
				}
				if (IsStruct(arguments.result[local.key])) {
					$normalizeOracleTemporalRow(arguments.result[local.key]);
				} else if ($isOracleDriverValue(arguments.result[local.key])) {
					local.converted = $oracleTemporalToDate(arguments.result[local.key]);
					if (IsDate(local.converted)) {
						arguments.result[local.key] = local.converted;
					}
				}
			}
		}
		return arguments.result;
	}

	/** Internal function: convert the Oracle temporal values in one row struct. */
	public void function $normalizeOracleTemporalRow(required struct row) {
		for (local.key in arguments.row) {
			if (IsNull(arguments.row[local.key]) || !$isOracleDriverValue(arguments.row[local.key])) {
				continue;
			}
			local.converted = $oracleTemporalToDate(arguments.row[local.key]);
			if (IsDate(local.converted)) {
				arguments.row[local.key] = local.converted;
			}
		}
	}

	/**
	 * Internal function: an Oracle TIMESTAMP/DATE driver object as a CFML
	 * date, to the millisecond. Converted from the driver's own
	 * java.sql.Timestamp (the instant in the JVM's timezone, like the other
	 * framework readers) with its sub-second part carried over, so a finder
	 * returns the same value on every engine. Returns "" when
	 * the object cannot be bridged without a connection (TIMESTAMP WITH TIME
	 * ZONE); callers then leave the value as it was.
	 */
	public any function $oracleTemporalToDate(required any value) {
		try {
			local.stamp = arguments.value.timestampValue();
		} catch (any e) {
			return "";
		}
		if (IsNull(local.stamp)) {
			return "";
		}
		local.date = $javaDateToCfml(local.stamp);
		local.millis = Int(local.stamp.getNanos() / 1000000);
		if (local.millis > 0) {
			local.date = DateAdd("l", local.millis, local.date);
		}
		return local.date;
	}

	/**
	 * On some engines (BoxLang, Adobe 2023) the Oracle driver's DATE/TIMESTAMP
	 * columns reach query results as raw `oracle.sql.*` driver objects instead
	 * of CFML dates. App code then cannot format, compare, output or JSON-render them
	 * (#3719). Convert, in place, every column whose first non-empty value is
	 * an Oracle TIMESTAMP/TIMESTAMPTZ/TIMESTAMPLTZ/DATE object into CFML dates,
	 * to the millisecond, through `$oracleTemporalToDate()`.
	 *
	 * One value per column is inspected to decide, so columns of simple values
	 * or real dates cost a single check. A cell is only replaced when the
	 * conversion yields a date; anything it cannot convert (for example a
	 * TIMESTAMP WITH TIME ZONE that needs a live connection) is left as it was
	 * rather than blanked.
	 */
	public query function $normalizeOracleTemporalColumns(required query query) {
		local.rowCount = arguments.query.recordCount;
		if (!local.rowCount) {
			return arguments.query;
		}
		local.columns = ListToArray(arguments.query.columnList);
		for (local.column in local.columns) {
			if (!$isOracleTemporalColumn(arguments.query, local.column, local.rowCount)) {
				continue;
			}
			for (local.row = 1; local.row <= local.rowCount; local.row++) {
				local.cell = arguments.query[local.column][local.row];
				if (IsNull(local.cell) || !$isOracleDriverValue(local.cell)) {
					continue;
				}
				local.converted = $oracleTemporalToDate(local.cell);
				if (IsDate(local.converted)) {
					QuerySetCell(arguments.query, local.column, local.converted, local.row);
				}
			}
		}
		return arguments.query;
	}

	/**
	 * Internal function for `$normalizeOracleTemporalColumns()`: is the first
	 * non-empty value in `column` an Oracle temporal driver object? Decided by
	 * the Java class name alone: the driver objects throw on Len(), string
	 * casts and date functions, so nothing else is called on them.
	 */
	public boolean function $isOracleTemporalColumn(required query query, required string column, required numeric rowCount) {
		for (local.row = 1; local.row <= arguments.rowCount; local.row++) {
			local.cell = arguments.query[arguments.column][local.row];
			if (IsNull(local.cell)) {
				continue;
			}
			if ($isOracleDriverValue(local.cell)) {
				return true;
			}
			// An empty string is a NULL column value: keep looking. Any other
			// value (text, number, CFML date) means this is not such a column.
			if ($javaClassName(local.cell) == "java.lang.String" && !Len(local.cell)) {
				continue;
			}
			return false;
		}
		return false;
	}

	/**
	 * Internal function: is `value` one of the Oracle driver's temporal
	 * objects? Exactly these classes, not every `oracle.sql.*`: the
	 * conversion treats numbers as epoch milliseconds, so a raw
	 * oracle.sql.NUMBER must never reach it.
	 */
	public boolean function $isOracleDriverValue(required any value) {
		return ListFind(
			"oracle.sql.TIMESTAMP,oracle.sql.TIMESTAMPTZ,oracle.sql.TIMESTAMPLTZ,oracle.sql.DATE",
			$javaClassName(arguments.value)
		) > 0;
	}

	/** Internal function: the Java class name of `value`, or "" when unknown. */
	public string function $javaClassName(required any value) {
		try {
			return arguments.value.getClass().getName();
		} catch (any e) {
			return "";
		}
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
			// Catalog view absent (pre-12c) — leave seq empty so $lastIdLookup throws.
			// Deliberately no local assignments in here (BoxLang catch-scope invariant).
		}
		if (Len(local.seq) && !REFind("^[A-Za-z][A-Za-z0-9_$##]*$", local.seq)) {
			return "";
		}
		return local.seq;
	}

	/**
	 * The text form of a driver-supplied generated key. Simple values pass through
	 * unchanged. A key OBJECT (BoxLang returns oracle.sql.ROWID as-is, #3708) is read
	 * via stringValue() (oracle.sql.ROWID) or, failing that, toString() (the
	 * java.sql.RowId contract). Anything without a readable text form is "" (no
	 * usable key), so the caller falls back to CURRVAL. The result is still gated by
	 * the numeric / extended-ROWID checks before it reaches any SQL.
	 */
	public string function $generatedKeyText(required any value) {
		if (IsSimpleValue(arguments.value)) {
			return arguments.value;
		}
		var state = {text = ""};
		try {
			state.text = arguments.value.stringValue();
		} catch (any e) {
			state.text = "";
		}
		if (!IsSimpleValue(state.text) || !Len(state.text)) {
			try {
				state.text = arguments.value.toString();
			} catch (any e) {
				state.text = "";
			}
		}
		return IsSimpleValue(state.text) ? state.text : "";
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
		// ListFirst because multi-row inserts can return a list. BoxLang hands back
		// the driver's key as an oracle.sql.ROWID OBJECT rather than a string, so read
		// its text form before any Len()/ListFirst() (#3708).
		local.generated = "";
		if (StructKeyExists(arguments.result, "generatedKey")) {
			local.generated = ListFirst($generatedKeyText(arguments.result.generatedKey));
		}
		if (!Len(local.generated) && StructKeyExists(arguments.result, "rowid")) {
			local.generated = $generatedKeyText(arguments.result.rowid);
		}
		if (Len(local.generated)) {
			// Some driver/engine combos return the identity value itself.
			if (IsNumeric(local.generated)) {
				return local.generated;
			}
			// Standard extended ROWID: 18 base-64 chars. The value originates from
			// the JDBC driver — not user input — but $query has no parameter
			// binding, so gate strictly before interpolating; UROWIDs and anything
			// unexpected fall through to CURRVAL, then throw. This exact-row
			// lookup targets OUR insert, so it is race-free under concurrent
			// inserts.
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
		// column's backing sequence. CURRVAL is session-scoped and cannot return
		// another session's key under concurrent inserts.
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

		$throwIdentityNotFound();
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
	 * Oracle bulk insert using `INSERT INTO t (cols) SELECT ... FROM dual UNION ALL ...`.
	 *
	 * Two Oracle constraints shape this, and satisfying only the first is what the
	 * previous `INSERT ALL` form did.
	 *
	 * 1. The default Base adapter shape — `INSERT INTO t (cols) VALUES (?,?), (?,?)`
	 *    (SQL standard table value constructor) — was rejected on Oracle 23 with
	 *    `ORA: returning clause is not allowed with INSERT and Table Value
	 *    Constructor`. The CFML engine's `cfquery` implicitly sets
	 *    `Statement.RETURN_GENERATED_KEYS` on INSERTs, which the Oracle JDBC driver
	 *    translates into a RETURNING clause, and Oracle 23 does not permit RETURNING
	 *    with multi-row VALUES (#2745).
	 *
	 * 2. In a multitable insert (`INSERT ALL`), Oracle evaluates each row's default
	 *    expressions ONCE PER ROW OF THE DRIVING QUERY and shares the result across
	 *    every INTO clause. The driving query was `SELECT 1 FROM dual` — a single row
	 *    — so every INTO received the SAME identity value, and any table with an
	 *    identity or sequence-backed primary key got a duplicate-key violation on the
	 *    second record: `ORA-00001 ... row with column values (ID:1) already exists`.
	 *    insertAll() could never insert more than one row into such a table (#3302).
	 *
	 * `INSERT ... SELECT ... UNION ALL` satisfies both: it is not a table value
	 * constructor, and its driving query returns one row per record, so the identity
	 * default is evaluated per row. It is also the shape `$upsertSQL` below already
	 * uses for its MERGE source, including the alias-the-first-branch-only detail.
	 *
	 * Oracle rejects RETURNING after `INSERT ... SELECT` too (ORA-03048), so this
	 * statement must also reach the driver without a generated-key request. insertAll()
	 * runs it with `$captureResult=false`, which drops the cfquery `result` attribute —
	 * the thing that makes Lucee request generated keys (#3653).
	 *
	 * BoxLang requests generated keys on every INSERT regardless of `result`, and
	 * for `INSERT ... SELECT` the Oracle driver then fails with ORA-17009 (Closed
	 * statement), which inside a transaction surfaces only as "Connection is closed"
	 * (#3715). The statement is therefore wrapped in an anonymous PL/SQL block:
	 * `BEGIN INSERT ... SELECT ...; END;` is not an INSERT to the engine, so no
	 * engine asks for keys, and bind parameters work inside the block.
	 *
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

		ArrayAppend(local.sql, "BEGIN INSERT INTO #arguments.tableName# (#local.colList#) ");

		local.propCount = ArrayLen(arguments.validProperties);
		for (local.r = arguments.batchStart; local.r <= arguments.batchEnd; local.r++) {
			if (local.r > arguments.batchStart) {
				ArrayAppend(local.sql, " UNION ALL ");
			}
			ArrayAppend(local.sql, "SELECT ");
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
				// Only the first branch needs column aliases; the rest of the
				// UNION ALL inherits them. Same rule as $upsertSQL's MERGE source.
				if (local.r == arguments.batchStart) {
					ArrayAppend(local.sql, " AS " & $quoteIdentifier(arguments.columns[local.p]));
				}
			}
			ArrayAppend(local.sql, " FROM dual");
		}
		ArrayAppend(local.sql, "; END;");

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
