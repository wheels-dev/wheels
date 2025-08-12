component {
	/**
	 * Whether or not to enable default validations for this model.
	 *
	 * [section: Model Configuration]
	 * [category: Validation Functions ]
	 *
	 * @value Set to `true` or `false`.
	 */
	public void function automaticValidations(required boolean value) {
		variables.wheels.class.automaticValidations = arguments.value;
	}

	/**
	 * Registers method(s) that should be called to validate objects before they are saved.
	 *
	 * [section: Model Configuration]
	 * [category: Validation Functions ]
	 *
	 * @methods Method name or list of method names to call. Can also be called with the `method` argument.
	 * @condition [see:validatesConfirmationOf].
	 * @unless [see:validatesConfirmationOf].
	 * @when [see:validatesConfirmationOf].
	 */
	public void function validate(string methods = "", string condition = "", string unless = "", string when = "onSave") {
		$registerValidation(argumentCollection = arguments);
	}

	/**
	 * Registers method(s) that should be called to validate new objects before they are inserted.
	 *
	 * [section: Model Configuration]
	 * [category: Validation Functions ]
	 *
	 * @methods [see:validate].
	 * @condition [see:validatesConfirmationOf].
	 * @unless [see:validatesConfirmationOf].
	 */
	public void function validateOnCreate(string methods = "", string condition = "", string unless = "") {
		$registerValidation(when = "onCreate", argumentCollection = arguments);
	}

	/**
	 * Registers method(s) that should be called to validate existing objects before they are updated.
	 *
	 * [section: Model Configuration]
	 * [category: Validation Functions ]
	 *
	 * @methods [see:validate].
	 * @condition [see:validatesConfirmationOf].
	 * @unless [see:validatesConfirmationOf].
	 */
	public void function validateOnUpdate(string methods = "", string condition = "", string unless = "") {
		$registerValidation(when = "onUpdate", argumentCollection = arguments);
	}

	/**
	 * Validates that the value of the specified property also has an identical confirmation value.
	 * This is common when having a user type in their email address a second time to confirm, confirming a password by typing it a second time, etc.
	 * The confirmation value only exists temporarily and never gets saved to the database.
	 * By convention, the confirmation property has to be named the same as the property with "Confirmation" appended at the end.
	 * Using the password example, to confirm our password property, we would create a property called `passwordConfirmation`.
	 *
	 * [section: Model Configuration]
	 * [category: Validation Functions]
	 *
	 * @properties Name of property or list of property names to validate against (can also be called with the `property` argument).
	 * @message Supply a custom error message here to override the built-in one.
	 * @when Pass in `onCreate` or `onUpdate` to limit when this validation occurs (by default validation will occur on both create and update, i.e. `onSave`).
	 * @condition String expression to be evaluated that decides if validation will be run (if the expression returns `true` validation will run).
	 * @unless String expression to be evaluated that decides if validation will be run (if the expression returns `false` validation will run).
	 * @caseSensitive Ensure the confirmed property comparison is case sensitive
	 */
	public void function validatesConfirmationOf(
		string properties = "",
		string message,
		string when = "onSave",
		string condition = "",
		string unless = "",
		boolean caseSensitive = false
	) {
		$args(name = "validatesConfirmationOf", args = arguments);
		$registerValidation(methods = "$validatesConfirmationOf", argumentCollection = arguments);
	}

	/**
	 * Validates that the value of the specified property does not exist in the supplied list.
	 *
	 * [section: Model Configuration]
	 * [category: Validation Functions ]
	 *
	 * @properties [see:validatesConfirmationOf].
	 * @list Single value or list of values that should not be allowed.
	 * @message [see:validatesConfirmationOf].
	 * @when [see:validatesConfirmationOf].
	 * @allowBlank If set to `true`, validation will be skipped if the property value is an empty string or doesn't exist at all. This is useful if you only want to run this validation after it passes the `validatesPresenceOf` test, thus avoiding duplicate error messages if it doesn't.
	 * @condition [see:validatesConfirmationOf].
	 * @unless [see:validatesConfirmationOf].
	 */
	public void function validatesExclusionOf(
		string properties = "",
		required string list,
		string message,
		string when = "onSave",
		boolean allowBlank,
		string condition = "",
		string unless = ""
	) {
		$args(name = "validatesExclusionOf", args = arguments);
		arguments.list = $listClean(arguments.list);
		$registerValidation(methods = "$validatesExclusionOf", argumentCollection = arguments);
	}

	/**
	 * Validates that the value of the specified property is formatted correctly by matching it against a regular expression using the regEx argument and / or against a built-in CFML validation type using the type argument (creditcard, date, email, etc.).
	 *
	 * [section: Model Configuration]
	 * [category: Validation Functions ]
	 *
	 * @properties [see:validatesConfirmationOf].
	 * @regEx Regular expression to verify against.
	 * @type One of the following types to verify against: creditcard, date, email, eurodate, guid, social_security_number, ssn, telephone, time, URL, USdate, UUID, variableName, zipcode (will be passed through to your CFML engine's IsValid() function).
	 * @message [see:validatesConfirmationOf].
	 * @when [see:validatesConfirmationOf].
	 * @allowBlank [see:validatesExclusionOf].
	 * @condition [see:validatesConfirmationOf].
	 * @unless [see:validatesConfirmationOf].
	 */
	public void function validatesFormatOf(
		string properties = "",
		string regEx = "",
		string type = "",
		string message,
		string when = "onSave",
		boolean allowBlank,
		string condition = "",
		string unless = ""
	) {
		$args(name = "validatesFormatOf", args = arguments);
		if ($get("showErrorInformation")) {
			if (
				Len(arguments.type)
				&& !ListFindNoCase(
					"creditcard,date,email,eurodate,guid,social_security_number,ssn,telephone,time,URL,USdate,UUID,variableName,zipcode,boolean",
					arguments.type
				)
			) {
				Throw(
					type = "Wheels.IncorrectArguments",
					message = "The `#arguments.type#` type is not supported.",
					extendedInfo = "Use one of the supported types: `creditcard`, `date`, `email`, `eurodate`, `guid`, `social_security_number`, `ssn`, `telephone`, `time`, `URL`, `USdate`, `UUID`, `variableName`, `zipcode`, `boolean`"
				);
			}
		}
		$registerValidation(methods = "$validatesFormatOf", argumentCollection = arguments);
	}

	/**
	 * Validates that the value of the specified property exists in the supplied list.
	 *
	 * [section: Model Configuration]
	 * [category: Validation Functions ]
	 *
	 * @properties [see:validatesConfirmationOf].
	 * @list List of allowed values.
	 * @message [see:validatesConfirmationOf].
	 * @when [see:validatesConfirmationOf].
	 * @allowBlank [see:validatesExclusionOf].
	 * @condition [see:validatesConfirmationOf].
	 * @unless [see:validatesConfirmationOf].
	 */
	public void function validatesInclusionOf(
		string properties = "",
		required string list,
		string message,
		string when = "onSave",
		boolean allowBlank,
		string condition = "",
		string unless = ""
	) {
		$args(name = "validatesInclusionOf", args = arguments);
		arguments.list = $listClean(arguments.list);
		$registerValidation(methods = "$validatesInclusionOf", argumentCollection = arguments);
	}

	/**
	 * Validates that the value of the specified property matches the length requirements supplied.
	 * Use the `exactly`, `maximum`, `minimum` and `within` arguments to specify the length requirements.
	 *
	 * [section: Model Configuration]
	 * [category: Validation Functions ]
	 *
	 * @properties [see:validatesConfirmationOf].
	 * @message [see:validatesConfirmationOf].
	 * @when [see:validatesConfirmationOf].
	 * @allowBlank [see:validatesExclusionOf].
	 * @exactly The exact length that the property value must be.
	 * @maximum The maximum length that the property value can be.
	 * @minimum The minimum length that the property value can be.
	 * @within A list of two values (minimum and maximum) that the length of the property value must fall within.
	 * @condition [see:validatesConfirmationOf].
	 * @unless [see:validatesConfirmationOf].
	 */
	public void function validatesLengthOf(
		string properties = "",
		string message,
		string when = "onSave",
		boolean allowBlank,
		numeric exactly,
		numeric maximum,
		numeric minimum,
		string within,
		string condition = "",
		string unless = ""
	) {
		$args(name = "validatesLengthOf", args = arguments);
		if (Len(arguments.within)) {
			arguments.within = $listClean(list = arguments.within, returnAs = "array");
		}
		$registerValidation(methods = "$validatesLengthOf", argumentCollection = arguments);
	}

	/**
	 * Validates that the value of the specified property is numeric.
	 *
	 * [section: Model Configuration]
	 * [category: Validation Functions ]
	 *
	 * @properties [see:validatesConfirmationOf].
	 * @message [see:validatesConfirmationOf].
	 * @when [see:validatesConfirmationOf].
	 * @allowBlank [see:validatesExclusionOf].
	 * @onlyInteger Specifies whether the property value must be an integer.
	 * @condition [see:validatesConfirmationOf].
	 * @unless [see:validatesConfirmationOf].
	 * @oddSpecifies whether or not the value must be an odd number.
	 * @evenSpecifies whether or not the value must be an even number.
	 * @greaterThan Specifies whether or not the value must be greater than the supplied value.
	 * @greaterThanOrEqualTo Specifies whether or not the value must be greater than or equal the supplied value.
	 * @equalTo Specifies whether or not the value must be equal to the supplied value.
	 * @lessThan Specifies whether or not the value must be less than the supplied value.
	 * @lessThanOrEqualTo Specifies whether or not the value must be less than or equal the supplied value.
	 */
	public void function validatesNumericalityOf(
		string properties = "",
		string message,
		string when = "onSave",
		boolean allowBlank,
		boolean onlyInteger,
		string condition = "",
		string unless = "",
		boolean odd,
		boolean even,
		numeric greaterThan,
		numeric greaterThanOrEqualTo,
		numeric equalTo,
		numeric lessThan,
		numeric lessThanOrEqualTo
	) {
		$args(name = "validatesNumericalityOf", args = arguments);
		$registerValidation(methods = "$validatesNumericalityOf", argumentCollection = arguments);
	}

	/**
	 * Validates that the specified property exists and that its value is not blank.
	 *
	 * [section: Model Configuration]
	 * [category: Validation Functions ]
	 *
	 * @properties [see:validatesConfirmationOf].
	 * @message [see:validatesConfirmationOf].
	 * @when [see:validatesConfirmationOf].
	 * @condition [see:validatesConfirmationOf].
	 * @unless [see:validatesConfirmationOf].
	 */
	public void function validatesPresenceOf(
		string properties = "",
		string message,
		string when = "onSave",
		string condition = "",
		string unless = ""
	) {
		$args(name = "validatesPresenceOf", args = arguments);
		$registerValidation(methods = "$validatesPresenceOf", argumentCollection = arguments);
	}

	/**
	 * Validates that the value of the specified property is unique in the database table.
	 * Useful for ensuring that two users can't sign up to a website with identical usernames for example.
	 * When a new record is created, a check is made to make sure that no record already exists in the database table with the given value for the specified property.
	 * When the record is updated, the same check is made but disregarding the record itself.
	 *
	 * [section: Model Configuration]
	 * [category: Validation Functions ]
	 *
	 * @properties [see:validatesConfirmationOf].
	 * @message [see:validatesConfirmationOf].
	 * @when [see:validatesConfirmationOf].
	 * @allowBlank [see:validatesExclusionOf].
	 * @scope One or more properties by which to limit the scope of the uniqueness constraint.
	 * @condition [see:validatesConfirmationOf].
	 * @unless [see:validatesConfirmationOf].
	 * @includeSoftDeletes [see:findAll].
	 */
	public void function validatesUniquenessOf(
		string properties = "",
		string message,
		string when = "onSave",
		boolean allowBlank,
		string scope = "",
		string condition = "",
		string unless = "",
		boolean includeSoftDeletes = "true"
	) {
		$args(name = "validatesUniquenessOf", args = arguments);
		arguments.scope = $listClean(arguments.scope);
		$registerValidation(methods = "$validatesUniquenessOf", argumentCollection = arguments);
	}

	/**
	 * Runs the validation on the object and returns `true` if it passes it.
	 * CFWheels will run the validation process automatically whenever an object is saved to the database, but sometimes it's useful to be able to run this method to see if the object is valid without saving it to the database.
	 *
	 * [section: Model Object]
	 * [category: Error Functions ]
	 *
	 * @callbacks [see:findAll].
	 */
	public boolean function valid(boolean callbacks = "true", boolean validateAssociations = false) {
		local.rv = false;
		clearErrors();
		if ($callback("beforeValidation", arguments.callbacks)) {
			if (isNew()) {
				if (
					$callback("beforeValidationOnCreate", arguments.callbacks)
					&& $validate("onSave,onCreate")
					&& $callback("afterValidation", arguments.callbacks)
					&& $callback("afterValidationOnCreate", arguments.callbacks)
				) {
					local.rv = true;
				}
			} else {
				if (
					$callback("beforeValidationOnUpdate", arguments.callbacks)
					&& $validate("onSave,onUpdate")
					&& $callback("afterValidation", arguments.callbacks)
					&& $callback("afterValidationOnUpdate", arguments.callbacks)
				) {
					local.rv = true;
				}
			}
		}
		local.areAssociationsValid = $validateAssociations(
			callbacks = arguments.callbacks,
			validateAssociations = arguments.validateAssociations
		);
		if (arguments.validateAssociations && local.rv) {
			local.rv = local.areAssociationsValid;
		}
		return local.rv;
	}

	/**
	 * Called from the high level validation helpers to register the validation in the class struct of the model.
	 */
	public void function $registerValidation(required string when) {
		// combine method / methods and property / properties into one variables for easier processing below
		// validate, validateOnCreate and validateOnUpdate do not take the properties argument however other validations do
		$combineArguments(args = arguments, combine = "methods,method", required = true);
		$combineArguments(args = arguments, combine = "properties,property", required = false);

		if (application.wheels.showErrorInformation) {
			if (StructKeyExists(arguments, "properties")) {
				if (!Len(arguments.properties)) {
					Throw(
						type = "Wheels.IncorrectArguments",
						message = "The `property` or `properties` argument is required but was not passed in.",
						extendedInfo = "Please pass in the names of the properties you want to validate. Use either the `property` argument (for a single property) or the `properties` argument (for a list of properties) to do this."
					);
				}
			}
		}

		// loop through all methods and properties and add info for each to the `class` struct
		local.iEnd = ListLen(arguments.methods);
		for (local.i = 1; local.i <= local.iEnd; local.i++) {
			// only loop once by default (will be used on the lower level validation helpers that do not take arguments: validate, validateOnCreate and validateOnUpdate)
			local.jEnd = 1;
			if (StructKeyExists(arguments, "properties")) {
				local.jEnd = ListLen(arguments.properties);
			}

			for (local.j = 1; local.j <= local.jEnd; local.j++) {
				local.validation = {};
				local.validation.method = Trim(ListGetAt(arguments.methods, local.i));
				local.validation.args = Duplicate(arguments);
				if (StructKeyExists(arguments, "properties")) {
					local.validation.args.property = Trim(ListGetAt(local.validation.args.properties, local.j));
				}
				StructDelete(local.validation.args, "when");
				StructDelete(local.validation.args, "methods");
				StructDelete(local.validation.args, "properties");
				ArrayAppend(variables.wheels.class.validations[arguments.when], local.validation);
			}
		}
	}

	/**
	 * Internal function.
	 **/
	public string function $validationErrorMessage(required string property, required string message) {
		local.rv = arguments.message;
		// evaluate the error message if it contains pound signs
		if (Find(Chr(35), local.rv)) {
			// Extract variable names between # symbols
			local.regex = "(##([^#chr(35)#]*)##|####)";
			local.matches = REMatchNoCase(local.regex, local.rv);
			local.matchCount = ArrayLen(local.matches);

			if (local.matchCount) {
				for (local.i = 1; local.i <= local.matchCount; local.i++) {
					local.fullMatch = local.matches[local.i]; // The full #variable# match

					// Ensure it contains #
					if (Find(Chr(35), local.fullMatch)) {
						local.varName = ReplaceNoCase(local.fullMatch, "#chr(35)#", "", "ALL");

						// If empty ##, replace with a single #
						if (Len(local.varName) EQ 0) {
							local.rv = ReplaceNoCase(local.rv, local.fullMatch, Chr(35), "one");
						} else {
							// Retrieve variable value from function scope or arguments
							if (StructKeyExists(variables, local.varName)) {
								local.value = variables[local.varName];
							} else if (StructKeyExists(arguments, local.varName)) {
								local.value = arguments[local.varName];
							} else {
								local.value = local.fullMatch; // Keep as-is if not found
							}

							// Replace occurrences of #variable# with the actual value
							local.rv = ReplaceNoCase(local.rv, local.fullMatch, local.value, "one");
						}
					}
				}
			}
		}

		// loop through each argument and replace bracketed occurrence with argument value
		for (local.key in arguments) {
			local.key = LCase(local.key);
			local.value = arguments[local.key];
			if (StructKeyExists(local, "value") && IsSimpleValue(local.value) && Len(local.value)) {
				if (local.key == "property") {
					local.value = this.$label(local.value);
				}
				local.rv = Replace(local.rv, "[[#local.key#]]", "{{#Chr(7)#}}", "all");
				local.rv = Replace(local.rv, "[#local.key#]", local.value, "all");
				local.rv = Replace(local.rv, "{{#Chr(7)#}}", "[#local.key#]", "all");
			}
		}
		return local.rv;
	}

	/**
	 * Runs all the validation methods setup on the object and adds errors as it finds them.
	 * Returns true if no errors were added, false otherwise.
	 */
	public boolean function $validate(required string type, boolean execute = "true") {
		// don't run any validations when we want to skip
		if (!arguments.execute) {
			return true;
		}

		// loop over the passed in types
		local.iEnd = ListLen(arguments.type);
		for (local.i = 1; local.i <= local.iEnd; local.i++) {
			local.item = ListGetAt(arguments.type, local.i);

			// loop through all validations for passed in type (onSave, onCreate etc) that has been set on this model object
			local.jEnd = ArrayLen(variables.wheels.class.validations[local.item]);
			for (local.j = 1; local.j <= local.jEnd; local.j++) {
				local.thisValidation = variables.wheels.class.validations[local.item][local.j];
				if ($evaluateCondition(argumentCollection = local.thisValidation.args)) {
					if (local.thisValidation.method == "$validatesPresenceOf") {
						// if the property does not exist, but it's db column has a default value, skip validatesPresenceOf
						local.propertyName = local.thisValidation.args.property;
						local.isDatabaseColumn = StructKeyExists(variables.wheels.class.properties, local.propertyName);
						local.hasDatabaseColumnDefault = local.isDatabaseColumn && Len(variables.wheels.class.properties[local.propertyName].columndefault);
						if (!this.hasProperty(local.propertyName) && local.hasDatabaseColumnDefault) {
							continue;
						}
						// if the property does not exist or if it's blank we add an error on the object (for all other validation types we call corresponding methods below instead)
						if (
							!this.hasProperty(local.propertyName)
							|| (IsSimpleValue(this[local.propertyName]) && !Len((this[local.propertyName])))
							|| (IsStruct(this[local.propertyName]) && !StructCount(this[local.propertyName]))
						) {
							addError(
								message = $validationErrorMessage(local.propertyName, local.thisValidation.args.message),
								property = local.propertyName,
								name = replace(local.thisValidation.method, "$validates", "", "one")
							);
						}
					} else {
						// if the validation set does not allow blank values we can set an error right away, otherwise we call a method to run the actual check
						if (
							StructKeyExists(local.thisValidation.args, "property")
							&& StructKeyExists(local.thisValidation.args,"allowBlank")
							&& !local.thisValidation.args.allowBlank
							&& (
								!StructKeyExists(this, local.thisValidation.args.property)
								|| !Len(this[local.thisValidation.args.property])
							)
						) {
							addError(
								message = $validationErrorMessage(local.thisValidation.args.property, local.thisValidation.args.message),
								property = local.thisValidation.args.property,
								name = replace(local.thisValidation.method, "$validates", "", "one")
							);
						} else if (
							!StructKeyExists(local.thisValidation.args, "property")
							|| (
								StructKeyExists(this, local.thisValidation.args.property)
								&& (
									Len(this[local.thisValidation.args.property])
									|| local.thisValidation.method == "$validatesUniquenessOf"
								)
							)
						) {
							$invoke(method = local.thisValidation.method, invokeArgs = local.thisValidation.args);
						}
					}
				}
			}
		}

		// Now that we've run all the validation checks we return "true" if no errors exist on the object, "false" otherwise.
		return !hasErrors();
	}

	/**
	 * Evaluates the condition to determine if the validation should be executed.
	 */
	public boolean function $evaluateCondition() {
		local.rv = false;
		local.evaluate = "condition,unless";
		local.iEnd = ListLen(local.evaluate);
		for (local.i = 1; local.i <= local.iEnd; local.i++) {
			local.item = ListGetAt(local.evaluate, local.i);
			if (StructKeyExists(arguments, local.item) && Len(arguments[local.item])) {
				local.key = local.item & "Evaluated";
				try {
        	local[local.key] = $evaluateConditionString(arguments[local.item]);
				} catch (any e) {
					return false;
				}
			}
		}
		// proceed with validation when "condition" has been supplied and it evaluates to "true" or when "unless" has been supplied and it evaluates to "false"
		// if both "condition" and "unless" have been supplied though, they both need to be evaluated correctly ("true"/false" that is) for validation to proceed
		if (
			(!StructKeyExists(arguments, "condition") || !Len(arguments.condition) || local.conditionEvaluated)
			&& (!StructKeyExists(arguments, "unless") || !Len(arguments.unless) || !local.unlessEvaluated)
		) {
			local.rv = true;
		}
		return local.rv;
	}

	/**
	 * Adds an error if the object property fail to pass the validation setup in the validatesConfirmationOf method.
	 */
	public void function $validatesConfirmationOf() {
		local.virtualConfirmProperty = arguments.property & "Confirmation";
		if (!StructKeyExists(this, local.virtualConfirmProperty)) {
			addError(property = local.virtualConfirmProperty, message = $validationErrorMessage(argumentCollection = arguments));
			return;
		}
		if (
			this[arguments.property] != this[local.virtualConfirmProperty] ||
			(arguments.caseSensitive && (Compare(this[arguments.property], this[local.virtualConfirmProperty]) != 0))
		) {
			addError(property = local.virtualConfirmProperty, message = $validationErrorMessage(argumentCollection = arguments));
		}
	}

	/**
	 * Adds an error if the object property fail to pass the validation setup in the validatesExclusionOf method.
	 */
	public void function $validatesExclusionOf() {
		if (ListFindNoCase(arguments.list, this[arguments.property])) {
			addError(property = arguments.property, message = $validationErrorMessage(argumentCollection = arguments));
		}
	}

	/**
	 * Adds an error if the object property fail to pass the validation setup in the validatesFormatOf method.
	 */
	public void function $validatesFormatOf() {
		if (
			(Len(arguments.regEx) && !ReFindNoCase(arguments.regEx, this[arguments.property]))
			|| (Len(arguments.type) && !IsValid(arguments.type, this[arguments.property]))
		) {
			addError(property = arguments.property, message = $validationErrorMessage(argumentCollection = arguments));
		}
	}

	/**
	 * Adds an error if the object property fail to pass the validation setup in the validatesInclusionOf method.
	 */
	public void function $validatesInclusionOf() {
		if (!ListFindNoCase(arguments.list, this[arguments.property])) {
			addError(property = arguments.property, message = $validationErrorMessage(argumentCollection = arguments));
		}
	}

	/**
	 * Adds an error if the object property fail to pass the validation setup in the validatesPresenceOf method.
	 */
	public void function $validatesPresenceOf(
		required string property,
		required string message,
		struct properties = this.properties()
	) {
		// if the property does not exist or if it's blank we add an error on the object
		if (
			!StructKeyExists(arguments.properties, arguments.property)
			|| (IsSimpleValue(arguments.properties[arguments.property]) && !Len(arguments.properties[arguments.property]))
			|| (IsStruct(arguments.properties[arguments.property]) && !StructCount(arguments.properties[arguments.property]))
		) {
			addError(property = arguments.property, message = $validationErrorMessage(argumentCollection = arguments));
		}
	}

	/**
	 * Adds an error if the object property fail to pass the validation setup in the validatesLengthOf method.
	 */
	public void function $validatesLengthOf(
		required string property,
		required string message,
		required numeric exactly,
		required numeric maximum,
		required numeric minimum,
		required any within,
		struct properties = this.properties()
	) {
		local.lenValue = Len(arguments.properties[arguments.property]);

		// for within, just create minimum / maximum values
		if (IsArray(arguments.within) && ArrayLen(arguments.within) == 2) {
			arguments.minimum = arguments.within[1];
			arguments.maximum = arguments.within[2];
		}

		if (
			(arguments.maximum && local.lenValue > arguments.maximum)
			|| (arguments.minimum && local.lenValue < arguments.minimum)
			|| (arguments.exactly && local.lenValue != arguments.exactly)
		) {
			addError(property = arguments.property, message = $validationErrorMessage(argumentCollection = arguments));
		}
	}

	/**
	 * Adds an error if the object property fail to pass the validation setup in the validatesNumericalityOf method.
	 */
	public void function $validatesNumericalityOf() {
		local.propertyValue = this[arguments.property];
		local.isValidNumber = IsNumeric(local.propertyValue);
		
		// Additional check for BoxLang compatibility - reject numbers with commas
		if (structKeyExists(server, "boxlang") && local.isValidNumber && Find(",", local.propertyValue)) {
			local.isValidNumber = false;
		}
		
		if (
			!local.isValidNumber || (
				arguments.onlyInteger && Round(this[arguments.property]) != this[arguments.property]
			) || (IsNumeric(arguments.greaterThan) && this[arguments.property] <= arguments.greaterThan) || (
				IsNumeric(arguments.greaterThanOrEqualTo) && this[arguments.property] < arguments.greaterThanOrEqualTo
			) || (IsNumeric(arguments.equalTo) && this[arguments.property] != arguments.equalTo) || (
				IsNumeric(arguments.lessThan) && this[arguments.property] >= arguments.lessThan
			) || (IsNumeric(arguments.lessThanOrEqualTo) && this[arguments.property] > arguments.lessThanOrEqualTo) || (
				IsBoolean(arguments.odd) && arguments.odd && !BitAnd(this[arguments.property], 1)
			) || (IsBoolean(arguments.even) && arguments.even && BitAnd(this[arguments.property], 1))
		) {
			addError(property = arguments.property, message = $validationErrorMessage(argumentCollection = arguments));
		}
	}

	/**
	 * Adds an error if the object property fail to pass the validation setup in the validatesUniquenessOf method.
	 */
	public void function $validatesUniquenessOf(
		required string property,
		required string message,
		string scope = "",
		struct properties = "#this.properties()#",
		boolean includeSoftDeletes = "true"
	) {
		if (!IsBoolean(variables.wheels.class.tableName) || variables.wheels.class.tableName) {
			local.where = [];

			// create the WHERE clause to be used in the query that checks if an identical value already exists
			// wrap value in single quotes unless it's numeric
			// example: "userName='Joe'"
			local.part = arguments.property & "=" & variables.wheels.class.adapter.$quoteValue(
				str = this[arguments.property],
				type = validationTypeForProperty(arguments.property)
			);
			if (
				Right(local.part, 3) == "=''"
				&& ListFindNoCase("integer,float,boolean", validationTypeForProperty(arguments.property))
			) {
				// when numeric property but blank we need to translate to IS NULL
				local.part = SpanExcluding(local.part, "=") & " IS NULL";
			}
			ArrayAppend(local.where, local.part);

			// add scopes to the WHERE clause if passed in, this means that checks for other properties are done in the WHERE clause as well
			// example: "userName='Joe'" becomes "userName='Joe' AND account=1" if scope is "account" for example
			arguments.scope = $listClean(arguments.scope);
			local.iEnd = ListLen(arguments.scope);
			for (local.i = 1; local.i <= local.iEnd; local.i++) {
				local.item = ListGetAt(arguments.scope, local.i);
				local.part = local.item & "=" & variables.wheels.class.adapter.$quoteValue(
					str = this[local.item],
					type = validationTypeForProperty(local.item)
				);
				if (Right(local.part, 3) == "=''" && ListFindNoCase("integer,float,boolean", validationTypeForProperty(local.item))) {
					// when numeric property but blank we need to translate to IS NULL
					local.part = SpanExcluding(local.part, "=") & " IS NULL";
				}
				ArrayAppend(local.where, local.part);
			}

			// try to fetch duplicate objects from the database
			// we add an error if duplicate objects were found and the current object is either not saved yet or not the same as any of the found duplicates
			local.existingObjects = findAll(
				select = primaryKey(),
				where = ArrayToList(local.where, " AND "),
				returnAs = "objects",
				reload = true,
				includeSoftDeletes = arguments.includeSoftDeletes,
				callbacks = false
			);
			if (ArrayLen(local.existingObjects)) {
				local.duplicate = false;
				if (isNew()) {
					local.duplicate = true;
				} else {
					local.iEnd = ArrayLen(local.existingObjects);
					for (local.i = 1; local.i <= local.iEnd; local.i++) {
						if (local.existingObjects[local.i].key() != key($persisted = true)) {
							local.duplicate = true;
						}
					}
				}
				if (local.duplicate) {
					addError(property = arguments.property, message = $validationErrorMessage(argumentCollection = arguments));
				}
			}
		}
	}

	/**
	 * Internal function.
	 **/
	public boolean function $validationExists(required string property, required string validation) {
		// checks to see if a validation has been created for a property
		local.rv = false;
		for (local.key in variables.wheels.class.validations) {
			if (StructKeyExists(variables.wheels.class.validations, local.key)) {
				local.eventArray = variables.wheels.class.validations[local.key];
				local.iEnd = ArrayLen(local.eventArray);
				for (local.i = 1; local.i <= local.iEnd; local.i++) {
					if (
						StructKeyExists(local.eventArray[local.i].args, "property")
						&& local.eventArray[local.i].args.property == arguments.property
						&& local.eventArray[local.i].method == "$#arguments.validation#"
					) {
						local.rv = true;
						break;
					}
				}
			}
		}
		return local.rv;
	}

	/**
	 * Function to evaluate a condition string without using Evaluate()
	 * @condition The condition to resolve
	 */
	public any function $evaluateConditionString(required string condition) {
		// Replace CFScript operators with CFScript equivalents
		local.operatorList = "eq,neq,lt,lte,gt,gte";
		local.normalizedCondition = ReplaceList(condition, "==,!=,<,<=,>,>=", local.operatorList);
		local.normalizedCondition = Replace(local.normalizedCondition, "  ", " ", "all"); // Normalize spaces
		local.before = local.normalizedCondition;

		for(value in local.operatorList){
			local.position = FindNoCase(value, local.normalizedCondition);
			if(local.position){
				local.middle = value;
				local.before = trim(Mid(local.normalizedCondition,1,local.position - 1));
				local.after = trim(Mid(local.normalizedCondition, local.position + len(local.middle), len(local.normalizedCondition)));
			}
		}

		// Handle cases where the condition references `this`, logical comparisons, or function calls
		if (Left(local.before, 5) == "this.") {

			// Handle `this.someMethod()` or `this.someVariable`
			local.key = Mid(local.before, 6, len(local.before)); // Extract the part after "this."
			local.beforeRegexPattern = "^(.*?)\(";
			local.beforeMatch = REFindNoCase(local.beforeRegexPattern, local.key, 1, true);

			if (local.beforeMatch.pos[1] > 0) {
				local.beforeParenthesis = Mid(local.key, 1, local.beforeMatch.len[1] - 1);
				local.afterParenthesis = Mid(local.key, local.beforeMatch.len[1] + 1, len(local.key));
			};

			if(structKeyExists(local, 'afterParenthesis')){
				local.afterRegexPattern = "^(.*?)\)";
				local.afterMatch = REFindNoCase(local.afterRegexPattern, local.afterParenthesis, 1, true);
				if (local.afterMatch.pos[1] > 0) {
					local.afterParenthesis = Mid(local.afterParenthesis, 1, local.afterMatch.len[1] - 1);
				}

				if(structKeyExists(this, local.beforeParenthesis)){

					if (IsCustomFunction(this[local.beforeParenthesis])) {
						local.argumentsCollection = {};
						// Parse parameters properly - split on comma first, then on equals
						local.paramList = ListToArray(local.afterParenthesis, ",");
						for (local.param in local.paramList) {
							local.param = Trim(local.param);
							if (Find("=", local.param)) {
								// Split the parameter on "="
								local.splitArg = ListToArray(local.param, "=");
								if (ArrayLen(local.splitArg) >= 2) {
									local.variableName = Trim(local.splitArg[1]); // Left-hand side (variable name)
									local.variableValue = Trim(local.splitArg[2]); // Right-hand side (value)
									// Remove quotes from the value
									local.variableValue = Replace(local.variableValue, "'", "", "all");
									local.variableValue = Replace(local.variableValue, '"', "", "all");
									
									// Add to the arguments collection
									local.argumentsCollection[local.variableName] = local.variableValue;
								}
							}
						}
						local.rv = invoke(this, local.beforeParenthesis, local.argumentsCollection); // Call the function
					} else {
						local.rv = this[local.beforeParenthesis]; // Return the variable value
					}
				}
			}

			if (StructKeyExists(this, local.key)) {
				if (IsCustomFunction(this[local.key])) {
					local.rv = invoke(this, local.key); // Call the function
				} else {
					local.rv = this[local.key]; // Return the variable value
				}
			}

		} else if(right(local.normalizedCondition, 2) eq '()'){
			if(find("!", local.normalizedCondition)){
				local.normalizedCondition = replace(local.normalizedCondition, "!", "", "one");
				return !invoke(this, replace(local.normalizedCondition, '()', ''));
			}	else{
				return invoke(this, replace(local.normalizedCondition, '()', ''));
			}
		} else {
			// Handle logical expressions (e.g., "1 eq 0", "5 gt 3", "myFunction() eq true")
			local.tokens = ListToArray(local.normalizedCondition, " ");
			if (ArrayLen(local.tokens) < 3) {
				return false; // Invalid condition
			}

			local.leftOperand = local.tokens[1];
			local.operator = local.tokens[2];
			local.rightOperand = local.tokens[3];

			// Resolve variables or cast to numeric values
			local.leftOperand = isNumeric(local.leftOperand) ? JavaCast("double", local.leftOperand) : local.leftOperand;
			local.rightOperand = isNumeric(local.rightOperand) ? JavaCast("double", local.rightOperand) : local.rightOperand;
			// Evaluate the logical expression
			return $resolveOperator(local.leftOperand, local.rightOperand, local.operator);
		}

		if(structKeyExists(local, 'after') && structKeyExists(local, 'middle')){
			local.singleRegexPattern = "^'.*'$";
			local.doubleRegexPattern = '^".*"$';
			if (REFindNoCase(local.singleRegexPattern, local.after)) {
    	  local.after = Replace(local.after, "'", "", "all");
    	}
			if (REFindNoCase(local.doubleRegexPattern, local.after)) {
    	  local.after = Replace(local.after, '"', "", "all");
    	}

			return $resolveOperator(local.rv, local.after, local.middle);
		}

		return structKeyExists(local, rv)? local.rv : false;
	}

	/**
 	 * Evaluate a logical expression based on the operator.
 	 */
	public boolean function $resolveOperator(required any firstOperator, required any secondOperator, required any operator){
		switch (arguments.operator) {
			case "eq":
				return (arguments.firstOperator == arguments.secondOperator);
			case "neq":
				return (arguments.firstOperator != arguments.secondOperator);
			case "lt":
				return (arguments.firstOperator < arguments.secondOperator);
			case "lte":
				return (arguments.firstOperator <= arguments.secondOperator);
			case "gt":
				return (arguments.firstOperator > arguments.secondOperator);
			case "gte":
				return (arguments.firstOperator >= arguments.secondOperator);
			default:
				throw("Unsupported operator in condition: " & arguments.operator);
		}
	}
}
