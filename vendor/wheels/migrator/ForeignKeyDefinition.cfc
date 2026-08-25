component extends="Base" {

	/*
	 * @onUpdate.hint how you want the constraint to act on update. possible values include `none`, `null`, or `cascade` which can also be set to `true`.
	 */
	public ForeignKeyDefinition function init(
		required any adapter,
		required string table,
		required string referenceTable,
		required string column,
		required string referenceColumn,
		string onUpdate = "",
		string onDelete = ""
	) {
		local.args = "adapter,table,referenceTable,column,referenceColumn,onUpdate,onDelete";
		local.argsArray = ListToArray(local.args);
		local.iEnd = ArrayLen(local.argsArray);
		for (local.i = 1; local.i <= local.iEnd; local.i++) {
			local.argumentName = local.argsArray[local.i];
			if (StructKeyExists(arguments, local.argumentName)) {
				this[local.argumentName] = arguments[local.argumentName];
			}
		}
		this.name = $defaultForeignKeyName(this.table, this.referenceTable, this.column);
		return this;
	}

	/**
	 * Default constraint name. Includes the column so two FKs from the same
	 * table to the same reference table do not collide.
	 */
	public string function $defaultForeignKeyName(
		required string table,
		required string referenceTable,
		required string column
	) {
		return "FK_#objectCase(arguments.table)#_#objectCase(arguments.referenceTable)#_#objectCase(arguments.column)#";
	}

	public string function toSQL() {
		local.args = "name,table,referenceTable,column,referenceColumn,onUpdate,onDelete";
		local.argsArray = ListToArray(local.args);
		local.iEnd = ArrayLen(local.argsArray);
		local.adapterArgs = {};
		for (local.i = 1; local.i <= local.iEnd; local.i++) {
			local.argumentName = local.argsArray[local.i];
			local.adapterArgs[local.argumentName] = this[local.argumentName];
		}
		return this.adapter.foreignKeySQL(argumentcollection = local.adapterArgs);
	}

	public string function toForeignKeySQL() {
		local.sql = "CONSTRAINT " & this.adapter.quoteTableName(this.name);
		local.sql = addForeignKeyOptions(local.sql);
		return local.sql;
	}

	public string function addForeignKeyOptions(required string sql) {
		local.options = {};
		local.optionalArguments = "referenceTable,referenceColumn,column";
		local.optionalArgumentsArray = ListToArray(local.optionalArguments);
		local.iEnd = ArrayLen(local.optionalArgumentsArray);
		for (local.i = 1; local.i <= local.iEnd; local.i++) {
			local.argumentName = local.optionalArgumentsArray[local.i];
			if (StructKeyExists(this, local.argumentName)) {
				local.options[local.argumentName] = this[local.argumentName];
			}
		}
		arguments.sql = this.adapter.addForeignKeyOptions(sql = arguments.sql, options = local.options);
		// CREATE TABLE uses this path; ALTER ADD uses toSQL()/foreignKeySQL().
		// Adapters historically dropped onUpdate/onDelete here.
		return $appendReferentialActions(arguments.sql);
	}

	/**
	 * Appends ON UPDATE / ON DELETE using the same mapping as Abstract.foreignKeySQL.
	 */
	public string function $appendReferentialActions(required string sql) {
		for (local.item in ListToArray("onUpdate,onDelete")) {
			if (StructKeyExists(this, local.item) && Len(this[local.item])) {
				arguments.sql &= this.adapter.$referentialActionSQL(item = local.item, action = this[local.item]);
			}
		}
		return arguments.sql;
	}

}
