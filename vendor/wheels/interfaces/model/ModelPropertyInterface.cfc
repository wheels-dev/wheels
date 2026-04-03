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
	 * Return the database table name for this model (getter only).
	 * Use `table()` to set the table name.
	 *
	 * @return The table name.
	 */
	public string function tableName();

	/**
	 * Set the primary key column(s) for this model.
	 *
	 * @property Comma-delimited list of column names that form the primary key.
	 */
	public void function setPrimaryKey(string property);

	/**
	 * Map this model to a specific database table. Pass `false` to disable table mapping.
	 *
	 * @name The database table name, or `false` to disable table mapping.
	 */
	public void function table(required any name);

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
	 * When `position` is specified, returns just that key (1-based index).
	 *
	 * @position 1-based index of a specific primary key column to return.
	 */
	public string function primaryKeys(numeric position);

	/**
	 * Return primary key column name(s). Alias for `primaryKeys()`.
	 *
	 * @position 1-based index of a specific primary key column to return.
	 */
	public string function primaryKey(numeric position);

}
