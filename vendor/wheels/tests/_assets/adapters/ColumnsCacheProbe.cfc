component extends="wheels.databaseAdapters.Base" output=false {

	this.columnInfoCalls = 0;
	this.freshColumns = QueryNew("column_name", "varchar", [{column_name: "fresh_id"}]);

	public any function $get(required string name, string functionName = "") {
		if (arguments.name == "cacheDatabaseSchema") {
			return true;
		}
		if (arguments.name == "showErrorInformation") {
			return false;
		}
		return false;
	}

	public query function $getColumnInfo() {
		this.columnInfoCalls++;
		return this.freshColumns;
	}

}
