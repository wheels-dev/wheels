component extends="wheels.databaseAdapters.PostgreSQL.PostgreSQLModel" output=false {

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
