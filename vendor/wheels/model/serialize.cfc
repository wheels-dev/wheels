component {
	/**
	 * Internal function.
	 */
	public any function $serializeQueryToObjects(
		required query query,
		string include = "",
		string callbacks = "true",
		string returnIncluded = "true"
	) {
		// grab our objects as structs first so we don't waste cpu creating objects we don't need
		local.rv = $serializeQueryToStructs(argumentCollection = arguments);
		local.rv = $serializeStructsToObjects(structs = local.rv, argumentCollection = arguments);
		return local.rv;
	}

	/**
	 * Internal function.
	 */
	public any function $serializeStructsToObjects(
		required any structs,
		required string include,
		required string callbacks,
		required string returnIncluded
	) {
		if (IsStruct(arguments.structs)) {
			local.rv = [arguments.structs];
		} else if (IsArray(arguments.structs)) {
			local.rv = arguments.structs;
		}
		local.iEnd = ArrayLen(local.rv);
		for (local.i = 1; local.i <= local.iEnd; local.i++) {
			if (Len(arguments.include) && arguments.returnIncluded) {
				// create each object from the associations before creating our root object
				local.jEnd = ListLen(arguments.include);
				for (local.j = 1; local.j <= local.jEnd; local.j++) {
					local.include = ListGetAt(arguments.include, local.j);
					local._model = model(variables.wheels.class.associations[local.include].modelName);
					if (variables.wheels.class.associations[local.include].type == "hasMany") {
						local.kEnd = ArrayLen(local.rv[local.i][local.include]);
						for (local.k = 1; local.k <= local.kEnd; local.k++) {
							local.rv[local.i][local.include][local.k] = local._model.$createInstance(
								properties = local.rv[local.i][local.include][local.k],
								persisted = true,
								base = false,
								callbacks = arguments.callbacks
							);
						}
					} else {
						// We have a hasOne or belongsTo association, so just add the object to the root object.
						local.rv[local.i][local.include] = local._model.$createInstance(
							properties = local.rv[local.i][local.include],
							persisted = true,
							base = false,
							callbacks = arguments.callbacks
						);
					}
				}
			}
			local.rv[local.i] = $createInstance(
				properties = local.rv[local.i],
				persisted = true,
				callbacks = arguments.callbacks
			);
		}
		return local.rv;
	}

	/**
	 * Internal function.
	 */
	public any function $serializeQueryToStructs(
		required query query,
		required string include,
		required string callbacks,
		required string returnIncluded
	) {
		local.rv = [];
		local.doneStructs = "";

		// loop through all of our records and create an object for each row in the query
		local.iEnd = arguments.query.recordCount;
		for (local.i = 1; local.i <= local.iEnd; local.i++) {
			// create a new struct
			local.struct = $queryRowToStruct(properties = arguments.query, row = local.i);
			local.structHash = $hashedKey(local.struct);
			if (!ListFind(local.doneStructs, local.structHash, Chr(7))) {
				if (Len(arguments.include) && arguments.returnIncluded) {
					// loop through our associations to build nested objects attached to the main object
					local.jEnd = ListLen(arguments.include);
					for (local.j = 1; local.j <= local.jEnd; local.j++) {
						local.include = ListGetAt(arguments.include, local.j);
						if (variables.wheels.class.associations[local.include].type == "hasMany") {
							// we have a hasMany association, so loop through all of the records again to find the ones that belong to our root object
							local.struct[local.include] = [];
							local.hasManyDoneStructs = "";

							// only get a reference to our model once per association
							local._model = model(variables.wheels.class.associations[local.include].modelName);

							local.kEnd = arguments.query.recordCount;
							for (local.k = 1; local.k <= local.kEnd; local.k++) {
								// is there anything we can do here to not instantiate an object if it is not going to be use or is already created
								// this extra instantiation is really slowing things down
								local.hasManyStruct = local._model.$queryRowToStruct(
									properties = arguments.query,
									row = local.k,
									base = false
								);
								local.hasManyStructHash = $hashedKey(local.hasManyStruct);
								if (!ListFind(local.hasManyDoneStructs, local.hasManyStructHash, Chr(7))) {
									// create object instance from values in current query row if it belongs to the current object
									local.primaryKeyColumnValues = "";
									local.lEnd = ListLen(primaryKeys());
									for (local.l = 1; local.l <= local.lEnd; local.l++) {
										local.primaryKeyColumnValues = ListAppend(
											local.primaryKeyColumnValues,
											arguments.query[primaryKeys(local.l)][local.k]
										);
									}
									if (
										Len(local._model.$keyFromStruct(local.hasManyStruct))
										&& this.$keyFromStruct(local.struct) == local.primaryKeyColumnValues
									) {
										ArrayAppend(local.struct[local.include], local.hasManyStruct);
									}
									local.hasManyDoneStructs = ListAppend(local.hasManyDoneStructs, local.hasManyStructHash, Chr(7));
								}
							}
						} else {
							// We have a hasOne or belongsTo association, so just add the object to the root object.
							local.struct[local.include] = model(variables.wheels.class.associations[local.include].modelName).$queryRowToStruct(
								properties = arguments.query,
								row = local.i,
								base = false
							);
						}
					}
				}

				/* To fix the bug below:
					https://github.com/cfwheels/cfwheels/issues/605

					Added callback for Afterfind in function. The afterFind hook was not being called when findAll(returnAs = 'struct') is used on the model.
					Called the afterFind hook, the hook adds the arguments defined in the hook to the object so get the properties using properties() function and then append the property struct to the individual record struct
				*/
				if (arguments.callbacks && structKeyExists(this, 'afterFindCallback') && arguments.returnas eq "struct") {
					$callback("afterFind", arguments.callbacks);
					local.objectProps = properties();
					structAppend(local.struct, local.objectProps);
				}

				ArrayAppend(local.rv, local.struct);
				local.doneStructs = ListAppend(local.doneStructs, local.structHash, Chr(7));
			}
		}
		return local.rv;
	}

	/**
	 * Internal function.
	 */
	public struct function $queryRowToStruct(
		required any properties,
		string name = "#variables.wheels.class.modelName#",
		numeric row = "1",
		boolean base = "true"
	) {
		local.rv = {};
		local.allProperties = ListToArray(ListAppend(variables.wheels.class.propertyList, variables.wheels.class.calculatedPropertyList));
		// a struct key is much faster than a list element
		local.columnStruct = $listToStruct(arguments.properties.columnList);
		local.iEnd = ArrayLen(local.allProperties);
		for (local.i = 1; local.i <= local.iEnd; local.i++) {
			// Wrap in try/catch because coldfusion has a problem with empty strings in queries for bit types.
			try {
				local.item = local.allProperties[local.i];
				if (!arguments.base && StructKeyExists(local.columnStruct, arguments.name & local.item)) {
					local.rv[local.item] = arguments.properties[arguments.name & local.item][arguments.row];
				} else if (StructKeyExists(local.columnStruct, local.item)) {
					local.rv[local.item] = arguments.properties[local.item][arguments.row];
				}
			} catch (any e) {
				local.rv[local.item] = "";
			}
		}

		for (local.column in arguments.properties.columnList) {
			if (!StructKeyExists(local.rv, local.column)) {
				local.rv[local.column] = arguments.properties[local.column][arguments.row];
			}
		}
		return local.rv;
	}

	/**
	 * Internal function.
	 */
	public string function $keyFromStruct(required struct struct) {
		local.rv = "";
		local.iEnd = ListLen(primaryKeys());
		for (local.i = 1; local.i <= local.iEnd; local.i++) {
			local.property = primaryKeys(local.i);
			if (StructKeyExists(arguments.struct, local.property)) {
				local.rv = ListAppend(local.rv, arguments.struct[local.property]);
			}
		}
		return local.rv;
	}
}
