component {
	/**
	 * Allows for nested objects, structs, and arrays to be set from params and other generated data.
	 *
	 * [section: Model Configuration]
	 * [category: Miscellaneous Functions]
	 *
	 * @association The association (or list of associations) you want to allow to be set through the params. This argument is also aliased as `associations`.
	 * @autoSave Whether to save the association(s) when the parent object is saved.
	 * @allowDelete Set this to `true` to tell Wheels to look for the property `_delete` in your model. If present and set to a value that evaluates to true, the model will be deleted when saving the parent.
	 * @sortProperty Set this to a property on the object that you would like to sort by. The property should be numeric, should start with 1, and should be consecutive. Only valid with `hasMany` associations.
	 * @rejectIfBlank A list of properties that should not be blank. If any of the properties are blank, any CRUD operations will be rejected.
	 */
	public void function nestedProperties(
		string association = "",
		boolean autoSave,
		boolean allowDelete,
		string sortProperty,
		string rejectIfBlank
	) {
		$args(args = arguments, name = "nestedProperties", combine = "association/associations");
		arguments.association = $listClean(arguments.association);
		local.iEnd = ListLen(arguments.association);
		for (local.i = 1; local.i <= local.iEnd; local.i++) {
			local.association = ListGetAt(arguments.association, local.i);
			if (StructKeyExists(variables.wheels.class.associations, local.association)) {
				variables.wheels.class.associations[local.association].nested.allow = true;
				variables.wheels.class.associations[local.association].nested.delete = arguments.allowDelete;
				variables.wheels.class.associations[local.association].nested.autoSave = arguments.autoSave;
				variables.wheels.class.associations[local.association].nested.sortProperty = arguments.sortProperty;
				variables.wheels.class.associations[local.association].nested.rejectIfBlank = $listClean(arguments.rejectIfBlank);

				// Add to the white list if it exists.
				if (StructKeyExists(variables.wheels.class.accessibleProperties, "whiteList")) {
					variables.wheels.class.accessibleProperties.whiteList[local.association] = 1;
				}
			} else if (application.wheels.showErrorInformation) {
				Throw(
					type = "Wheels.AssociationNotFound",
					message = "The `#local.association#` association was not found on the `#variables.wheels.class.modelName#` model.",
					extendedInfo = "Make sure you have called `hasMany()`, `hasOne()`, or `belongsTo()` before calling the `nestedProperties()` method."
				);
			}
		}
	}

	/**
	 * Internal function.
	 */
	public boolean function $validateAssociations(required boolean callbacks, boolean validateAssociations = false) {
		local.associations = variables.wheels.class.associations;
		local.rv = true;
		for (local.association in local.associations) {
			if (
				local.associations[local.association].nested.allow
				&& local.associations[local.association].nested.autoSave
				&& StructKeyExists(this, local.association)
			) {
				local.array = this[local.association];
				if (IsObject(this[local.association])) {
					local.array = [this[local.association]];
				}
				if (IsArray(local.array)) {
					for (local.i = 1; local.i <= ArrayLen(local.array); local.i++) {
						if (!isNull(local.array[local.i])) {
							local.isAssociationValid = local.array[local.i].valid(
								callbacks = arguments.callbacks,
								validateAssociations = arguments.validateAssociations
							);
							if (!local.isAssociationValid) {
								local.rv = false;
							}
						}
					}
				}
			}
		}
		return local.rv;
	}

	/**
	 * Internal function.
	 */
	public boolean function $saveAssociations(
		required any parameterize,
		required boolean reload,
		required boolean validate,
		required boolean callbacks
	) {
		local.rv = true;
		local.associations = variables.wheels.class.associations;
		for (local.association in local.associations) {
			if (
				local.associations[local.association].nested.allow
				&& local.associations[local.association].nested.autoSave
				&& StructKeyExists(this, local.association)
			) {
				local.array = this[local.association];
				if (!IsNull(this[local.association]) && IsObject(this[local.association])) {
					local.array = [this[local.association]];
				}
				if (IsArray(local.array)) {
					// Get our expanded information for this association.
					local.info = $expandedAssociations(include = local.association);
					local.info = local.info[1];

					for (local.i = 1; local.i <= ArrayLen(local.array); local.i++) {
						if (!isNull(local.array[local.i])) {
							if (ListFindNoCase("hasMany,hasOne", local.associations[local.association].type)) {
								$setForeignKeyValues(missingMethodArguments = local.array[local.i], keys = local.info.foreignKey);
							}
							local.saveResult = $invoke(componentReference = local.array[local.i], method = "save", invokeArgs = arguments);
							if (local.rv) {
								// Don't change the return value when we have already received a false.
								local.rv = local.saveResult;
							}
						}
					}
				}
			}
		}

		// If the associations were not saved correctly, roll them back to their new state but keep the errors.
		if (!local.rv) {
			$resetAssociationsToNew();
		}

		return local.rv;
	}

	/**
	 * Internal function.
	 */
	public boolean function $setAssociations() {
		local.associations = variables.wheels.class.associations;
		for (local.item in local.associations) {
			local.association = local.associations[local.item];
			if (local.association.nested.allow && local.association.nested.autoSave && StructKeyExists(this, local.item)) {
				if (ListFindNoCase("belongsTo,hasOne", local.association.type) && IsStruct(this[local.item])) {
					$setOneToOneAssociationProperty(
						property = local.item,
						value = this[local.item],
						association = local.association,
						delete = true
					);
				} else if (local.association.type == "hasMany" && IsArray(this[local.item]) && ArrayLen(this[local.item])) {
					$setCollectionAssociationProperty(
						property = local.item,
						value = this[local.item],
						association = local.association,
						delete = true
					);
				}
			}
		}
		return true;
	}

	/**
	 * Internal function.
	 */
	public void function $setOneToOneAssociationProperty(
		required string property,
		required struct value,
		required struct association,
		boolean delete = "false"
	) {
		if (
			!StructKeyExists(this, arguments.property)
			|| !IsObject(this[arguments.property])
			|| StructKeyExists(this[arguments.property], "_delete")
		) {
			this[arguments.property] = $getAssociationObject(argumentCollection = arguments);
		}
		if (IsObject(this[arguments.property])) {
			this[arguments.property].setProperties(properties = arguments.value);
		} else {
			StructDelete(this, arguments.property);
		}
	}

	/**
	 * Internal function.
	 */
	public void function $setCollectionAssociationProperty(
		required string property,
		required any value,
		required struct association,
		boolean delete = false
	) {
		local.model = model(arguments.association.modelName);
		if (!StructKeyExists(this, arguments.property) || !IsArray(this[arguments.property])) {
			this[arguments.property] = [];
		}
		if (IsStruct(arguments.value)) {
			for (local.item in arguments.value) {
				// Check to see if the id is a tickcount, if so the object is new.
				if (IsNumeric(local.item) && Ceiling(Right(GetTickCount(), 12) / 900000000) == Ceiling(local.item / 900000000)) {
					ArrayAppend(
						this[arguments.property],
						$getAssociationObject(
							property = arguments.property,
							value = arguments.value[local.item],
							association = arguments.association,
							delete = arguments.delete
						)
					);
					$updateCollectionObject(property = arguments.property, value = arguments.value[local.item]);
				} else {
					// Get our primary keys.
					local.keys = local.model.primaryKey();
					local.itemArray = ListToArray(local.item, ",", true);
					local.iEnd = ListLen(local.keys);
					for (local.i = 1; local.i <= local.iEnd; local.i++) {
						arguments.value[local.item][ListGetAt(local.keys, local.i)] = local.itemArray[local.i];
					}

					ArrayAppend(
						this[arguments.property],
						$getAssociationObject(
							property = arguments.property,
							value = arguments.value[local.item],
							association = arguments.association,
							delete = arguments.delete
						)
					);
					$updateCollectionObject(property = arguments.property, value = arguments.value[local.item]);
				}
			}
		} else if (IsArray(arguments.value)) {
			for (local.i = 1; local.i <= ArrayLen(arguments.value); local.i++) {
				if (
					IsObject(arguments.value[local.i])
					&& ArrayLen(this[arguments.property]) >= local.i
					&& IsObject(this[arguments.property][local.i])
					&& this[arguments.property][local.i].compareTo(arguments.value[local.i])
				) {
					this[arguments.property][local.i] = $getAssociationObject(
						property = arguments.property,
						value = arguments.value[local.i],
						association = arguments.association,
						delete = arguments.delete
					);
					if (!IsStruct(this[arguments.property][local.i]) && !this[arguments.property][local.i]) {
						ArrayDeleteAt(this[arguments.property], local.i);
						local.i--;
					} else {
						$updateCollectionObject(property = arguments.property, value = arguments.value[local.i], position = local.i);
					}
				} else if (
					IsStruct(arguments.value[local.i])
					&& ArrayLen(this[arguments.property]) >= local.i
					&& IsObject(this[arguments.property][local.i])
				) {
					this[arguments.property][local.i] = $getAssociationObject(
						property = arguments.property,
						value = arguments.value[local.i],
						association = arguments.association,
						delete = arguments.delete
					);
					if (!IsStruct(this[arguments.property][local.i]) && !this[arguments.property][local.i]) {
						ArrayDeleteAt(this[arguments.property], local.i);
						local.i--;
					} else {
						$updateCollectionObject(property = arguments.property, value = arguments.value[local.i], position = local.i);
					}
				} else {
					ArrayAppend(
						this[arguments.property],
						$getAssociationObject(
							property = arguments.property,
							value = arguments.value[local.i],
							association = arguments.association,
							delete = arguments.delete
						)
					);
					$updateCollectionObject(property = arguments.property, value = arguments.value[local.i]);
				}
			}
		}

		// Sort the order of the objects in the array if the property is set.
		if (Len(arguments.association.nested.sortProperty)) {
			local.sortedArray = [];
			local.iEnd = ArrayLen(this[arguments.property]);
			for (local.i = 1; local.i <= local.iEnd; local.i++) {
				if (!IsNumeric(this[arguments.property][local.i][arguments.association.nested.sortProperty])) {
					return;
				}
				local.prop = this[arguments.property][local.i];
				local.sortedArray[this[arguments.property][local.i][arguments.association.nested.sortProperty]] = local.prop;
			}
			this[arguments.property] = local.sortedArray;
		}
	}

	/**
	 * Internal function.
	 */
	public void function $updateCollectionObject(required string property, required struct value, numeric position = 0) {
		if (!arguments.position) {
			arguments.position = ArrayLen(this[arguments.property]);
		}
		if (IsObject(this[arguments.property][arguments.position])) {
			this[arguments.property][arguments.position].setProperties(properties = arguments.value);
		} else {
			ArrayDeleteAt(this[arguments.property], arguments.position);
		}
	}

	/**
	 * Internal function.
	 */
	public any function $getAssociationObject(
		required string property,
		required struct value,
		required struct association,
		required boolean delete
	) {
		local.object = false;
		local.delete = false;
		local.args = {};
		local.model = model(arguments.association.modelName);

		// Check to see if the struct has all of the keys we need from rejectIfBlank.
		if ($structKeysExist(struct = arguments.value, properties = arguments.association.nested.rejectIfBlank)) {
			// Get our primary keys, if they don't exist, then we create a new object.
			local.args.key = $createPrimaryKeyList(params = arguments.value, keys = local.model.primaryKey());
			if (IsObject(arguments.value)) {
				local.object = arguments.value;
			} else if (Len(local.args.key)) {
				local.object = local.model.findByKey(argumentCollection = local.args);
			}

			if (
				StructKeyExists(arguments.value, "_delete") && IsBoolean(arguments.value["_delete"]) && arguments.value["_delete"]
			) {
				local.delete = true;
			}
			if (!IsObject(local.object) && !local.delete) {
				StructDelete(local.args, "key");
				return $invoke(componentReference = local.model, method = "new", invokeArgs = local.args);
			} else if (Len(local.args.key) && local.delete && arguments.association.nested.delete && arguments.delete) {
				$invoke(componentReference = local.model, method = "deleteByKey", invokeArgs = local.args);
				return false;
			}
		}
		return local.object;
	}

	/**
	 * Internal function.
	 */
	public string function $createPrimaryKeyList(required struct params, required string keys) {
		local.rv = "";
		local.iEnd = ListLen(arguments.keys);
		for (local.i = 1; local.i <= local.iEnd; local.i++) {
			local.key = ListGetAt(arguments.keys, local.i);
			if (!StructKeyExists(arguments.params, local.key) || !Len(arguments.params[local.key])) {
				return "";
			}
			local.rv = ListAppend(local.rv, arguments.params[local.key]);
		}
		return local.rv;
	}

	/**
	 * Internal function.
	 */
	public void function $resetToNew() {
		if ($persistedOnInitialization()) {
			return;
		}

		// Remove the persisted properties container.
		StructDelete(variables, "$persistedProperties");

		// Remove any primary keys set by the save.
		local.keys = primaryKeys();
		local.iEnd = ListLen(local.keys);
		for (local.i = 1; local.i <= local.iEnd; local.i++) {
			local.item = ListGetAt(local.keys, local.i);
			StructDelete(this, local.item);
		}
	}

	/**
	 * Internal function.
	 */
	public void function $resetAssociationsToNew() {
		local.associations = variables.wheels.class.associations;
		for (local.association in local.associations) {
			local.nested = local.associations[local.association].nested;
			if (local.nested.allow && local.nested.autoSave && StructKeyExists(this, local.association)) {
				local.array = this[local.association];
				if (IsObject(this[local.association])) {
					local.array = [this[local.association]];
				}
				if (IsArray(local.array)) {
					local.iEnd = ArrayLen(local.array);
					for (local.i = 1; local.i <= local.iEnd; local.i++) {
						local.array[local.i].$resetToNew();
					}
				}
			}
		}
	}

	/**
	 * Internal function.
	 */
	public boolean function $persistedOnInitialization() {
		if (
			StructKeyExists(variables.wheels.instance, "persistedOnInitialization")
			&& variables.wheels.instance.persistedOnInitialization
		) {
			return true;
		} else {
			return false;
		}
	}
}
