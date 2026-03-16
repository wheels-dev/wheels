component extends="wheels.databaseAdapters.PostgreSQL.PostgreSQLMigrator" {

	/**
	 * name of database adapter
	 */
	public string function adapterName() {
		return "CockroachDB";
	}

	/**
	 * generates sql for primary key options
	 * CockroachDB does not support SERIAL; use INT DEFAULT unique_rowid() instead
	 */
	public string function addPrimaryKeyOptions(required string sql, struct options = {}) {
		if (StructKeyExists(arguments.options, "autoIncrement") && arguments.options.autoIncrement) {
			arguments.sql = ReplaceNoCase(arguments.sql, "INTEGER", "INT DEFAULT unique_rowid()", "all");
		}
		arguments.sql = arguments.sql & " PRIMARY KEY";
		return arguments.sql;
	}

}
