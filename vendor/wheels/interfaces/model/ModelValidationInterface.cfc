/**
 * Contract for model validation registration and execution.
 *
 * The default implementation lives in `wheels.model.validations` and is mixed
 * into Model instances at runtime. Compliance is verified by runtime reflection tests.
 *
 * Validators are registered in a model's `config()` method and executed when
 * `valid()` or `save(validate=true)` is called.
 *
 * [section: Model]
 * [category: Interface]
 */
interface {

	/**
	 * Toggle automatic validations (inferred from database column constraints).
	 *
	 * @value True to enable, false to disable.
	 */
	public void function automaticValidations(required boolean value);

	/**
	 * Register custom validation methods that run on both create and update.
	 *
	 * @methods Comma-delimited list of method names to call.
	 * @condition CFML expression that must be true for validation to run.
	 * @unless CFML expression that must be false for validation to run.
	 * @when When to run: "onCreate", "onUpdate", or blank for both.
	 */
	public void function validate(string methods, string condition, string unless, string when);

	/**
	 * Register custom validation methods that run only on create.
	 *
	 * @methods Comma-delimited list of method names.
	 * @condition CFML expression.
	 * @unless CFML expression.
	 */
	public void function validateOnCreate(string methods, string condition, string unless);

	/**
	 * Register custom validation methods that run only on update.
	 *
	 * @methods Comma-delimited list of method names.
	 * @condition CFML expression.
	 * @unless CFML expression.
	 */
	public void function validateOnUpdate(string methods, string condition, string unless);

	/**
	 * Validate that the specified properties are not blank.
	 *
	 * @properties Comma-delimited list of property names.
	 * @message Custom error message.
	 * @when When to run.
	 * @condition CFML expression.
	 * @unless CFML expression.
	 */
	public void function validatesPresenceOf(string properties, string message, string when, string condition, string unless);

	/**
	 * Validate that the specified properties are unique in the database.
	 *
	 * @properties Comma-delimited list of property names.
	 * @message Custom error message.
	 * @when When to run.
	 * @allowBlank Allow blank values to pass.
	 * @scope Additional columns to include in the uniqueness check.
	 * @condition CFML expression.
	 * @unless CFML expression.
	 * @includeSoftDeletes Include soft-deleted records in uniqueness check.
	 */
	public void function validatesUniquenessOf(
		string properties,
		string message,
		string when,
		boolean allowBlank,
		string scope,
		string condition,
		string unless,
		boolean includeSoftDeletes
	);

	/**
	 * Validate the length of the specified properties.
	 *
	 * @properties Comma-delimited list of property names.
	 * @message Custom error message.
	 * @when When to run.
	 * @allowBlank Allow blank values.
	 * @exactly Exact length required.
	 * @maximum Maximum length allowed.
	 * @minimum Minimum length required.
	 * @within Range as "min,max".
	 * @condition CFML expression.
	 * @unless CFML expression.
	 */
	public void function validatesLengthOf(
		string properties,
		string message,
		string when,
		boolean allowBlank,
		numeric exactly,
		numeric maximum,
		numeric minimum,
		string within,
		string condition,
		string unless
	);

	/**
	 * Validate the format of the specified properties using regex or named type.
	 *
	 * @properties Comma-delimited list of property names.
	 * @regEx Regular expression pattern.
	 * @type Named format type (e.g., "email", "URL").
	 * @message Custom error message.
	 * @when When to run.
	 * @allowBlank Allow blank values.
	 * @condition CFML expression.
	 * @unless CFML expression.
	 */
	public void function validatesFormatOf(
		string properties,
		string regEx,
		string type,
		string message,
		string when,
		boolean allowBlank,
		string condition,
		string unless
	);

	/**
	 * Validate that the specified properties contain numeric values.
	 *
	 * @properties Comma-delimited list of property names.
	 * @message Custom error message.
	 * @when When to run.
	 * @allowBlank Allow blank values.
	 * @onlyInteger Only allow integer values.
	 * @odd Value must be odd.
	 * @even Value must be even.
	 * @greaterThan Value must be greater than this.
	 * @greaterThanOrEqualTo Value must be >= this.
	 * @equalTo Value must equal this.
	 * @lessThan Value must be less than this.
	 * @lessThanOrEqualTo Value must be <= this.
	 * @condition CFML expression.
	 * @unless CFML expression.
	 */
	public void function validatesNumericalityOf(
		string properties,
		string message,
		string when,
		boolean allowBlank,
		boolean onlyInteger,
		boolean odd,
		boolean even,
		numeric greaterThan,
		numeric greaterThanOrEqualTo,
		numeric equalTo,
		numeric lessThan,
		numeric lessThanOrEqualTo,
		string condition,
		string unless
	);

	/**
	 * Validate that the specified properties contain values from the given list.
	 *
	 * @properties Comma-delimited list of property names.
	 * @list Comma-delimited list of allowed values.
	 * @message Custom error message.
	 * @when When to run.
	 * @allowBlank Allow blank values.
	 * @condition CFML expression.
	 * @unless CFML expression.
	 */
	public void function validatesInclusionOf(
		string properties,
		required string list,
		string message,
		string when,
		boolean allowBlank,
		string condition,
		string unless
	);

	/**
	 * Validate that the specified properties do NOT contain values from the given list.
	 *
	 * @properties Comma-delimited list of property names.
	 * @list Comma-delimited list of disallowed values.
	 * @message Custom error message.
	 * @when When to run.
	 * @allowBlank Allow blank values.
	 * @condition CFML expression.
	 * @unless CFML expression.
	 */
	public void function validatesExclusionOf(
		string properties,
		required string list,
		string message,
		string when,
		boolean allowBlank,
		string condition,
		string unless
	);

	/**
	 * Validate that the specified properties match a confirmation field (e.g., passwordConfirmation).
	 *
	 * @properties Comma-delimited list of property names.
	 * @message Custom error message.
	 * @when When to run.
	 * @caseSensitive Whether the comparison is case-sensitive.
	 * @condition CFML expression.
	 * @unless CFML expression.
	 */
	public void function validatesConfirmationOf(
		string properties,
		string message,
		string when,
		boolean caseSensitive,
		string condition,
		string unless
	);

	/**
	 * Run all registered validations and return whether the model is valid.
	 *
	 * @callbacks Whether to run beforeValidation/afterValidation callbacks.
	 * @validateAssociations Whether to also validate associated models.
	 * @return True if all validations passed.
	 */
	public boolean function valid(boolean callbacks, boolean validateAssociations);

}
