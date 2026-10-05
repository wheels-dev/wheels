<cfscript>

	/**
	 * Inserts multiple records into the database in a single batch operation.
	 * Accepts an array of structs where each struct represents a record to insert.
	 * All structs must have the same set of keys (property names).
	 * Batches in groups of up to 1000 rows, fewer where the database limits the parameters per
	 * statement (SQL Server). All batches run in one
	 * transaction (see `transaction`), so a failing batch rolls back the ones before it. No
	 * validations or callbacks run.
	 *
	 * [section: Model Class]
	 * [category: Create Functions]
	 *
	 * @records Array of structs, each containing property name/value pairs to insert.
	 * @timestamps Set to `false` to skip automatic `createdAt`/`updatedAt` timestamping.
	 * @transaction [see:save].
	 * @parameterize [see:findAll].
	 */
	public struct function insertAll(
		required array records,
		boolean timestamps = true,
		string transaction = $get("transactionMode"),
		any parameterize
	) {
		$args(name = "insertAll", args = arguments);

		if (!ArrayLen(arguments.records)) {
			return {insertedCount: 0};
		}

		$validateBulkRecordKeys(arguments.records);

		if (arguments.timestamps) {
			arguments.records = $addBulkTimestamps(records = arguments.records, isInsert = true);
		}

		local.state = {count = 0};
		local.batchArgs = {
			method = "$insertAllBatches",
			transaction = arguments.transaction,
			records = arguments.records,
			mapped = $mapBulkProperties(arguments.records),
			state = local.state
		};
		if (StructKeyExists(arguments, "parameterize")) {
			local.batchArgs.parameterize = arguments.parameterize;
		}
		// Every batch runs in one transaction (per `transaction`, like save()), so a failing batch
		// rolls back the ones before it.
		invokeWithTransaction(argumentCollection = local.batchArgs);

		$markMigrationDidWork();
		$clearRequestCache();
		return {insertedCount: local.state.count};
	}

	/**
	 * Internal function. Rows per bulk statement: 1000, or fewer when the statement would otherwise
	 * bind more parameters than the database accepts (one per column per row). SQL Server accepts
	 * about 2100, so a 5-column batch of 1000 rows used to throw Wheels.TooManyParameters there.
	 * A row wider than the limit still gets one row per statement, which the adapter then refuses
	 * with Wheels.TooManyParameters before running it. `limit` (default: the adapter's) is for specs.
	 */
	public numeric function $bulkBatchSize(required numeric columnCount, any parameterize = true, numeric limit = -1) {
		local.rv = 1000;
		local.limit = arguments.limit >= 0 ? arguments.limit : variables.wheels.class.adapter.$maxBoundParameters();
		if (local.limit > 0 && arguments.columnCount > 0 && !(IsBoolean(arguments.parameterize) && !arguments.parameterize)) {
			local.rv = Max(1, Min(local.rv, Int(local.limit / arguments.columnCount)));
		}
		return local.rv;
	}

	/**
	 * Internal function. Runs insertAll()'s INSERT statements, in batches of 1000 rows, inside the
	 * transaction invokeWithTransaction() opened. Adds the row count to `state.count`.
	 */
	public boolean function $insertAllBatches(required array records, required struct mapped, required struct state, any parameterize) {
		local.batchSize = $bulkBatchSize(columnCount = ArrayLen(arguments.mapped.columns), parameterize = StructKeyExists(arguments, "parameterize") ? arguments.parameterize : true);
		local.totalRecords = ArrayLen(arguments.records);
		for (local.batchStart = 1; local.batchStart <= local.totalRecords; local.batchStart += local.batchSize) {
			local.batchEnd = Min(local.batchStart + local.batchSize - 1, local.totalRecords);
			local.sql = variables.wheels.class.adapter.$bulkInsertSQL(
				tableName = $quotedTableName(),
				columns = arguments.mapped.columns,
				validProperties = arguments.mapped.validProperties,
				records = arguments.records,
				batchStart = local.batchStart,
				batchEnd = local.batchEnd,
				propertyInfo = variables.wheels.class.properties
			);
			// Nothing here reads the result or a generated key, so don't request one:
			// on Lucee that asks the driver for generated keys, and the Oracle driver
			// then appends a RETURNING clause Oracle rejects (#3653).
			variables.wheels.class.adapter.$querySetup(
				parameterize = arguments.parameterize,
				sql = local.sql,
				$captureResult = false
			);
			arguments.state.count += (local.batchEnd - local.batchStart + 1);
		}
		return true;
	}

	/**
	 * Inserts or updates multiple records in a single batch operation (upsert).
	 * Uses database-specific conflict resolution syntax (e.g., `ON CONFLICT ... DO UPDATE` for PostgreSQL/SQLite).
	 * The `uniqueBy` argument specifies which properties form the unique constraint for conflict detection.
	 *
	 * [section: Model Class]
	 * [category: Create Functions]
	 *
	 * @records Array of structs, each containing property name/value pairs.
	 * @uniqueBy Comma-delimited list of property names that form the unique constraint for conflict detection.
	 * @timestamps Set to `false` to skip automatic `createdAt`/`updatedAt` timestamping. An auto-stamped `createdAt` is only written when a row is inserted; an existing row keeps its original value (except on H2, whose `MERGE ... KEY` rewrites every column).
	 * @transaction [see:save].
	 * @parameterize [see:findAll].
	 */
	public struct function upsertAll(
		required array records,
		required string uniqueBy,
		boolean timestamps = true,
		string transaction = $get("transactionMode"),
		any parameterize
	) {
		$args(name = "upsertAll", args = arguments);

		if (!ArrayLen(arguments.records)) {
			return {upsertedCount: 0};
		}

		$validateBulkRecordKeys(arguments.records);

		// When the framework (not the caller) supplies the create timestamp, its column must stay out of
		// the conflict-update list below, otherwise an upsert that hits an existing row overwrites that
		// row's original createdAt with now. A createdAt the caller put in the records is written as given.
		local.excludeColumns = [];
		if (
			arguments.timestamps
			&& variables.wheels.class.timeStampingOnCreate
			&& !StructKeyExists(arguments.records[1], variables.wheels.class.timeStampOnCreateProperty)
		) {
			ArrayAppend(
				local.excludeColumns,
				variables.wheels.class.properties[variables.wheels.class.timeStampOnCreateProperty].column
			);
		}

		if (arguments.timestamps) {
			arguments.records = $addBulkTimestamps(records = arguments.records, isInsert = true);
		}

		local.mapped = $mapBulkProperties(arguments.records);

		// Map uniqueBy property names to column names.
		local.uniqueByList = ListToArray(arguments.uniqueBy);
		local.uniqueByColumns = [];
		for (local.uProp in local.uniqueByList) {
			local.uProp = Trim(local.uProp);
			if (!StructKeyExists(variables.wheels.class.properties, local.uProp)) {
				Throw(
					type = "Wheels.InvalidUniqueByProperty",
					message = "The uniqueBy property `#local.uProp#` is not a valid property of this model.",
					extendedInfo = "Valid properties are: #StructKeyList(variables.wheels.class.properties)#"
				);
			}
			ArrayAppend(local.uniqueByColumns, variables.wheels.class.properties[local.uProp].column);
		}

		// Update columns = all columns except the unique constraint columns and an auto-added createdAt.
		local.updateColumns = [];
		for (local.c = 1; local.c <= ArrayLen(local.mapped.columns); local.c++) {
			if (
				!ArrayFindNoCase(local.uniqueByColumns, local.mapped.columns[local.c])
				&& !ArrayFindNoCase(local.excludeColumns, local.mapped.columns[local.c])
			) {
				ArrayAppend(local.updateColumns, local.mapped.columns[local.c]);
			}
		}
		// Excluding createdAt must never leave the conflict clause empty (e.g. a model that stamps only
		// createdAt, upserting records that carry nothing but the uniqueBy columns): several adapters then
		// emit no update clause and a conflict raises a duplicate-key error. Keep the prior behaviour there.
		if (!ArrayLen(local.updateColumns) && ArrayLen(local.excludeColumns)) {
			local.updateColumns = local.excludeColumns;
		}

		local.state = {count = 0};
		local.batchArgs = {
			method = "$upsertAllBatches",
			transaction = arguments.transaction,
			records = arguments.records,
			mapped = local.mapped,
			uniqueByColumns = local.uniqueByColumns,
			updateColumns = local.updateColumns,
			state = local.state
		};
		if (StructKeyExists(arguments, "parameterize")) {
			local.batchArgs.parameterize = arguments.parameterize;
		}
		// Same as insertAll(): every batch runs in one transaction, per `transaction`.
		invokeWithTransaction(argumentCollection = local.batchArgs);

		$markMigrationDidWork();
		$clearRequestCache();
		return {upsertedCount: local.state.count};
	}

	/**
	 * Internal function. Runs upsertAll()'s statements, in batches of 1000 rows, inside the
	 * transaction invokeWithTransaction() opened. Adds the row count to `state.count`.
	 */
	public boolean function $upsertAllBatches(
		required array records,
		required struct mapped,
		required array uniqueByColumns,
		required array updateColumns,
		required struct state,
		any parameterize
	) {
		local.batchSize = $bulkBatchSize(columnCount = ArrayLen(arguments.mapped.columns), parameterize = StructKeyExists(arguments, "parameterize") ? arguments.parameterize : true);
		local.totalRecords = ArrayLen(arguments.records);
		for (local.batchStart = 1; local.batchStart <= local.totalRecords; local.batchStart += local.batchSize) {
			local.batchEnd = Min(local.batchStart + local.batchSize - 1, local.totalRecords);
			local.sql = variables.wheels.class.adapter.$upsertSQL(
				tableName = $quotedTableName(),
				columns = arguments.mapped.columns,
				uniqueBy = arguments.uniqueByColumns,
				updateColumns = arguments.updateColumns,
				validProperties = arguments.mapped.validProperties,
				records = arguments.records,
				batchStart = local.batchStart,
				batchEnd = local.batchEnd,
				propertyInfo = variables.wheels.class.properties
			);
			// Same as insertAll(): no result or generated key is read (#3653).
			variables.wheels.class.adapter.$querySetup(
				parameterize = arguments.parameterize,
				sql = local.sql,
				$captureResult = false
			);
			arguments.state.count += (local.batchEnd - local.batchStart + 1);
		}
		return true;
	}

	/**
	 * Validates that all records in a bulk array have the same set of keys.
	 */
	public void function $validateBulkRecordKeys(required array records) {
		local.referenceKeys = ListSort(StructKeyList(arguments.records[1]), "textnocase");
		local.iEnd = ArrayLen(arguments.records);
		for (local.i = 2; local.i <= local.iEnd; local.i++) {
			local.currentKeys = ListSort(StructKeyList(arguments.records[local.i]), "textnocase");
			if (local.currentKeys != local.referenceKeys) {
				Throw(
					type = "Wheels.InvalidRecordKeys",
					message = "All records must have the same set of keys.",
					extendedInfo = "Record 1 has keys [#local.referenceKeys#] but record #local.i# has keys [#local.currentKeys#]."
				);
			}
		}
	}

	/**
	 * Maps record property names to database column names, filtering out non-model properties.
	 * Returns a struct with `columns` and `validProperties` arrays.
	 */
	public struct function $mapBulkProperties(required array records) {
		local.propertyNames = ListToArray(ListSort(StructKeyList(arguments.records[1]), "textnocase"));
		local.columns = [];
		local.validProperties = [];
		for (local.prop in local.propertyNames) {
			if (StructKeyExists(variables.wheels.class.properties, local.prop)) {
				ArrayAppend(local.columns, variables.wheels.class.properties[local.prop].column);
				ArrayAppend(local.validProperties, local.prop);
			}
		}

		if (!ArrayLen(local.columns)) {
			Throw(
				type = "Wheels.InvalidProperties",
				message = "No valid properties found in the records.",
				extendedInfo = "The keys in the record structs must match model property names."
			);
		}

		return {columns: local.columns, validProperties: local.validProperties};
	}

	/**
	 * Adds `createdAt` and `updatedAt` timestamps to bulk record arrays when the model
	 * is configured for automatic timestamping.
	 */
	public array function $addBulkTimestamps(required array records, boolean isInsert = true) {
		local.now = $timestamp(variables.wheels.class.timeStampMode);

		if (arguments.isInsert && variables.wheels.class.timeStampingOnCreate) {
			local.createProp = variables.wheels.class.timeStampOnCreateProperty;
			for (local.i = 1; local.i <= ArrayLen(arguments.records); local.i++) {
				if (!StructKeyExists(arguments.records[local.i], local.createProp) || !Len(arguments.records[local.i][local.createProp])) {
					arguments.records[local.i][local.createProp] = local.now;
				}
			}
		}

		if (variables.wheels.class.timeStampingOnUpdate) {
			local.updateProp = variables.wheels.class.timeStampOnUpdateProperty;
			for (local.i = 1; local.i <= ArrayLen(arguments.records); local.i++) {
				if (!StructKeyExists(arguments.records[local.i], local.updateProp) || !Len(arguments.records[local.i][local.updateProp])) {
					arguments.records[local.i][local.updateProp] = local.now;
				}
			}
		}

		return arguments.records;
	}
</cfscript>
