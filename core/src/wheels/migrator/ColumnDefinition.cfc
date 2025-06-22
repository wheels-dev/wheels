component extends="Base" {

	public ColumnDefinition function init(required any adapter, required string name, required string type) {
		local.args = "adapter,name,type,limit,precision,scale,default,null,autoIncrement,afterColumn";
		local.iEnd = ListLen(local.args);
		for (local.i = 1; local.i <= local.iEnd; local.i++) {
			local.argumentName = ListGetAt(local.args, local.i);
			if (StructKeyExists(arguments, local.argumentName)) {
				this[local.argumentName] = arguments[local.argumentName];
			}
		}
		return this;
	}

	public string function toSQL() {
		local.sql = this.adapter.quoteColumnName(this.name) & " " & sqlType();
		local.sql = addColumnOptions(local.sql);
		return local.sql;
	}

	public string function toColumnNameSQL() {
		local.sql = this.adapter.quoteColumnName(this.name);
		return local.sql;
	}

	public string function toPrimaryKeySQL() {
		local.sql = this.adapter.quoteColumnName(this.name) & " " & sqlType();
		local.sql = addPrimaryKeyOptions(local.sql);
		return local.sql;
	}

	public string function sqlType() {
		local.options = {};
		local.optionalArguments = "limit,precision,scale";
		local.iEnd = ListLen(local.optionalArguments);
		for (local.i = 1; local.i <= local.iEnd; local.i++) {
			local.argumentName = ListGetAt(local.optionalArguments, local.i);
			if (StructKeyExists(this, local.argumentName)) {
				local.options[local.argumentName] = this[local.argumentName];
			}
		}
		local.sql = this.adapter.typeToSQL(type = this.type, options = local.options);
		return local.sql;
	}

	public string function addColumnOptions(required string sql) {
		local.options = {};
		local.optionalArguments = "type,default,null,afterColumn";
		local.iEnd = ListLen(local.optionalArguments);
		for (local.i = 1; local.i <= local.iEnd; local.i++) {
			local.argumentName = ListGetAt(local.optionalArguments, local.i);
			if (StructKeyExists(this, local.argumentName)) {
				local.options[local.argumentName] = this[local.argumentName];
			}
		}
		arguments.sql = this.adapter.addColumnOptions(sql = arguments.sql, options = local.options);
		return arguments.sql;
	}

	public string function addPrimaryKeyOptions(required string sql) {
		local.options = {};
		local.optionalArguments = "autoIncrement,null";
		local.iEnd = ListLen(local.optionalArguments);
		for (local.i = 1; local.i <= local.iEnd; local.i++) {
			local.argumentName = ListGetAt(local.optionalArguments, local.i);
			if (StructKeyExists(this, local.argumentName)) {
				local.options[local.argumentName] = this[local.argumentName];
			}
		}
		arguments.sql = this.adapter.addPrimaryKeyOptions(sql = arguments.sql, options = local.options);
		return arguments.sql;
	}

}
