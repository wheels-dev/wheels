component extends="wheels.databaseAdapters.Base" output=false {

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

		switch (arguments.type) {
			case "bigint":
				local.rv = "cf_sql_bigint";
				break;
			case "binary":
			case "geometry":
			case "point":
			case "linestring":
			case "polygon":
			case "multipoint":
			case "multilinestring":
			case "multipolygon":
			case "geometrycollection":
				local.rv = "cf_sql_binary";
				break;
			case "bit":
			case "bool":
				local.rv = "cf_sql_bit";
				break;
			case "blob":
			case "tinyblob":
			case "mediumblob":
			case "longblob":
				local.rv = "cf_sql_blob";
				break;
			case "char":
				local.rv = "cf_sql_char";
				break;
			case "date":
				local.rv = "cf_sql_date";
				break;
			case "decimal":
				local.rv = "cf_sql_decimal";
				break;
			case "double":
				local.rv = "cf_sql_double";
				break;
			case "float":
				local.rv = "cf_sql_float";
				break;
			case "int":
			case "mediumint":
				local.rv = "cf_sql_integer";
				break;
			case "smallint":
			case "year":
				local.rv = "cf_sql_smallint";
				break;
			case "time":
				local.rv = "cf_sql_time";
				break;
			case "datetime":
			case "timestamp":
				local.rv = "cf_sql_timestamp";
				break;
			case "tinyint":
				local.rv = "cf_sql_tinyint";
				break;
			case "varbinary":
				local.rv = "cf_sql_varbinary";
				break;
			case "varchar":
			case "enum":
			case "set":
			case "tinytext":
				local.rv = "cf_sql_varchar";
				break;
			case "json":
			case "text":
			case "mediumtext":
			case "longtext":
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
		$moveAggregateToHaving(args = arguments);
		return $performQuery(argumentCollection = arguments);
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
		required struct propertyInfo,
		required any quoteFunc
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
