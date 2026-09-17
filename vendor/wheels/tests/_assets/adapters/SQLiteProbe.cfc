component extends="wheels.databaseAdapters.SQLite.SQLiteModel" output=false {

	this.capturedSql = [];
	this.queryResults = [];

	public any function $query(required string sql) {
		ArrayAppend(this.capturedSql, arguments.sql);
		if (ArrayLen(this.queryResults)) {
			local.queued = this.queryResults[1];
			ArrayDeleteAt(this.queryResults, 1);
			return local.queued;
		}
		return QueryNew("lastId", "varchar", [{lastId: ""}]);
	}

}
