component extends="wheels.databaseAdapters.Base" output=false {

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
		local.result = queryExecute(
			"SELECT GET_LOCK(?, ?) AS lockResult",
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
	 * MySQL implements advisory locks directly via GET_LOCK / RELEASE_LOCK
	 * and does not require an enclosing transaction.
	 */
	public boolean function $supportsAdvisoryLocks() {
		return true;
	}

	/**
	 * Override Base adapter's function.
	 */
	public string function $defaultValues() {
		return "() VALUES()";
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
