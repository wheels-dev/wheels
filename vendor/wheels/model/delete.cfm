<cfscript>
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
		// A permanent delete is a real DELETE: it reaches rows that are already soft-deleted too.
		if (!arguments.softDelete) {
			arguments.includeSoftDeletes = true;
		}
		arguments.include = $listClean(arguments.include);
		arguments.where = $cleanInList(arguments.where);
		// A comparison between two numbers (1 = 0, 1 = 1) goes into the SQL unbound.
		arguments.where = $passThroughLiteralPredicates(arguments.where);
		if (arguments.instantiate) {
			local.rv = 0;
			local.objects = findAll(
				callbacks = arguments.callbacks,
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
		// A permanent delete is a real DELETE: it reaches rows that are already soft-deleted too.
		if (!arguments.softDelete) {
			arguments.includeSoftDeletes = true;
		}
		$keyLengthCheck(arguments.key);
		local.where = $keyWhereWithScope(key = arguments.key, where = StructKeyExists(arguments, "where") ? arguments.where : "");
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
		// A permanent delete is a real DELETE: it reaches rows that are already soft-deleted too.
		if (!arguments.softDelete) {
			arguments.includeSoftDeletes = true;
		}
		local.object = findOne(
			callbacks = arguments.callbacks,
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
		if (variables.wheels.class.softDeletion && arguments.softDelete) {
			// Already soft-deleted (as loaded, not as edited in memory): there is nothing to do, and
			// stamping deletedAt again would lose when it was first deleted.
			if (Len($persistedSoftDeleteValue())) {
				return false;
			}
		} else if (!arguments.softDelete) {
			// A permanent delete is a real DELETE, so dependents that are already soft-deleted go too.
			// A default delete of a model without a soft-delete column still soft-deletes its
			// soft-delete dependents, and leaves the ones already soft-deleted as they are.
			arguments.includeSoftDeletes = true;
		}
		arguments.sql = [];
		arguments.sql = $addDeleteClause(sql = arguments.sql, softDelete = arguments.softDelete);
		arguments.sql = $addKeyWhereClause(sql = arguments.sql, includeSoftDeletes = arguments.includeSoftDeletes);
		if (variables.wheels.class.softDeletion && arguments.softDelete) {
			// Only a row that isn't soft-deleted yet, so a stale copy of a row soft-deleted elsewhere
			// changes nothing. Keep the timestamp being written for the object to hold afterwards.
			ArrayAppend(arguments.sql, " AND " & $quoteColumn(variables.wheels.class.softDeleteColumn) & " IS NULL");
			arguments.$softDeletedAt = arguments.sql[2].value;
			arguments.$softDeleteBefore = $softDeleteState();
		}
		return invokeWithTransaction(method = "$delete", argumentCollection = arguments);
	}

	/**
	 * Deletes all records and return how many was deleted.
	 * The only reason this is in its own method is so we can wrap it in an "invokeWithTransaction" call.
	 */
	public numeric function $deleteAll() {
		local.deleted = variables.wheels.class.adapter.$querySetup(sql = arguments.sql, parameterize = arguments.parameterize);
		$markMigrationDidWork();
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
		// A soft delete that doesn't complete (afterDelete returns false, or a dependent throws) puts
		// back the object's deletedAt, so a retry isn't refused as "already deleted". Catch-free, so
		// it also runs when the request aborts on BoxLang.
		try {
			local.rv = $deleteRecordAndDependents(argumentCollection = arguments);
		} finally {
			if (!local.rv && StructKeyExists(arguments, "$softDeleteBefore")) {
				$restoreSoftDeleteState(arguments.$softDeleteBefore);
			}
		}
		return local.rv;
	}

	/**
	 * Internal function. The body of `$delete()`: callbacks, dependents and the statement itself.
	 */
	public boolean function $deleteRecordAndDependents() {
		local.rv = false;
		if ($callback("beforeDelete", arguments.callbacks)) {
			if (StructKeyExists(arguments, "$softDeletedAt")) {
				// A soft delete keeps the row, so no foreign key needs the dependents handled first:
				// mark this row, then soft-delete its dependents only if this call is what did it.
				local.recordCount = $runDeleteStatement(sql = arguments.sql, parameterize = arguments.parameterize);
				if (local.recordCount == 1) {
					$markSoftDeleted(arguments.$softDeletedAt);
					$deleteDependents(
						softDelete = true,
						includeSoftDeletes = arguments.includeSoftDeletes,
						callbacks = arguments.callbacks,
						parentSoftDeleted = true
					);
				}
			} else {
				// Delete dependent record(s) before the record itself so foreign key constraints don't
				// prevent the deletion.
				$deleteDependents(
					softDelete = arguments.softDelete,
					includeSoftDeletes = arguments.includeSoftDeletes,
					callbacks = arguments.callbacks
				);
				local.recordCount = $runDeleteStatement(sql = arguments.sql, parameterize = arguments.parameterize);
			}
			if (local.recordCount == 1 && $callback("afterDelete", arguments.callbacks)) {
				local.rv = true;
				// v4.2.0: queue afterCommit/afterRollback (fires at the outermost
				// transaction resolve, or immediately in none/false mode).
				if (StructKeyExists(arguments, "$softDeleteBefore")) {
					// A rollback of the surrounding transaction puts deletedAt back too.
					$enqueueTransactionCallbacks(operation = "delete", callbacks = arguments.callbacks, softDeleteBefore = arguments.$softDeleteBefore);
				} else {
					$enqueueTransactionCallbacks(operation = "delete", callbacks = arguments.callbacks);
				}
			}
		}
		return local.rv;
	}

	/**
	 * Internal function. The soft-delete column's value as last loaded or saved, ignoring an unsaved
	 * in-memory edit; "" when the object doesn't hold the column.
	 */
	public string function $persistedSoftDeleteValue() {
		local.column = variables.wheels.class.softDeleteColumn;
		if (hasChanged(local.column)) {
			return changedFrom(local.column);
		}
		if (StructKeyExists(this, local.column) && IsSimpleValue(this[local.column])) {
			return this[local.column];
		}
		return "";
	}

	/**
	 * Internal function. The object's soft-delete column, in memory and as last persisted, for
	 * `$restoreSoftDeleteState()`.
	 */
	public struct function $softDeleteState() {
		local.column = variables.wheels.class.softDeleteColumn;
		local.rv = {
			hasValue = StructKeyExists(this, local.column),
			hasPersisted = StructKeyExists(variables, "$persistedProperties") && StructKeyExists(variables.$persistedProperties, local.column)
		};
		if (local.rv.hasValue) {
			local.rv.value = this[local.column];
		}
		if (local.rv.hasPersisted) {
			local.rv.persisted = variables.$persistedProperties[local.column];
		}
		return local.rv;
	}

	/**
	 * Internal function. Puts the soft-delete column back as `$softDeleteState()` captured it.
	 */
	public void function $restoreSoftDeleteState(required struct state) {
		local.column = variables.wheels.class.softDeleteColumn;
		if (arguments.state.hasValue) {
			this[local.column] = arguments.state.value;
		} else {
			StructDelete(this, local.column);
		}
		if (StructKeyExists(variables, "$persistedProperties")) {
			if (arguments.state.hasPersisted) {
				variables.$persistedProperties[local.column] = arguments.state.persisted;
			} else {
				StructDelete(variables.$persistedProperties, local.column);
			}
		}
	}

	/**
	 * Internal function. Records a soft delete on the object: the column holds the timestamp written and
	 * counts as saved. Only this column's baseline changes; every other property keeps its own.
	 */
	public void function $markSoftDeleted(required any value) {
		local.column = variables.wheels.class.softDeleteColumn;
		this[local.column] = arguments.value;
		if (!StructKeyExists(variables, "$persistedProperties")) {
			variables.$persistedProperties = {};
		}
		variables.$persistedProperties[local.column] = arguments.value;
	}

	/**
	 * Internal function. Runs an object's DELETE (or soft-delete UPDATE) statement and returns how many
	 * rows it changed.
	 */
	public numeric function $runDeleteStatement(required array sql, any parameterize) {
		local.deleted = variables.wheels.class.adapter.$querySetup(sql = arguments.sql, parameterize = arguments.parameterize);
		$markMigrationDidWork();
		$clearRequestCache();
		return local.deleted.result.recordCount;
	}
</cfscript>
