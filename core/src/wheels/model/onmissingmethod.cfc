component {
	/**
	 * This method is not designed to be called directly from your code, but provides functionality for dynamic finders such as `findOneByEmail()`
	 *
	 * [section: Model Class]
	 * [category: Miscellaneous Functions]
	 */
	public any function onMissingMethod(required string missingMethodName, required struct missingMethodArguments) {
		if (
			Right(arguments.missingMethodName, 10) == "hasChanged"
			&& StructKeyExists(variables.wheels.class.properties, ReplaceNoCase(arguments.missingMethodName, "hasChanged", ""))
		) {
			local.rv = hasChanged(property = ReplaceNoCase(arguments.missingMethodName, "hasChanged", ""));
		} else if (
			Right(arguments.missingMethodName, 11) == "changedFrom"
			&& StructKeyExists(variables.wheels.class.properties, ReplaceNoCase(arguments.missingMethodName, "changedFrom", ""))
		) {
			local.rv = changedFrom(property = ReplaceNoCase(arguments.missingMethodName, "changedFrom", ""));
		} else if (
			Right(arguments.missingMethodName, 9) == "IsPresent"
			&& StructKeyExists(variables.wheels.class.properties, ReplaceNoCase(arguments.missingMethodName, "IsPresent", ""))
		) {
			local.rv = propertyIsPresent(property = ReplaceNoCase(arguments.missingMethodName, "IsPresent", ""));
		} else if (
			Right(arguments.missingMethodName, 7) == "IsBlank"
			&& StructKeyExists(variables.wheels.class.properties, ReplaceNoCase(arguments.missingMethodName, "IsBlank", ""))
		) {
			local.rv = propertyIsBlank(property = ReplaceNoCase(arguments.missingMethodName, "IsBlank", ""));
		} else if (
			Left(arguments.missingMethodName, 9) == "columnFor"
			&& StructKeyExists(variables.wheels.class.properties, ReplaceNoCase(arguments.missingMethodName, "columnFor", ""))
		) {
			local.rv = columnForProperty(property = ReplaceNoCase(arguments.missingMethodName, "columnFor", ""));
		} else if (
			Left(arguments.missingMethodName, 6) == "toggle"
			&& StructKeyExists(variables.wheels.class.properties, ReplaceNoCase(arguments.missingMethodName, "toggle", ""))
		) {
			local.rv = toggle(
				property = ReplaceNoCase(arguments.missingMethodName, "toggle", ""),
				argumentCollection = arguments.missingMethodArguments
			);
		} else if (
			Left(arguments.missingMethodName, 3) == "has"
			&& StructKeyExists(variables.wheels.class.properties, ReplaceNoCase(arguments.missingMethodName, "has", ""))
		) {
			local.rv = hasProperty(property = ReplaceNoCase(arguments.missingMethodName, "has", ""));
		} else if (
			Left(arguments.missingMethodName, 6) == "update"
			&& StructKeyExists(variables.wheels.class.properties, ReplaceNoCase(arguments.missingMethodName, "update", ""))
		) {
			if (!StructKeyExists(arguments.missingMethodArguments, "value")) {
				Throw(
					type = "Wheels.IncorrectArguments",
					message = "The `value` argument is required but was not passed in.",
					extendedInfo = "Pass in a value to the dynamic updateProperty in the `value` argument."
				);
			}
			local.rv = updateProperty(
				property = ReplaceNoCase(arguments.missingMethodName, "update", ""),
				value = arguments.missingMethodArguments.value
			);
		} else if (
			Left(arguments.missingMethodName, 9) == "findOneBy"
			|| Left(arguments.missingMethodName, 9) == "findAllBy"
		) {
			// cfformat-ignore-start
			if (StructKeyExists(server, "lucee")) {
				// since Lucee passes in the method name in all upper case we have to do this here
				local.finderProperties = ListToArray(LCase(ReplaceNoCase(ReplaceNoCase(ReplaceNoCase(arguments.missingMethodName, "And", "|", "all"), "findAllBy", "", "all"), "findOneBy", "", "all")), "|");
			} else {
				local.finderProperties = ListToArray(ReplaceNoCase(ReplaceNoCase(Replace(arguments.missingMethodName, "And", "|", "all"), "findAllBy", "", "all"), "findOneBy", "", "all"), "|");
			}
			// cfformat-ignore-end

			// sometimes values will have commas in them, allow the developer to change the delimiter
			local.delimiter = ",";
			if (StructKeyExists(arguments.missingMethodArguments, "delimiter")) {
				local.delimiter = arguments.missingMethodArguments["delimiter"];
			}

			// split the values into an array for easier processing
			local.values = "";
			if (StructKeyExists(arguments.missingMethodArguments, "value")) {
				local.values = arguments.missingMethodArguments.value;
			} else if (StructKeyExists(arguments.missingMethodArguments, "values")) {
				local.values = arguments.missingMethodArguments.values;
			} else {
				local.values = arguments.missingMethodArguments[1];
			}

			if (!IsArray(local.values)) {
				if (ArrayLen(local.finderProperties) == 1) {
					// don't know why but this screws up in CF8
					local.temp = [];
					ArrayAppend(local.temp, local.values);
					local.values = local.temp;
				} else {
					local.values = $listClean(list = local.values, delim = local.delimiter, returnAs = "array");
				}
			}

			// where clause
			local.addToWhere = [];

			// loop through all the properties they want to query and assign values
			local.iEnd = ArrayLen(local.finderProperties);
			for (local.i = 1; local.i <= local.iEnd; local.i++) {
				local.property = local.finderProperties[local.i];
				if (ArrayLen(local.values) >= local.i) {
					local.value = local.values[local.i];
				} else if (StructKeyExists(arguments.missingMethodArguments, local.property)) {
					local.value = arguments.missingMethodArguments[local.property];
				}
				ArrayAppend(
					local.addToWhere,
					"#local.property# #$dynamicFinderOperator(local.property)# #variables.wheels.class.adapter.$quoteValue(str = local.value, type = validationTypeForProperty(local.property))#"
				);
			}

			// construct where clause
			local.addToWhere = ArrayToList(local.addToWhere, " AND ");
			arguments.missingMethodArguments.where = IIf(
				StructKeyExists(arguments.missingMethodArguments, "where") && Len(arguments.missingMethodArguments.where),
				"'(' & arguments.missingMethodArguments.where & ') AND (' & local.addToWhere & ')'",
				"local.addToWhere"
			);

			// remove unneeded arguments
			StructDelete(arguments.missingMethodArguments, "delimiter");
			StructDelete(arguments.missingMethodArguments, "1");
			StructDelete(arguments.missingMethodArguments, "value");
			StructDelete(arguments.missingMethodArguments, "values");

			// call finder method
			if (StructKeyExists(server, "boxlang")) {
				// BoxLang-specific handling to avoid argumentCollection parsing issues
				if (Left(arguments.missingMethodName, 9) == "findOneBy") {
					local.rv = findOne(argumentCollection = arguments.missingMethodArguments);
				} else {
					local.rv = findAll(argumentCollection = arguments.missingMethodArguments);
				}
			} else {
				// Adobe ColdFusion and Lucee compatibility
				local.rv = IIf(
					Left(arguments.missingMethodName, 9) == "findOneBy",
					"findOne(argumentCollection=arguments.missingMethodArguments)",
					"findAll(argumentCollection=arguments.missingMethodArguments)"
				);
			}
		} else if (Left(arguments.missingMethodName, 14) == "findOrCreateBy") {
			local.rv = $findOrCreateBy(argumentCollection = arguments);
		} else {
			local.rv = $associationMethod(argumentCollection = arguments);
		}

		if (!StructKeyExists(local, "rv")) {
			Throw(
				type = "Wheels.MethodNotFound",
				message = "The method `#arguments.missingMethodName#` was not found in the `#variables.wheels.class.modelName#` model.",
				extendedInfo = "Check your spelling or add the method to the model's CFC file."
			);
		}

		return local.rv;
	}

	/**
	 * Internal function.
	 */
	public any function $findOrCreateBy() {
		// default save to true but set to passed in value if it exists and then delete from arguments
		local.save = true;
		if (StructKeyExists(arguments.missingMethodArguments, "save")) {
			local.save = arguments.missingMethodArguments.save;
			StructDelete(arguments.missingMethodArguments, "save");
		}

		// get the property name from the last part of the function name
		local.property = ReplaceNoCase(arguments.missingMethodName, "findOrCreateBy", "");

		// get the value from the parameter that matches the property name or the first one if named arguments were not used or just one argument was passed in
		if (StructKeyExists(arguments.missingMethodArguments, "1")) {
			arguments.missingMethodArguments[local.property] = arguments.missingMethodArguments[1];
			StructDelete(arguments.missingMethodArguments, "1");
		} else if (StructCount(arguments.missingMethodArguments) == 1) {
			local.key = ListGetAt(StructKeyList(arguments.missingMethodArguments), 1);
			if (local.key != local.property) {
				arguments.missingMethodArguments[local.property] = arguments.missingMethodArguments[local.key];
				StructDelete(arguments.missingMethodArguments, local.key);
			}
		}
		local.value = arguments.missingMethodArguments[local.property];

		// setup arguments for passing in to findOne and create
		StructDelete(arguments, "missingMethodName");
		StructDelete(arguments.missingMethodArguments, local.property);
		StructAppend(arguments, arguments.missingMethodArguments);
		StructDelete(arguments, "missingMethodArguments");

		// add where argument for findOne and remove afterwards
		arguments.where = $keyWhereString(local.property, local.value);
		local.object = findOne(argumentCollection = arguments);
		StructDelete(arguments, "where");

		if (IsObject(local.object)) {
			local.rv = local.object;
		} else {
			arguments[local.property] = local.value;
			if (local.save) {
				local.rv = create(argumentCollection = arguments);
			} else {
				local.rv = new (argumentCollection = arguments);
			}
		}
		return local.rv;
	}

	/**
	 * Internal function.
	 */
	public string function $dynamicFinderOperator(required string property) {
		if (
			StructKeyExists(variables.wheels.class.properties, arguments.property)
			&& variables.wheels.class.properties[arguments.property].dataType == "text"
		) {
			return "LIKE";
		} else {
			return "=";
		}
	}

	/**
	 * Internal function.
	 */
	public any function $associationMethod() {
		for (local.key in variables.wheels.class.associations) {
			local.method = "";
			if (
				StructKeyExists(variables.wheels.class.associations[local.key], "shortcut")
				&& arguments.missingMethodName == variables.wheels.class.associations[local.key].shortcut
			) {
				local.method = "findAll";
				local.joinAssociation = $expandedAssociations(include = local.key);
				local.joinAssociation = local.joinAssociation[1];
				local.joinClass = local.joinAssociation.modelName;
				local.info = model(local.joinClass).$expandedAssociations(
					include = ListFirst(variables.wheels.class.associations[local.key].through)
				);
				local.info = local.info[1];
				local.componentReference = model(local.info.modelName);
				local.include = ListLast(variables.wheels.class.associations[local.key].through);
				if (StructKeyExists(arguments.missingMethodArguments, "include")) {
					local.include = "#local.include#(#arguments.missingMethodArguments.include#)";
				}
				arguments.missingMethodArguments.include = local.include;
				local.where = $keyWhereString(
					properties = local.joinAssociation.foreignKey,
					keys = primaryKeys()
				);
				if (StructKeyExists(arguments.missingMethodArguments, "where")) {
					local.where = "(#local.where#) AND (#arguments.missingMethodArguments.where#)";
				}
				arguments.missingMethodArguments.where = local.where;
				if (!StructKeyExists(arguments.missingMethodArguments, "returnIncluded")) {
					arguments.missingMethodArguments.returnIncluded = false;
				}
			} else if (ListFindNoCase(variables.wheels.class.associations[local.key].methods, arguments.missingMethodName)) {
				local.info = $expandedAssociations(include = local.key);
				local.info = local.info[1];
				local.componentReference = model(local.info.modelName);
				if (local.info.type == "hasOne") {
					local.where = $keyWhereString(properties = local.info.foreignKey, keys = primaryKeys());
					if (StructKeyExists(arguments.missingMethodArguments, "where") && Len(arguments.missingMethodArguments.where)) {
						local.where = "(#local.where#) AND (#arguments.missingMethodArguments.where#)";
					}

					// create a generic method name (example: "hasProfile" becomes "hasObject")
					local.name = ReplaceNoCase(arguments.missingMethodName, local.key, "object");

					if (local.name == "object") {
						local.method = "findOne";
						arguments.missingMethodArguments.where = local.where;
					} else if (local.name == "hasObject") {
						local.method = "exists";
						arguments.missingMethodArguments.where = local.where;
					} else if (local.name == "newObject") {
						local.method = "new";
						$setForeignKeyValues(missingMethodArguments = arguments.missingMethodArguments, keys = local.info.foreignKey);
					} else if (local.name == "createObject") {
						local.method = "create";
						$setForeignKeyValues(missingMethodArguments = arguments.missingMethodArguments, keys = local.info.foreignKey);
					} else if (local.name == "removeObject") {
						local.method = "updateOne";
						arguments.missingMethodArguments.where = local.where;
						$setForeignKeyValues(
							missingMethodArguments = arguments.missingMethodArguments,
							keys = local.info.foreignKey,
							setToNull = true
						);
					} else if (local.name == "deleteObject") {
						local.method = "deleteOne";
						arguments.missingMethodArguments.where = local.where;
					} else if (local.name == "setObject") {
						// single argument, must be either the key or the object
						if (StructCount(arguments.missingMethodArguments) == 1) {
							if (IsObject(arguments.missingMethodArguments[1])) {
								local.componentReference = arguments.missingMethodArguments[1];
								local.method = "update";
							} else {
								arguments.missingMethodArguments.key = arguments.missingMethodArguments[1];
								local.method = "updateByKey";
							}
							StructClear(arguments.missingMethodArguments);
						} else {
							// multiple arguments so ensure that either 'key' or the association name exists (local.key)
							if (
								StructKeyExists(arguments.missingMethodArguments, local.key)
								&& IsObject(arguments.missingMethodArguments[local.key])
							) {
								local.componentReference = arguments.missingMethodArguments[local.key];
								local.method = "update";
								StructDelete(arguments.missingMethodArguments, local.key);
							} else if (StructKeyExists(arguments.missingMethodArguments, "key")) {
								local.method = "updateByKey";
							} else {
								Throw(
									type = "Wheels.IncorrectArguments",
									message = "The `#local.key#` or `key` named argument is required.",
									extendedInfo = "When using multiple arguments for #local.name#() you must supply an object using the argument `#local.key#` or a key using the argument `key`, e.g. #local.name#(#local.key#=post) or #local.name#(key=post.id)."
								);
							}
						}
						$setForeignKeyValues(missingMethodArguments = arguments.missingMethodArguments, keys = local.info.foreignKey);
					}
				} else if (local.info.type == "hasMany") {
					if (structKeyExists(local.info, "joinKey") AND Len(local.info.joinKey) AND local.info.joinKey NEQ primaryKeys()) {
						local.where = $keyWhereString(properties = local.info.foreignKey, keys = local.info.joinKey);
					} else {
						local.where = $keyWhereString(properties = local.info.foreignKey, keys = primaryKeys());
					}
					if (StructKeyExists(arguments.missingMethodArguments, "where") && Len(arguments.missingMethodArguments.where)) {
						local.where = "(#local.where#) AND (#arguments.missingMethodArguments.where#)";
					}
					local.singularKey = singularize(local.key);

					// create a generic method name (example: "hasComments" becomes "hasObjects")
					local.name = ReplaceNoCase(arguments.missingMethodName, local.key, "objects");
					if (local.name == arguments.missingMethodName) {
						// we should never change anything more than once so if the plural version was already replaced we do not need to replace the singular one
						local.name = ReplaceNoCase(local.name, local.singularKey, "object");
					}

					if (local.name == "objects") {
						local.method = "findAll";
						arguments.missingMethodArguments.where = local.where;
					} else if (local.name == "addObject") {
						// single argument, must be either the key or the object
						if (StructCount(arguments.missingMethodArguments) == 1) {
							if (IsObject(arguments.missingMethodArguments[1])) {
								local.componentReference = arguments.missingMethodArguments[1];
								local.method = "update";
							} else {
								arguments.missingMethodArguments.key = arguments.missingMethodArguments[1];
								local.method = "updateByKey";
							}
							StructClear(arguments.missingMethodArguments);
						} else {
							// multiple arguments so ensure that either 'key' or the singularized association name exists (local.singularKey)
							if (
								StructKeyExists(arguments.missingMethodArguments, local.singularKey)
								&& IsObject(arguments.missingMethodArguments[local.singularKey])
							) {
								local.componentReference = arguments.missingMethodArguments[local.singularKey];
								local.method = "update";
								StructDelete(arguments.missingMethodArguments, local.singularKey);
							} else if (StructKeyExists(arguments.missingMethodArguments, "key")) {
								local.method = "updateByKey";
							} else {
								Throw(
									type = "Wheels.IncorrectArguments",
									message = "The `#local.singularKey#` or `key` named argument is required.",
									extendedInfo = "When using multiple arguments for #local.name#() you must supply an object using the argument `#local.singularKey#` or a key using the argument `key`, e.g. #local.name#(#local.singularKey#=post) or #local.name#(key=post.id)."
								);
							}
						}
						$setForeignKeyValues(missingMethodArguments = arguments.missingMethodArguments, keys = local.info.foreignKey);
					} else if (local.name == "removeObject") {
						// single argument, must be either the key or the object
						if (StructCount(arguments.missingMethodArguments) == 1) {
							if (IsObject(arguments.missingMethodArguments[1])) {
								local.componentReference = arguments.missingMethodArguments[1];
								local.method = "update";
							} else {
								arguments.missingMethodArguments.key = arguments.missingMethodArguments[1];
								local.method = "updateByKey";
							}
							StructClear(arguments.missingMethodArguments);
						} else {
							// multiple arguments so ensure that either 'key' or the singularized object name exists (local.singularKey)
							if (
								StructKeyExists(arguments.missingMethodArguments, local.singularKey)
								&& IsObject(arguments.missingMethodArguments[local.singularKey])
							) {
								local.componentReference = arguments.missingMethodArguments[local.singularKey];
								local.method = "update";
								StructDelete(arguments.missingMethodArguments, local.singularKey);
							} else if (StructKeyExists(arguments.missingMethodArguments, "key")) {
								local.method = "updateByKey";
							} else {
								Throw(
									type = "Wheels.IncorrectArguments",
									message = "The `#local.singularKey#` or `key` named argument is required.",
									extendedInfo = "When using multiple arguments for #local.name#() you must supply an object using the argument `#local.singularKey#` or a key using the argument `key`, e.g. #local.name#(#local.singularKey#=post) or #local.name#(key=post.id)."
								);
							}
						}
						$setForeignKeyValues(
							missingMethodArguments = arguments.missingMethodArguments,
							keys = local.info.foreignKey,
							setToNull = true
						);
					} else if (local.name == "deleteObject") {
						// single argument, must be either the key or the object
						if (StructCount(arguments.missingMethodArguments) == 1) {
							if (IsObject(arguments.missingMethodArguments[1])) {
								local.componentReference = arguments.missingMethodArguments[1];
								local.method = "delete";
							} else {
								arguments.missingMethodArguments.key = arguments.missingMethodArguments[1];
								local.method = "deleteByKey";
							}
							StructClear(arguments.missingMethodArguments);
						} else {
							// multiple arguments so ensure that either 'key' or the singularized object name exists (local.singularKey)
							if (
								StructKeyExists(arguments.missingMethodArguments, local.singularKey)
								&& IsObject(arguments.missingMethodArguments[local.singularKey])
							) {
								local.componentReference = arguments.missingMethodArguments[local.singularKey];
								local.method = "delete";
								StructDelete(arguments.missingMethodArguments, local.singularKey);
							} else if (StructKeyExists(arguments.missingMethodArguments, "key")) {
								local.method = "deleteByKey";
							} else {
								Throw(
									type = "Wheels.IncorrectArguments",
									message = "The `#local.singularKey#` or `key` named argument is required.",
									extendedInfo = "When using multiple arguments for #local.name#() you must supply an object using the argument `#local.singularKey#` or a key using the argument `key`, e.g. #local.name#(#local.singularKey#=post) or #local.name#(key=post.id)."
								);
							}
						}
						$setForeignKeyValues(missingMethodArguments = arguments.missingMethodArguments, keys = local.info.foreignKey);
					} else if (local.name == "hasObjects") {
						local.method = "exists";
						arguments.missingMethodArguments.where = local.where;
					} else if (local.name == "newObject") {
						local.method = "new";
						$setForeignKeyValues(missingMethodArguments = arguments.missingMethodArguments, keys = local.info.foreignKey);
					} else if (local.name == "createObject") {
						local.method = "create";
						$setForeignKeyValues(missingMethodArguments = arguments.missingMethodArguments, keys = local.info.foreignKey);
					} else if (local.name == "objectCount") {
						local.method = "count";
						arguments.missingMethodArguments.where = local.where;
					} else if (local.name == "findOneObject") {
						local.method = "findOne";
						arguments.missingMethodArguments.where = local.where;
					} else if (local.name == "removeAllObjects") {
						local.method = "updateAll";
						arguments.missingMethodArguments.where = local.where;
						$setForeignKeyValues(
							missingMethodArguments = arguments.missingMethodArguments,
							keys = local.info.foreignKey,
							setToNull = true
						);
					} else if (local.name == "deleteAllObjects") {
						local.method = "deleteAll";
						arguments.missingMethodArguments.where = local.where;
					}
				} else if (local.info.type == "belongsTo") {
					local.where = $keyWhereString(keys = local.info.foreignKey, properties = local.componentReference.primaryKeys());
					if (StructKeyExists(arguments.missingMethodArguments, "where") && Len(arguments.missingMethodArguments.where)) {
						local.where = "(#local.where#) AND (#arguments.missingMethodArguments.where#)";
					}

					// create a generic method name (example: "hasAuthor" becomes "hasObject")
					local.name = ReplaceNoCase(arguments.missingMethodName, local.key, "object");

					if (local.name == "object") {
						local.method = "findByKey";
						arguments.missingMethodArguments.key = $propertyValue(name = local.info.foreignKey);
					} else if (local.name == "hasObject") {
						local.method = "exists";
						arguments.missingMethodArguments.key = $propertyValue(name = local.info.foreignKey);
					}
				}
			}
			if (Len(local.method)) {
				local.rv = $invoke(
					componentReference = local.componentReference,
					method = local.method,
					invokeArgs = arguments.missingMethodArguments
				);
			}
		}

		if (StructKeyExists(local, "rv")) {
			return local.rv;
		}
	}

	/**
	 * Internal function.
	 */
	public string function $propertyValue(required string name) {
		local.rv = "";
		local.iEnd = ListLen(arguments.name);
		for (local.i = 1; local.i <= local.iEnd; local.i++) {
			local.item = ListGetAt(arguments.name, local.i);
			local.rv = ListAppend(local.rv, this[local.item]);
		}
		return local.rv;
	}

	/**
	 * Internal function.
	 */
	public void function $setForeignKeyValues(
		required struct missingMethodArguments,
		required string keys,
		boolean setToNull = "false"
	) {
		local.iEnd = ListLen(arguments.keys);
		for (local.i = 1; local.i <= local.iEnd; local.i++) {
			local.item = ListGetAt(arguments.keys, local.i);
			if (arguments.setToNull) {
				arguments.missingMethodArguments[local.item] = "";
			} else {
				arguments.missingMethodArguments[local.item] = this[primaryKeys(local.i)];
			}
		}
	}
}
