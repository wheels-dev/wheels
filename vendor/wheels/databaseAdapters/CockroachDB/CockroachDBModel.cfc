component extends="wheels.databaseAdapters.PostgreSQL.PostgreSQLModel" output=false {

	/**
	 * Map database types to the ones used in CFML.
	 * CockroachDB uses the PostgreSQL wire protocol but may report native type names
	 * in JDBC metadata (e.g. STRING instead of varchar, BYTES instead of bytea).
	 * Types not explicitly handled here delegate to the PostgreSQL adapter.
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
			case "string":
				local.rv = "cf_sql_varchar";
				break;
			case "bytes":
				local.rv = "cf_sql_binary";
				break;
			case "int":
			case "int4":
			case "integer":
			case "serial":
			case "int64":
				local.rv = "cf_sql_bigint";
				break;
			case "interval":
				local.rv = "cf_sql_varchar";
				break;
			case "geometry":
				local.rv = "cf_sql_other";
				break;
			default:
				local.rv = super.$getType(argumentCollection = arguments);
				break;
		}
		return local.rv;
	}

	/**
	 * Override query setup to append RETURNING clause to INSERTs.
	 * CockroachDB does not support pg_get_serial_sequence()/currval(),
	 * so the RETURNING clause is the correct way to retrieve generated keys.
	 */
	public struct function $querySetup(
		required array sql,
		numeric limit = 0,
		numeric offset = 0,
		required boolean parameterize,
		string $primaryKey = ""
	) {
		if (Left(arguments.sql[1], 11) == "INSERT INTO") {
			ArrayAppend(arguments.sql, "RETURNING #arguments.$primaryKey#");
		}
		$convertMaxRowsToLimit(args = arguments);
		$removeColumnAliasesInOrderClause(args = arguments);
		$addColumnsToSelectAndGroupBy(args = arguments);
		$moveAggregateToHaving(args = arguments);
		return $performQuery(argumentCollection = arguments);
	}

	/**
	 * Override generated key name.
	 */
	public string function $generatedKey() {
		return "lastId";
	}

	/**
	 * Retrieve the last inserted primary key value.
	 * Tries multiple strategies: result.generatedKey (Lucee), result.query (ACF),
	 * and the returningIdentity query result from the RETURNING clause.
	 */
	public any function $identitySelect(
		required struct queryAttributes,
		required struct result,
		required string primaryKey,
		any returningIdentity = ""
	) {
		var query = {};
		local.sql = Trim(arguments.result.sql);
		if (Left(local.sql, 11) != "INSERT INTO") {
			return;
		}
		// If the engine already populated the generated key (e.g. Lucee's result.lastId), return it
		if (StructKeyExists(arguments.result, $generatedKey()) && Len(arguments.result[$generatedKey()])) {
			local.rv = {};
			local.rv[$generatedKey()] = arguments.result[$generatedKey()];
			return local.rv;
		}

		local.startPar = Find("(", local.sql) + 1;
		local.endPar = Find(")", local.sql);
		local.columnList = "";
		if (local.endPar) {
			local.rawColumns = Mid(local.sql, local.startPar, (local.endPar - local.startPar));
			if (StructKeyExists(server, "boxlang")) {
				local.columnList = REReplace(local.rawColumns, "\s*,\s*", ",", "all");
				local.columnList = REReplace(local.columnList, "[\r\n]", "", "all");
				local.columnList = Trim(local.columnList);
			} else {
				local.columnList = ReplaceList(local.rawColumns, "#Chr(10)#,#Chr(13)#, ", ",,");
			}
		}

		// Strip identifier quotes for comparison
		local.columnList = $stripIdentifierQuotes(local.columnList);

		if (!ListFindNoCase(local.columnList, ListFirst(arguments.primaryKey))) {
			local.rv = {};
			if (StructKeyExists(arguments.result, "generatedKey")) {
				query.id = ListFirst(arguments.result.generatedKey);
			} else if (IsQuery(arguments.returningIdentity) && arguments.returningIdentity.recordCount) {
				query.id = arguments.returningIdentity[arguments.primaryKey][1];
			}
			if (StructKeyExists(query, "id")) {
				local.rv[$generatedKey()] = query.id;
				return local.rv;
			}
		}
	}

}
