component extends="wheels.databaseAdapters.Abstract" {

	// SQLite type mapping (simpler type system)
	variables.sqlTypes = {};
	variables.sqlTypes['biginteger'] = { name = 'INTEGER' };
	variables.sqlTypes['binary'] = { name = 'BLOB' };
	variables.sqlTypes['boolean'] = { name = 'INTEGER' }; // SQLite has no real BOOLEAN type
	variables.sqlTypes['date'] = { name = 'TEXT' };
	variables.sqlTypes['datetime'] = { name = 'TEXT' };
	variables.sqlTypes['decimal'] = { name = 'REAL' };
	variables.sqlTypes['float'] = { name = 'REAL' };
	variables.sqlTypes['integer'] = { name = 'INTEGER' };
	variables.sqlTypes['string'] = { name = 'TEXT', limit = 255 };
	variables.sqlTypes['text'] = { name = 'TEXT' };
	variables.sqlTypes['mediumtext'] = { name = 'TEXT' };
	variables.sqlTypes['longtext'] = { name = 'TEXT' };
	variables.sqlTypes['time'] = { name = 'TEXT' };
	variables.sqlTypes['timestamp'] = { name = 'TEXT' };
	variables.sqlTypes['uuid'] = { name = 'TEXT', limit = 36 };

	/**
	 * name of database adapter
	 */
	public string function adapterName() {
		return "SQLite";
	}

	/**
	 * SQLite supports inline foreign key definitions
	 */
	public string function addForeignKeyOptions(required string sql, struct options = {}) {
		arguments.sql &= " REFERENCES " & arguments.options.referenceTable;
		if (StructKeyExists(arguments.options, "referenceColumn")) {
			arguments.sql &= " (" & arguments.options.referenceColumn & ")";
		}
		// Add ON DELETE / ON UPDATE if provided
		if (StructKeyExists(arguments.options, "onDelete")) {
			arguments.sql &= " ON DELETE " & arguments.options.onDelete;
		}
		if (StructKeyExists(arguments.options, "onUpdate")) {
			arguments.sql &= " ON UPDATE " & arguments.options.onUpdate;
		}
		return arguments.sql;
	}

	/**
	 * Generates SQL for primary key options.
	 * In SQLite, only INTEGER PRIMARY KEY is auto-incrementable.
	 */
	public string function addPrimaryKeyOptions(required string sql, struct options = {}) {
		arguments.sql &= " PRIMARY KEY";
		if (
			StructKeyExists(arguments.options, "autoIncrement") &&
			arguments.options.autoIncrement &&
			FindNoCase("INTEGER", arguments.sql)
		) {
			arguments.sql &= " AUTOINCREMENT";
		}
		return arguments.sql;
	}

	/**
	 * Surround table or index names with double quotes (SQLite standard).
	 */
	public string function quoteTableName(required string name) {
		return """#Replace(objectCase(arguments.name), ".", """.""", "ALL")#""";
	}

	/**
	 * Surround column names with double quotes.
	 */
	public string function quoteColumnName(required string name) {
		return """#objectCase(arguments.name)#""";
	}

	/**
	 * In SQLite, most types can have default values, except BLOB.
	 */
	public boolean function optionsIncludeDefault(string type, string default = "", boolean allowNull = true) {
		if (ListFindNoCase("blob", arguments.type)) {
			return false;
		}
		return true;
	}

	/**
	 * generates sql to rename a table
	 */
	public string function renameTable(required string oldName, required string newName) {
		return "ALTER TABLE #quoteTableName(arguments.oldName)# RENAME TO #quoteTableName(arguments.newName)#";
	}

	/**
	 * SQLite supports simple RENAME COLUMN syntax from version 3.25.0+.
	 */
	public string function renameColumnInTable(
		required string name,
		required string columnName,
		required string newColumnName
	) {
		return "ALTER TABLE #quoteTableName(arguments.name)# RENAME COLUMN #quoteColumnName(arguments.columnName)# TO #quoteColumnName(arguments.newColumnName)#";
	}

	/**
	 * Removes an index in SQLite.
	 */
	public string function removeIndex(required string table, string indexName = "") {
		return "DROP INDEX IF EXISTS #quoteTableName(arguments.indexName)#";
	}

}
