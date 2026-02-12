component {
	/**
	 * Creates a new object, saves it to the database (if the validation permits it), and returns it.
	 * If the validation fails, the unsaved object (with errors added to it) is still returned.
	 * Property names and values can be passed in either using named arguments or as a struct to the `properties` argument.
	 *
	 * [section: Model Class]
	 * [category: Create Functions]
	 *
	 * @properties [see:new].
	 * @parameterize [see:findAll].
	 * @reload [see:findAll].
	 * @validate [see:save].
	 * @transaction [see:save].
	 * @callbacks [see:findAll].
	 * @allowExplicitTimestamps Set this to `true` to allow explicit assignment of `createdAt` or `updatedAt` properties
	 */
	public any function create(
		struct properties = {},
		any parameterize,
		boolean reload,
		boolean validate = true,
		string transaction = $get("transactionMode"),
		boolean callbacks = true,
		boolean allowExplicitTimestamps = false
	) {
		$args(name = "create", args = arguments);
		$setProperties(
			argumentCollection = arguments,
			filterList = "properties,parameterize,reload,validate,transaction,callbacks"
		);
		local.rv = new (argumentCollection = arguments);
		local.rv.save(
			callbacks = arguments.callbacks,
			parameterize = arguments.parameterize,
			reload = arguments.reload,
			transaction = arguments.transaction,
			validate = arguments.validate
		);
		return local.rv;
	}

	/**
	 * Creates a new object based on supplied `properties` and returns it.
	 * The object is not saved to the database, it only exists in memory.
	 * Property names and values can be passed in either using named arguments or as a struct to the `properties` argument.
	 *
	 * [section: Model Class]
	 * [category: Create Functions]
	 *
	 * @properties The properties you want to set on the object (can also be passed in as named arguments).
	 * @callbacks [see:findAll].
	 * @allowExplicitTimestamps Set this to `true` to allow explicit assignment of `createdAt` or `updatedAt` properties
	 */
	public any function new(
		struct properties = {},
		boolean callbacks = true,
		boolean allowExplicitTimestamps = false
	) {
		arguments.properties = $setProperties(
			argumentCollection = arguments,
			filterList = "properties,reload,transaction,callbacks",
			setOnModel = false
		);
		local.rv = $createInstance(callbacks = arguments.callbacks, persisted = false, properties = arguments.properties);
		local.rv.$setDefaultValues();
		return local.rv;
	}

	/**
	 * Saves the object if it passes validation and callbacks.
	 * Returns `true` if the object was saved successfully to the database, `false` if not.
	 *
	 * [section: Model Class]
	 * [category: CRUD Functions]
	 *
	 * @parameterize [see:findAll].
	 * @reload [see:findAll].
	 * @validate Set to `false` to skip validations for this operation.
	 * @transaction Set this to `commit` to update the database, `rollback` to run all the database queries but not commit them, or `none` to skip transaction handling altogether.
	 * @callbacks [see:findAll].
	 */
	public boolean function save(
		any parameterize,
		boolean reload,
		boolean validate = true,
		string transaction = $get("transactionMode"),
		boolean callbacks = true
	) {
		$args(name = "save", args = arguments);
		clearErrors();
		return invokeWithTransaction(argumentCollection = arguments, method = "$save");
	}

	/**
	 * Creates a new object instance.
	 * Called from the new function above.
	 * Also called from findByKey, findOne and findAll when returnAs is object(s).
	 */
	public any function $createInstance(
		required struct properties,
		required boolean persisted,
		numeric row = 1,
		boolean base = true,
		boolean callbacks = true
	) {
		local.fileName = $objectFileName(
			name = variables.wheels.class.modelName,
			objectPath = variables.wheels.class.path,
			type = "model"
		);
		local.rv = $createObjectFromRoot(
			base = arguments.base,
			fileName = local.fileName,
			path = variables.wheels.class.path,
			method = "$initModelObject",
			name = variables.wheels.class.modelName,
			persisted = arguments.persisted,
			properties = arguments.properties,
			row = arguments.row,
			useFilterLists = !arguments.persisted
		);

		/**
		 *	Wirebox adjustment for wirebox specific structs
		*/
		if (isStruct(local.rv) && StructKeyExists(local.rv, '$wbMixer')){
			structDelete(local.rv, '$wbMixer');
		}
		if (isStruct(local.rv) && StructKeyExists(local.rv, '$WBDELEGATEMAP')){
			structDelete(local.rv, '$WBDELEGATEMAP');
		}

		// If the object should be persisted, run afterFind callback, otherwise run afterNew callback.
		// Then proceed to afterInitialization callback unless the previous callback method returned false.
		local.afterFindResult = arguments.persisted && local.rv.$callback("afterFind", arguments.callbacks);
		local.afterNewResult = !arguments.persisted && local.rv.$callback("afterNew", arguments.callbacks);
		if (local.afterFindResult || local.afterNewResult) {
			local.rv.$callback("afterInitialization", arguments.callbacks);
		}

		return local.rv;
	}

	/**
	 * Creates a new record in the database or update it if it already exists.
	 * Also set associations and run all related callbacks.
	 * Called from the save function above (inside a transaction).
	 */
	public boolean function $save(
		required any parameterize,
		required boolean reload,
		required boolean validate,
		required boolean callbacks
	) {
		local.rv = false;

		// Make sure all of our associations are set properly before saving.
		$setAssociations();

		if ($callback("beforeValidation", arguments.callbacks)) {
			if (isNew()) {
				if (
					$callback("beforeValidationOnCreate", arguments.callbacks)
					&& $validate("onSave,onCreate", arguments.validate)
					&& $callback("afterValidation", arguments.callbacks)
					&& $callback("afterValidationOnCreate", arguments.callbacks)
					&& $callback("beforeSave", arguments.callbacks)
					&& $callback("beforeCreate", arguments.callbacks)
				) {
					local.rollback = false;
					if (!Len(key())) {
						local.rollback = true;
					}

					$create(parameterize = arguments.parameterize, reload = arguments.reload);
					if (
						$saveAssociations(argumentCollection = arguments)
						&& $callback("afterCreate", arguments.callbacks)
						&& $callback("afterSave", arguments.callbacks)
					) {
						$updatePersistedProperties();
						if (arguments.reload) {
							this.reload();
						}
						local.rv = true;
					} else if (local.rollback) {
						$resetToNew();
					}
				} else {
					$validateAssociations(callbacks = arguments.callbacks);
				}
			} else {
				if (
					$callback("beforeValidationOnUpdate", arguments.callbacks)
					&& $validate("onSave,onUpdate", arguments.validate)
					&& $callback("afterValidation", arguments.callbacks)
					&& $callback("afterValidationOnUpdate", arguments.callbacks)
					&& $callback("beforeSave", arguments.callbacks)
					&& $callback("beforeUpdate", arguments.callbacks)
				) {
					$update(parameterize = arguments.parameterize, reload = arguments.reload);
					if (
						$saveAssociations(argumentCollection = arguments)
						&& $callback("afterUpdate", arguments.callbacks)
						&& $callback("afterSave", arguments.callbacks)
					) {
						$updatePersistedProperties();
						if (arguments.reload) {
							this.reload();
						}
						local.rv = true;
					}
				} else {
					$validateAssociations(callbacks = arguments.callbacks);
				}
			}
		} else {
			$validateAssociations(callbacks = arguments.callbacks);
		}
		return local.rv;
	}

	/**
	 * Create an INSERT statement and run to create the record.
	 */
	public boolean function $create(required any parameterize, required boolean reload) {
		// Allow explicit assignment of the createdAt/updatedAt properties if allowExplicitTimestamps is true
		local.allowExplicitTimestamps = StructKeyExists(this, "allowExplicitTimestamps") && this.allowExplicitTimestamps;

		if (
			local.allowExplicitTimestamps
			&& StructKeyExists(this, $get("timeStampOnCreateProperty"))
			&& Len(this[$get("timeStampOnCreateProperty")])
		) {
			// leave createdat unmolested
		} else if (variables.wheels.class.timeStampingOnCreate) {
			$timestampProperty(property = variables.wheels.class.timeStampOnCreateProperty);
		}
		if (
			local.allowExplicitTimestamps
			&& StructKeyExists(this, $get("timeStampOnUpdateProperty"))
			&& Len(this[$get("timeStampOnUpdateProperty")])
		) {
			// leave updatedat unmolested
		} else if ($get("setUpdatedAtOnCreate") && variables.wheels.class.timeStampingOnUpdate) {
			$timestampProperty(property = variables.wheels.class.timeStampOnUpdateProperty);
		}

		local.pks = listToArray(primaryKeys());
		local.uuidBasedKeys = [];
		local.columnMeta = {};
		local.key = "";
		local.primaryKeyExplicitlySet = false; // Track if primary key was explicitly provided

		for (local.key in local.pks) {
			local.key = trim(local.key);
			local.columnMeta = this.columnDataForProperty(local.key);

			// Check if the primary key was explicitly set by the user
			if (structKeyExists(this, local.key) && len(this[local.key])) {
				local.primaryKeyExplicitlySet = true;
			}

			if ($isUUIDColumn(local.columnMeta)) {
				arrayAppend(local.uuidBasedKeys, local.key);
			}
		}

		for (local.key in local.uuidBasedKeys) {
			if (!structKeyExists(this, local.key) || isNull(this[local.key])) {
				local.newUUID = generateUUID();

				while (true) {
					local.exists = this.findOne(
						where = "#local.primaryKey# = '#local.newUUID#'"
					);

					if (!local.exists) {
						this[local.key] = local.newUUID;
						break;
					} else {
						local.newUUID = generateUUID();
					}
				}
			}
		}

		// Start by adding column names and values for the properties that exist on the object to two arrays.
		local.sql = [];
		local.sql2 = [];
		for (local.key in variables.wheels.class.properties) {
			// Only include this property if it has a value, or the column is not nullable and has no default set.
			if (
				StructKeyExists(this, local.key)
				&& (
					Len(this[local.key])
					|| (
						!variables.wheels.class.properties[local.key].nullable
						&& !Len(variables.wheels.class.properties[local.key].columndefault)
					)
				)
			) {
				ArrayAppend(local.sql, $quoteColumn(variables.wheels.class.properties[local.key].column));
				ArrayAppend(local.sql, ",");
				ArrayAppend(local.sql2, $buildQueryParamValues(local.key));
				ArrayAppend(local.sql2, ",");
			}
		}

		if (ArrayLen(local.sql)) {
			// Create wrapping SQL code and merge the second array that holds the values with the first one.
			ArrayPrepend(local.sql, "INSERT INTO #$quotedTableName()# (");
			ArrayPrepend(local.sql2, " VALUES (");
			ArrayDeleteAt(local.sql, ArrayLen(local.sql));
			ArrayDeleteAt(local.sql2, ArrayLen(local.sql2));
			ArrayAppend(local.sql, ")");
			ArrayAppend(local.sql2, ")");
			local.iEnd = ArrayLen(local.sql);
			for (local.i = 1; local.i <= local.iEnd; local.i++) {
				ArrayAppend(local.sql, local.sql2[local.i]);
			}

			// Map the primary keys down to the SQL columns.
			local.iEnd = ArrayLen(local.pks);
			for (local.i = 1; local.i <= local.iEnd; local.i++) {
				local.pks[local.i] = variables.wheels.class.properties[local.pks[local.i]].column;
			}
			local.pks = ArrayToList(local.pks);
		} else {
			// No properties were set on the object so we insert a record with only default values to the database.
			local.pks = primaryKey(0);
			ArrayAppend(
				local.sql,
				"INSERT INTO #$quotedTableName()#" & variables.wheels.class.adapter.$defaultValues($primaryKey = local.pks)
			);
		}

		// Run the insert sql statement and set the primary key value on the object (if one was returned from the database).
		local.inserted = variables.wheels.class.adapter.$querySetup(
			parameterize = arguments.parameterize,
			sql = local.sql,
			$primaryKey = local.pks
		);
		$clearRequestCache();
		local.generatedKey = variables.wheels.class.adapter.$generatedKey();
		if (StructKeyExists(local.inserted.result, local.generatedKey)) {
			if (StructKeyExists(server, "boxlang")) {
				if (!local.primaryKeyExplicitlySet) {
					this[primaryKeys(1)] = local.inserted.result[local.generatedKey];
				}
			} else {
				this[primaryKeys(1)] = local.inserted.result[local.generatedKey];
			}
		}

		return true;
	}

	/**
	 * Determines if a column is likely intended to store UUID value
	 */
	public boolean function $isUUIDColumn(required struct columnMeta) {
		return (
			listFindNoCase("uniqueidentifier,char,varchar,uuid,raw,text", arguments.columnMeta.dataType)
			&& (arguments.columnMeta.size == 36 || isNull(arguments.columnMeta.size))
		);
	}

}
