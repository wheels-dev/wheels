component {
	/**
	 * Adds an error on a specific property.
	 *
	 * [section: Model Object]
	 * [category: Error Functions]
	 *
	 * @property The name of the property you want to add an error on.
	 * @message The error message (such as "Please enter a correct name in the form field" for example).
	 * @name A name to identify the error by (useful when you need to distinguish one error from another one set on the same object and you don't want to use the error message itself for that).
	 */
	public void function addError(required string property, required string message, string name = "") {
		ArrayAppend(variables.wheels.errors, arguments);
	}

	/**
	 * Adds an error on a specific property.
	 *
	 * [section: Model Object]
	 * [category: Error Functions]
	 *
	 * @message [see:addError].
	 * @name [see:addError].
	 */
	public void function addErrorToBase(required string message, string name = "") {
		arguments.property = "";
		addError(argumentCollection = arguments);
	}

	/**
	 * Returns an array of all the errors on the object.
	 *
	 * [section: Model Object]
	 * [category: Error Functions]
	 *
	 * @seenErrors is a private argument not meant to be used by the user, the function uses this to ensure circular dependency avoidance.
	 * It does this by storing instances of models that are associations, and not checking associations of those instances because they have already been checked.
	 */
	public array function allErrors(boolean includeAssociations = false, array seenErrors = []) {
		if (arguments.includeAssociations) {
			local.rv = [];
			ArrayAppend(local.rv, variables.wheels.errors, true);
			ArrayAppend(local.rv, allAssociationErrors(arguments.seenErrors), true);
			return local.rv;
		}
		return variables.wheels.errors;
	}

	/**
	 * Gets all associated errors recursively
	 *
	 * [section: Model Object]
	 * [category: Error Functions]
	 */
	public array function allAssociationErrors(array seenErrors = []) {
		local.rv = [];
		for (local.association in variables.wheels.class.associations) {
			if (StructKeyExists(this, local.association)) {
				// base case
				if (ArrayContains(arguments.seenErrors, this[local.association])) {
					return local.rv;
				}
				ArrayAppend(arguments.seenErrors, this[local.association]);
				local.array = this[local.association];
				if (!IsNull(this[local.association]) && IsObject(this[local.association])) {
					local.array = [this[local.association]];
				}
				if (IsArray(local.array)) {
					local.iEnd = ArrayLen(local.array);
					for (local.i = 1; local.i <= local.iEnd; local.i++) {
						local.associationModel = local.array[local.i];
						ArrayAppend(local.rv, local.associationModel.allErrors(true, arguments.seenErrors, true), true);
					}
				}
			}
		}
		return local.rv;
	}

	/**
	 * Clears out all errors set on the object or only the ones set for a specific property or name.
	 *
	 * [section: Model Object]
	 * [category: Error Functions]
	 *
	 * @property Specify a property name here if you want to clear all errors set on that property.
	 * @name Specify an error name here if you want to clear all errors set with that error name.
	 */
	public void function clearErrors(string property = "", string name = "") {
		if (!Len(arguments.property) && !Len(arguments.name)) {
			ArrayClear(variables.wheels.errors);
		} else {
			local.iEnd = ArrayLen(variables.wheels.errors);
			for (local.i = local.iEnd; local.i >= 1; local.i--) {
				local.error = variables.wheels.errors[local.i];
				if (local.error.property == arguments.property && local.error.name == arguments.name) {
					ArrayDeleteAt(variables.wheels.errors, local.i);
				} else if (local.error.property == arguments.property && !Len(arguments.name)) {
					ArrayDeleteAt(variables.wheels.errors, local.i);
				}
			}
		}
	}

	/**
	 * Returns the number of errors this object has associated with it.
	 * Specify property or name if you wish to count only specific errors.
	 *
	 * [section: Model Object]
	 * [category: Error Functions]
	 *
	 * @property Specify a property name here if you want to count only errors set on a specific property.
	 * @name Specify an error name here if you want to count only errors set with a specific error name.
	 */
	public numeric function errorCount(string property = "", string name = "") {
		if (!Len(arguments.property) && !Len(arguments.name)) {
			return ArrayLen(variables.wheels.errors);
		} else {
			return ArrayLen(errorsOn(argumentCollection = arguments));
		}
	}

	/**
	 * Returns an array of all errors associated with the supplied property (and error name if passed in).
	 *
	 * [section: Model Object]
	 * [category: Error Functions]
	 *
	 * @property Specify the property name to return errors for here.
	 * @name If you want to return only errors on the property set with a specific error name you can specify it here.
	 */
	public array function errorsOn(required string property, string name = "") {
		local.rv = [];
		local.iEnd = ArrayLen(variables.wheels.errors);
		for (local.i = 1; local.i <= local.iEnd; local.i++) {
			local.error = variables.wheels.errors[local.i];
			if (local.error.property == arguments.property && local.error.name == arguments.name) {
				ArrayAppend(local.rv, variables.wheels.errors[local.i]);
			} else if (local.error.property == arguments.property && !Len(arguments.name)) {
				ArrayAppend(local.rv, variables.wheels.errors[local.i]);
			}
		}
		return local.rv;
	}

	/**
	 * Returns an array of all errors associated with the object as a whole (not related to any specific property).
	 *
	 * [section: Model Object]
	 * [category: Error Functions]
	 *
	 * @name Specify an error name here to only return errors for that error name.
	 */
	public array function errorsOnBase(string name = "") {
		arguments.property = "";
		return errorsOn(argumentCollection = arguments);
	}

	/**
	 * Returns `true` if the object has any errors.
	 * You can also limit to only check a specific property or name for errors.
	 *
	 * [section: Model Object]
	 * [category: Error Functions]
	 *
	 * @property Name of the property to check if there are any errors set on.
	 * @name Error name to check if there are any errors set with.
	 */
	public boolean function hasErrors(string property = "", string name = "") {
		if (errorCount(argumentCollection = arguments) > 0) {
			return true;
		} else {
			return false;
		}
	}
}
