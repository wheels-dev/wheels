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
	 * Internal function. The SQL default expression that generates a UUID for a
	 * uniqueidentifier column whose default is SQL Server's `newid()` (#4094). Each
	 * adapter sets `variables.uuidDefaultSQL`; SQL Server keeps `newid()`. Returns ""
	 * when the server is too old to generate one in a default, so the column is
	 * created without a default instead of with DDL the server rejects.
	 */
	public string function $uuidDefaultSQL() {
		if (StructKeyExists(variables, "uuidDefaultSupported") && !variables.uuidDefaultSupported) {
			$warnUuidDefaultOmitted();
			return "";
		}
		return StructKeyExists(variables, "uuidDefaultSQL") ? variables.uuidDefaultSQL : "newid()";
	}

	/**
	 * Internal function. Set by Migration.init() from the server version.
	 */
	public void function $setUuidDefaultSupported(required boolean supported) {
		variables.uuidDefaultSupported = arguments.supported;
	}

	/**
	 * Internal function. One-time note that a uniqueidentifier column was created
	 * without a database default, so the app must set its value.
	 */
	public void function $warnUuidDefaultOmitted() {
		local.appKey = $appKey();
		if (StructKeyExists(application[local.appKey], "$uuidDefaultOmittedWarned")) {
			return;
		}
		application[local.appKey].$uuidDefaultOmittedWarned = true;
		local.text = "This #adapterName()# server cannot generate a UUID in a column default "
			& "(PostgreSQL 13+ and MySQL 8.0.13+ can), so uniqueidentifier columns are created "
			& "without one. Set the value when you create a record, e.g. with generateUUID(). (##4094)";
		announce(local.text);
		cflog(type = "warning", file = "wheels", text = local.text);
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
				$rejectEmptyStringDefault(arguments.options);
				if (arguments.options.default eq "" && !$emptyDefaultBecomesNull(arguments.options)) {
					// No default given: a NOT NULL column gets no DEFAULT clause at all
					// (MySQL rejects DEFAULT NULL NOT NULL), and nothing emits a bare
					// DEFAULT or an empty literal for a type that is not string-like.
				} else if (arguments.options.default eq "NULL" || arguments.options.default eq "") {
					arguments.sql = arguments.sql & " DEFAULT NULL";
				} else if (arguments.options.type == 'boolean') {
					arguments.sql = arguments.sql & " DEFAULT #IIf(arguments.options.default, 1, 0)#";
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
			arguments.sql = arguments.sql & " AFTER " & quoteColumnName(arguments.options.afterColumn);
		}
		return arguments.sql;
	}

	// what's the purpose of this?
	public boolean function optionsIncludeDefault(string type, default = "", boolean allowNull = true) {
		return true;
	}

	/**
	 * An empty `default` on a column that is not string-like means "no default"
	 * (`float()` itself defaults to `default=""`). It renders as DEFAULT NULL when the
	 * column may hold null, and as no DEFAULT clause on a NOT NULL column, which MySQL
	 * rejects as DEFAULT NULL NOT NULL. Never as a bare DEFAULT or an empty literal.
	 * (string/text/char reject an empty default first: $rejectEmptyStringDefault.)
	 */
	public boolean function $emptyDefaultBecomesNull(required struct options) {
		return !(
			StructKeyExists(arguments.options, "allowNull")
			&& IsBoolean(arguments.options.allowNull)
			&& !arguments.options.allowNull
		);
	}

	/**
	 * Fail-loud contract for `default=""` on string-like columns. Abstract
	 * used to omit the DEFAULT clause; PostgreSQL used to emit `DEFAULT ''`.
	 * Both now throw `Wheels.InvalidDefault` so the adapters cannot silently
	 * diverge.
	 */
	public void function $rejectEmptyStringDefault(required struct options) {
		if (
			StructKeyExists(arguments.options, "default")
			&& arguments.options.default eq ""
			&& StructKeyExists(arguments.options, "type")
			&& ListFindNoCase("string,text,char", arguments.options.type)
		) {
			Throw(
				type = "Wheels.InvalidDefault",
				message = "An empty string default is not allowed for #arguments.options.type# columns.",
				extendedInfo = "Omit the default, pass a non-empty value, or use default='NULL'. Abstract used to omit the DEFAULT clause and PostgreSQL used to emit DEFAULT ''."
			);
		}
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
				"binary,char,date,datetime,time,timestamp,text,string",
				arguments.options.type
			)
		) {
			// Escape every embedded single quote (not just the first) so the
			// generated DDL stays balanced for values like "O'Brien's".
			arguments.value = "'#Replace(arguments.value, "'", "''", "all")#'";
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
	 * Inline CREATE TABLE foreign-key fragment. Quotes identifiers through
	 * the adapter so reserved/mixed-case names stay valid.
	 */
	public string function addForeignKeyOptions(required string sql, struct options = {}) {
		if (StructKeyExists(arguments.options, "column")) {
			arguments.sql = arguments.sql & " FOREIGN KEY (" & quoteColumnName(arguments.options.column) & ")";
		}
		if (
			StructKeyExists(arguments.options, "referenceTable")
			&& StructKeyExists(arguments.options, "referenceColumn")
		) {
			arguments.sql = arguments.sql & " REFERENCES " & quoteTableName(arguments.options.referenceTable);
			arguments.sql = arguments.sql & " (" & quoteColumnName(arguments.options.referenceColumn) & ")";
		}
		return arguments.sql;
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
		local.sql = "CONSTRAINT #quoteTableName(arguments.name)# FOREIGN KEY (#quoteColumnName(arguments.column)#) REFERENCES #quoteTableName(arguments.referenceTable)#(#quoteColumnName(arguments.referenceColumn)#)";
		for (local.item in ListToArray("onUpdate,onDelete")) {
			if (Len(arguments[local.item])) {
				local.sql = local.sql & $referentialActionSQL(item = local.item, action = arguments[local.item]);
			}
		}
		return local.sql;
	}

	/**
	 * Maps a known onUpdate/onDelete value. Unknown values throw instead of
	 * silently becoming CASCADE.
	 */
	public string function $referentialActionSQL(required string item, required string action) {
		switch (arguments.action) {
			case "none":
				return " " & UCase(humanize(arguments.item)) & " NO ACTION";
			case "null":
				return " " & UCase(humanize(arguments.item)) & " SET NULL";
			case "cascade":
			case "true":
				return " " & UCase(humanize(arguments.item)) & " CASCADE";
			default:
				Throw(
					type = "Wheels.InvalidReferentialAction",
					message = "The referential action `#arguments.action#` is not supported.",
					extendedInfo = "Use none, null, cascade, or true. Unknown onUpdate/onDelete values used to silently become CASCADE."
				);
		}
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
