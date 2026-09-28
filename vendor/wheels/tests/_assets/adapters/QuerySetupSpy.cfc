/**
 * Test double that records the `$captureResult` argument of every $querySetup() call
 * instead of running the query, so specs can pin what the bulk paths ask the adapter
 * for (#3653). Extends the SQLite adapter only for its SQL builders ($upsertSQL,
 * identifier quoting); nothing reaches a database.
 */
component extends="wheels.databaseAdapters.SQLite.SQLiteModel" output=false {

	this.captureResult = [];

	public struct function $querySetup(
		required array sql,
		numeric limit = 0,
		numeric offset = 0,
		required boolean parameterize,
		string $primaryKey = ""
	) {
		// Recorded as a string so the comparison cannot depend on how an engine
		// represents a boolean that travelled through argumentCollection.
		if (!StructKeyExists(arguments, "$captureResult")) {
			ArrayAppend(this.captureResult, "not passed");
		} else if (arguments["$captureResult"]) {
			ArrayAppend(this.captureResult, "true");
		} else {
			ArrayAppend(this.captureResult, "false");
		}
		return {result = {}};
	}

}
