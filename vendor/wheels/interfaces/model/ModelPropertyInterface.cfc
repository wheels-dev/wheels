/**
 * Contract for model property and column introspection plus configuration.
 *
 * The default implementation lives in `wheels.model.properties` and is mixed
 * into Model instances at runtime. Compliance is verified by runtime reflection tests.
 *
 * This interface combines config-time setters (called in `config()`) with
 * runtime getters (called anywhere). Both relate to the same concern: "what
 * properties does this model have and how are they mapped?"
 *
 * [section: Model]
 * [category: Interface]
 */
interface {

	/**
	 * Set or get the database table name for this model.
	 * When called with `name`, sets the table name. Returns the current table name.
	 *
	 * @name The database table name to use.
	 * @return The table name.
	 */
	public string function tableName(string name);

	/**
	 * Set the primary key column(s) for this model.
	 *
	 * @property Comma-delimited list of column names that form the primary key.
	 */
	public void function setPrimaryKey(string property);

	/**
	 * Map this model to a specific database table (alias for `tableName`).
	 *
	 * @name The database table name.
	 */
	public void function table(string name);

	/**
	 * Return a struct of all property name/value pairs on the current instance.
	 *
	 * @return Struct where keys are property names and values are current values.
	 */
	public struct function properties();

	/**
	 * Bulk-set property values from a struct.
	 *
	 * @properties Struct of property name/value pairs.
	 */
	public void function setProperties(struct properties);

	/**
	 * Return true if this instance has not been saved to the database.
	 */
	public boolean function isNew();

	/**
	 * Return true if this instance exists in the database (opposite of isNew).
	 */
	public boolean function isPersisted();

	/**
	 * Return the primary key value(s) for this instance as a string.
	 * For composite keys, values are comma-delimited.
	 */
	public string function key();

	/**
	 * Return a comma-delimited list of column names for this model's table.
	 */
	public string function columnNames();

	/**
	 * Return a comma-delimited list of primary key column names.
	 */
	public string function primaryKeys();

}
