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
        required string primaryKey
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
	 * Default VALUES syntax (same as MySQL).
	 */
	public string function $defaultValues() {
		return " DEFAULT VALUES";
	}

}
