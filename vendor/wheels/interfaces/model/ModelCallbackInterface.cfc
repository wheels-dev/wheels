/**
 * Contract for model lifecycle callbacks (hooks).
 *
 * The default implementation lives in `wheels.model.callbacks` and is mixed
 * into Model instances at runtime. Compliance is verified by runtime reflection tests.
 *
 * Callbacks are registered in a model's `config()` method and fire automatically
 * during create, update, save, delete, find, and validation operations.
 *
 * [section: Model]
 * [category: Interface]
 */
interface {

	/**
	 * Register methods to run before any validation (create or update).
	 * @methods Comma-delimited list of method names.
	 */
	public void function beforeValidation(string methods);

	/**
	 * Register methods to run after all validations pass (create or update).
	 * @methods Comma-delimited list of method names.
	 */
	public void function afterValidation(string methods);

	/**
	 * Register methods to run before validation on create only.
	 * @methods Comma-delimited list of method names.
	 */
	public void function beforeValidationOnCreate(string methods);

	/**
	 * Register methods to run after validation on create only.
	 * @methods Comma-delimited list of method names.
	 */
	public void function afterValidationOnCreate(string methods);

	/**
	 * Register methods to run before validation on update only.
	 * @methods Comma-delimited list of method names.
	 */
	public void function beforeValidationOnUpdate(string methods);

	/**
	 * Register methods to run after validation on update only.
	 * @methods Comma-delimited list of method names.
	 */
	public void function afterValidationOnUpdate(string methods);

	/**
	 * Register methods to run before a new record is inserted.
	 * @methods Comma-delimited list of method names.
	 */
	public void function beforeCreate(string methods);

	/**
	 * Register methods to run after a new record is inserted.
	 * @methods Comma-delimited list of method names.
	 */
	public void function afterCreate(string methods);

	/**
	 * Register methods to run before an existing record is updated.
	 * @methods Comma-delimited list of method names.
	 */
	public void function beforeUpdate(string methods);

	/**
	 * Register methods to run after an existing record is updated.
	 * @methods Comma-delimited list of method names.
	 */
	public void function afterUpdate(string methods);

	/**
	 * Register methods to run before save (fires on both create and update).
	 * @methods Comma-delimited list of method names.
	 */
	public void function beforeSave(string methods);

	/**
	 * Register methods to run after save (fires on both create and update).
	 * @methods Comma-delimited list of method names.
	 */
	public void function afterSave(string methods);

	/**
	 * Register methods to run before a record is deleted.
	 * @methods Comma-delimited list of method names.
	 */
	public void function beforeDelete(string methods);

	/**
	 * Register methods to run after a record is deleted.
	 * @methods Comma-delimited list of method names.
	 */
	public void function afterDelete(string methods);

	/**
	 * Register methods to run after `new()` creates an unsaved instance.
	 * @methods Comma-delimited list of method names.
	 */
	public void function afterNew(string methods);

	/**
	 * Register methods to run after a record is loaded from the database.
	 * @methods Comma-delimited list of method names.
	 */
	public void function afterFind(string methods);

	/**
	 * Register methods to run after the model class is fully initialized (config complete).
	 * @methods Comma-delimited list of method names.
	 */
	public void function afterInitialization(string methods);

}
