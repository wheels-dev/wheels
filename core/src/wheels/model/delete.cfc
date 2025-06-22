component {
	/**
	 * Deletes all records that match the `where` argument.
	 * By default, objects will not be instantiated and therefore callbacks and validations are not invoked.
	 * You can change this behavior by passing in `instantiate=true`.
	 * Returns the number of records that were deleted.
	 *
	 * [section: Model Class]
	 * [category: Delete Functions]
	 *
	 * @where [see:findAll].
	 * @include [see:findAll].
	 * @reload [see:findAll].
	 * @parameterize [see:findAll].
	 * @instantiate [see:updateAll].
	 * @useIndex [see:findAll].
	 * @transaction [see:save].
	 * @callbacks [see:findAll].
	 * @includeSoftDeletes [see:findAll].
	 * @softDelete Set to `false` to permanently delete a record, even if it has a soft delete column.
	 */
	public numeric function deleteAll(
		string where = "",
		string include = "",
		boolean reload,
		any parameterize,
		boolean instantiate,
		struct useIndex = {},
		string transaction = application.wheels.transactionMode,
		boolean callbacks = true,
		boolean includeSoftDeletes = false,
		boolean softDelete = true
	) {
		$args(name = "deleteAll", args = arguments);
		arguments.include = $listClean(arguments.include);
		arguments.where = $cleanInList(arguments.where);
		if (arguments.instantiate) {
			local.rv = 0;
			local.objects = findAll(
				include = arguments.include,
				includeSoftDeletes = arguments.includeSoftDeletes,
				parameterize = arguments.parameterize,
				reload = arguments.reload,
				returnAs = "objects",
				useIndex = arguments.useIndex,
				returnIncluded = false,
				where = arguments.where
			);
			local.iEnd = ArrayLen(local.objects);
			for (local.i = 1; local.i <= local.iEnd; local.i++) {
				local.deleted = local.objects[local.i].delete(
					callbacks = arguments.callbacks,
					parameterize = arguments.parameterize,
					softDelete = arguments.softDelete,
					transaction = arguments.transaction
				);
				if (local.deleted) {
					local.rv++;
				}
			}
		} else {
			arguments.sql = [];
			arguments.sql = $addDeleteClause(sql = arguments.sql, softDelete = arguments.softDelete, useIndex = arguments.useIndex);
			local.indexHint = this.$indexHint(
				useIndex = arguments.useIndex,
				modelName = variables.wheels.class.modelName,
				adapterName = get("adapterName")
			);
			if (Len(local.indexHint) && !(variables.wheels.class.softDeletion && arguments.softDelete)) {
				ArrayAppend(arguments.sql, local.indexHint);
			}
			arguments.sql = $addWhereClause(
				sql = arguments.sql,
				where = arguments.where,
				include = arguments.include,
				includeSoftDeletes = arguments.includeSoftDeletes,
				softDelete = arguments.softDelete,
				useIndex = arguments.useIndex
			);
			arguments.sql = $addWhereClauseParameters(sql = arguments.sql, where = arguments.where);
			local.rv = invokeWithTransaction(method = "$deleteAll", argumentCollection = arguments);
		}
		return local.rv;
	}

	/**
	 * Finds the record with the supplied key and deletes it.
	 * Returns `true` on successful deletion of the row, `false` otherwise.
	 *
	 * [section: Model Class]
	 * [category: Delete Functions]
	 *
	 * @key Primary key value(s) of the record to fetch. Separate with comma if passing in multiple primary key values. Accepts a string, list, or a numeric value.
	 * @reload [see:findAll].
	 * @transaction [see:save].
	 * @callbacks [see:findAll].
	 * @includeSoftDeletes [see:findAll].
	 * @softDelete [see:deleteAll].
	 */
	public boolean function deleteByKey(
		required any key,
		boolean reload,
		string transaction = application.wheels.transactionMode,
		boolean callbacks = true,
		boolean includeSoftDeletes = false,
		boolean softDelete = true
	) {
		$args(name = "deleteByKey", args = arguments);
		$keyLengthCheck(arguments.key);
		local.where = $keyWhereString(values = arguments.key);
		return deleteOne(
			callbacks = arguments.callbacks,
			includeSoftDeletes = arguments.includeSoftDeletes,
			reload = arguments.reload,
			softDelete = arguments.softDelete,
			transaction = arguments.transaction,
			where = local.where
		);
	}

	/**
	 * Gets an object based on conditions and deletes it.
	 *
	 * [section: Model Class]
	 * [category: Delete Functions]
	 *
	 * @where [see:findAll].
	 * @order [see:findAll].
	 * @reload [see:findAll].
	 * @transaction [see:save].
	 * @callbacks [see:findAll].
	 * @includeSoftDeletes [see:findAll].
	 * @useIndex [see:findAll].
	 * @softDelete [see:deleteAll].
	 */
	public boolean function deleteOne(
		string where = "",
		string order = "",
		boolean reload,
		string transaction = application.wheels.transactionMode,
		boolean callbacks = true,
		boolean includeSoftDeletes = false,
		struct useIndex = {},
		boolean softDelete = true
	) {
		$args(name = "deleteOne", args = arguments);
		local.object = findOne(
			includeSoftDeletes = arguments.includeSoftDeletes,
			order = arguments.order,
			reload = arguments.reload,
			useIndex = arguments.useIndex,
			where = arguments.where
		);
		if (IsObject(local.object)) {
			local.rv = local.object.delete(
				callbacks = arguments.callbacks,
				softDelete = arguments.softDelete,
				transaction = arguments.transaction
			);
		} else {
			local.rv = false;
		}
		return local.rv;
	}

	/**
	 * Deletes the object, which means the row is deleted from the database (unless prevented by a `beforeDelete` callback).
	 * Returns `true` on successful deletion of the row, `false` otherwise.
	 *
	 * [section: Model Object]
	 * [category: CRUD Functions]
	 *
	 * @parameterize [see:findAll].
	 * @transaction [see:save].
	 * @callbacks [see:findAll].
	 * @includeSoftDeletes [see:findAll].
	 * @softDelete [see:deleteAll].
	 */
	public boolean function delete(
		any parameterize,
		string transaction = application.wheels.transactionMode,
		boolean callbacks = true,
		boolean includeSoftDeletes = false,
		boolean softDelete = true
	) {
		$args(name = "delete", args = arguments);
		arguments.sql = [];
		arguments.sql = $addDeleteClause(sql = arguments.sql, softDelete = arguments.softDelete);
		arguments.sql = $addKeyWhereClause(sql = arguments.sql, includeSoftDeletes = arguments.includeSoftDeletes);
		return invokeWithTransaction(method = "$delete", argumentCollection = arguments);
	}

	/**
	 * Deletes all records and return how many was deleted.
	 * The only reason this is in its own method is so we can wrap it in an "invokeWithTransaction" call.
	 */
	public numeric function $deleteAll() {
		local.deleted = variables.wheels.class.adapter.$querySetup(sql = arguments.sql, parameterize = arguments.parameterize);
		$clearRequestCache();
		return local.deleted.result.recordCount;
	}

	/**
	 * Run delete callbacks, delete dependent child records and delete the record itself.
	 * Return true if delete was successful (one record was deleted) and neither of the callbacks returned false.
	 * The only reason this is in its own method is so we can wrap it in an "invokeWithTransaction" call.
	 */
	public boolean function $delete() {
		local.rv = false;
		if ($callback("beforeDelete", arguments.callbacks)) {
			// Delete dependent record(s).
			// Done before the main record is deleted to make sure eventual foreign key constraints does not prevent deletion.
			$deleteDependents();

			local.deleted = variables.wheels.class.adapter.$querySetup(
				sql = arguments.sql,
				parameterize = arguments.parameterize
			);
			$clearRequestCache();
			if (local.deleted.result.recordCount == 1 && $callback("afterDelete", arguments.callbacks)) {
				local.rv = true;
			}
		}
		return local.rv;
	}
}
