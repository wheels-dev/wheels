component extends="../Abstract" {

	variables.sqlTypes = {};
	variables.sqlTypes['biginteger'] = {name = 'BIGINT UNSIGNED'};
	variables.sqlTypes['binary'] = {name = 'BLOB'};
	variables.sqlTypes['boolean'] = {name = 'TINYINT', limit = 1};
	variables.sqlTypes['date'] = {name = 'DATE'};
	variables.sqlTypes['datetime'] = {name = 'DATETIME'};
	variables.sqlTypes['decimal'] = {name = 'DECIMAL'};
	variables.sqlTypes['float'] = {name = 'FLOAT'};
	variables.sqlTypes['integer'] = {name = 'INT'};
	variables.sqlTypes['string'] = {name = 'VARCHAR', limit = 255};
	variables.sqlTypes['text'] = {name = 'TEXT'};
	variables.sqlTypes['mediumtext'] = {name = 'MEDIUMTEXT'};
	variables.sqlTypes['longtext'] = {name = 'LONGTEXT'};
	variables.sqlTypes['time'] = {name = 'TIME'};
	variables.sqlTypes['timestamp'] = {name = 'TIMESTAMP'};
	variables.sqlTypes['uuid'] = {name = 'VARBINARY', limit = 16};

	/**
	 * name of database adapter
	 */
	public string function adapterName() {
		return "MySQL";
	}

	public string function addForeignKeyOptions(required string sql, struct options = {}) {
		arguments.sql = arguments.sql & " FOREIGN KEY (" & arguments.options.column & ")";
		if (StructKeyExists(arguments.options, "referenceTable")) {
			if (StructKeyExists(arguments.options, "referenceColumn")) {
				arguments.sql = arguments.sql & " REFERENCES ";
				arguments.sql = arguments.sql & arguments.options.referenceTable;
				arguments.sql = arguments.sql & " (" & arguments.options.referenceColumn & ")";
			}
		}
		return arguments.sql;
	}

	/**
	 * generates sql for primary key options
	 */
	public string function addPrimaryKeyOptions(required string sql, struct options = {}) {
		if (StructKeyExists(arguments.options, "allowNull") && arguments.options.allowNull) {
			arguments.sql = arguments.sql & " NULL";
		} else {
			arguments.sql = arguments.sql & " NOT NULL";
		}
		if (StructKeyExists(arguments.options, "autoIncrement") && arguments.options.autoIncrement) {
			arguments.sql = arguments.sql & " AUTO_INCREMENT";
		}
		arguments.sql = arguments.sql & " PRIMARY KEY";
		return arguments.sql;
	}

	/**
	 * surrounds table or index names with backticks
	 */
	public string function quoteTableName(required string name) {
		return "`#Replace(objectCase(arguments.name), ".", "`.`", "ALL")#`";
	}

	/**
	 * surrounds column names with backticks
	 */
	public string function quoteColumnName(required string name) {
		return "`#objectCase(arguments.name)#`";
	}

	/**
	 * MySQL text fields can't have default
	 */
	public boolean function optionsIncludeDefault(string type, string default = "", boolean allowNull = true) {
		if (ListFindNoCase("text,mediumtext,longtext,float", arguments.type)) {
			return false;
		} else {
			return true;
		}
	}

	/**
	 * generates sql to rename an existing column in a table
	 * MySQL can't use rename column, need to recreate column definition and use change instead
	 */
	public string function renameColumnInTable(
		required string name,
		required string columnName,
		required string newColumnName
	) {
		return "ALTER TABLE #quoteTableName(arguments.name)# CHANGE COLUMN #quoteColumnName(arguments.columnName)# #quoteColumnName(arguments.newColumnName)# #$getColumnDefinition(tableName = arguments.name, columnName = arguments.columnName)#";
	}

	/**
	 * generates sql to remove a database index
	 * MySQL requires table name as well as index name
	 */
	public string function removeIndex(required string table, string indexName = "") {
		return "DROP INDEX #quoteTableName(arguments.indexName)# ON #quoteTableName(arguments.table)#";
	}

}
