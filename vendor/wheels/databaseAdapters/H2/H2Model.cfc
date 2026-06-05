component extends="wheels.databaseAdapters.Base" output=false {

	/**
	 * H2 reports unquoted identifiers in uppercase, so lowercase auto-derived
	 * property names — otherwise models expose `FIRSTNAME` instead of
	 * `firstname`. See Base.$lowerCaseColumnNames().
	 */
	public boolean function $lowerCaseColumnNames() {
		return true;
	}

	/**
	 * Map database types to the ones used in CFML.
	 */
	public string function $getType(required string type, string scale, string details) {
		switch (arguments.type) {
			case "bigint":
			case "int8":
				local.rv = "cf_sql_bigint";
				break;
			case "binary":
			case "bytea":
			case "raw":
			case "binary varying":
				local.rv = "cf_sql_binary";
				break;
			case "bit":
			case "bool":
			case "boolean":
				local.rv = "cf_sql_bit";
				break;
			case "binary large object":
			case "blob":
			case "tinyblob":
			case "mediumblob":
			case "longblob":
			case "image":
			case "oid":
				local.rv = "cf_sql_blob";
				break;
			case "char":
			case "character":
			case "nchar":
			case "UUID":
				local.rv = "cf_sql_char";
				break;
			case "date":
				local.rv = "cf_sql_date";
				break;
			case "dec":
			case "decimal":
			case "number":
			case "numeric":
				local.rv = "cf_sql_decimal";
				break;
			case "double":
			case "double precision":
				local.rv = "cf_sql_double";
				break;
			case "float":
			case "float4":
			case "float8":
			case "real":
				local.rv = "cf_sql_float";
				break;
			case "int":
			case "int4":
			case "integer":
			case "mediumint":
			case "signed":
			case "identity":
				local.rv = "cf_sql_integer";
				break;
			case "int2":
			case "smallint":
			case "year":
				local.rv = "cf_sql_smallint";
				break;
			case "time":
				local.rv = "cf_sql_time";
				break;
			case "datetime":
			case "smalldatetime":
			case "timestamp":
				local.rv = "cf_sql_timestamp";
				break;
			case "tinyint":
				local.rv = "cf_sql_tinyint";
				break;
			case "varbinary":
			case "longvarbinary":
				local.rv = "cf_sql_varbinary";
				break;
			case "varchar":
			case "varchar2":
			case "longvarchar":
			case "varchar_ignorecase":
			case "nvarchar":
			case "nvarchar2":
			case "clob":
			case "nclob":
			case "text":
			case "tinytext":
			case "mediumtext":
			case "longtext":
			case "ntext":
			case "enum":
			case "character varying":
			case "character large object":
				local.rv = "cf_sql_varchar";
				break;
			case "nvarchar_casesensitive":
				local.rv = "cf_sql_nvarchar";
				break;
			case "json":
				local.rv = "cf_sql_longvarchar";
				break;
		}
		return local.rv;
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
		pkList = "";
		for (row in local.index) {
			if (Find('primary_key', row.INDEX_NAME)) {
				pkList = ListAppend(pkList, row.COLUMN_NAME);
			}
		}
		arguments.type = "columns";
		local.columns = $dbinfo(argumentCollection = arguments);
		for (local.i = 1; i <= local.columns.recordCount; i++) {
			if (ListFind(pkList, local.columns["COLUMN_NAME"][i])) {
				QuerySetCell(local.columns, "IS_PRIMARYKEY", "YES", i);
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
