component extends="Base" {

	public any function init(required any adapter, required string name) {
		local.args = "adapter,name,selectSql";
		this.selectSql = "";
		local.iEnd = ListLen(local.args);
		for (local.i = 1; local.i <= local.iEnd; local.i++) {
			local.argumentName = ListGetAt(local.args, local.i);
			if (StructKeyExists(arguments, local.argumentName)) {
				this[local.argumentName] = arguments[local.argumentName];
			}
		}
		return this;
	}

	/**
	 * Select statement to build view.
	 */
	public any function selectStatement(required string sql) {
		this.selectSql = arguments.sql;
		return this;
	}

	/**
	 * Creates the table in the database.
	 */
	public void function create() {
		$execute(this.adapter.createView(name = this.name, sql = this.selectSql));
		announce("Created view #objectCase(this.name)#");
	}

}
