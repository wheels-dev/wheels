component extends="wheels.databaseAdapters.Base" output=false {

	/**
	 * Internal function. This database converts a high-precision decimal sent as text exactly,
	 * in an insert and in a comparison (#4172).
	 */
	public string function $wideDecimalBindType() {
		return "cf_sql_varchar";
	}

	/**
	 * Internal function. MySQL compares a multi-element IN list of text values with a DECIMAL
	 * column as doubles, so a high-precision decimal also binds inside an exact cast (#4172).
	 */
	public struct function $wideDecimalCastLimits() {
		return {precision = 65, scale = 30};
	}

	/**
	 * Internal function. Casts high-precision decimal params exactly before running the query.
	 */
	public struct function $performQuery(
		required array sql,
		required boolean parameterize,
		numeric limit = 0,
		numeric offset = 0,
		string dataSource = variables.dataSource,
		string $primaryKey = "",
		string $debugName = "query",
		boolean $captureResult = true
	) {
		$castWideDecimalParams(args = arguments);
		return super.$performQuery(argumentCollection = arguments);
	}

	variables.mysqlTypeMap = {
		"bigint": "cf_sql_bigint",
		"binary": "cf_sql_binary",
		"geometry": "cf_sql_binary",
		"point": "cf_sql_binary",
		"linestring": "cf_sql_binary",
		"polygon": "cf_sql_binary",
		"multipoint": "cf_sql_binary",
		"multilinestring": "cf_sql_binary",
		"multipolygon": "cf_sql_binary",
		"geometrycollection": "cf_sql_binary",
		"bit": "cf_sql_bit",
		"bool": "cf_sql_bit",
		"blob": "cf_sql_blob",
		"tinyblob": "cf_sql_blob",
		"mediumblob": "cf_sql_blob",
		"longblob": "cf_sql_blob",
		"char": "cf_sql_char",
		"date": "cf_sql_date",
		"decimal": "cf_sql_decimal",
		"double": "cf_sql_double",
		"float": "cf_sql_float",
		"int": "cf_sql_integer",
		"mediumint": "cf_sql_integer",
		"smallint": "cf_sql_smallint",
		"year": "cf_sql_smallint",
		"time": "cf_sql_time",
		"datetime": "cf_sql_timestamp",
		"timestamp": "cf_sql_timestamp",
		"tinyint": "cf_sql_tinyint",
		"varbinary": "cf_sql_varbinary",
		"varchar": "cf_sql_varchar",
		"enum": "cf_sql_varchar",
		"set": "cf_sql_varchar",
		"tinytext": "cf_sql_varchar",
		"json": "cf_sql_longvarchar",
		"text": "cf_sql_longvarchar",
		"mediumtext": "cf_sql_longvarchar",
		"longtext": "cf_sql_longvarchar"
	};

	/**
	 * A MySQL TINYINT or SMALLINT column may be signed or UNSIGNED, and both map to
	 * the same cf_sql type, so the range covers both: TINYINT -128 to 255, SMALLINT
	 * -32768 to 65535 (#4087). On Adobe ColdFusion a negative key in a signed TINYINT
	 * column still fails to bind, since Adobe accepts CF_SQL_TINYINT only from 0 to 255.
	 */
	public struct function $integerKeyRange(required string sqlType) {
		if (arguments.sqlType == "cf_sql_tinyint") {
			return {min = "-128", max = "255"};
		}
		if (arguments.sqlType == "cf_sql_smallint") {
			return {min = "-32768", max = "65535"};
		}
		return super.$integerKeyRange(argumentCollection = arguments);
	}

	/**
	 * Map database types to the ones used in CFML.
	 */
	public string function $getType(required string type, string scale, string details) {
		// Special handling for unsigned (stores only positive or 0 numbers) data types.
		// When using unsigned data types we can store a higher value than usual so we need to map to different CF types.
		// E.g. unsigned int stores up to 4,294,967,295 instead of 2,147,483,647 so we map to cf_sql_bigint to support that.
		if (StructKeyExists(arguments, "details") && arguments.details == "unsigned") {
			if (arguments.type == "int") {
				return "cf_sql_bigint";
			} else if (arguments.type == "bigint") {
				return "cf_sql_decimal";
			}
		}

		local.key = LCase(arguments.type);
		if (StructKeyExists(variables.mysqlTypeMap, local.key)) {
			return variables.mysqlTypeMap[local.key];
		}
		$throwUnknownColumnType(arguments.type);
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
		$moveAggregateToHaving(args = arguments);
		return $performQuery(argumentCollection = arguments);
	}

	/**
	 * Acquire a MySQL advisory lock using GET_LOCK.
	 * Returns after the lock is acquired or the timeout expires.
	 * Throws if the lock could not be acquired within the timeout.
	 */
	public void function $acquireAdvisoryLock(required string name, numeric timeout = 10) {
		$acquireAdvisoryLockSession(name = arguments.name, timeout = arguments.timeout);
	}

	/**
	 * Internal function. Acquires the lock and returns the holding connection's id, read in the same
	 * statement so it is the session that took the lock (#4197).
	 */
	public string function $acquireAdvisoryLockSession(required string name, numeric timeout = 10) {
		local.result = queryExecute(
			"SELECT GET_LOCK(?, ?) AS lockResult, CONNECTION_ID() AS sessionId",
			[arguments.name, arguments.timeout],
			{datasource: variables.dataSource, username: variables.username, password: variables.password}
		);
		if (!IsQuery(local.result) || local.result.lockResult != 1) {
			Throw(
				type = "Wheels.AdvisoryLockTimeout",
				message = "Could not acquire advisory lock '#arguments.name#' within #arguments.timeout# seconds.",
				extendedInfo = "The MySQL GET_LOCK function returned a non-1 result, indicating the lock could not be acquired."
			);
		}
		return local.result.sessionId;
	}

	/**
	 * Release a MySQL advisory lock.
	 */
	public void function $releaseAdvisoryLock(required string name) {
		queryExecute(
			"SELECT RELEASE_LOCK(?)",
			[arguments.name],
			{datasource: variables.dataSource, username: variables.username, password: variables.password}
		);
	}

	/**
	 * Internal function. RELEASE_LOCK returns 1 only on the session holding the lock (#4197).
	 */
	public boolean function $tryReleaseAdvisoryLock(required string name) {
		local.result = queryExecute(
			"SELECT RELEASE_LOCK(?) AS released",
			[arguments.name],
			{datasource: variables.dataSource, username: variables.username, password: variables.password}
		);
		return IsQuery(local.result) && IsNumeric(local.result.released) && local.result.released == 1;
	}

	/**
	 * Internal function. IS_USED_LOCK returns the holding connection's id, or NULL when free; with
	 * `holder`, only that connection holding it counts (#4197).
	 */
	public boolean function $isAdvisoryLockHeld(required string name, string holder = "") {
		local.result = queryExecute(
			"SELECT IS_USED_LOCK(?) AS holder",
			[arguments.name],
			{datasource: variables.dataSource, username: variables.username, password: variables.password}
		);
		if (!IsQuery(local.result) || !IsNumeric(local.result.holder)) {
			return false;
		}
		return !Len(arguments.holder) || local.result.holder == arguments.holder;
	}

	/**
	 * MySQL implements advisory locks directly via GET_LOCK / RELEASE_LOCK
	 * and does not require an enclosing transaction.
	 */
	public boolean function $supportsAdvisoryLocks() {
		return true;
	}

	/**
	 * MySQL supports the transaction-scoped path (#4198): the transaction pins one connection, so
	 * GET_LOCK / RELEASE_LOCK and the callback's own queries all run on the same session.
	 */
	public boolean function $supportsTransactionalAdvisoryLock() {
		return true;
	}

	/**
	 * GET_LOCK is session- not transaction-scoped: it does not auto-release at transaction end, so
	 * the caller must release it explicitly on the pinned connection before the transaction closes
	 * (#4198).
	 */
	public boolean function $transactionalAdvisoryLockIsSessionScoped() {
		return true;
	}

	/**
	 * Internal function. Acquires a MySQL advisory lock on the current (pinned) connection with
	 * GET_LOCK (#4198). Mirrors the session-scoped acquire; the difference is only that the enclosing
	 * transaction guarantees this runs on the same connection as the callback's queries and the
	 * release. Throws Wheels.AdvisoryLockTimeout when the lock cannot be taken in time.
	 */
	public void function $acquireAdvisoryLockTransactional(required string name, numeric timeout = 10) {
		local.result = queryExecute(
			"SELECT GET_LOCK(?, ?) AS lockResult",
			[arguments.name, arguments.timeout],
			$advisoryLockConnection()
		);
		if (!IsQuery(local.result) || local.result.lockResult != 1) {
			Throw(
				type = "Wheels.AdvisoryLockTimeout",
				message = "Could not acquire advisory lock '#arguments.name#' within #arguments.timeout# seconds.",
				extendedInfo = "The MySQL GET_LOCK function returned a non-1 result, indicating the lock could not be acquired."
			);
		}
	}

	/**
	 * Internal function. Releases the MySQL advisory lock on the pinned connection before the
	 * transaction closes (#4198). Unlike the default (#4200) path, there is no borrowed-session
	 * retry: the release runs on the same pinned connection that took the lock, so a non-1 result is
	 * a real failure and is thrown. The caller runs this in a finally inside the transaction block,
	 * so a release error never replaces the callback's own error.
	 */
	public void function $releaseAdvisoryLockTransactional(required string name) {
		local.result = queryExecute(
			"SELECT RELEASE_LOCK(?) AS released",
			[arguments.name],
			$advisoryLockConnection()
		);
		if (!IsQuery(local.result) || !IsNumeric(local.result.released) || local.result.released != 1) {
			Throw(
				type = "Wheels.AdvisoryLockReleaseFailed",
				message = "Advisory lock '#arguments.name#' could not be released on its pinned connection.",
				extendedInfo = "RELEASE_LOCK returned a non-1 result on the connection that holds the lock, which should not happen inside the lock's own transaction."
			);
		}
	}

	/**
	 * MySQL and MariaDB treat a backslash inside a quoted string as an escape
	 * character unless sql_mode includes NO_BACKSLASH_ESCAPES, so doubling the
	 * quotes is not enough to write such a value as a literal. A value that
	 * contains a backslash is written as a utf8mb4 hex literal instead, which
	 * reads back as the same string whatever the sql_mode. Other values keep
	 * the plain quoted form.
	 */
	public string function $inlineStringLiteral(required string str) {
		if (Find("\", arguments.str) == 0) {
			return super.$inlineStringLiteral(arguments.str);
		}
		return "_utf8mb4 X'" & UCase(BinaryEncode(CharsetDecode(arguments.str, "utf-8"), "hex")) & "'";
	}

	/**
	 * MySQL code writes a backslash escape character as ESCAPE '\\', the
	 * escaped spelling under the default sql_mode, so a doubled backslash here
	 * means one backslash, as MySQL reads it. It is written as a single
	 * character, so ESCAPE '\\' and the portable ESCAPE '\' both work in every
	 * sql_mode.
	 */
	public string function $inlineEscapeCharacter(required string str) {
		if (Compare(arguments.str, "\\") == 0) {
			return $inlineStringLiteral("\");
		}
		return $inlineStringLiteral(arguments.str);
	}

	/**
	 * Override Base adapter's function.
	 */
	public string function $defaultValues() {
		return "() VALUES()";
	}

	/**
	 * Override Base adapter's function.
	 * Since 10.2.7, MariaDB reports column defaults as SQL expressions: a nullable
	 * column without a default comes back as the text NULL and a string default as
	 * a quoted literal ('draft'). Normalize those to what MySQL reports, so a
	 * missing default isn't read as a real one (#3927). MySQL is unchanged.
	 */
	public query function $getColumnInfo(
		required string table,
		required string datasource,
		required string username,
		required string password
	) {
		local.rv = super.$getColumnInfo(argumentCollection = arguments);
		if ($usesExpressionDefaults(arguments.datasource, arguments.username, arguments.password)) {
			for (local.column in ["column_default_value", "column_default", "default_value", "COLUMN_DEF"]) {
				if (ListFindNoCase(local.rv.columnList, local.column)) {
					for (local.i = 1; local.i <= local.rv.recordCount; local.i++) {
						local.value = local.rv[local.column][local.i];
						if (!IsNull(local.value) && IsSimpleValue(local.value)) {
							QuerySetCell(local.rv, local.column, $normalizeMariaDBColumnDefault(local.value), local.i);
						}
					}
				}
			}
		}
		return local.rv;
	}

	/**
	 * Internal function.
	 * Whether the server reports column defaults as SQL expressions (MariaDB
	 * 10.2.7+), checked once per datasource.
	 */
	public boolean function $usesExpressionDefaults(
		required string datasource,
		string username = "",
		string password = ""
	) {
		if (!StructKeyExists(variables, "$expressionDefaultsByDataSource")) {
			variables.$expressionDefaultsByDataSource = {};
		}
		if (!StructKeyExists(variables.$expressionDefaultsByDataSource, arguments.datasource)) {
			local.state = {result = false, probed = false};
			try {
				local.info = $dbinfo(
					type = "version",
					datasource = arguments.datasource,
					username = arguments.username,
					password = arguments.password
				);
				local.state.result = $isExpressionDefaultMariaDB(
					local.info["database_productname"][1],
					local.info["database_version"][1]
				);
				local.state.probed = true;
			} catch (any e) {
				// Can't tell this time: keep MySQL's reading, and don't cache it so
				// the next column read probes again.
			}
			if (!local.state.probed) {
				return false;
			}
			variables.$expressionDefaultsByDataSource[arguments.datasource] = local.state.result;
		}
		return variables.$expressionDefaultsByDataSource[arguments.datasource];
	}

	/**
	 * Internal function.
	 * True for MariaDB 10.2.7 and later. Through the MySQL driver MariaDB reports
	 * itself in the version string, before 11.0 with a 5.5.5- prefix.
	 */
	public boolean function $isExpressionDefaultMariaDB(required string productName, required string version) {
		if (!FindNoCase("MariaDB", arguments.productName & " " & arguments.version)) {
			return false;
		}
		local.version = ReReplace(arguments.version, "^5\.5\.5-", "");
		local.match = ReMatch("^[0-9]+\.[0-9]+\.[0-9]+", local.version);
		if (!ArrayLen(local.match)) {
			return false;
		}
		local.parts = ListToArray(local.match[1], ".");
		local.number = local.parts[1] * 1000000 + local.parts[2] * 1000 + local.parts[3];
		return local.number >= 10002007;
	}

	/**
	 * Internal function.
	 * A MariaDB expression-style column default as MySQL reports it: the text
	 * NULL (no default) becomes "", a quoted string literal is unquoted (a
	 * literal 'NULL' stays the text NULL), and anything else (numbers,
	 * current_timestamp(), b'0') is left as it is.
	 */
	public string function $normalizeMariaDBColumnDefault(required string value) {
		if (Compare(arguments.value, "NULL") == 0) {
			return "";
		}
		if (
			Len(arguments.value) >= 2
			&& Compare(Left(arguments.value, 1), "'") == 0
			&& Compare(Right(arguments.value, 1), "'") == 0
		) {
			return Replace(Mid(arguments.value, 2, Len(arguments.value) - 2), "''", "'", "all");
		}
		return arguments.value;
	}

	/**
	 * Override Base adapter's function.
	 * MySQL uses backticks to quote identifiers.
	 */
	public string function $quoteIdentifier(required string name) {
		return "`#arguments.name#`";
	}

	/**
	 * MySQL upsert using ON DUPLICATE KEY UPDATE col = VALUES(col) syntax.
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

		// ON DUPLICATE KEY UPDATE clause.
		if (ArrayLen(arguments.updateColumns)) {
			local.setClause = "";
			for (local.uc in arguments.updateColumns) {
				if (Len(local.setClause)) local.setClause &= ", ";
				local.setClause &= $quoteIdentifier(local.uc) & " = VALUES(" & $quoteIdentifier(local.uc) & ")";
			}
			ArrayAppend(local.sql, " ON DUPLICATE KEY UPDATE #local.setClause#");
		}

		return local.sql;
	}

}
