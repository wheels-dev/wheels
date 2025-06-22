component extends="Abstract" {

	variables.sqlTypes = {};
	variables.sqlTypes['primaryKey'] = "int NOT NULL IDENTITY (1, 1)";
	variables.sqlTypes['binary'] = {name = 'IMAGE'};
	variables.sqlTypes['boolean'] = {name = 'BIT'};
	variables.sqlTypes['date'] = {name = 'date'};
	variables.sqlTypes['datetime'] = {name = 'DATETIME'};
	variables.sqlTypes['decimal'] = {name = 'DECIMAL'};
	variables.sqlTypes['float'] = {name = 'FLOAT'};
	variables.sqlTypes['integer'] = {name = 'INT'};
	variables.sqlTypes['string'] = {name = 'VARCHAR', limit = 255};
	variables.sqlTypes['text'] = {name = 'NVARCHAR', limit = "max"};
	variables.sqlTypes['time'] = {name = 'time'};
	variables.sqlTypes['timestamp'] = {name = 'timestamp'};
	variables.sqlTypes['uniqueidentifier'] = {name = 'UNIQUEIDENTIFIER'};
	variables.sqlTypes['char'] = {name = 'CHAR', limit = 10};

	public string function adapterName() {
		return "MicrosoftSQLServer";
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

	public string function addPrimaryKeyOptions(required string sql, struct options = "#StructNew()#") {
		if (StructKeyExists(arguments.options, "null") && arguments.options.null) {
			arguments.sql = arguments.sql & " NULL";
		} else {
			arguments.sql = arguments.sql & " NOT NULL";
		}
		if (StructKeyExists(arguments.options, "autoIncrement") && arguments.options.autoIncrement) {
			arguments.sql = arguments.sql & " IDENTITY(1,1)";
		}
		arguments.sql = arguments.sql & " PRIMARY KEY";
		return arguments.sql;
	}

	public string function primaryKeyConstraint(required string name, required array primaryKeys) {
		local.sql = "CONSTRAINT [PK_#arguments.name#] PRIMARY KEY CLUSTERED (";
		for (local.i = 1; local.i lte ArrayLen(arguments.primaryKeys); local.i++) {
			if (local.i != 1) {
				local.sql = local.sql & ", ";
			}
			local.sql = local.sql & arguments.primaryKeys[local.i].toColumnNameSQL() & " ASC";
		}
		local.sql = local.sql & ")";
		return local.sql;
	}

	/**
	 * Surrounds table names with square brackets
	 */
	public string function quoteTableName(required string name) {
		return "[#Replace(objectCase(arguments.name), ".", "`.`", "ALL")#]";
	}

	/**
	 * Surrounds column names with square brackets
	 */
	public string function quoteColumnName(required string name) {
		return "[#objectCase(arguments.name)#]";
	}

	/**
	 * generates sql to rename a table
	 */
	public string function renameTable(required string oldName, required string newName) {
		return "EXEC sp_rename '#objectCase(arguments.oldName)#', '#objectCase(arguments.newName)#'";
	}

	/**
	 * generates sql to drop a table
	 */
	public string function dropTable(required string name) {
		return "IF EXISTS(SELECT name FROM sysobjects WHERE name = N'#objectCase(arguments.name)#' AND xtype='U') DROP TABLE #quoteTableName(arguments.name)#";
	}

	/**
	 * generates sql to drop a view
	 */
	public string function dropView(required string name) {
		return "IF EXISTS(SELECT name FROM sysobjects WHERE name = N'#objectCase(arguments.name)#' AND xtype='V') DROP VIEW #quoteTableName(arguments.name)#";
	}

	/**
	 * generates sql to add a new column to a table
	 */
	public string function addColumnToTable(required string name, required any column) {
		return "ALTER TABLE #quoteTableName(arguments.name)# ADD #arguments.column.toSQL()#";
	}

	/**
	 * generates sql to change an existing column in a table
	 */
	public string function changeColumnInTable(required string name, required any column) {
		local.sql = "";
		for (local.i in ["default", "null", "afterColumn"]) {
			if (StructKeyExists(arguments.column, local.i)) {
				local.opts = {};
				local.opts.type = arguments.column.type;
				local.opts[local.i] = arguments.column[local.i];
				local.columnSQL = addColumnOptions(sql = "", options = local.opts, alter = true);
				if (local.i == "null") {
					local.sql = local.sql & "ALTER TABLE #quoteTableName(arguments.name)# ALTER COLUMN #objectCase(arguments.column.name)# #arguments.column.sqlType()# #local.columnSQL#;";
				} else if (local.i == "default") {
					// SQL server will throw an exception if a default constraint exists
					local.sql = local.sql & "ALTER TABLE #quoteTableName(arguments.name)# ADD CONSTRAINT DF_#objectCase(arguments.column.name)# #local.columnSQL# FOR #objectCase(arguments.column.name)#;";
				}
			}
		}
		return local.sql;
	}

	/**
	 * generates sql to rename an existing column in a table
	 */
	public string function renameColumnInTable(
		required string name,
		required string columnName,
		required string newColumnName
	) {
		return "EXEC sp_rename '#objectCase(arguments.name)#.#objectCase(arguments.columnName)#', '#objectCase(arguments.newColumnName)#'";
	}

	/**
	 * generates sql to drop a column from a table
	 */
	public string function dropColumnFromTable(required string name, required string columnName) {
		$removeCheckConstraints(arguments.name, arguments.columnName);
		$removeDefaultConstraint(arguments.name, arguments.columnName);
		$removeIndexes(arguments.name, arguments.columnName);
		return "ALTER TABLE #quoteTableName(arguments.name)# DROP COLUMN #quoteColumnName(arguments.columnName)#";
	}

	/**
	 * generates sql to add a foreign key constraint to a table
	 */
	public string function dropForeignKeyFromTable(required string name, required any keyName) {
		return "ALTER TABLE #quoteTableName(arguments.name)# DROP CONSTRAINT #objectCase(arguments.keyname)#";
	}

	/**
	 * generates sql to remove a database index
	 */
	public string function removeIndex(required string table, string indexName = "") {
		return "DROP INDEX #objectCase(arguments.table)#.#quoteColumnName(arguments.indexName)#";
	}

	private void function $removeCheckConstraints(required string name, required string columnName) {
		local.constraints = $query(
			datasource = application.wheels.dataSourceName,
			sql = "
				SELECT 	constraint_name
				FROM		information_schema.constraint_column_usage
				WHERE		table_name = '#objectCase(arguments.name)#'
				AND 		column_name = '#objectCase(arguments.columnName)#'
			"
		);
		for (local.row in local.constraints) {
			$execute("ALTER TABLE #quoteTableName(arguments.name)# DROP CONSTRAINT #local.row.constraint_name#");
		};
	}

	/**
	 * Removes default constraints on a given column.
	 */
	private void function $removeDefaultConstraint(required string name, required string columnName) {
		local.constraints = $query(
			datasource = application.wheels.dataSourceName,
			sql = "EXEC sp_helpconstraint #quoteTableName(arguments.name)#, 'nomsg'"
		);
		if (StructKeyExists(local, "constraints") && Val(local.constraints.RecordCount)) {
			local.defaults = $query(
				dbtype = "query",
				query = local.constraints,
				sql = "
					SELECT	*
					FROM	query
					WHERE	constraint_type = 'DEFAULT on column #objectCase(arguments.columnName)#'
				"
			);
			for (local.row in local.defaults) {
				$execute("ALTER TABLE #quoteTableName(arguments.name)# DROP CONSTRAINT #local.row.constraint_name#");
			};
		}
	}

	/**
	 * Removes all indexes on a given column
	 */
	private void function $removeIndexes(required string name, required string columnName) {
		// Based on info presented in `http://stackoverflow.com/questions/765867/list-of-all-index-index-columns-in-sql-server-db`
		local.indexes = $query(
			datasource = application.wheels.dataSourceName,
			sql = "
			SELECT
				t.name AS table_name,
				col.name AS column_name,
				ind.name AS index_name,
				ind.index_id,
				ic.index_column_id
			FROM
				sys.indexes ind
				INNER JOIN sys.index_columns ic
					ON ind.object_id = ic.object_id and ind.index_id = ic.index_id
				INNER JOIN sys.columns col
					ON ic.object_id = col.object_id and ic.column_id = col.column_id
				INNER JOIN sys.tables t
					ON ind.object_id = t.object_id
			WHERE
				t.name = '#objectCase(arguments.name)#'
				AND col.name = '#objectCase(arguments.columnName)#'
			"
		);
		for (local.row in local.indexes) {
			$execute(removeIndex(arguments.name, local.indexes.index_name));
		};
	}

	public string function typeToSQL(required string type, struct options = {}) {
		var sql = '';
		if (IsDefined("variables.sqlTypes") && StructKeyExists(variables.sqlTypes, arguments.type)) {
			if (IsStruct(variables.sqlTypes[arguments.type])) {
				sql = variables.sqlTypes[arguments.type]['name'];
				if (arguments.type == 'decimal') {
					if (
						!StructKeyExists(arguments.options, 'precision') && StructKeyExists(
							variables.sqlTypes[arguments.type],
							'precision'
						)
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
				} else if (arguments.type == 'integer') {
					if (StructKeyExists(arguments.options, 'limit')) {
						sql = sql;
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
	 * prepends sql server identity_insert on to allow inserting primary key values
	 */
	public string function addRecordPrefix(required string table) {
		return "SET IDENTITY_INSERT #quoteTableName(arguments.table)# ON";
	}

	/**
	 * appends sql server identity_insert on to disallow inserting primary key values
	 */
	public string function addRecordSuffix(required string table) {
		return "SET IDENTITY_INSERT #quoteTableName(arguments.table)# OFF";
	}

}
