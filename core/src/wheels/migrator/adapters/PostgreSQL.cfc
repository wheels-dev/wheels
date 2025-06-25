component extends="Abstract" {

	variables.sqlTypes = {};
	variables.sqlTypes['binary'] = {name = 'BYTEA'};
	variables.sqlTypes['boolean'] = {name = 'BOOLEAN'};
	variables.sqlTypes['date'] = {name = 'DATE'};
	variables.sqlTypes['datetime'] = {name = 'TIMESTAMP'};
	variables.sqlTypes['decimal'] = {name = 'DECIMAL'};
	variables.sqlTypes['float'] = {name = 'FLOAT'};
	variables.sqlTypes['integer'] = {name = 'INTEGER'};
	variables.sqlTypes['string'] = {name = 'VARCHAR', limit = 255};
	variables.sqlTypes['text'] = {name = 'TEXT'};
	variables.sqlTypes['time'] = {name = 'TIME'};
	variables.sqlTypes['timestamp'] = {name = 'TIMESTAMP'};

	/**
	 * name of database adapter
	 */
	public string function adapterName() {
		return "PostgreSQL";
	}

	/**
	 * generates sql for primary key options
	 */
	public string function addPrimaryKeyOptions(required string sql, struct options = {}) {
		if (StructKeyExists(arguments.options, "autoIncrement") && arguments.options.autoIncrement) {
			arguments.sql = ReplaceNoCase(arguments.sql, "INTEGER", "SERIAL", "all");
		}
		arguments.sql = arguments.sql & " PRIMARY KEY";
		return arguments.sql;
	}

	/**
	 * PostgreSQL alter column statements use extended SQL
	 */
	public string function addColumnOptions(
		required string sql,
		struct options = "#StructNew()#",
		boolean alter = "false"
	) {
		if (StructKeyExists(arguments.options, 'type') && arguments.options.type != 'primaryKey') {
			if (StructKeyExists(arguments.options, 'default') && optionsIncludeDefault(argumentCollection = arguments.options)) {
				if (arguments.alter) {
					arguments.sql = arguments.sql & " SET";
				}
				if (
					arguments.options.default == "NULL"
					|| (
						arguments.options.default == ""
						&& ListFindNoCase("boolean,date,datetime,time,timestamp,decimal,float,integer", arguments.options.type)
					)
				) {
					arguments.sql = arguments.sql & " DEFAULT NULL";
				} else if (arguments.options.type == 'boolean') {
					arguments.sql = arguments.sql & " DEFAULT #IIf(arguments.options.default, true, false)#";
				} else if (arguments.options.type == 'string' && arguments.options.default eq "") {
					arguments.sql = arguments.sql & "DEFAULT ''";
				} else {
					arguments.sql = arguments.sql & " DEFAULT #quote(value = arguments.options.default, options = arguments.options)#";
				}
			}
			if (StructKeyExists(arguments.options, 'null')) {
				if (arguments.alter) {
					if (arguments.options.null) {
						arguments.sql = arguments.sql & " DROP NOT NULL";
					} else {
						arguments.sql = arguments.sql & " SET NOT NULL";
					}
				} else if (!arguments.options.null) {
					arguments.sql = arguments.sql & " NOT NULL";
				}
			}
		}
		if (StructKeyExists(arguments.options, "afterColumn") && Len(Trim(arguments.options.afterColumn)) GT 0) {
			arguments.sql = arguments.sql & " AFTER #arguments.options.afterColumn#";
		}
		return arguments.sql;
	}

	/**
	 * Don't quote tables
	 */
	public string function quoteTableName(required string name) {
		return objectCase(arguments.name);
	}

	/**
	 * Don't quote columns
	 */
	public string function quoteColumnName(required string name) {
		return objectCase(arguments.name);
	}

	/**
	 * generates sql to rename a table
	 */
	public string function renameTable(required string oldName, required string newName) {
		return "ALTER TABLE #quoteTableName(arguments.oldName)# RENAME TO #quoteTableName(arguments.newName)#";
	}

	/**
	 * generates sql to change an existing column in a table
	 * NOTE FOR addColumnToTable & changeColumnInTable
	 * Rails adaptor appears to be applying default/nulls in separate queries
	 */
	public string function changeColumnInTable(required string name, required any column) {
		for (local.i in ["default", "null", "afterColumn"]) {
			if (StructKeyExists(arguments.column, local.i)) {
				local.opts = {};
				local.opts.type = arguments.column.type;
				local.opts[local.i] = arguments.column[local.i];
				local.columnSQL = addColumnOptions(
					sql = " ALTER COLUMN #arguments.column.name#",
					options = local.opts,
					alter = true
				);
				if (!StructKeyExists(local, "sql")) {
					local.sql = "ALTER TABLE #quoteTableName(objectCase(arguments.name))# ALTER COLUMN #objectCase(arguments.column.name)# TYPE #arguments.column.sqlType()#";
				}
				if (Len(arguments.column[local.i])) {
					local.sql = ListAppend(local.sql, local.columnSQL, ",#Chr(13)##Chr(10)#");
				}
			}
		}
		return local.sql;
	}

	/**
	 * generates sql to add a foreign key constraint to a table
	 */
	public string function dropForeignKeyFromTable(required string name, required any keyName) {
		return "ALTER TABLE #quoteTableName(objectCase(arguments.name))# DROP CONSTRAINT #quoteTableName(arguments.keyname)#";
	}

}
