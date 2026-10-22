/**
 * Test double for the $performQuery() argument forwarding in performance-slice part B.
 * Extends the SQLite adapter (its identifier quoting only; nothing reaches a database) and
 * records the queryAttributes of every $executeQuery() call instead of running the query, so a
 * spec can pin exactly which arguments stay builder-only and which are forwarded as query
 * attributes.
 */
component extends="wheels.databaseAdapters.SQLite.SQLiteModel" output=false {

	this.capturedQueryAttributes = [];

	public struct function $executeQuery(
		required struct queryAttributes,
		required array sql,
		required boolean parameterize,
		required numeric limit,
		required numeric offset,
		required string comment,
		required string debugName,
		required string primaryKey
	) {
		ArrayAppend(this.capturedQueryAttributes, Duplicate(arguments.queryAttributes));
		return {result = {}};
	}

}
