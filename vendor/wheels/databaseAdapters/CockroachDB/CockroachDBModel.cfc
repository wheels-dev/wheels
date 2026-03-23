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

}
