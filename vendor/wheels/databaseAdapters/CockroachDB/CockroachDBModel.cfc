component extends="wheels.databaseAdapters.PostgreSQL.PostgreSQLModel" output=false {

	/**
	 * Override PostgreSQL's $identitySelect which uses pg_get_serial_sequence() and currval().
	 * CockroachDB doesn't support these functions. Since CockroachDB's unique_rowid() generates
	 * monotonically increasing values, we use a MAX-based query (similar to the Oracle adapter).
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
			local.columnList = "";
			if (local.endPar) {
				local.rawColumns = Mid(local.sql, local.startPar, (local.endPar - local.startPar));

				// BoxLang compatibility fix - ReplaceList behaves differently
				if (StructKeyExists(server, "boxlang")) {
					local.columnList = REReplace(local.rawColumns, "\s*,\s*", ",", "all");
					local.columnList = REReplace(local.columnList, "[\r\n]", "", "all");
					local.columnList = Trim(local.columnList);
				} else {
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
				// Strip identifier quotes that may have been added by $quoteIdentifier
				local.tbl = ReReplace(local.tbl, '^"|"$', "", "all");
				query = $query(
					sql = "SELECT max(#arguments.primaryKey#) AS lastId FROM #local.tbl#",
					argumentCollection = arguments.queryAttributes
				);
				local.rv[$generatedKey()] = query.lastId;
				return local.rv;
			}
		}
	}

	/**
	 * Map database types to the ones used in CFML.
	 * CockroachDB requires cf_sql_boolean for boolean columns instead of cf_sql_bit,
	 * as it enforces strict type checking and rejects boolean-to-bit/integer comparisons.
	 */
	public string function $getType(required string type, string scale, string details) {
		switch (arguments.type) {
			case "bool":
			case "boolean":
				local.rv = "cf_sql_boolean";
				break;
			case "bit":
			case "varbit":
				local.rv = "cf_sql_bit";
				break;
			default:
				local.rv = super.$getType(argumentCollection = arguments);
				break;
		}
		return local.rv;
	}

}
