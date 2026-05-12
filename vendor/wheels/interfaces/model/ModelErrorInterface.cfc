/**
 * Contract for model error reporting and inspection.
 *
 * The default implementation lives in `wheels.model.errors` and is mixed into
 * Model instances at runtime via `$integrateComponents()`. Because of this
 * mixin pattern, concrete models cannot use `implements=` at compile time.
 * Compliance is verified by runtime reflection tests instead.
 *
 * These methods are the complement to `ModelValidationInterface` — validations
 * register rules, while errors report the results of running those rules.
 * Any model replacement must implement both interfaces for a complete validation story.
 *
 * Community replacements: implement every method below and register via
 * `bind("ModelErrorInterface").to("your.CustomErrors")` in `config/services.cfm`.
 *
 * [section: Model]
 * [category: Interface]
 */
interface {

	/**
	 * Add an error message on a specific property.
	 *
	 * @property The property name the error belongs to.
	 * @message The error message text.
	 * @name Optional error name/category for grouping.
	 */
	public void function addError(required string property, required string message, string name);

	/**
	 * Add an error message to the model base (not tied to a specific property).
	 *
	 * @message The error message text.
	 * @name Optional error name/category for grouping.
	 */
	public void function addErrorToBase(required string message, string name);

	/**
	 * Return an array of all error structs on the object.
	 * Each struct contains `property`, `message`, and `name` keys.
	 *
	 * @includeAssociations Whether to include errors from associated models.
	 * @seenErrors Internal tracking array to prevent infinite recursion with circular associations.
	 */
	public array function allErrors(boolean includeAssociations, array seenErrors);

	/**
	 * Clear all errors, or only errors on a specific property/name.
	 *
	 * @property Clear only errors on this property (empty string = all).
	 * @name Clear only errors with this name.
	 */
	public void function clearErrors(string property, string name);

	/**
	 * Return the number of errors, optionally filtered by property and/or name.
	 *
	 * @property Count only errors on this property.
	 * @name Count only errors with this name.
	 */
	public numeric function errorCount(string property, string name);

	/**
	 * Return an array of error structs for a specific property.
	 *
	 * @property The property name to get errors for.
	 * @name Optional error name filter.
	 */
	public array function errorsOn(required string property, string name);

	/**
	 * Return an array of base-level error structs (not tied to any property).
	 *
	 * @name Optional error name filter.
	 */
	public array function errorsOnBase(string name);

	/**
	 * Return true if the object has any errors, optionally filtered by property/name.
	 *
	 * @property Check only this property for errors.
	 * @name Check only errors with this name.
	 */
	public boolean function hasErrors(string property, string name);

}
