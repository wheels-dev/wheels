component extends="wheels.databaseAdapters.Base" output=false {

	/**
	 * H2 reports unquoted identifiers in uppercase, so lowercase auto-derived
	 * property names — otherwise models expose `FIRSTNAME` instead of
	 * `firstname`. See Base.$lowerCaseColumnNames().
	 */
	public boolean function $lowerCaseColumnNames() {
		return true;
	}

	variables.h2TypeMap = {
		"bigint": "cf_sql_bigint",
		"int8": "cf_sql_bigint",
		"binary": "cf_sql_binary",
		"bytea": "cf_sql_binary",
		"raw": "cf_sql_binary",
		"binary varying": "cf_sql_binary",
		"bit": "cf_sql_bit",
		"bool": "cf_sql_bit",
		"boolean": "cf_sql_bit",
		"binary large object": "cf_sql_blob",
		"blob": "cf_sql_blob",
		"tinyblob": "cf_sql_blob",
		"mediumblob": "cf_sql_blob",
		"longblob": "cf_sql_blob",
		"image": "cf_sql_blob",
		"oid": "cf_sql_blob",
		"char": "cf_sql_char",
		"character": "cf_sql_char",
		"nchar": "cf_sql_char",
		"uuid": "cf_sql_char",
		"date": "cf_sql_date",
		"dec": "cf_sql_decimal",
		"decimal": "cf_sql_decimal",
		"number": "cf_sql_decimal",
		"numeric": "cf_sql_decimal",
		"double": "cf_sql_double",
		"double precision": "cf_sql_double",
		"float": "cf_sql_float",
		"float4": "cf_sql_float",
		"float8": "cf_sql_float",
		"real": "cf_sql_float",
		"int": "cf_sql_integer",
		"int4": "cf_sql_integer",
		"integer": "cf_sql_integer",
		"mediumint": "cf_sql_integer",
		"signed": "cf_sql_integer",
		"identity": "cf_sql_integer",
		"int2": "cf_sql_smallint",
		"smallint": "cf_sql_smallint",
		"year": "cf_sql_smallint",
		"time": "cf_sql_time",
		"datetime": "cf_sql_timestamp",
		"smalldatetime": "cf_sql_timestamp",
		"timestamp": "cf_sql_timestamp",
		"tinyint": "cf_sql_tinyint",
		"varbinary": "cf_sql_varbinary",
		"longvarbinary": "cf_sql_varbinary",
		"varchar": "cf_sql_varchar",
		"varchar2": "cf_sql_varchar",
		"longvarchar": "cf_sql_varchar",
		"varchar_ignorecase": "cf_sql_varchar",
		"nvarchar": "cf_sql_varchar",
		"nvarchar2": "cf_sql_varchar",
		"clob": "cf_sql_varchar",
		"nclob": "cf_sql_varchar",
		"text": "cf_sql_varchar",
		"tinytext": "cf_sql_varchar",
		"mediumtext": "cf_sql_varchar",
		"longtext": "cf_sql_varchar",
		"ntext": "cf_sql_varchar",
		"enum": "cf_sql_varchar",
		"character varying": "cf_sql_varchar",
		"character large object": "cf_sql_varchar",
		"nvarchar_casesensitive": "cf_sql_nvarchar",
		"json": "cf_sql_longvarchar"
	};

	/**
	 * Map database types to the ones used in CFML.
	 */
	public string function $getType(required string type, string scale, string details) {
		local.key = LCase(arguments.type);
		if (StructKeyExists(variables.h2TypeMap, local.key)) {
			return variables.h2TypeMap[local.key];
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
		$addColumnsToSelectAndGroupBy(args = arguments);
		$moveAggregateToHaving(args = arguments);
		return $performQuery(argumentCollection = arguments);
	}

	/**
	 * H2 does not support advisory locks.
	 */
	public void function $acquireAdvisoryLock(required string name, numeric timeout = 10) {
		Throw(
			type = "Wheels.AdvisoryLockNotSupported",
			message = "H2 does not support advisory locks.",
			extendedInfo = "Advisory locks are not available in H2. Consider using a different database for features that require advisory locking."
		);
	}

	/**
	 * H2 does not support advisory locks.
	 */
	public void function $releaseAdvisoryLock(required string name) {
		Throw(
			type = "Wheels.AdvisoryLockNotSupported",
			message = "H2 does not support advisory locks.",
			extendedInfo = "Advisory locks are not available in H2."
		);
	}

	/**
	 * Override Base adapter's function.
	 * When using H2, cfdbinfo incorrectly returns information_schema tables.
	 * To fix we create a new query result that excludes these tables.
	 * Yes, it should actually be "table_schem" below, not a typo.
	 */
	public query function $getColumns() {
		local.columns = super.$getColumns(argumentCollection = arguments);
		local.rv = QueryNew(local.columns.columnList);
		local.iEnd = local.columns.recordCount;
		for (local.i = 1; local.i <= local.iEnd; local.i++) {
			if (local.columns["table_schem"][local.i] != "information_schema") {
				QueryAddRow(local.rv);
				local.jEnd = ListLen(local.columns.columnList);
				for (local.j = 1; local.j <= local.jEnd; local.j++) {
					local.item = ListGetAt(local.columns.columnList, local.j);
					QuerySetCell(local.rv, local.item, local.columns[local.item][local.i]);
				}
			}
		}
		return local.rv;
	}

	/**
	 * Override Base adapter's function.
	 * When using H2, cfdbinfo does not return the primarykey flag
	 * We need to check the indexes and look for an index with a name starting with primary_key
	 */
	public query function $getColumnInfo(
		required string table,
		required string datasource,
		required string username,
		required string password
	) {
		arguments.type = "index";
		local.index = $dbinfo(argumentCollection = arguments);
		local.pkList = "";
		for (local.row in local.index) {
			if (Find('primary_key', local.row.INDEX_NAME)) {
				local.pkList = ListAppend(local.pkList, local.row.COLUMN_NAME);
			}
		}
		arguments.type = "columns";
		local.columns = $dbinfo(argumentCollection = arguments);
		for (local.i = 1; local.i <= local.columns.recordCount; local.i++) {
			if (ListFind(local.pkList, local.columns["COLUMN_NAME"][local.i])) {
				QuerySetCell(local.columns, "IS_PRIMARYKEY", "YES", local.i);
			}
		}

		return local.columns;
	}

	/**
	 * H2 upsert using single MERGE INTO with multi-row VALUES.
	 * H2 syntax: MERGE INTO t (cols) KEY (uniqueBy) VALUES (row1), (row2), ...
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

		// Build KEY clause.
		local.keyList = "";
		for (local.u in arguments.uniqueBy) {
			if (Len(local.keyList)) local.keyList &= ", ";
			local.keyList &= $quoteIdentifier(local.u);
		}

		ArrayAppend(local.sql, "MERGE INTO #arguments.tableName# (#local.colList#) KEY (#local.keyList#) VALUES ");

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

		return local.sql;
	}

}
