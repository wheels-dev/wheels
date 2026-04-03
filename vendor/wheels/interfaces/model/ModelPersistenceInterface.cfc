/**
 * Contract for model write operations (create, save, update, delete).
 *
 * The default implementation lives in `wheels.model.crud` and is mixed into
 * Model instances at runtime via `$integrateComponents()`. Compliance is
 * verified by runtime reflection tests.
 *
 * [section: Model]
 * [category: Interface]
 */
interface {

	/**
	 * Create an unsaved model instance with the given properties.
	 *
	 * @properties Struct of property name/value pairs.
	 * @callbacks Whether to run afterNew callbacks.
	 * @allowExplicitTimestamps Whether to allow manual createdAt/updatedAt values.
	 */
	public any function new(struct properties, boolean callbacks, boolean allowExplicitTimestamps);

	/**
	 * Create and save a new record in a single call.
	 *
	 * @properties Struct of property name/value pairs.
	 * @parameterize Use cfqueryparam.
	 * @reload Reload the object from the database after saving.
	 * @validate Run validations before saving.
	 * @transaction Transaction mode: "commit", "rollback", or "none".
	 * @callbacks Run before/after callbacks.
	 * @allowExplicitTimestamps Allow manual timestamp values.
	 */
	public any function create(
		struct properties,
		any parameterize,
		boolean reload,
		boolean validate,
		string transaction,
		boolean callbacks,
		boolean allowExplicitTimestamps
	);

	/**
	 * Persist the current model instance to the database (insert or update).
	 *
	 * @parameterize Use cfqueryparam.
	 * @reload Reload from database after saving.
	 * @validate Run validations.
	 * @transaction Transaction mode.
	 * @callbacks Run callbacks.
	 * @return True if the save succeeded (validations passed).
	 */
	public boolean function save(
		any parameterize,
		boolean reload,
		boolean validate,
		string transaction,
		boolean callbacks
	);

	/**
	 * Update the current model instance with the given properties and save.
	 *
	 * @properties Struct of property name/value pairs to update.
	 * @parameterize Use cfqueryparam.
	 * @reload Reload after saving.
	 * @validate Run validations.
	 * @transaction Transaction mode.
	 * @callbacks Run callbacks.
	 * @allowExplicitTimestamps Allow manual timestamps.
	 * @return True if the update succeeded.
	 */
	public boolean function update(
		struct properties,
		any parameterize,
		boolean reload,
		boolean validate,
		string transaction,
		boolean callbacks,
		boolean allowExplicitTimestamps
	);

	/**
	 * Update all records matching the criteria without instantiating them.
	 *
	 * @where SQL WHERE clause.
	 * @include Associations to join.
	 * @properties Struct of property name/value pairs.
	 * @reload Reload affected records.
	 * @parameterize Use cfqueryparam.
	 * @instantiate Whether to instantiate each record before updating (for callbacks).
	 * @useIndex Database index hint.
	 * @validate Run validations (only when instantiate=true).
	 * @transaction Transaction mode.
	 * @callbacks Run callbacks (only when instantiate=true).
	 * @includeSoftDeletes Include soft-deleted records.
	 * @return Number of records updated.
	 */
	public numeric function updateAll(
		string where,
		string include,
		struct properties,
		boolean reload,
		any parameterize,
		boolean instantiate,
		string useIndex,
		boolean validate,
		string transaction,
		boolean callbacks,
		boolean includeSoftDeletes
	);

	/**
	 * Find a record by primary key, update it with the given properties, and save.
	 *
	 * @key Primary key value.
	 * @properties Struct of properties to update.
	 * @reload Reload after saving.
	 * @validate Run validations.
	 * @transaction Transaction mode.
	 * @callbacks Run callbacks.
	 * @includeSoftDeletes Include soft-deleted records.
	 * @return The updated model object, or false if not found or validation failed.
	 */
	public any function updateByKey(
		any key,
		struct properties,
		boolean reload,
		boolean validate,
		string transaction,
		boolean callbacks,
		boolean includeSoftDeletes
	);

	/**
	 * Find the first matching record, update it, and save.
	 *
	 * @where SQL WHERE clause.
	 * @order SQL ORDER BY clause.
	 * @properties Struct of properties to update.
	 * @reload Reload after saving.
	 * @validate Run validations.
	 * @useIndex Database index hint.
	 * @transaction Transaction mode.
	 * @callbacks Run callbacks.
	 * @includeSoftDeletes Include soft-deleted records.
	 */
	public any function updateOne(
		string where,
		string order,
		struct properties,
		boolean reload,
		boolean validate,
		string useIndex,
		string transaction,
		boolean callbacks,
		boolean includeSoftDeletes
	);

	/**
	 * Update a single property on the current instance and save immediately.
	 *
	 * @property Property name.
	 * @value New value.
	 * @parameterize Use cfqueryparam.
	 * @transaction Transaction mode.
	 * @callbacks Run callbacks.
	 * @return True if the update succeeded.
	 */
	public boolean function updateProperty(
		string property,
		any value,
		any parameterize,
		string transaction,
		boolean callbacks
	);

	/**
	 * Delete the current model instance from the database.
	 *
	 * @parameterize Use cfqueryparam.
	 * @transaction Transaction mode.
	 * @callbacks Run callbacks.
	 * @includeSoftDeletes Include soft-deleted records.
	 * @softDelete Whether to soft-delete (set deletedAt) instead of hard-delete.
	 * @return True if the record was deleted.
	 */
	public boolean function delete(
		any parameterize,
		string transaction,
		boolean callbacks,
		boolean includeSoftDeletes,
		boolean softDelete
	);

	/**
	 * Delete all records matching the criteria without instantiating them.
	 *
	 * @where SQL WHERE clause.
	 * @include Associations to join.
	 * @reload Reload affected records.
	 * @parameterize Use cfqueryparam.
	 * @instantiate Instantiate each record before deleting (for callbacks).
	 * @useIndex Database index hint.
	 * @transaction Transaction mode.
	 * @callbacks Run callbacks (only when instantiate=true).
	 * @includeSoftDeletes Include soft-deleted records.
	 * @softDelete Soft-delete instead of hard-delete.
	 * @return Number of records deleted.
	 */
	public numeric function deleteAll(
		string where,
		string include,
		boolean reload,
		any parameterize,
		boolean instantiate,
		string useIndex,
		string transaction,
		boolean callbacks,
		boolean includeSoftDeletes,
		boolean softDelete
	);

	/**
	 * Find a record by primary key and delete it.
	 *
	 * @key Primary key value.
	 * @reload Reload before deleting.
	 * @transaction Transaction mode.
	 * @callbacks Run callbacks.
	 * @includeSoftDeletes Include soft-deleted records.
	 * @softDelete Soft-delete instead of hard-delete.
	 * @return True if the record was found and deleted.
	 */
	public boolean function deleteByKey(
		any key,
		boolean reload,
		string transaction,
		boolean callbacks,
		boolean includeSoftDeletes,
		boolean softDelete
	);

	/**
	 * Find the first matching record and delete it.
	 *
	 * @where SQL WHERE clause.
	 * @order SQL ORDER BY clause.
	 * @reload Reload before deleting.
	 * @transaction Transaction mode.
	 * @callbacks Run callbacks.
	 * @includeSoftDeletes Include soft-deleted records.
	 * @useIndex Database index hint.
	 * @softDelete Soft-delete instead of hard-delete.
	 * @return True if a record was found and deleted.
	 */
	public boolean function deleteOne(
		string where,
		string order,
		boolean reload,
		string transaction,
		boolean callbacks,
		boolean includeSoftDeletes,
		string useIndex,
		boolean softDelete
	);

}
