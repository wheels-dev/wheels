component extends="wheels.databaseAdapters.PostgreSQL.PostgreSQLModel" output=false {

	/**
	 * Map database types to the ones used in CFML.
	 * CockroachDB requires cf_sql_boolean for boolean columns instead of cf_sql_bit,
	 * as it enforces strict type checking and rejects boolean-to-bit/integer comparisons.
	 *
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
	 * Override PostgreSQL's $identitySelect for CockroachDB compatibility.
	 *
	 * PostgreSQL's implementation uses pg_get_serial_sequence() + currval() to retrieve the last
	 * inserted identity value. This works for SERIAL columns (which use sequences internally) but
	 * fails for CockroachDB's unique_rowid() default, which has no underlying sequence.
	 *
	 * This override checks whether the column is backed by a sequence before calling currval().
	 * For unique_rowid() columns, we return void and let the JDBC driver's generated key handling
	 * provide the value (if available).
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

				// Check if the column is backed by a sequence (SERIAL columns).
				// unique_rowid() columns have no sequence, so pg_get_serial_sequence returns NULL.
				try {
					local.seqQuery = $query(
						sql = "SELECT pg_get_serial_sequence('#local.tbl#', '#arguments.primaryKey#') AS seq_name",
						argumentCollection = arguments.queryAttributes
					);
					if (
						IsQuery(local.seqQuery)
						&& local.seqQuery.recordCount
						&& Len(Trim(local.seqQuery.seq_name))
					) {
						query = $query(
							sql = "SELECT currval('#local.seqQuery.seq_name#') AS lastId",
							argumentCollection = arguments.queryAttributes
						);
						local.rv[$generatedKey()] = query.lastId;
						return local.rv;
					}
				} catch (any e) {
					// If sequence lookup fails, fall through gracefully
				}

				// For unique_rowid() columns (no sequence), the JDBC driver should have
				// returned the generated key already. If it didn't, we cannot retrieve it
				// after the fact — return void so the caller handles missing keys gracefully.
			}
		}
	}

}
