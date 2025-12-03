component extends="Base" {

	public Migration function init() {
		var dbType = $getDBType();
		if (dbType == '') {
			Throw(
				type = "wheels.model.migrate.DatabaseNotSupported",
				message = "#dbType# is not supported by Wheels.",
				extendedInfo = "Use SQL Server, MySQL, MariaDB, PostgreSQL, Oracle, SQLite or H2."
			);
		} else {
			this.adapter = CreateObject("component", "adapters.#dbType#");
		}
		return this;
	}

	/**
	 * Migrates up: will be executed when migrating your schema forward
	 * Along with down(), these are the two main functions in any migration file
	 * Only available in a migration CFC
	 *
	 * [section: Migrator]
	 * [category: Migration Functions]
	 *
	 */
	public void function up() {
		announce("UP MIGRATION NOT IMPLEMENTED");
	}

	/**
	 * Migrates down: will be executed when migrating your schema backward
	 * Along with up(), these are the two main functions in any migration file
	 * Only available in a migration CFC
	 *
	 * [section: Migrator]
	 * [category: Migration Functions]
	 *
	 */
	public void function down() {
		announce("DOWN MIGRATION NOT IMPLEMENTED");
	}

	/**
	 * Creates a table definition object to store table properties
	 * Only available in a migration CFC
	 *
	 * [section: Migrator]
	 * [category: Migration Functions]
	 *
	 * @name The name of the table to create
	 * @force whether to drop the table before creating it
	 * @id Whether to create a default primarykey or not
	 * @primaryKey Name of the primary key field to create
	 */
	public TableDefinition function createTable(
		required string name,
		boolean force = "false",
		boolean id = "true",
		string primaryKey = "id"
	) {
		arguments.adapter = this.adapter;
		return CreateObject("component", "TableDefinition").init(argumentCollection = arguments);
	}

	/**
	 * Creates a view definition object to store view properties
	 * Only available in a migration CFC
	 *
	 * [section: Migrator]
	 * [category: Migration Functions]
	 *
	 * @name Name of the view to change properties on
	 */
	public ViewDefinition function createView(required string name) {
		arguments.adapter = this.adapter;
		return CreateObject("component", "ViewDefinition").init(argumentCollection = arguments);
	}

	/**
	 * Creates a table definition object to store modifications to table properties
	 * Only available in a migration CFC
	 *
	 * [section: Migrator]
	 * [category: Migration Functions]
	 *
	 * @name Name of the table to set change properties on
	 */
	public TableDefinition function changeTable(required string name) {
		return CreateObject("component", "TableDefinition").init(adapter = this.adapter, name = arguments.name);
	}

	/**
	 * Renames a table
	 * Only available in a migration CFC
	 *
	 * [section: Migrator]
	 * [category: Migration Functions]
	 *
	 * @oldName Name the old table
	 * @newName New name for the table
	 */
	public void function renameTable(required string oldName, required string newName) {
		$execute(this.adapter.renameTable(argumentCollection = arguments));
		announce("Renamed table #arguments.oldName# to #arguments.newName#");
	}

	/**
	 * Drops a table from the database
	 * Only available in a migration CFC
	 *
	 * [section: Migrator]
	 * [category: Migration Functions]
	 *
	 * @name Name of the table to drop
	 */
	public void function dropTable(required string name) {
		local.appKey = $appKey();
		local.adapterName = $getDBType();
		if (application[local.appKey].serverName != "lucee" && local.adapterName != "SQLite") {
			local.foreignKeys = $getForeignKeys(arguments.name);
			local.foreignKeysArray = ListToArray(local.foreignKeys);
			local.iEnd = ArrayLen(local.foreignKeysArray);
			for (local.i = 1; local.i <= local.iEnd; local.i++) {
				local.foreignKeyName = local.foreignKeysArray[local.i];
				dropForeignKey(table = arguments.name, keyname = local.foreignKeyName);
			}
		}
		$execute(this.adapter.dropTable(name = arguments.name));
		announce("Dropped table #arguments.name#");
	}

	/**
	 * drops a view from the database
	 * Only available in a migration CFC
	 *
	 * [section: Migrator]
	 * [category: Migration Functions]
	 *
	 * @name Name of the view to drop
	 */
	public void function dropView(required string name) {
		$execute(this.adapter.dropView(name = arguments.name));
		announce("Dropped view #arguments.name#");
	}

	/**
	 * adds a column to existing table
	 * Only available in a migration CFC
	 *
	 * [section: Migrator]
	 * [category: Migration Functions]
	 *
	 * @table The Name of the table to add the column to
	 * @columnType The type of the new column
	 * @afterColumn The name of the column which this column should be inserted after
	 * @columnName THe name of the new column
	 * @referenceName Name for new reference column, see documentation for references function, required if columnType is 'reference'
	 * @default Default value for this column
	 * @allowNull Whether to allow NULL values
	 * @limit Character or integer size limit for column
	 * @precision precision value for decimal columns, i.e. number of digits the column can hold
	 * @scale scale value for decimal columns, i.e. number of digits that can be placed to the right of the decimal point (must be less than or equal to precision)
	 */
	public void function addColumn(
		required string table,
		required string columnType,
		required string columnName = "",
		string afterColumn = "",
		string referenceName = "",
		string default,
		boolean allowNull,
		numeric limit,
		numeric precision,
		numeric scale
	) {
		arguments.addColumns = true;
		changeColumn(argumentCollection = arguments);
	}

	/**
	 * changes a column definition
	 * Only available in a migration CFC
	 *
	 * [section: Migrator]
	 * [category: Migration Functions]
	 *
	 * @table The Name of the table where the column is
	 * @columnName THe name of the column
	 * @columnType The type of the column
	 * @afterColumn The name of the column which this column should be inserted after
	 * @referenceName Name for reference column, see documentation for references function, required if columnType is 'reference'
	 * @default Default value for this column
	 * @allowNull Whether to allow NULL values
	 * @limit Character or integer size limit for column
	 * @precision (For decimal type) the maximum number of digits allow
	 * @scale (For decimal type) the number of digits to the right of the decimal point
	 * @addColumns if true, attempts to add columns and database will likely throw an error if column already exists
	 */
	public void function changeColumn(
		required string table,
		required string columnName,
		required string columnType,
		string afterColumn = "",
		string referenceName = "",
		string default,
		boolean allowNull,
		numeric limit,
		numeric precision,
		numeric scale,
		boolean addColumns = "false"
	) {
		var t = changeTable(arguments.table);
		if (arguments.columnType == "reference") {
			arguments.columnType = "references";
			arguments.referenceNames = arguments.referenceName;
		} else {
			arguments.columnNames = arguments.columnName;
		}
		invoke(t, arguments.columnType, arguments);
		t.change(addColumns = arguments.addColumns);
	}

	/**
	 * Renames a table column
	 * Only available in a migration CFC
	 *
	 * [section: Migrator]
	 * [category: Migration Functions]
	 *
	 * @table The table containing the column to rename
	 * @columnName The column name to rename
	 * @newColumnName The new column name
	 */
	public void function renameColumn(required string table, required string columnName, required string newColumnName) {
		$execute(
			this.adapter.renameColumnInTable(
				name = arguments.table,
				columnName = arguments.columnName,
				newColumnName = arguments.newColumnName
			)
		);
		announce("Renamed column #arguments.columnName# to #arguments.newColumnName# in table #arguments.table#");
	}

	/**
	 * Removes a column from a database table
	 * Only available in a migration CFC
	 *
	 * [section: Migrator]
	 * [category: Migration Functions]
	 *
	 * @table The table containing the column to remove
	 * @columnName The column name to remove
	 * @referenceName optional reference name
	 */
	public void function removeColumn(required string table, string columnName = "", string referenceName = "") {
		if (arguments.referenceName != "") {
			arguments.columnName = arguments.referenceName & "id";
		}
		$execute(this.adapter.dropColumnFromTable(name = arguments.table, columnName = arguments.columnName));
		announce("Removed column #arguments.columnName# from #arguments.table#");
	}

	/**
	 * Add a foreign key constraint to the database, using the reference name that was used to create it
	 * Only available in a migration CFC
	 *
	 * [section: Migrator]
	 * [category: Migration Functions]
	 *
	 * @table The table name to perform the operation on
	 * @referenceName The reference table name to perform the operation on
	 */
	public void function addReference(required string table, required string referenceName) {
		addForeignKey(
			table = arguments.table,
			referenceTable = pluralize(arguments.referenceName),
			column = "#arguments.referenceName#id",
			referenceColumn = "id"
		);
	}

	/**
	 * Add a foreign key constraint to the database, using the reference name that was used to create it
	 * Only available in a migration CFC
	 *
	 * [section: Migrator]
	 * [category: Migration Functions]
	 *
	 * @table The table name to perform the operation on
	 * @referenceTable The reference table name to perform the operation on
	 * @column The column name to perform the operation on
	 * @referenceColumn The reference column name to perform the operation on
	 */
	public void function addForeignKey(
		required string table,
		required string referenceTable,
		required string column,
		required string referenceColumn
	) {
		var foreignKey = CreateObject("component", "ForeignKeyDefinition").init(
			adapter = this.adapter,
			argumentCollection = arguments
		);
		$execute(this.adapter.addForeignKeyToTable(name = arguments.table, foreignKey = foreignKey));
		announce("Added foreign key #foreignKey.name#");
	}

	/**
	 * Drop a foreign key constraint from the database, using the reference name that was used to create it
	 * Only available in a migration CFC
	 *
	 * [section: Migrator]
	 * [category: Migration Functions]
	 *
	 * @table The table name to perform the operation on
	 * @referenceName the name of the reference to drop
	 *
	 */
	public void function dropReference(required string table, required string referenceName) {
		dropForeignKey(arguments.table, "FK_#arguments.table#_#pluralize(arguments.referenceName)#");
	}

	/**
	 * Drops a foreign key constraint from the database
	 * Only available in a migration CFC
	 *
	 * [section: Migrator]
	 * [category: Migration Functions]
	 *
	 * @table The table name to perform the operation on
	 * @keyName the name of the key to drop
	 *
	 */
	public void function dropForeignKey(required string table, required string keyName) {
		$execute(this.adapter.dropForeignKeyFromTable(name = arguments.table, keyName = arguments.keyName));
		announce("Dropped foreign key #arguments.keyName#");
	}

	/**
	 * Add database index on a table column
	 * Only available in a migration CFC
	 *
	 * [section: Migrator]
	 * [category: Migration Functions]
	 *
	 * @table The table name to perform the index operation on
	 * @columnNames One or more column names to index, comma separated
	 * @unique If true will create a unique index constraint
	 * @indexName The name of the index to add: Defaults to table name + underscore + first column name
	 */
	public void function addIndex(
		required string table,
		string columnNames,
		boolean unique = "false",
		string indexName = objectCase("#arguments.table#_#ListFirst(arguments.columnNames)#")
	) {
		$combineArguments(args = arguments, combine = "columnNames,columnName", required = true);
		$execute(this.adapter.addIndex(argumentCollection = arguments));
		announce("Added index to column(s) #arguments.columnNames# in table #arguments.table#");
	}

	/**
	 * Remove a database index
	 * Only available in a migration CFC
	 *
	 * [section: Migrator]
	 * [category: Migration Functions]
	 *
	 * @table The table name to perform the index operation on
	 * @indexName the name of the index to remove
	 */
	public void function removeIndex(required string table, required string indexName) {
		$execute(this.adapter.removeIndex(argumentCollection = arguments));
		announce("Removed index #arguments.indexName# from table #arguments.table#");
	}

	/**
	 * Executes a raw sql query
	 * Only available in a migration CFC
	 *
	 * [section: Migrator]
	 * [category: Migration Functions]
	 *
	 * @sql Arbitrary SQL String
	 */
	public void function execute(required string sql) {
		$execute(arguments.sql);
		announce("Executed SQL: #arguments.sql#");
	}

	/**
	 * Adds a record to a table
	 * Only available in a migration CFC
	 *
	 * [section: Migrator]
	 * [category: Migration Functions]
	 *
	 * @table The table name to add the record to
	 */
	public void function addRecord(required string table) {
		local.appKey = $appKey();
		local.columnNames = "";
		local.columnValues = "";
		if (
			!StructKeyExists(arguments, application[local.appKey].timeStampOnCreateProperty)
			&& ListFindNoCase($getColumns(arguments.table), application[local.appKey].timeStampOnCreateProperty)
		) {
			arguments[application[local.appKey].timeStampOnCreateProperty] = $timestamp();
		}
		if (
			application[local.appKey].setUpdatedAtOnCreate
			&& !StructKeyExists(arguments, application[local.appKey].timeStampOnUpdateProperty)
			&& ListFindNoCase($getColumns(arguments.table), application[local.appKey].timeStampOnUpdateProperty)
		) {
			arguments[application[local.appKey].timeStampOnUpdateProperty] = $timestamp();
		}

		for (local.key in arguments) {
			if (local.key neq "table") {
				local.columnNames = ListAppend(local.columnNames, this.adapter.quoteColumnName(local.key));
				if (IsNumeric(arguments[local.key])) {
					local.columnValues = ListAppend(local.columnValues, arguments[local.key]);
				} else if (IsBoolean(arguments[local.key])) {
					local.columnValues = ListAppend(local.columnValues, IIf(arguments[local.key], 1, 0));
				} else if (IsDate(arguments[local.key])) {
					if(get("adapterName") == "SQLite" && $isTimestampLiteral(arguments[local.key])){
						local.columnValues = '"#$convertToString(arguments[local.key])#"';
					} else {
						local.columnValues = ListAppend(local.columnValues, "#arguments[local.key]#");
					}
				} else {
					if (REFind("^'.*'$", arguments[local.key])) {
						// strip only first and last quote
						local.cleaned = Mid(arguments[local.key], 2, Len(arguments[local.key]) - 2);
						// wrap in double quotes
						local.columnValues = ListAppend(local.columnValues, '"' & local.cleaned & '"');
					} else {
						// normal values
						local.columnValues = ListAppend(
							local.columnValues,
							"'#Replace(arguments[local.key], "'", "''", "all")#'"
						);
					}
				}
			}
		}
		if (local.columnNames != '') {
			if (ListContainsNoCase(local.columnnames, "[id]")) {
				$execute(this.adapter.addRecordPrefix(arguments.table));
			}
			$execute(
				"INSERT INTO #this.adapter.quoteTableName(arguments.table)# ( #local.columnNames# ) VALUES ( #local.columnValues# )"
			);
			if (ListContainsNoCase(local.columnnames, "[id]")) {
				$execute(this.adapter.addRecordSuffix(arguments.table));
			}
			announce("Added record to table #arguments.table#");
		}
	}

	/**
	 * Updates an existing record in a table
	 * Only available in a migration CFC
	 *
	 * [section: Migrator]
	 * [category: Migration Functions]
	 *
	 * @table The table name where the record is
	 * @where The where clause, i.e admin = 1
	 */
	public void function updateRecord(required string table, string where = "") {
		local.appKey = $appKey();
		local.columnUpdates = "";
		if (
			!StructKeyExists(arguments, application[local.appKey].timeStampOnUpdateProperty)
			&& ListFindNoCase($getColumns(arguments.table), application[local.appKey].timeStampOnUpdateProperty)
		) {
			arguments[application[local.appKey].timeStampOnUpdateProperty] = $timestamp();
		}
		for (local.key in arguments) {
			if (local.key neq "table" && local.key neq "where") {
				local.update = "#this.adapter.quoteColumnName(local.key)# = ";
				if (IsNumeric(arguments[local.key])) {
					local.update = local.update & "#arguments[local.key]#";
				} else if (IsBoolean(arguments[local.key])) {
					local.update = local.update & "#IIf(arguments[local.key], 1, 0)#";
				} else if (IsDate(arguments[local.key])) {
					local.update = local.update & "#arguments[local.key]#";
				} else {
					arguments[local.key] = ReplaceNoCase(arguments[local.key], "'", "''", "all");
					local.update = local.update & "'#arguments[local.key]#'";
				}
				local.columnUpdates = ListAppend(local.columnUpdates, local.update);
			}
		}
		if (local.columnUpdates != '') {
			local.sql = 'UPDATE #this.adapter.quoteTableName(arguments.table)# SET #local.columnUpdates#';
			local.message = 'Updated record(s) in table #arguments.table#';
			if (arguments.where != '') {
				local.sql = local.sql & ' WHERE #arguments.where#';
				local.message = local.message & ' where #arguments.where#';
			}
			$execute(local.sql);
			announce(local.message);
		}
	}

	/**
	 * Removes existing records from a table
	 * Only available in a migration CFC
	 *
	 * [section: Migrator]
	 * [category: Migration Functions]
	 *
	 * @table The table name to remove the record from
	 * @where The where clause, i.e id = 123
	 */
	public void function removeRecord(required string table, string where = "") {
		local.sql = 'DELETE FROM #this.adapter.quoteTableName(arguments.table)#';
		local.message = 'Removed record(s) from table #arguments.table#';
		if (arguments.where != '') {
			local.sql = local.sql & ' WHERE #arguments.where#';
			local.message = local.message & ' where #arguments.where#';
		}
		$execute(local.sql);
		announce(local.message);
	}

	/**
	 * Determines whether the given value is a ColdFusion timestamp literal.
	 *
	 * A valid CFML timestamp literal follows the exact format:
	 * {ts 'YYYY-MM-DD HH:MM:SS'}
	 *
	 * @value The value to evaluate.
	 * @return True if the value matches the ColdFusion timestamp literal syntax, otherwise false.
	 */
	private boolean function $isTimestampLiteral(required string value) {
		return REFind("^\{ts '(\d{4})-(\d{2})-(\d{2}) (\d{2}):(\d{2}):(\d{2})'\}$", value) == 1;
	}
}
