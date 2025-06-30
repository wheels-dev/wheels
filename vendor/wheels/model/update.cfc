component {
	/**
	 * Updates all properties for the records that match the `where` argument.
	 * Property names and values can be passed in either using named arguments or as a struct to the `properties` argument.
	 * By default, objects will not be instantiated and therefore callbacks and validations are not invoked.
	 * You can change this behavior by passing in `instantiate=true`.
	 * This method returns the number of records that were updated.
	 *
	 * [section: Model Class]
	 * [category: Update Functions]
	 *
	 * @where [see:findAll].
	 * @include [see:findAll].
	 * @properties The properties you want to set on the object (can also be passed in as named arguments).
	 * @reload [see:findAll].
	 * @parameterize [see:findAll].
	 * @instantiate Whether or not to instantiate the object(s) first. When objects are not instantiated, any callbacks and validations set on them will be skipped.
	 * @useIndex [see:findAll].
	 * @validate [see:save].
	 * @transaction [see:save].
	 * @callbacks [see:findAll].
	 * @includeSoftDeletes [see:findAll].
	 */
	public numeric function updateAll(
		string where = "",
		string include = "",
		struct properties = {},
		boolean reload,
		any parameterize,
		boolean instantiate,
		struct useIndex = {},
		boolean validate = "true",
		string transaction = "#application.wheels.transactionMode#",
		boolean callbacks = "true",
		boolean includeSoftDeletes = "false"
	) {
		$args(name = "updateAll", args = arguments);
		arguments.include = $listClean(arguments.include);
		arguments.where = $cleanInList(arguments.where);
		arguments.properties = $setProperties(
			argumentCollection = arguments,
			filterList = "where,include,properties,reload,parameterize,instantiate,useIndex,validate,transaction,callbacks,includeSoftDeletes",
			setOnModel = false
		);

		if (arguments.instantiate) {
			// Find and instantiate each object and call its update function.
			local.rv = 0;
			local.objects = findAll(
				where = arguments.where,
				include = arguments.include,
				reload = arguments.reload,
				parameterize = arguments.parameterize,
				callbacks = arguments.callbacks,
				includeSoftDeletes = arguments.includeSoftDeletes,
				returnIncluded = false,
				returnAs = "objects",
				useIndex = arguments.useIndex
			);
			local.iEnd = ArrayLen(local.objects);
			for (local.i = 1; local.i <= local.iEnd; local.i++) {
				if (
					local.objects[local.i].update(
						properties = arguments.properties,
						parameterize = arguments.parameterize,
						transaction = arguments.transaction,
						callbacks = arguments.callbacks
					)
				) {
					local.rv++;
				}
			}
		} else {
			arguments.sql = [];
			// Issue#1273: Added this section to allow included tables to be referenced in the query
			local.migration = CreateObject("component", "wheels.migrator.Migration").init();
			local.indexHint = this.$indexHint(
				useIndex = arguments.useIndex,
				modelName = variables.wheels.class.modelName,
				adapterName = get("adapterName")
			);
			
			if (ListFind('MySQL', local.migration.adapter.adapterName())){
				local.list = "";
				local.associations = [];
				local.associations = $expandedAssociations(
					include = arguments.include,
					includeSoftDeletes = arguments.includeSoftDeletes
				);
				local.iEnd = ArrayLen(local.associations);
				for (local.i = 1; local.i <= local.iEnd; local.i++) {
					local.list &= local.associations[local.i].join;
				}
				if (Len(local.indexHint)) {
					ArrayAppend(arguments.sql, "UPDATE #tableName()# #local.indexHint# #local.list# SET");
				} else {
					ArrayAppend(arguments.sql, "UPDATE #tableName()# #local.list# SET");
				}
				
			}
			else if (ListFind('MicrosoftSQLServer', local.migration.adapter.adapterName())){
				if (Len(local.indexHint)) {
					ArrayAppend(arguments.sql, "UPDATE #tableName()# #local.indexHint# SET");
				} else {
					ArrayAppend(arguments.sql, "UPDATE #tableName()# SET");
				}
			}
			else if (ListFind('PostgreSQL,H2,Oracle', local.migration.adapter.adapterName())){
				ArrayAppend(arguments.sql, "UPDATE #tableName()# SET");
			}
			local.pos = 0;
			for (local.key in arguments.properties) {
				local.pos++;
				ArrayAppend(arguments.sql, "#variables.wheels.class.properties[local.key].column# = ");
				local.param = {
					value = arguments.properties[local.key],
					type = variables.wheels.class.properties[local.key].type,
					dataType = variables.wheels.class.properties[local.key].dataType,
					scale = variables.wheels.class.properties[local.key].scale,
					null = !Len(arguments.properties[local.key])
				};
				ArrayAppend(arguments.sql, local.param);
				if (StructCount(arguments.properties) > local.pos) {
					ArrayAppend(arguments.sql, ",");
				}
			}
			arguments.sql = $addWhereClause(
				sql = arguments.sql,
				where = arguments.where,
				include = arguments.include,
				includeSoftDeletes = arguments.includeSoftDeletes
			);
			arguments.sql = $addWhereClauseParameters(sql = arguments.sql, where = arguments.where);
			if (ListFind('H2', local.migration.adapter.adapterName()) && arguments.include != ""){
				arrayAppend(arguments.sql, ")");
			}
			local.rv = invokeWithTransaction(method = "$updateAll", argumentCollection = arguments);
		}
		return local.rv;
	}

	/**
	 * Finds the object with the supplied `key` and saves it (if validation permits it) with the supplied `properties` and / or named arguments.
	 * Property names and values can be passed in either using named arguments or as a struct to the `properties` argument.
	 * Returns `true` if the object was found and updated successfully, `false` otherwise.
	 *
	 * [section: Model Class]
	 * [category: Update Functions]
	 *
	 * @key Primary key value(s) of the record to fetch. Separate with comma if passing in multiple primary key values. Accepts a string, list, or a numeric value.
	 * @properties The properties you want to set on the object (can also be passed in as named arguments).
	 * @reload [see:findAll].
	 * @validate [see:save].
	 * @transaction [see:save].
	 * @callbacks [see:findAll].
	 * @includeSoftDeletes [see:findAll].
	 */
	public boolean function updateByKey(
		required any key,
		struct properties = {},
		boolean reload,
		boolean validate = "true",
		string transaction = "#application.wheels.transactionMode#",
		boolean callbacks = "true",
		boolean includeSoftDeletes = "false"
	) {
		$args(name = "updateByKey", args = arguments);
		$keyLengthCheck(arguments.key);
		arguments.where = $keyWhereString(values = arguments.key);
		StructDelete(arguments, "key");
		return updateOne(argumentCollection = arguments);
	}


	/**
	 * Gets an object based on the arguments used and updates it with the supplied `properties`.
	 * Returns `true` if an object was found and updated successfully, `false` otherwise.
	 *
	 * [section: Model Class]
	 * [category: Update Functions]
	 *
	 * @where [see:findAll].
	 * @order [see:findAll].
	 * @properties The properties you want to set on the object (can also be passed in as named arguments).
	 * @reload [see:findAll].
	 * @validate [see:save].
	 * @useIndex [see:findAll].
	 * @transaction [see:save].
	 * @callbacks [see:findAll].
	 * @includeSoftDeletesYou can set this argument to true to include soft-deleted records in the results.
	 */
	public boolean function updateOne(
		string where = "",
		string order = "",
		struct properties = {},
		boolean reload,
		boolean validate = "true",
		struct useIndex = {},
		string transaction = "#application.wheels.transactionMode#",
		boolean callbacks = "true",
		boolean includeSoftDeletes = "false"
	) {
		$args(name = "updateOne", args = arguments);
		local.object = findOne(
			includeSoftDeletes = arguments.includeSoftDeletes,
			order = arguments.order,
			reload = arguments.reload,
			useIndex = arguments.useIndex,
			where = arguments.where
		);
		StructDelete(arguments, "where");
		StructDelete(arguments, "order");
		if (IsObject(local.object)) {
			return local.object.update(argumentCollection = arguments);
		} else {
			return false;
		}
	}

	/**
	 * Updates the object with the supplied `properties` and saves it to the database.
	 * Returns `true` if the object was saved successfully to the database and `false` otherwise.
	 *
	 * [section: Model Object]
	 * [category: CRUD Functions]
	 *
	 * @properties The properties you want to set on the object (can also be passed in as named arguments).
	 * @parameterize [see:findAll].
	 * @reload [see:findAll].
	 * @validate [see:save].
	 * @transaction [see:save].
	 * @callbacks [see:findAll].
	 * @allowExplicitTimestamps Set this to `true` to allow explicit assignment of `createdAt` or `updatedAt` properties
	 */
	public boolean function update(
		struct properties = {},
		any parameterize,
		boolean reload,
		boolean validate = true,
		string transaction = "#application.wheels.transactionMode#",
		boolean callbacks = true,
		boolean allowExplicitTimestamps = false
	) {
		$args(name = "update", args = arguments);
		$setProperties(
			argumentCollection = arguments,
			filterList = "properties,parameterize,reload,validate,transaction,callbacks,allowExplicitTimestamps"
		);
		return save(
			callbacks = arguments.callbacks,
			parameterize = arguments.parameterize,
			reload = arguments.reload,
			transaction = arguments.transaction,
			validate = arguments.validate,
			allowExplicitTimestamps = arguments.allowExplicitTimestamps
		);
	}

	/**
	 * Updates a single `property` and saves the record without going through the normal validation procedure.
	 * This is especially useful for boolean flags on existing records.
	 *
	 * [section: Model Object]
	 * [category: CRUD Functions]
	 *
	 * @property Name of the property to update the value for globally.
	 * @value Value to set on the given property globally.
	 * @parameterize [see:findAll].
	 * @transaction [see:save].
	 * @callbacks [see:findAll].
	 */
	public boolean function updateProperty(
		string property,
		any value,
		any parameterize,
		string transaction = "#application.wheels.transactionMode#",
		boolean callbacks = "true"
	) {
		$args(name = "updateProperty", args = arguments);
		arguments.reload = false;
		arguments.validate = false;
		if (StructKeyExists(arguments, "property") && StructKeyExists(arguments, "value")) {
			arguments.properties = {};
			arguments.properties[arguments.property] = arguments.value;
			StructDelete(arguments, "property");
			StructDelete(arguments, "value");
		}
		return update(argumentCollection = arguments);
	}

	/**
	 * Internal function.
	 **/
	public numeric function $updateAll() {
		local.updated = variables.wheels.class.adapter.$querySetup(parameterize = arguments.parameterize, sql = arguments.sql);
		$clearRequestCache();
		return local.updated.result.recordCount;
	}

	/**
	 * Internal function.
	 **/
	public boolean function $update(required any parameterize, required boolean reload) {
		// Perform update if changes have been made.
		if (hasChanged()) {
			// Allow explicit assignment of the createdAt/updatedAt properties if allowExplicitTimestamps is true
			local.allowExplicitTimestamps = StructKeyExists(this, "allowExplicitTimestamps") && this.allowExplicitTimestamps;
			if (
				local.allowExplicitTimestamps
				&& StructKeyExists(this, $get("timeStampOnUpdateProperty"))
				&& Len(this[$get("timeStampOnUpdateProperty")])
			) {
				// leave updatedAt unmolested
			} else if ($get("setUpdatedAtOnCreate") && variables.wheels.class.timeStampingOnUpdate) {
				$timestampProperty(property = variables.wheels.class.timeStampOnUpdateProperty);
			}
			local.sql = [];
			ArrayAppend(local.sql, "UPDATE #tableName()# SET ");

			// Include all changed non-key values in the update.
			for (local.key in variables.wheels.class.properties) {
				if (StructKeyExists(this, local.key) && !ListFindNoCase(primaryKeys(), local.key) && hasChanged(local.key)) {
					ArrayAppend(local.sql, "#variables.wheels.class.properties[local.key].column# = ");
					local.param = $buildQueryParamValues(local.key);
					ArrayAppend(local.sql, local.param);
					ArrayAppend(local.sql, ",");
				}
			}

			// Submit the update if we generated an SQL SET statement.
			if (ArrayLen(local.sql) > 1) {
				ArrayDeleteAt(local.sql, ArrayLen(local.sql));
				local.sql = $addKeyWhereClause(sql = local.sql);
				variables.wheels.class.adapter.$querySetup(sql = local.sql, parameterize = arguments.parameterize);
				$clearRequestCache();
				if (arguments.reload) {
					this.reload();
				}
			}
		}

		return true;
	}
}
