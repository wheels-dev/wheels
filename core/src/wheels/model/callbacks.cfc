component {
	/**
	 * Registers method(s) that should be called after a new object is created.
	 *
	 * [section: Model Configuration]
	 * [category: Callback Functions]
	 *
	 * @methods [see:afterNew].
	 */
	public void function afterCreate(string methods = "") {
		$registerCallback(argumentCollection = arguments, type = "afterCreate");
	}

	/**
	 * Registers method(s) that should be called after an object is deleted.
	 *
	 * [section: Model Configuration]
	 * [category: Callback Functions]
	 *
	 * @methods [see:afterNew].
	 */
	public void function afterDelete(string methods = "") {
		$registerCallback(argumentCollection = arguments, type = "afterDelete");
	}

	/**
	 * Registers method(s) that should be called after an existing object has been initialized (which is usually done with the `findByKey` or `findOne` method).
	 *
	 * [section: Model Configuration]
	 * [category: Callback Functions]
	 *
	 * @methods [see:afterNew].
	 */
	public void function afterFind(string methods = "") {
		$registerCallback(argumentCollection = arguments, type = "afterFind");
	}

	/**
	 * Registers method(s) that should be called after an object has been initialized.
	 *
	 * [section: Model Configuration]
	 * [category: Callback Functions]
	 *
	 * @methods [see:afterNew].
	 */
	public void function afterInitialization(string methods = "") {
		$registerCallback(argumentCollection = arguments, type = "afterInitialization");
	}

	/**
	 * Registers method(s) that should be called after a new object has been initialized (which is usually done with the `new` method).
	 *
	 * [section: Model Configuration]
	 * [category: Callback Functions]
	 *
	 * @methods Method name or list of method names that should be called when this callback event occurs in an object's life cycle (can also be called with the `method` argument).
	 */
	public void function afterNew(string methods = "") {
		$registerCallback(argumentCollection = arguments, type = "afterNew");
	}

	/**
	 * Registers method(s) that should be called after an object is saved.
	 *
	 * [section: Model Configuration]
	 * [category: Callback Functions]
	 *
	 * @methods [see:afterNew].
	 */
	public void function afterSave(string methods = "") {
		$registerCallback(argumentCollection = arguments, type = "afterSave");
	}

	/**
	 * Registers method(s) that should be called after an existing object is updated.
	 *
	 * [section: Model Configuration]
	 * [category: Callback Functions]
	 *
	 * @methods [see:afterNew].
	 */
	public void function afterUpdate(string methods = "") {
		$registerCallback(argumentCollection = arguments, type = "afterUpdate");
	}

	/**
	 * Registers method(s) that should be called after an object is validated.
	 *
	 * [section: Model Configuration]
	 * [category: Callback Functions]
	 *
	 * @methods [see:afterNew].
	 */
	public void function afterValidation(string methods = "") {
		$registerCallback(argumentCollection = arguments, type = "afterValidation");
	}

	/**
	 * Registers method(s) that should be called after a new object is validated.
	 *
	 * [section: Model Configuration]
	 * [category: Callback Functions]
	 *
	 * @methods [see:afterNew].
	 */
	public void function afterValidationOnCreate(string methods = "") {
		$registerCallback(argumentCollection = arguments, type = "afterValidationOnCreate");
	}

	/**
	 * Registers method(s) that should be called after an existing object is validated.
	 *
	 * [section: Model Configuration]
	 * [category: Callback Functions]
	 *
	 * @methods [see:afterNew].
	 */
	public void function afterValidationOnUpdate(string methods = "") {
		$registerCallback(argumentCollection = arguments, type = "afterValidationOnUpdate");
	}

	/**
	 * Registers method(s) that should be called before a new object is created.
	 *
	 * [section: Model Configuration]
	 * [category: Callback Functions]
	 *
	 * @methods [see:afterNew].
	 */
	public void function beforeCreate(string methods = "") {
		$registerCallback(argumentCollection = arguments, type = "beforeCreate");
	}

	/**
	 * Registers method(s) that should be called before an object is deleted.
	 *
	 * [section: Model Configuration]
	 * [category: Callback Functions]
	 *
	 * @methods [see:afterNew].
	 */
	public void function beforeDelete(string methods = "") {
		$registerCallback(argumentCollection = arguments, type = "beforeDelete");
	}

	/**
	 *  Registers method(s) that should be called before an object is saved.
	 *
	 * [section: Model Configuration]
	 * [category: Callback Functions]
	 *
	 * @methods [see:afterNew].
	 */
	public void function beforeSave(string methods = "") {
		$registerCallback(argumentCollection = arguments, type = "beforeSave");
	}

	/**
	 * Registers method(s) that should be called before an existing object is updated.
	 *
	 * [section: Model Configuration]
	 * [category: Callback Functions]
	 *
	 * @methods [see:afterNew].
	 */
	public void function beforeUpdate(string methods = "") {
		$registerCallback(argumentCollection = arguments, type = "beforeUpdate");
	}

	/**
	 * Registers method(s) that should be called before an object is validated.
	 *
	 * [section: Model Configuration]
	 * [category: Callback Functions]
	 *
	 * @methods [see:afterNew].
	 */
	public void function beforeValidation(string methods = "") {
		$registerCallback(argumentCollection = arguments, type = "beforeValidation");
	}

	/**
	 * Registers method(s) that should be called before a new object is validated.
	 *
	 * [section: Model Configuration]
	 * [category: Callback Functions]
	 *
	 * @methods [see:afterNew].
	 */
	public void function beforeValidationOnCreate(string methods = "") {
		$registerCallback(argumentCollection = arguments, type = "beforeValidationOnCreate");
	}

	/**
	 * Registers method(s) that should be called before an existing object is validated.
	 *
	 * [section: Model Configuration]
	 * [category: Callback Functions]
	 *
	 * @methods [see:afterNew].
	 */
	public void function beforeValidationOnUpdate(string methods = "") {
		$registerCallback(argumentCollection = arguments, type = "beforeValidationOnUpdate");
	}

	/**
	 * Internal function.
	 */
	public void function $registerCallback(required string type, required string methods) {
		// Create this type in the array if it doesn't already exist.
		if (!StructKeyExists(variables.wheels.class.callbacks, arguments.type)) {
			variables.wheels.class.callbacks[arguments.type] = [];
		}

		local.existingCallbacks = ArrayToList(variables.wheels.class.callbacks[arguments.type]);
		if (StructKeyExists(arguments, "method")) {
			arguments.methods = arguments.method;
		}
		arguments.methods = $listClean(arguments.methods);
		local.iEnd = ListLen(arguments.methods);
		for (local.i = 1; local.i <= local.iEnd; local.i++) {
			if (!ListFindNoCase(local.existingCallbacks, ListGetAt(arguments.methods, local.i))) {
				ArrayAppend(variables.wheels.class.callbacks[arguments.type], ListGetAt(arguments.methods, local.i));
			}
		}
	}

	/**
	 * Internal function.
	 */
	public void function $clearCallbacks(string type = "") {
		arguments.type = $listClean(list = "#arguments.type#", returnAs = "array");

		// No type(s) was passed in. get all the callback types registered.
		if (ArrayIsEmpty(arguments.type)) {
			arguments.type = ListToArray(StructKeyList(variables.wheels.class.callbacks));
		}

		// Loop through each callback type and clear it.
		local.iEnd = ArrayLen(arguments.type);
		for (local.i = 1; local.i <= local.iEnd; local.i++) {
			variables.wheels.class.callbacks[arguments.type[local.i]] = [];
		}
	}

	/**
	 * Internal function.
	 */
	public any function $callbacks(string type = "") {
		if (Len(arguments.type)) {
			if (StructKeyExists(variables.wheels.class.callbacks, arguments.type)) {
				local.rv = variables.wheels.class.callbacks[arguments.type];
			} else {
				local.rv = [];
			}
		} else {
			local.rv = variables.wheels.class.callbacks;
		}
		return local.rv;
	}

	/**
	 * Internal function.
	 */
	public boolean function $callback(required string type, required boolean execute, any collection = "") {
		if (arguments.execute) {
			// Get all callbacks for the type and loop through them all until the end or one of them returns false.
			local.callbacks = $callbacks(arguments.type);
			local.iEnd = ArrayLen(local.callbacks);
			for (local.i = 1; local.i <= local.iEnd; local.i++) {
				local.method = local.callbacks[local.i];
				if (arguments.type == "afterFind") {
					// Since this is an afterFind callback we need to handle it differently.
					if (IsQuery(arguments.collection)) {
						local.rv = $queryCallback(method = local.method, collection = arguments.collection);
					} else {
						local.invokeArgs = properties();
						local.rv = $invoke(method = local.method, invokeArgs = local.invokeArgs);
						if (StructKeyExists(local, "rv") && IsStruct(local.rv)) {
							setProperties(local.rv);
							StructDelete(local, "rv");
						}
					}
				} else {
					// This is a regular callback so just call the method.
					local.rv = $invoke(method = local.method);
				}

				// Break the loop if the callback returned false.
				if (StructKeyExists(local, "rv") && IsBoolean(local.rv) && !local.rv) {
					break;
				}
			}
		}

		// Return true by default (happens when no callbacks are set or none of the callbacks returned a result).
		if (!StructKeyExists(local, "rv")) {
			local.rv = true;
		}

		return local.rv;
	}

	/**
	 * Internal function.
	 */
	public boolean function $queryCallback(required string method, required query collection) {
		// We return true by default, will be overridden only if the callback method returns false on one of the iterations.
		local.rv = true;
		// Loop over all query rows and execute the callback method for each.
		local.rowNumber = 0;
		for (local.row in arguments.collection) {
			local.rowNumber++;
			// Execute the callback method.
			local.result = $invoke(method = arguments.method, invokeArgs = local.row);

			if (StructKeyExists(local, "result")) {
				if (IsStruct(local.result)) {
					// The arguments struct was returned so we need to add the changed values to the query row.
					for (local.key in local.result) {
						// Add a new column to the query if a value was passed back for a column that did not exist originally.
						if (!QueryKeyExists(arguments.collection, local.key)) {
							QueryAddColumn(arguments.collection, local.key, []);
						}
						if (structKeyExists(server, "boxlang")) {
							if (local.result[local.key] == "") {
								continue;
							}
						}
						arguments.collection[local.key][local.rowNumber] = local.result[local.key];
					}
				} else if (IsBoolean(local.result) && !local.result) {
					// Break the loop and return false if the callback returned false.
					local.rv = false;
					break;
				}
			}
		}

		// Update the request with a hash of the query if it changed so that we can find it with pagination.
		local.querykey = $hashedKey(arguments.collection);
		if (!StructKeyExists(request.wheels, local.querykey)) {
			request.wheels[local.querykey] = variables.wheels.class.modelName;
		}

		return local.rv;
	}
}
