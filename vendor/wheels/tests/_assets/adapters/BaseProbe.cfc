/**
 * Test double for the Base database adapter. Captures every SQL string passed
 * to $query() and serves mock resultsets from a FIFO queue instead of hitting
 * a database, so adapter-unit specs can exercise the identity-retrieval
 * template without a live connection.
 */
component extends="wheels.databaseAdapters.Base" output=false {

	this.boxlangMode = false;
	this.capturedSql = [];
	// FIFO queue of mock query objects served by $query().
	this.queryResults = [];

	public boolean function $isBoxLangEngine() {
		return this.boxlangMode;
	}

	public any function $query(required string sql) {
		ArrayAppend(this.capturedSql, arguments.sql);
		if (ArrayLen(this.queryResults)) {
			local.queued = this.queryResults[1];
			ArrayDeleteAt(this.queryResults, 1);
			return local.queued;
		}
		return QueryNew("lastId", "varchar", [{lastId: ""}]);
	}

	public struct function $performQuery(
		required array sql,
		required boolean parameterize,
		numeric limit = 0,
		numeric offset = 0,
		string dataSource = "",
		string $primaryKey = "",
		string $debugName = "query"
	) {
		return {sql: arguments.sql};
	}

}
