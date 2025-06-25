component extends="Abstract" {

	variables.sqlTypes = {};
	variables.sqlTypes['biginteger'] = {name = 'BIGINT'};
	variables.sqlTypes['binary'] = {name = 'BLOB'};
	variables.sqlTypes['boolean'] = {name = 'TINYINT', limit = 1};
	variables.sqlTypes['date'] = {name = 'DATE'};
	variables.sqlTypes['datetime'] = {name = 'TIMESTAMP'};
	variables.sqlTypes['decimal'] = {name = 'DECIMAL'};
	variables.sqlTypes['float'] = {name = 'DOUBLE'};
	variables.sqlTypes['integer'] = {name = 'INTEGER'};
	variables.sqlTypes['string'] = {name = 'VARCHAR', limit = 255};
	variables.sqlTypes['text'] = {name = 'CLOB'};
	variables.sqlTypes['time'] = {name = 'TIME'};
	variables.sqlTypes['timestamp'] = {name = 'TIMESTAMP'};
	variables.sqlTypes['uuid'] = {name = 'VARBINARY', limit = 16};

	/**
	 * name of database adapter
	 */
	public string function adapterName() {
		return "H2";
	}

	/**
	 * generates sql for primary key options on H2 Database
	 */
	public string function addPrimaryKeyOptions(required string sql, struct options = {}) {
		if (StructKeyExists(arguments.options, "null") && arguments.options.null) {
			arguments.sql = arguments.sql & " NULL";
		} else {
			arguments.sql = arguments.sql & " NOT NULL";
		}
		if (StructKeyExists(arguments.options, "autoIncrement") && arguments.options.autoIncrement) {
			arguments.sql = arguments.sql & " AUTO_INCREMENT";
		}
		return arguments.sql;
	}

	/**
	 * generates sql to create a table
	 */
	public string function createTable(
		required string name,
		required array columns,
		array primaryKeys = [],
		array foreignKeys = []
	) {
		local.sql = "CREATE TABLE #quoteTableName(arguments.name)# (#Chr(13)##Chr(10)#";
		local.iEnd = ArrayLen(arguments.primaryKeys);

		if (local.iEnd == 1) {
			// if we have a single primary key, define the column with the primaryKey adapter method
			local.sql = local.sql & " " & arguments.primaryKeys[1].toPrimaryKeySQL() & ",#Chr(13)##Chr(10)#";
		} else if (local.iEnd > 1) {
			// add the primary key columns like we would normal columns
			for (local.i = 1; local.i <= local.iEnd; local.i++) {
				local.sql = local.sql & " " & arguments.primaryKeys[local.i].toSQL();
				if (local.i != local.iEnd || ArrayLen(arguments.columns)) {
					local.sql = local.sql & ",#Chr(13)##Chr(10)#";
				}
			}
		}

		// define the columns in the sql
		local.iEnd = ArrayLen(arguments.columns);
		for (local.i = 1; local.i <= local.iEnd; local.i++) {
			local.sql = local.sql & " " & arguments.columns[local.i].toSQL();
			if (local.i != local.iEnd) {
				local.sql = local.sql & ",#Chr(13)##Chr(10)#";
			}
		}

		// H2 requires a constraint regardless of the number of primarykeys
		local.sql = local.sql & ",#Chr(13)##Chr(10)# " & primaryKeyConstraint(argumentCollection = arguments);

		// define the foreign keys
		local.iEnd = ArrayLen(arguments.foreignKeys);
		for (local.i = 1; local.i <= local.iEnd; local.i++) {
			local.sql = local.sql & ",#Chr(13)##Chr(10)# " & arguments.foreignKeys[local.i].toForeignKeySQL();
		}
		local.sql = local.sql & "#Chr(13)##Chr(10)#)";

		return local.sql;
	}

	/**
	 * surrounds table or index names with quotes (no quotes for H2)
	 */
	public any function quoteTableName(required string name) {
		return objectCase(arguments.name);
	}

	/**
	 * surrounds column names with quotes (no quotes for H2)
	 */
	public any function quoteColumnName(required string name) {
		return objectCase(arguments.name);
	}

	/**
	 * generates sql to rename a table
	 */
	public string function renameTable(required string oldName, required string newName) {
		return "ALTER TABLE #objectCase(arguments.oldName)# RENAME TO #objectCase(arguments.newName)#";
	}

	/**
	 * generates sql to rename an existing column in a table
	 */
	public string function renameColumnInTable(
		required string name,
		required string columnName,
		required string newColumnName
	) {
		return "ALTER TABLE #objectCase(arguments.name)# ALTER COLUMN #objectCase(arguments.columnName)# RENAME TO #objectCase(arguments.newColumnName)#";
	}

	/**
	 * generates sql to change an existing column in a table
	 */
	public string function changeColumnInTable(required string name, required any column) {
		return "ALTER TABLE #quoteTableName(objectCase(arguments.name))# ALTER COLUMN #arguments.column.toSQL()#";
	}

	/**
	 * generates sql to drop a foreign key constraint from a table
	 */
	public string function dropForeignKeyFromTable(required string name, required string keyName) {
		return "ALTER TABLE #quoteTableName(arguments.name)# DROP CONSTRAINT #objectCase(arguments.keyname)#";
	}

}
