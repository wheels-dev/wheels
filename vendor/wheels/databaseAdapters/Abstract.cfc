component extends="wheels.migrator.Base"{

	/**
	 * generates sql for a column's data type definition
	 */
	public string function typeToSQL(required string type, struct options = {}) {
		var sql = '';
		if (IsDefined("variables.sqlTypes") && StructKeyExists(variables.sqlTypes, arguments.type)) {
			if (IsStruct(variables.sqlTypes[arguments.type])) {
				sql = variables.sqlTypes[arguments.type]['name'];
				if (arguments.type == 'decimal') {
					if (
						!StructKeyExists(arguments.options, 'precision')
						&& StructKeyExists(variables.sqlTypes[arguments.type], 'precision')
					) {
						arguments.options.precision = variables.sqlTypes[arguments.type]['precision'];
					}
					if (
						!StructKeyExists(arguments.options, 'scale') && StructKeyExists(variables.sqlTypes[arguments.type], 'scale')
					) {
						arguments.options.scale = variables.sqlTypes[arguments.type]['scale'];
					}
					if (StructKeyExists(arguments.options, 'precision')) {
						if (StructKeyExists(arguments.options, 'scale')) {
							sql = sql & '(#arguments.options.precision#,#arguments.options.scale#)';
						} else {
							sql = sql & '(#arguments.options.precision#)';
						}
					}
				} else {
					if (
						!StructKeyExists(arguments.options, 'limit') && StructKeyExists(variables.sqlTypes[arguments.type], 'limit')
					) {
						arguments.options.limit = variables.sqlTypes[arguments.type]['limit'];
					}
					if (StructKeyExists(arguments.options, 'limit')) {
						sql = sql & '(#arguments.options.limit#)';
					}
				}
			} else {
				sql = variables.sqlTypes[arguments.type];
			}
		}
		return sql;
	}

	/**
	 * throw an exception for adapters without its own addPrimaryKeyOptions implementation
	 */
	public string function addPrimaryKeyOptions() {
		Throw(message = "The `addPrimaryKeyOptions` must be implemented in the storage specific adapter.");
	}

	/**
	 * generates sql for a primary key constraint
	 */
	public string function primaryKeyConstraint(required string name, required array primaryKeys) {
		local.sql = "PRIMARY KEY (";
		for (local.i = 1; local.i lte ArrayLen(arguments.primaryKeys); local.i++) {
			if (local.i != 1) {
				local.sql = local.sql & ", ";
			}
			local.sql = local.sql & arguments.primaryKeys[local.i].toColumnNameSQL();
		}
		local.sql = local.sql & ")";
		return local.sql;
	}

	/**
	 * generates sql for column options
	 */
	public string function addColumnOptions(required string sql, struct options = "#StructNew()#") {
		if (StructKeyExists(arguments.options, 'type') && arguments.options.type != 'primaryKey') {
			if (StructKeyExists(arguments.options, 'default') && optionsIncludeDefault(argumentCollection = arguments.options)) {
				if (
					arguments.options.default eq "NULL"
					|| (
						arguments.options.default eq ""
						&& ListFindNoCase("boolean,date,datetime,time,timestamp,decimal,float,integer", arguments.options.type)
					)
				) {
					arguments.sql = arguments.sql & " DEFAULT NULL";
				} else if (arguments.options.type == 'boolean') {
					arguments.sql = arguments.sql & " DEFAULT #IIf(arguments.options.default, 1, 0)#";
				} else if (arguments.options.type == 'string' && arguments.options.default eq "") {
					arguments.sql = arguments.sql;
				} else {
					arguments.sql = arguments.sql & " DEFAULT #quote(value = arguments.options.default, options = arguments.options)#";
				}
			}
			if (StructKeyExists(arguments.options, 'allowNull')) {
				if (arguments.options.allowNull) {
					arguments.sql = arguments.sql & " NULL";
				} else {
					arguments.sql = arguments.sql & " NOT NULL";
				}
			}
		}
		if (StructKeyExists(arguments.options, "afterColumn") And Len(Trim(arguments.options.afterColumn)) GT 0) {
			arguments.sql = arguments.sql & " AFTER #arguments.options.afterColumn#";
		}
		return arguments.sql;
	}

	// what's the purpose of this?
	public boolean function optionsIncludeDefault(string type, string default = "", boolean allowNull = true) {
		return true;
	}

	/**
	 * quote value if required
	 */
	public string function quote(required string value, struct options = {}) {
		if (ListFindNoCase("CURRENT_TIMESTAMP", arguments.value)) {
			return arguments.value;
		}
		if (
			StructKeyExists(arguments.options, 'type') && ListFindNoCase(
				"binary,date,datetime,time,timestamp",
				arguments.options.type
			)
		) {
			arguments.value = "'#arguments.value#'";
		} else if (StructKeyExists(arguments.options, 'type') && ListFindNoCase("text,string", arguments.options.type)) {
			arguments.value = "'#ReplaceNoCase(arguments.value, "'", "''")#'";
		}
		return arguments.value;
	}

	/**
	 * surrounds table or index names with quotes
	 */
	public string function quoteTableName(required string name) {
		return "'#Replace(objectCase(arguments.name), ".", "`.`", "ALL")#'";
	}

	/**
	 * surrounds column names with quotes
	 */
	public string function quoteColumnName(required string name) {
		return "'#objectCase(arguments.name)#'";
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

		// if we have multiple primarykeys the adapter might need to add a constraint here
		if (ArrayLen(arguments.primaryKeys) > 1) {
			local.sql = local.sql & ",#Chr(13)##Chr(10)# " & primaryKeyConstraint(argumentCollection = arguments);
		}

		// define the foreign keys
		local.iEnd = ArrayLen(arguments.foreignKeys);
		for (local.i = 1; local.i <= local.iEnd; local.i++) {
			local.sql = local.sql & ",#Chr(13)##Chr(10)# " & arguments.foreignKeys[local.i].toForeignKeySQL();
		}
		local.sql = local.sql & "#Chr(13)##Chr(10)#)";
		return local.sql;
	}

	/**
	 * generates sql to rename a table
	 */
	public string function renameTable(required string oldName, required string newName) {
		return "ALTER TABLE #quoteTableName(arguments.oldName)# RENAME #quoteTableName(arguments.newName)#";
	}

	/**
	 * generates sql to drop a table
	 */
	public string function dropTable(required string name) {
		return "DROP TABLE IF EXISTS #quoteTableName(objectCase(arguments.name))#";
	}

	/**
	 * generates sql to add a new column to a table
	 */
	public string function addColumnToTable(required string name, required any column) {
		return "ALTER TABLE #quoteTableName(objectCase(arguments.name))# ADD COLUMN #arguments.column.toSQL()#";
	}

	/**
	 * generates sql to change an existing column in a table
	 */
	public string function changeColumnInTable(required string name, required any column) {
		return "ALTER TABLE #quoteTableName(objectCase(arguments.name))# CHANGE #quoteColumnName(arguments.column.name)# #arguments.column.toSQL()#";
	}

	/**
	 * generates sql to rename an existing column in a table
	 */
	public string function renameColumnInTable(
		required string name,
		required string columnName,
		required string newColumnName
	) {
		return "ALTER TABLE #quoteTableName(objectCase(arguments.name))# RENAME COLUMN #quoteColumnName(arguments.columnName)# TO #quoteColumnName(arguments.newColumnName)#";
	}

	/**
	 * generates sql to drop a column from a table
	 */
	public string function dropColumnFromTable(required string name, required string columnName) {
		return "ALTER TABLE #quoteTableName(objectCase(arguments.name))# DROP COLUMN #quoteColumnName(arguments.columnName)#";
	}

	/**
	 * generates sql to add a foreign key constraint to a table
	 */
	public string function addForeignKeyToTable(required string name, required any foreignKey) {
		return "ALTER TABLE #quoteTableName(objectCase(arguments.name))# ADD #arguments.foreignKey.toSQL()#";
	}

	/**
	 * generates sql to drop a foreign key constraint from a table
	 */
	public string function dropForeignKeyFromTable(required string name, required string keyName) {
		return "ALTER TABLE #quoteTableName(objectCase(arguments.name))# DROP FOREIGN KEY #quoteTableName(arguments.keyname)#";
	}

	/**
	 * generates sql for foreign key constraint
	 */
	public string function foreignKeySQL(
		required string name,
		required string table,
		required string referenceTable,
		required string column,
		required string referenceColumn,
		string onUpdate = "",
		string onDelete = ""
	) {
		local.sql = "CONSTRAINT #quoteTableName(arguments.name)# FOREIGN KEY (#quoteColumnName(arguments.column)#) REFERENCES #objectCase(arguments.referenceTable)#(#quoteColumnName(arguments.referenceColumn)#)";
		for (local.item in ListToArray("onUpdate,onDelete")) {
			if (Len(arguments[local.item])) {
				switch (arguments[local.item]) {
					case "none":
						local.sql = local.sql & " " & UCase(humanize(local.item)) & " NO ACTION";
						break;
					case "null":
						local.sql = local.sql & " " & UCase(humanize(local.item)) & " SET NULL";
						break;
					default:
						local.sql = local.sql & " " & UCase(humanize(local.item)) & " CASCADE";
						break;
				}
			}
		}
		return local.sql;
	}

	/**
	 * generates sql to add database index on a table column
	 */
	public string function addIndex(
		required string table,
		string columnNames,
		boolean unique = false,
		string indexName = "#objectCase(arguments.table)#_#ListFirst(arguments.columnNames)#"
	) {
		$combineArguments(args = arguments, combine = "columnNames,columnName", required = true);
		var sql = "CREATE ";
		if (arguments.unique) {
			sql = sql & "UNIQUE ";
		}
		sql = sql & "INDEX #quoteTableName(arguments.indexName)# ON #quoteTableName(arguments.table)#(";

		local.columnNamesArray = ListToArray(arguments.columnNames);
		local.iEnd = ArrayLen(local.columnNamesArray);
		for (local.i = 1; local.i <= local.iEnd; local.i++) {
			sql = sql & quoteColumnName(local.columnNamesArray[local.i]);
			if (local.i != local.iEnd) {
				sql = sql & ",";
			}
		}
		sql = sql & ")";
		return sql;
	}

	/**
	 * generates sql to remove a database index
	 */
	public any function removeIndex(required string table, string indexName = "") {
		return "DROP INDEX #quoteTableName(arguments.indexName)#";
	}

	/**
	 * generates sql to create a view
	 */
	public string function createView(required string name, required string sql) {
		return "CREATE VIEW #quoteTableName(arguments.name)# AS " & arguments.sql;
	}

	/**
	 * generates sql to drop a view
	 */
	public string function dropView(required string name) {
		return "DROP VIEW IF EXISTS #quoteTableName(arguments.name)#";
	}

	public string function addRecordPrefix() {
		return "";
	}

	public string function addRecordSuffix() {
		return "";
	}

}
