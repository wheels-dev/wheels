/**
 * Contract for model association definitions (hasMany, hasOne, belongsTo).
 *
 * The default implementation lives in `wheels.model.associations` and is mixed
 * into Model instances at runtime. Compliance is verified by runtime reflection tests.
 *
 * Associations are declared in a model's `config()` method and affect how
 * `findAll(include="...")` joins related tables.
 *
 * [section: Model]
 * [category: Interface]
 */
interface {

	/**
	 * Declare a one-to-many association.
	 *
	 * @name Name of the association (also used as the include key).
	 * @modelName Model class to associate with (default: singularize `name`).
	 * @foreignKey Column on the associated table pointing back to this model.
	 * @joinKey Column on this table used for the join (default: primary key).
	 * @joinType SQL join type: "inner" or "outer".
	 * @dependent What to do with associated records on delete: "delete", "deleteAll", "removeAll", or "false".
	 * @shortcut Name of a shortcut through a join model (many-to-many).
	 * @through The join model association name for shortcut.
	 */
	public void function hasMany(
		string name,
		string modelName,
		string foreignKey,
		string joinKey,
		string joinType,
		string dependent,
		string shortcut,
		string through
	);

	/**
	 * Declare a one-to-one association (this model has the primary key).
	 *
	 * @name Name of the association.
	 * @modelName Model class to associate with.
	 * @foreignKey Column on the associated table pointing back to this model.
	 * @joinKey Column on this table used for the join.
	 * @joinType SQL join type.
	 * @dependent What to do with the associated record on delete.
	 */
	public void function hasOne(
		string name,
		string modelName,
		string foreignKey,
		string joinKey,
		string joinType,
		string dependent
	);

	/**
	 * Declare a belongs-to association (this model holds the foreign key).
	 *
	 * @name Name of the association.
	 * @modelName Model class to associate with.
	 * @foreignKey Column on this table pointing to the associated model.
	 * @joinKey Column on the associated table (default: its primary key).
	 * @joinType SQL join type.
	 */
	public void function belongsTo(
		string name,
		string modelName,
		string foreignKey,
		string joinKey,
		string joinType
	);

}
