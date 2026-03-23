component extends="wheels.databaseAdapters.PostgreSQL.PostgreSQLMigrator" {

	variables.sqlTypes = {};
	variables.sqlTypes['biginteger'] = {name = 'INT8'};
	variables.sqlTypes['binary'] = {name = 'BYTES'};
	variables.sqlTypes['boolean'] = {name = 'BOOL'};
	variables.sqlTypes['date'] = {name = 'DATE'};
	variables.sqlTypes['datetime'] = {name = 'TIMESTAMP'};
	variables.sqlTypes['decimal'] = {name = 'DECIMAL'};
	variables.sqlTypes['float'] = {name = 'FLOAT8'};
	variables.sqlTypes['integer'] = {name = 'INT'};
	variables.sqlTypes['string'] = {name = 'STRING', limit = 255};
	variables.sqlTypes['text'] = {name = 'STRING'};
	variables.sqlTypes['time'] = {name = 'TIME'};
	variables.sqlTypes['timestamp'] = {name = 'TIMESTAMP'};
	variables.sqlTypes['uuid'] = {name = 'UUID'};

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
			arguments.sql = REReplace(arguments.sql, "\bINT\b", "INT DEFAULT unique_rowid()");
		}
		arguments.sql = arguments.sql & " PRIMARY KEY";
		return arguments.sql;
	}

}
