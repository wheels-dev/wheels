component extends="Base" output=false {

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
			case "number":
				local.rv = "cf_sql_numeric";
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
	 * Call functions to make adapter specific changes to arguments before executing query.
	 */
	public struct function $querySetup(
		required array sql,
		numeric limit = 0,
		numeric offset = 0,
		required boolean parameterize,
		string $primaryKey = ""
	) {
		$removeColumnAliasesInOrderClause(args = arguments);
		$addColumnsToSelectAndGroupBy(args = arguments);

		// Oracle DB doesn't support limit and offset in SQL.
		StructDelete(arguments, "limit");
		StructDelete(arguments, "offset");

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
		required string primaryKey
	) {
		var query = {};
		local.sql = Trim(arguments.result.sql);
		if (Left(local.sql, 11) == "INSERT INTO" && !StructKeyExists(arguments.result, $generatedKey())) {
			local.startPar = Find("(", local.sql) + 1;
			local.endPar = Find(")", local.sql);
			local.columnList = ReplaceList(
				Mid(local.sql, local.startPar, (local.endPar - local.startPar)),
				"#Chr(10)#,#Chr(13)#, ",
				",,"
			);
			if (!ListFindNoCase(local.columnList, ListFirst(arguments.primaryKey))) {
				local.rv = {};
				local.tbl = SpanExcluding(Right(local.sql, Len(local.sql) - 12), " ");
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
		return "() VALUES()";
	}

	/**
	 * Set a default for the table alias string (e.g. "users AS users2").
	 * Individual database adapters will override when necessary.
	 */
	public string function $tableAlias(required string table, required string alias) {
		return arguments.table & " " & arguments.alias;
	}


}
