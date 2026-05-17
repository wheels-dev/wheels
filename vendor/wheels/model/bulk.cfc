component {

	/**
	 * Inserts multiple records into the database in a single batch operation.
	 * Accepts an array of structs where each struct represents a record to insert.
	 * All structs must have the same set of keys (property names).
	 * Batches in groups of 1000 to avoid database parameter limits.
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

		local.mapped = $mapBulkProperties(arguments.records);

		// Batch in groups of 1000 rows.
		local.batchSize = 1000;
		local.totalInserted = 0;
		local.totalRecords = ArrayLen(arguments.records);

		for (local.batchStart = 1; local.batchStart <= local.totalRecords; local.batchStart += local.batchSize) {
			local.batchEnd = Min(local.batchStart + local.batchSize - 1, local.totalRecords);

			local.sql = variables.wheels.class.adapter.$bulkInsertSQL(
				tableName = $quotedTableName(),
				columns = local.mapped.columns,
				validProperties = local.mapped.validProperties,
				records = arguments.records,
				batchStart = local.batchStart,
				batchEnd = local.batchEnd,
				propertyInfo = variables.wheels.class.properties
			);

			variables.wheels.class.adapter.$querySetup(
				parameterize = arguments.parameterize,
				sql = local.sql
			);

			local.totalInserted += (local.batchEnd - local.batchStart + 1);
		}

		$clearRequestCache();
		return {insertedCount: local.totalInserted};
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
	 * @timestamps Set to `false` to skip automatic `createdAt`/`updatedAt` timestamping.
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

		// Update columns = all columns except the unique constraint columns.
		local.updateColumns = [];
		for (local.c = 1; local.c <= ArrayLen(local.mapped.columns); local.c++) {
			if (!ArrayFindNoCase(local.uniqueByColumns, local.mapped.columns[local.c])) {
				ArrayAppend(local.updateColumns, local.mapped.columns[local.c]);
			}
		}

		// Batch in groups of 1000 rows.
		local.batchSize = 1000;
		local.totalUpserted = 0;
		local.totalRecords = ArrayLen(arguments.records);

		for (local.batchStart = 1; local.batchStart <= local.totalRecords; local.batchStart += local.batchSize) {
			local.batchEnd = Min(local.batchStart + local.batchSize - 1, local.totalRecords);

			local.sql = variables.wheels.class.adapter.$upsertSQL(
				tableName = $quotedTableName(),
				columns = local.mapped.columns,
				uniqueBy = local.uniqueByColumns,
				updateColumns = local.updateColumns,
				validProperties = local.mapped.validProperties,
				records = arguments.records,
				batchStart = local.batchStart,
				batchEnd = local.batchEnd,
				propertyInfo = variables.wheels.class.properties
			);

			variables.wheels.class.adapter.$querySetup(
				parameterize = arguments.parameterize,
				sql = local.sql
			);

			local.totalUpserted += (local.batchEnd - local.batchStart + 1);
		}

		$clearRequestCache();
		return {upsertedCount: local.totalUpserted};
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

}
