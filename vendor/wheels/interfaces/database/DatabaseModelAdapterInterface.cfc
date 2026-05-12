/**
 * Contract for database model adapters (query execution and column introspection).
 *
 * The default implementation lives in `wheels.databaseAdapters.Base` (extends
 * `wheels.Global`). Concrete adapters: `MySQLModel`, `PostgreSQLModel`, `H2Model`,
 * `MicrosoftSQLServerModel`, `OracleModel`, `SQLiteModel`, `CockroachDBModel`.
 *
 * This is the query-side adapter. For schema DDL (migrations), see
 * `DatabaseMigratorAdapterInterface`.
 *
 * [section: Database]
 * [category: Interface]
 */
interface {

	/**
	 * Initialize the adapter with datasource credentials.
	 *
	 * @dataSource CFML datasource name.
	 * @username Database username.
	 * @password Database password.
	 * @return The initialized adapter instance.
	 */
	public any function $init(required string dataSource, required string username, required string password);

	/**
	 * Execute a query using the Wheels SQL builder output.
	 *
	 * @queryAttributes Struct of cfquery tag attributes.
	 * @sql Array of SQL fragments and parameter structs.
	 * @parameterize Whether to use cfqueryparam.
	 * @limit Maximum rows to return.
	 * @offset Rows to skip.
	 * @comment SQL comment to prepend.
	 * @debugName Name for debug/logging output.
	 * @primaryKey Primary key column name(s).
	 * @return Struct with keys: query (the result set), result (cfquery result metadata).
	 */
	public struct function $executeQuery(
		required struct queryAttributes,
		required array sql,
		required boolean parameterize,
		required numeric limit,
		required numeric offset,
		required string comment,
		required string debugName,
		required string primaryKey
	);

	/**
	 * Lower-level query execution (called by `$executeQuery` and other internal methods).
	 *
	 * @sql Array of SQL fragments.
	 * @parameterize Whether to use cfqueryparam.
	 * @limit Maximum rows.
	 * @offset Rows to skip.
	 * @dataSource Override datasource.
	 * @$primaryKey Primary key for identity retrieval.
	 * @$debugName Debug/logging name.
	 * @return Struct with query and result metadata.
	 */
	public struct function $performQuery(
		required array sql,
		required boolean parameterize,
		numeric limit,
		numeric offset,
		string dataSource,
		string $primaryKey,
		string $debugName
	);

	/**
	 * Retrieve the auto-generated identity/key after an INSERT.
	 *
	 * @queryAttributes Struct of cfquery attributes.
	 * @result The cfquery result struct from the INSERT.
	 * @primaryKey Primary key column name.
	 * @returningIdentity Engine-specific identity retrieval hint.
	 * @return The generated key value.
	 */
	public any function $identitySelect(
		required struct queryAttributes,
		required struct result,
		required string primaryKey,
		any returningIdentity
	);

	/**
	 * Return the engine-specific key name for auto-generated identity values.
	 * E.g., "GENERATED_KEY" for MySQL, "identitycol" for SQL Server.
	 */
	public string function $generatedKey();

	/**
	 * Return column metadata for a table.
	 *
	 * @tableName The database table name.
	 * @return Query object with column details.
	 */
	public query function $getColumns(required string tableName);

	/**
	 * Return raw column info from the datasource (via cfdbinfo or equivalent).
	 *
	 * @table Table name.
	 * @datasource CFML datasource name.
	 * @username Database username.
	 * @password Database password.
	 * @return Query of column metadata.
	 */
	public query function $getColumnInfo(required string table, required string datasource, required string username, required string password);

	/**
	 * Map a database column type to a Wheels validation type.
	 *
	 * @type The database column type string.
	 * @return The Wheels validation type ("string", "numeric", "date", etc.).
	 */
	public string function $getValidationType(required string type);

	/**
	 * Quote a database identifier (table or column name) for the target engine.
	 *
	 * @name The identifier to quote.
	 * @return The quoted identifier (e.g., `` `name` `` for MySQL, `"name"` for PostgreSQL).
	 */
	public string function $quoteIdentifier(required string name);

	/**
	 * Quote a literal value for SQL inclusion.
	 *
	 * @str The value to quote.
	 * @sqlType Optional SQL type hint.
	 * @type Optional Wheels type hint.
	 * @return The quoted value string.
	 */
	public string function $quoteValue(required string str, string sqlType, string type);

	/**
	 * Remove identifier quoting characters from a string.
	 *
	 * @str The string to strip.
	 * @return The unquoted string.
	 */
	public string function $stripIdentifierQuotes(required string str);

	/**
	 * Generate a table alias expression for SQL.
	 *
	 * @table The table name.
	 * @alias The alias to assign.
	 * @return SQL fragment like "tablename AS alias".
	 */
	public string function $tableAlias(required string table, required string alias);

	/**
	 * Process a comma-delimited table name list for a given SQL action.
	 *
	 * @list Comma-delimited table names.
	 * @action The SQL action context.
	 * @return Processed table name string.
	 */
	public string function $tableName(required string list, required string action);

	/**
	 * Process column alias expressions for a given SQL action.
	 *
	 * @list Comma-delimited column expressions.
	 * @action The SQL action context.
	 * @return Processed column alias string.
	 */
	public string function $columnAlias(required string list, required string action);

	/**
	 * Remove column aliases from ORDER BY clauses (required for some engines).
	 *
	 * @args Query builder args struct (modified in place).
	 */
	public void function $removeColumnAliasesInOrderClause(required struct args);

	/**
	 * Check whether a SQL expression contains an aggregate function.
	 *
	 * @sql The SQL expression to check.
	 * @return True if the expression contains COUNT, SUM, AVG, MIN, MAX, etc.
	 */
	public boolean function $isAggregateFunction(required string sql);

	/**
	 * Add required columns to SELECT and GROUP BY for aggregate queries.
	 *
	 * @args Query builder args struct (modified in place).
	 */
	public void function $addColumnsToSelectAndGroupBy(required struct args);

	/**
	 * Convert maxRows to a LIMIT clause for the target engine.
	 *
	 * @args Query builder args struct (modified in place).
	 */
	public void function $convertMaxRowsToLimit(required struct args);

	/**
	 * Move aggregate expressions from WHERE to HAVING clause.
	 *
	 * @args Query builder args struct (modified in place).
	 */
	public void function $moveAggregateToHaving(required struct args);

	/**
	 * Return the engine-specific SQL fragment for random ordering.
	 * E.g., "RAND()" for MySQL, "RANDOM()" for PostgreSQL.
	 */
	public string function $randomOrder();

	/**
	 * Return the engine-specific SQL for a DEFAULT VALUES insert.
	 */
	public string function $defaultValues();

	/**
	 * Wrap text in a SQL comment.
	 *
	 * @text The comment text.
	 * @return SQL comment string.
	 */
	public string function $comment(required string text);

	/**
	 * Clean values inside an IN(...) statement for safe SQL generation.
	 *
	 * @statement The IN clause content.
	 * @return Cleaned statement string.
	 */
	public string function $cleanInStatementValue(required string statement);

	/**
	 * Convert Wheels parameter settings to cfqueryparam attributes.
	 *
	 * @settings Struct of parameter configuration.
	 * @return Struct of cfqueryparam-compatible attributes.
	 */
	public struct function $queryParams(required struct settings);

	/**
	 * Mark this adapter instance as shared (used by multiple model classes).
	 *
	 * @flag True to mark as shared, false for exclusive use.
	 */
	public void function $setSharedModel(required boolean flag);

	/**
	 * Check whether this adapter instance is shared across model classes.
	 */
	public boolean function $isSharedModel();

}
