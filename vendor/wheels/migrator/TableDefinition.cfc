component extends="Base" {

	public any function init(
		required any adapter,
		required string name,
		boolean force = "true",
		boolean id = "true",
		string primaryKey = "id"
	) {
		local.args = "adapter,name,force";
		this.primaryKeys = [];
		this.foreignKeys = [];
		this.columns = [];
		local.argsArray = ListToArray(local.args);
		local.iEnd = ArrayLen(local.argsArray);
		for (local.i = 1; local.i <= local.iEnd; local.i++) {
			local.argumentName = local.argsArray[local.i];
			if (StructKeyExists(arguments, local.argumentName)) {
				this[local.argumentName] = arguments[local.argumentName];
			}
		}
		if (arguments.id && Len(arguments.primaryKey)) {
			this.primaryKey(name = arguments.primaryKey, autoIncrement = true);
		}
		return this;
	}

	/**
	 * Adds a primary key definition to the table. this method also allows for multiple primary keys.
	 *
	 * Accepts `columnName` / `columnNames` as aliases for `name` (per #2803) so the
	 * PK helper matches the argument-naming convention every other column helper
	 * in this file uses. The legacy `name` parameter keeps working — it is still
	 * what the body reads and what `init()` passes when adding the conventional
	 * `id` primary key.
	 *
	 * [section: Migrator]
	 * [category: Table Definition Functions]
	 *
	 * @name Legacy parameter for the primary-key column name. New code should prefer `columnName`.
	 * @columnName Modern singular alias for `name` (matches sibling column helpers).
	 * @columnNames Modern plural alias for `name`. Accepted for muscle-memory parity with `t.integer(columnNames=...)` etc.; the primary key is still inherently a single column here.
	 */
	public any function primaryKey(
		string name,
		string columnName,
		string columnNames,
		string type = "integer",
		boolean autoIncrement = "false",
		numeric limit,
		numeric precision,
		numeric scale,
		string references,
		string onUpdate = "",
		string onDelete = ""
	) {
		// Accept columnName / columnNames as aliases for name (#2803). Precedence
		// (per $combineArguments semantics): the later call wins, so when both
		// columnName and columnNames are supplied, columnNames takes priority —
		// matching addReference() / dropReference() in Migration.cfc.
		$combineArguments(args = arguments, combine = "name,columnName", required = false);
		$combineArguments(args = arguments, combine = "name,columnNames", required = true);
		arguments.allowNull = false;
		arguments.adapter = this.adapter;

		// don't allow multiple autoIncrement primarykeys
		if (ArrayLen(this.primaryKeys) && arguments.autoIncrement) {
			Throw(message = "You cannot have multiple auto increment primary keys.");
		}

		local.column = CreateObject("component", "ColumnDefinition").init(argumentCollection = arguments);
		ArrayAppend(this.primaryKeys, local.column);

		if (StructKeyExists(arguments, "references")) {
			local.referenceTable = pluralize(arguments.references);
			local.foreignKey = CreateObject("component", "ForeignKeyDefinition").init(
				adapter = this.adapter,
				table = this.name,
				referenceTable = local.referenceTable,
				column = arguments.name,
				referenceColumn = "id",
				onUpdate = arguments.onUpdate,
				onDelete = arguments.onDelete
			);
			ArrayAppend(this.foreignKeys, local.foreignKey);
		}
		return this;
	}

	/**
	 * Adds a column to table definition.
	 *
	 * [section: Migrator]
	 * [category: Table Definition Functions]
	 */
	public any function column(
		required string columnName,
		required string columnType,
		string default,
		boolean allowNull,
		any limit,
		numeric precision,
		numeric scale
	) {
		arguments.adapter = this.adapter;
		arguments.name = arguments.columnName;
		arguments.type = arguments.columnType;
		
		if (StructKeyExists(arguments, "size") 
			&& arguments.columnType == "text" 
			&& arguments.adapter.adapterName() == "MySQL") {

			local.size = LCase(arguments.size);
			if (ListFindNoCase("mediumtext,longtext", local.size)) {
				arguments.type = local.size;
			} else {
				arguments.type = "text";
			}
		}

		local.column = CreateObject("component", "ColumnDefinition").init(argumentCollection = arguments);
		ArrayAppend(this.columns, local.column);
		return this;
	}

	/**
	 * Adds integer columns to table definition.
	 *
	 * [section: Migrator]
	 * [category: Table Definition Functions]
	 */
	public any function bigInteger(string columnNames, numeric limit, string default, boolean allowNull) {
		$combineArguments(args = arguments, combine = "columnNames,columnName", required = true);
		arguments.columnType = "biginteger";
		local.columnNamesArray = ListToArray(arguments.columnNames);
		local.iEnd = ArrayLen(local.columnNamesArray);
		for (local.i = 1; local.i <= local.iEnd; local.i++) {
			arguments.columnName = Trim(local.columnNamesArray[local.i]);
			column(argumentCollection = arguments);
		}
		return this;
	}

	/**
	 * Adds binary columns to table definition.
	 *
	 * [section: Migrator]
	 * [category: Table Definition Functions]
	 */
	public any function binary(string columnNames, string default, boolean allowNull) {
		$combineArguments(args = arguments, combine = "columnNames,columnName", required = true);
		arguments.columnType = "binary";
		local.columnNamesArray = ListToArray(arguments.columnNames);
		local.iEnd = ArrayLen(local.columnNamesArray);
		for (local.i = 1; local.i <= local.iEnd; local.i++) {
			arguments.columnName = Trim(local.columnNamesArray[local.i]);
			column(argumentCollection = arguments);
		}
		return this;
	}

	/**
	 * Adds boolean columns to table definition.
	 *
	 * [section: Migrator]
	 * [category: Table Definition Functions]
	 */
	public any function boolean(string columnNames, string default, boolean allowNull) {
		$combineArguments(args = arguments, combine = "columnNames,columnName", required = true);
		arguments.columnType = "boolean";
		local.columnNamesArray = ListToArray(arguments.columnNames);
		local.iEnd = ArrayLen(local.columnNamesArray);
		for (local.i = 1; local.i <= local.iEnd; local.i++) {
			arguments.columnName = Trim(local.columnNamesArray[local.i]);
			column(argumentCollection = arguments);
		}
		return this;
	}

	/**
	 * Adds date columns to table definition.
	 *
	 * [section: Migrator]
	 * [category: Table Definition Functions]
	 */
	public any function date(string columnNames, string default, boolean allowNull) {
		$combineArguments(args = arguments, combine = "columnNames,columnName", required = true);
		arguments.columnType = "date";
		local.columnNamesArray = ListToArray(arguments.columnNames);
		local.iEnd = ArrayLen(local.columnNamesArray);
		for (local.i = 1; local.i <= local.iEnd; local.i++) {
			arguments.columnName = Trim(local.columnNamesArray[local.i]);
			column(argumentCollection = arguments);
		}
		return this;
	}

	/**
	 * adds datetime columns to table definition
	 *
	 * [section: Migrator]
	 * [category: Table Definition Functions]
	 */
	public any function datetime(string columnNames, string default, boolean allowNull) {
		$combineArguments(args = arguments, combine = "columnNames,columnName", required = true);
		arguments.columnType = "datetime";
		local.columnNamesArray = ListToArray(arguments.columnNames);
		local.iEnd = ArrayLen(local.columnNamesArray);
		for (local.i = 1; local.i <= local.iEnd; local.i++) {
			arguments.columnName = Trim(local.columnNamesArray[local.i]);
			column(argumentCollection = arguments);
		}
		return this;
	}

	/**
	 * adds decimal columns to table definition
	 *
	 * [section: Migrator]
	 * [category: Table Definition Functions]
	 */
	public any function decimal(string columnNames, string default, boolean allowNull, numeric precision, numeric scale) {
		$combineArguments(args = arguments, combine = "columnNames,columnName", required = true);
		arguments.columnType = "decimal";
		local.columnNamesArray = ListToArray(arguments.columnNames);
		local.iEnd = ArrayLen(local.columnNamesArray);
		for (local.i = 1; local.i <= local.iEnd; local.i++) {
			arguments.columnName = Trim(local.columnNamesArray[local.i]);
			column(argumentCollection = arguments);
		}
		return this;
	}

	/**
	 * adds float columns to table definition
	 *
	 * [section: Migrator]
	 * [category: Table Definition Functions]
	 */
	public any function float(string columnNames, string default = "", boolean allowNull = "true") {
		$combineArguments(args = arguments, combine = "columnNames,columnName", required = true);
		arguments.columnType = "float";
		local.columnNamesArray = ListToArray(arguments.columnNames);
		local.iEnd = ArrayLen(local.columnNamesArray);
		for (local.i = 1; local.i <= local.iEnd; local.i++) {
			arguments.columnName = Trim(local.columnNamesArray[local.i]);
			column(argumentCollection = arguments);
		}
		return this;
	}

	/**
	 * adds integer columns to table definition
	 *
	 * [section: Migrator]
	 * [category: Table Definition Functions]
	 */
	public any function integer(string columnNames, numeric limit, string default, boolean allowNull) {
		$combineArguments(args = arguments, combine = "columnNames,columnName", required = true);
		arguments.columnType = "integer";
		local.columnNamesArray = ListToArray(arguments.columnNames);
		local.iEnd = ArrayLen(local.columnNamesArray);
		for (local.i = 1; local.i <= local.iEnd; local.i++) {
			arguments.columnName = Trim(local.columnNamesArray[local.i]);
			column(argumentCollection = arguments);
		}
		return this;
	}

	/**
	 * adds string columns to table definition
	 *
	 * [section: Migrator]
	 * [category: Table Definition Functions]
	 */
	public any function string(string columnNames, any limit, string default, boolean allowNull) {
		$combineArguments(args = arguments, combine = "columnNames,columnName", required = true);
		arguments.columnType = "string";
		local.columnNamesArray = ListToArray(arguments.columnNames);
		local.iEnd = ArrayLen(local.columnNamesArray);
		for (local.i = 1; local.i <= local.iEnd; local.i++) {
			arguments.columnName = Trim(local.columnNamesArray[local.i]);
			column(argumentCollection = arguments);
		}
		return this;
	}

	/**
	 * adds char columns to table definition
	 *
	 * [section: Migrator]
	 * [category: Table Definition Functions]
	 */
	public any function char(string columnNames, any limit, string default, boolean allowNull) {
		$combineArguments(args = arguments, combine = "columnNames,columnName", required = true);
		arguments.columnType = "char";
		local.columnNamesArray = ListToArray(arguments.columnNames);
		local.iEnd = ArrayLen(local.columnNamesArray);
		for (local.i = 1; local.i <= local.iEnd; local.i++) {
			arguments.columnName = Trim(local.columnNamesArray[local.i]);
			column(argumentCollection = arguments);
		}
		return this;
	}

	/**
	 * Adds text columns to table definition.
	 *
	 * In MySQL databases, you can specify different text sizes:
	 * - Regular TEXT (65KB) - default when no size is specified
	 * - MEDIUMTEXT (16MB) - specify size="mediumtext"
	 * - LONGTEXT (4GB) - specify size="longtext"
	 *
	 * For other database engines, the size parameter is ignored and the default text type is used.
	 *
	 * [section: Migrator]
	 * [category: Table Definition Functions]
	 */
	public any function text(string columnNames, string default, boolean allowNull, string size) {
		$combineArguments(args = arguments, combine = "columnNames,columnName", required = true);
		arguments.columnType = "text";
		local.columnNamesArray = ListToArray(arguments.columnNames);
		local.iEnd = ArrayLen(local.columnNamesArray);
		for (local.i = 1; local.i <= local.iEnd; local.i++) {
			arguments.columnName = Trim(local.columnNamesArray[local.i]);
			column(argumentCollection = arguments);
		}
		return this;
	}

	/**
	 * adds UUID columns to table definition
	 *
	 * [section: Migrator]
	 * [category: Table Definition Functions]
	 */
	public any function uniqueidentifier(string columnNames, string default = "newid()", boolean allowNull) {
		$combineArguments(args = arguments, combine = "columnNames,columnName", required = true);
		arguments.columnType = "uniqueidentifier";
		local.columnNamesArray = ListToArray(arguments.columnNames);
		local.iEnd = ArrayLen(local.columnNamesArray);
		for (local.i = 1; local.i <= local.iEnd; local.i++) {
			arguments.columnName = Trim(local.columnNamesArray[local.i]);
			column(argumentCollection = arguments);
		}
		return this;
	}

	/**
	 * adds time columns to table definition
	 *
	 * [section: Migrator]
	 * [category: Table Definition Functions]
	 */
	public any function time(string columnNames, string default, boolean allowNull) {
		$combineArguments(args = arguments, combine = "columnNames,columnName", required = true);
		arguments.columnType = "time";
		local.columnNamesArray = ListToArray(arguments.columnNames);
		local.iEnd = ArrayLen(local.columnNamesArray);
		for (local.i = 1; local.i <= local.iEnd; local.i++) {
			arguments.columnName = Trim(local.columnNamesArray[local.i]);
			column(argumentCollection = arguments);
		}
		return this;
	}

	/**
	 * adds timestamp columns to table definition
	 *
	 * [section: Migrator]
	 * [category: Table Definition Functions]
	 */
	public any function timestamp(string columnNames, string default, boolean allowNull, string columnType = "datetime") {
		$combineArguments(args = arguments, combine = "columnNames,columnName", required = true);
		local.columnNamesArray = ListToArray(arguments.columnNames);
		local.iEnd = ArrayLen(local.columnNamesArray);
		for (local.i = 1; local.i <= local.iEnd; local.i++) {
			arguments.columnName = Trim(local.columnNamesArray[local.i]);
			column(argumentCollection = arguments);
		}
		return this;
	}

	/**
	 * adds Wheels convention automatic timestamp and soft delete columns to table definition
	 *
	 * [section: Migrator]
	 * [category: Table Definition Functions]
	 */
	public any function timestamps() {
		local.columnNames = ArrayToList([$get("timeStampOnCreateProperty"), $get("timeStampOnUpdateProperty"), $get("softDeleteProperty")]);
		timestamp(columnNames = local.columnNames, allowNull = true);
		return this;
	}

	/**
	 * Adds integer reference columns to the table definition and (unless
	 * `foreignKey=false` or `polymorphic=true`) registers a matching foreign-key
	 * constraint. The column suffix depends on the `useUnderscoreReferenceColumns`
	 * setting: `false` (framework default) → `<name>id`; `true` (default for
	 * apps generated by `wheels new`) → `<name>_id`, matching Wheels model
	 * `belongsTo` defaults. With `polymorphic=true`, a `<name>type` / `<name>_type`
	 * companion column is added and no FK is registered.
	 *
	 * Accepts `columnNames` as an alias for `referenceNames` (per #2781) — both
	 * are list-shaped (single name or comma-delimited). New code should use
	 * `columnNames` for consistency with every other column helper here.
	 *
	 * [section: Migrator]
	 * [category: Table Definition Functions]
	 *
	 * @referenceNames Comma-delimited list of reference base names (e.g. `"user,role"`). Each produces a `<name>_id` (or `<name>id`) column. Legacy parameter — `columnNames` is the modern alias.
	 * @columnNames Modern alias for `referenceNames`. Pass one or the other — not both.
	 * @default Default value for the generated integer column(s).
	 * @allowNull If true, the generated column(s) allow NULL.
	 * @polymorphic If true, also creates a `<name>type` / `<name>_type` companion column and skips the foreign-key constraint.
	 * @foreignKey If true (default), registers a foreign key on the generated column. Ignored when `polymorphic=true`.
	 * @onUpdate Foreign-key ON UPDATE clause. Engine-specific values; common: `"cascade"`, `"null"`, `"none"`.
	 * @onDelete Foreign-key ON DELETE clause. Same value set as `onUpdate`.
	 */
	public any function references(
		string referenceNames,
		string columnNames,
		string default,
		boolean allowNull = "false",
		boolean polymorphic = "false",
		boolean foreignKey = "true",
		string onUpdate = "",
		string onDelete = ""
	) {
		$combineArguments(args = arguments, combine = "referenceNames,columnNames", required = true);
		local.idSuffix = $get("useUnderscoreReferenceColumns") ? "_id" : "id";
		local.typeSuffix = $get("useUnderscoreReferenceColumns") ? "_type" : "type";
		local.referenceNamesArray = ListToArray(arguments.referenceNames);
		local.iEnd = ArrayLen(local.referenceNamesArray);
		for (local.i = 1; local.i <= local.iEnd; local.i++) {
			local.referenceName = local.referenceNamesArray[local.i];

			// get all possible arguments for the column
			local.columnArgs = {};
			for (local.arg in ListToArray("columnType,default,allowNull,limit,precision,scale"))
				if (StructKeyExists(arguments, local.arg)) local.columnArgs[local.arg] = arguments[local.arg];

			// default the column to an integer if not provided
			if (!StructKeyExists(local.columnArgs, "columnType")) local.columnArgs.columnType = "integer";

			column(columnName = local.referenceName & local.idSuffix, argumentCollection = local.columnArgs);

			if (arguments.polymorphic) column(columnName = local.referenceName & local.typeSuffix, columnType = "string");

			if (arguments.foreignKey && !arguments.polymorphic) {
				local.referenceTable = pluralize(local.referenceName);
				local.foreignKey = CreateObject("component", "ForeignKeyDefinition").init(
					adapter = this.adapter,
					table = this.name,
					referenceTable = local.referenceTable,
					column = "#local.referenceName##local.idSuffix#",
					referenceColumn = "id",
					onUpdate = arguments.onUpdate,
					onDelete = arguments.onDelete
				);
				ArrayAppend(this.foreignKeys, local.foreignKey);
			}
		}
		return this;
	}

	/**
	 * creates the table in the database
	 *
	 * [section: Migrator]
	 * [category: Table Definition Functions]
	 */
	public void function create() {
		if (this.force) {
			$execute(this.adapter.dropTable(this.name));
			announce("Dropped table #objectCase(this.name)#");
		}
		$execute(
			this.adapter.createTable(
				name = this.name,
				primaryKeys = this.primaryKeys,
				columns = this.columns,
				foreignKeys = this.foreignKeys
			)
		);
		announce("Created table #objectCase(this.name)#");
		local.iEnd = ArrayLen(this.foreignKeys);
		for (local.i = 1; local.i <= local.iEnd; local.i++) {
			announce("--> added foreign key #this.foreignKeys[local.i].name#");
		}
	}

	/**
	 * alters existing table in the database
	 *
	 * [section: Migrator]
	 * [category: Table Definition Functions]
	 */
	public void function change(boolean addColumns = "false") {
		local.existingColumns = $getColumns(this.name);
		local.iEnd = ArrayLen(this.columns);
		for (local.i = 1; local.i <= local.iEnd; local.i++) {
			if (arguments.addColumns || !ListFindNoCase(local.existingColumns, this.columns[local.i].name)) {
				$execute(this.adapter.addColumnToTable(name = this.name, column = this.columns[local.i]));
				announce("Added column #this.columns[local.i].name# to table #this.name#");
			} else {
				$execute(this.adapter.changeColumnInTable(name = this.name, column = this.columns[local.i]));
				announce("Changed column #this.columns[local.i].name# in table #this.name#");
			}
		}
		local.iEnd = ArrayLen(this.foreignKeys);
		for (local.i = 1; local.i <= local.iEnd; local.i++) {
			$execute(this.adapter.addForeignKeyToTable(name = this.name, foreignKey = this.foreignKeys[local.i]));
			announce("Added foreign key #this.foreignKeys[local.i].name# to table #this.name#");
		}
	}

}
