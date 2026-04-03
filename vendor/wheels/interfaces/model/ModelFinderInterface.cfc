/**
 * Contract for model read operations (finders, counting, existence checks).
 *
 * The default implementation lives in `wheels.model.read` and is mixed into
 * Model instances at runtime via `$integrateComponents()`. Because of this
 * mixin pattern, concrete models cannot use `implements=` at compile time.
 * Compliance is verified by runtime reflection tests instead.
 *
 * Community replacements: implement every method below and register via
 * `bind("ModelFinderInterface").to("your.CustomFinder")` in `config/services.cfm`.
 *
 * [section: Model]
 * [category: Interface]
 */
interface {

	/**
	 * Return all records matching the given criteria.
	 *
	 * @where SQL WHERE clause (use `parameterize=true` to auto-quote values).
	 * @order SQL ORDER BY clause.
	 * @group SQL GROUP BY clause.
	 * @select Comma-delimited list of columns to return.
	 * @distinct Whether to apply SELECT DISTINCT.
	 * @include Comma-delimited list of associations to join.
	 * @maxRows Maximum number of rows to return.
	 * @page Page number for pagination (requires `perPage`).
	 * @perPage Records per page (requires `page`).
	 * @count If true, return just the count instead of records.
	 * @handle Named handle for pagination helpers.
	 * @cache Minutes to cache the query result.
	 * @reload Force fresh query even if cached.
	 * @parameterize Whether to use cfqueryparam on values.
	 * @returnAs Return format: "query", "object(s)", "struct(s)".
	 * @returnIncluded Whether to include associated model columns in result.
	 * @callbacks Whether to run afterFind callbacks.
	 * @includeSoftDeletes Whether to include soft-deleted records.
	 * @useIndex Database index hint.
	 * @dataSource Override datasource for this query.
	 */
	public any function findAll(
		string where,
		string order,
		string group,
		string select,
		boolean distinct,
		string include,
		numeric maxRows,
		numeric page,
		numeric perPage,
		boolean count,
		string handle,
		any cache,
		boolean reload,
		any parameterize,
		string returnAs,
		boolean returnIncluded,
		boolean callbacks,
		boolean includeSoftDeletes,
		string useIndex,
		string dataSource
	);

	/**
	 * Return the first record matching the given criteria, or an empty string if not found.
	 *
	 * @where SQL WHERE clause.
	 * @order SQL ORDER BY clause.
	 * @select Comma-delimited list of columns.
	 * @include Associations to join.
	 * @handle Named handle for pagination.
	 * @cache Minutes to cache.
	 * @reload Force fresh query.
	 * @parameterize Use cfqueryparam.
	 * @returnAs Return format.
	 * @includeSoftDeletes Include soft-deleted records.
	 * @useIndex Database index hint.
	 * @dataSource Override datasource.
	 */
	public any function findOne(
		string where,
		string order,
		string select,
		string include,
		string handle,
		any cache,
		boolean reload,
		any parameterize,
		string returnAs,
		boolean includeSoftDeletes,
		string useIndex,
		string dataSource
	);

	/**
	 * Return the record with the given primary key, or an empty string if not found.
	 *
	 * @key Primary key value.
	 * @select Columns to return.
	 * @include Associations to join.
	 * @handle Named handle.
	 * @cache Minutes to cache.
	 * @reload Force fresh query.
	 * @parameterize Use cfqueryparam.
	 * @returnAs Return format.
	 * @callbacks Run afterFind callbacks.
	 * @includeSoftDeletes Include soft-deleted records.
	 * @dataSource Override datasource.
	 */
	public any function findByKey(
		any key,
		string select,
		string include,
		string handle,
		any cache,
		boolean reload,
		any parameterize,
		string returnAs,
		boolean callbacks,
		boolean includeSoftDeletes,
		string dataSource
	);

	/**
	 * Return the first record ordered by primary key (or specified property).
	 *
	 * @property Column to sort by.
	 * @$sort Sort direction override (framework-internal).
	 */
	public any function findFirst(string property, string $sort);

	/**
	 * Return the last record ordered by primary key (or specified property).
	 *
	 * @property Column to sort by.
	 */
	public any function findLastOne(string property);

	/**
	 * Return all primary key values as a delimited string.
	 *
	 * @quoted Whether to quote each value.
	 * @delimiter Separator between values.
	 */
	public string function findAllKeys(boolean quoted, string delimiter);

	/**
	 * Iterate over records one at a time, loading in batches internally for memory efficiency.
	 *
	 * @batchSize Number of records to load per internal query.
	 * @callback Closure receiving each record: `function(record) {}`.
	 * @where SQL WHERE clause.
	 * @order SQL ORDER BY clause.
	 * @include Associations to join.
	 * @select Columns to return.
	 * @parameterize Use cfqueryparam.
	 * @includeSoftDeletes Include soft-deleted records.
	 * @returnAs Return format for each record.
	 */
	public void function findEach(
		numeric batchSize,
		required any callback,
		string where,
		string order,
		string include,
		string select,
		any parameterize,
		boolean includeSoftDeletes,
		string returnAs
	);

	/**
	 * Iterate over records in batch groups, passing each batch to the callback.
	 *
	 * @batchSize Number of records per batch.
	 * @callback Closure receiving each batch: `function(records) {}`.
	 * @where SQL WHERE clause.
	 * @order SQL ORDER BY clause.
	 * @include Associations to join.
	 * @select Columns to return.
	 * @parameterize Use cfqueryparam.
	 * @includeSoftDeletes Include soft-deleted records.
	 * @returnAs Return format for the batch.
	 */
	public void function findInBatches(
		numeric batchSize,
		required any callback,
		string where,
		string order,
		string include,
		string select,
		any parameterize,
		boolean includeSoftDeletes,
		string returnAs
	);

	/**
	 * Return the count of records matching the criteria.
	 *
	 * @where SQL WHERE clause.
	 * @include Associations to join.
	 * @parameterize Use cfqueryparam.
	 * @includeSoftDeletes Include soft-deleted records.
	 */
	public numeric function count(
		string where,
		string include,
		any parameterize,
		boolean includeSoftDeletes
	);

	/**
	 * Return true if at least one record matches the criteria.
	 *
	 * @where SQL WHERE clause.
	 * @key Primary key to check.
	 * @reload Force fresh query.
	 * @parameterize Use cfqueryparam.
	 * @includeSoftDeletes Include soft-deleted records.
	 */
	public boolean function exists(
		string where,
		any key,
		boolean reload,
		any parameterize,
		boolean includeSoftDeletes
	);

	/**
	 * Reload the current model instance from the database, refreshing all properties.
	 */
	public void function reload();

}
