/**
 * Schema diff engine that compares model property definitions against the current
 * database schema and generates migration CFC files automatically.
 *
 * Limitations:
 * - Calculated properties (property(sql="...")) are excluded from the diff.
 * - Tableless models are skipped.
 */
component extends="wheels.migrator.Base" {

	/**
	 * Compares a single model's expected schema (from its property definitions) against
	 * the actual database columns and returns a struct describing the differences.
	 *
	 * @modelName The name of the model to diff (e.g. "User").
	 * @options Optional struct: renames (explicit hints), heuristicThreshold (0-1, default 0.7).
	 * @return Struct with keys: modelName, tableName, addColumns, removeColumns, changeColumns, renameColumns, suggestedRenames.
	 */
	public struct function diff(required string modelName, struct options = {}) {
		local.modelObj = model(arguments.modelName);
		local.tableName = local.modelObj.tableName();
		local.primaryKeyList = local.modelObj.primaryKeys();
		local.classData = local.modelObj.$classData();
		local.properties = local.classData.properties;
		local.calculatedProperties = local.classData.calculatedProperties;

		local.expectedColumns = {};
		for (local.propName in local.properties) {
			// Skip calculated properties
			if (StructKeyExists(local.calculatedProperties, local.propName)) {
				continue;
			}
			local.prop = local.properties[local.propName];
			local.expectedColumns[LCase(local.prop.column)] = {
				property: local.propName,
				column: local.prop.column,
				type: local.prop.type,
				dataType: local.prop.dataType,
				nullable: local.prop.nullable,
				size: StructKeyExists(local.prop, "size") ? local.prop.size : "",
				scale: StructKeyExists(local.prop, "scale") ? local.prop.scale : ""
			};
			if (StructKeyExists(local.prop, "columnDefault")) {
				local.expectedColumns[LCase(local.prop.column)]["default"] = local.prop.columnDefault;
			}
		}

		local.appKey = $appKey();
		local.dbColumns = $dbinfo(
			type = "columns",
			table = local.tableName,
			datasource = application[local.appKey].dataSourceName,
			username = application[local.appKey].dataSourceUserName,
			password = application[local.appKey].dataSourcePassword
		);

		local.actualColumns = {};
		local.iEnd = local.dbColumns.recordCount;
		for (local.i = 1; local.i <= local.iEnd; local.i++) {
			local.colName = LCase(local.dbColumns["column_name"][local.i]);
			local.typeName = Trim(SpanExcluding(local.dbColumns["type_name"][local.i], "("));
			local.actualColumns[local.colName] = {
				column: local.colName,
				typeName: local.typeName,
				size: local.dbColumns["column_size"][local.i],
				nullable: local.dbColumns["is_nullable"][local.i],
				isPrimaryKey: local.dbColumns["is_primarykey"][local.i],
				decimalDigits: local.dbColumns["decimal_digits"][local.i]
			};
		}

		local.addColumns = [];
		local.removeColumns = [];
		local.changeColumns = [];

		for (local.colName in local.expectedColumns) {
			if (!StructKeyExists(local.actualColumns, local.colName)) {
				local.expected = local.expectedColumns[local.colName];
				ArrayAppend(local.addColumns, {
					name: local.expected.column,
					type: $cfSqlTypeToMigrationType(local.expected.type),
					nullable: IsBoolean(local.expected.nullable) ? local.expected.nullable : true,
					"default": StructKeyExists(local.expected, "default") ? local.expected["default"] : ""
				});
			}
		}

		for (local.colName in local.actualColumns) {
			if (!StructKeyExists(local.expectedColumns, local.colName)) {
				local.actual = local.actualColumns[local.colName];
				// Don't suggest removing primary key columns
				if (IsBoolean(local.actual.isPrimaryKey) && local.actual.isPrimaryKey) {
					continue;
				}
				ArrayAppend(local.removeColumns, {
					name: local.colName
				});
			}
		}

		for (local.colName in local.expectedColumns) {
			if (StructKeyExists(local.actualColumns, local.colName)) {
				local.expected = local.expectedColumns[local.colName];
				local.actual = local.actualColumns[local.colName];

				if (ListFindNoCase(local.primaryKeyList, local.expected.property)) {
					continue;
				}

				local.expectedMigType = $cfSqlTypeToMigrationType(local.expected.type);
				local.actualMigType = $dbTypeToMigrationType(local.actual.typeName);

				if (local.expectedMigType != local.actualMigType && local.actualMigType != "unknown") {
					ArrayAppend(local.changeColumns, {
						name: local.colName,
						from: {type: local.actualMigType},
						to: {type: local.expectedMigType}
					});
				}
			}
		}

		// Build type lookups for RenameDetector
		local.addTypesMap = {};
		for (local.col in local.addColumns) {
			local.addTypesMap[local.col.name] = local.col.type;
		}
		local.removeTypesMap = {};
		for (local.col in local.removeColumns) {
			// Remove columns carry only name; look up migration type from actualColumns
			local.actual = local.actualColumns[LCase(local.col.name)];
			local.removeTypesMap[local.col.name] = $dbTypeToMigrationType(local.actual.typeName);
		}

		// Build hints struct from options
		local.hints = {};
		if (StructKeyExists(arguments.options, "renames")) {
			local.hints.renames = arguments.options.renames;
		}
		local.threshold = StructKeyExists(arguments.options, "heuristicThreshold")
			? arguments.options.heuristicThreshold
			: 0.7;

		// Delegate to RenameDetector
		local.detector = CreateObject("component", "wheels.migrator.RenameDetector");
		local.detection = local.detector.detect(
			addColumns = local.addColumns,
			removeColumns = local.removeColumns,
			addTypes = local.addTypesMap,
			removeTypes = local.removeTypesMap,
			hints = local.hints,
			threshold = local.threshold
		);

		return {
			modelName: arguments.modelName,
			tableName: local.tableName,
			addColumns: local.detection.remainingAdds,
			removeColumns: local.detection.remainingRemoves,
			changeColumns: local.changeColumns,
			renameColumns: local.detection.confirmedRenames,
			suggestedRenames: local.detection.suggestedRenames
		};
	}

	/**
	 * Iterates all models registered in the application, calls diff() on each,
	 * and returns combined results. Skips tableless models and models that fail to load.
	 *
	 * @options Optional struct: hints (per-model rename hints keyed by model name), heuristicThreshold (0-1, default 0.7).
	 * @return Struct keyed by model name, each value is the diff result for that model.
	 */
	public struct function diffAll(struct options = {}) {
		local.results = {};
		local.appKey = $appKey();

		local.perModelHints = StructKeyExists(arguments.options, "hints") ? arguments.options.hints : {};
		local.threshold = StructKeyExists(arguments.options, "heuristicThreshold")
			? arguments.options.heuristicThreshold
			: 0.7;

		// Validate the threshold up front: when it's out of range every per-model
		// diff() throws, and the catch below would swallow all of them — silently
		// reporting "no drift" instead of surfacing the configuration error.
		if (local.threshold < 0 || local.threshold > 1) {
			Throw(
				type = "Wheels.InvalidThreshold",
				message = "heuristicThreshold must be between 0 and 1, got " & local.threshold
			);
		}

		if (StructKeyExists(application[local.appKey], "models")) {
			for (local.modelName in application[local.appKey].models) {
				try {
					local.modelObj = model(local.modelName);

					local.tName = local.modelObj.tableName();
					if (IsBoolean(local.tName) && !local.tName) {
						continue;
					}

					// Build this model's options: {renames, heuristicThreshold}
					local.modelOptions = {heuristicThreshold: local.threshold};
					if (StructKeyExists(local.perModelHints, local.modelName)
						&& StructKeyExists(local.perModelHints[local.modelName], "renames")) {
						local.modelOptions.renames = local.perModelHints[local.modelName].renames;
					}

					local.diffResult = diff(local.modelName, local.modelOptions);

					if (
						ArrayLen(local.diffResult.addColumns)
						|| ArrayLen(local.diffResult.removeColumns)
						|| ArrayLen(local.diffResult.changeColumns)
						|| ArrayLen(local.diffResult.renameColumns)
						|| ArrayLen(local.diffResult.suggestedRenames)
					) {
						local.results[local.modelName] = local.diffResult;
					}
				} catch (any e) {
					// Skip models that fail to load (e.g. missing tables) — but
					// deliberate validation throws (bad rename hints, type-mismatch
					// hints, out-of-range thresholds) must surface to the caller
					// instead of silently dropping the model from the results.
					if (
						ListFindNoCase(
							"Wheels.InvalidThreshold,Wheels.InvalidRenameHint,Wheels.DuplicateRenameHint,Wheels.RenameHintTypeMismatch",
							e.type
						)
					) {
						rethrow;
					}
					continue;
				}
			}
		}

		return local.results;
	}

	/**
	 * Generates a migration CFC string with proper up() and down() methods
	 * using the Wheels migration DSL.
	 *
	 * @diffResult The diff struct returned by diff().
	 * @migrationName A human-readable name for the migration.
	 * @return The CFC file content as a string.
	 */
	public string function generateMigrationCFC(required struct diffResult, required string migrationName) {
		local.nl = Chr(10);
		local.tab = Chr(9);
		local.upBody = "";
		local.downBody = "";

		// Emit renameColumns first in up(); reversed renames go last in down()
		local.renameColumns = StructKeyExists(arguments.diffResult, "renameColumns")
			? arguments.diffResult.renameColumns
			: [];
		local.iEnd = ArrayLen(local.renameColumns);
		for (local.i = 1; local.i <= local.iEnd; local.i++) {
			local.r = local.renameColumns[local.i];
			local.upBody &= local.tab & local.tab
				& 'renameColumn(table="' & arguments.diffResult.tableName
				& '", columnName="' & local.r.from
				& '", newColumnName="' & local.r.to & '");' & local.nl;
		}

		local.iEnd = ArrayLen(arguments.diffResult.addColumns);
		for (local.i = 1; local.i <= local.iEnd; local.i++) {
			local.col = arguments.diffResult.addColumns[local.i];
			local.upBody &= local.tab & local.tab
				& 'addColumn(table="' & arguments.diffResult.tableName
				& '", columnType="' & local.col.type
				& '", columnName="' & local.col.name & '"'
				& ', allowNull=' & (IsBoolean(local.col.nullable) && local.col.nullable ? "true" : "false")
				& ');' & local.nl;
			local.downBody &= local.tab & local.tab
				& 'removeColumn(table="' & arguments.diffResult.tableName
				& '", columnName="' & local.col.name & '");' & local.nl;
		}

		local.iEnd = ArrayLen(arguments.diffResult.removeColumns);
		for (local.i = 1; local.i <= local.iEnd; local.i++) {
			local.col = arguments.diffResult.removeColumns[local.i];
			local.upBody &= local.tab & local.tab
				& 'removeColumn(table="' & arguments.diffResult.tableName
				& '", columnName="' & local.col.name & '");' & local.nl;
			local.downBody &= local.tab & local.tab
				& '// TODO: restore column "' & local.col.name & '" — original type unknown' & local.nl;
		}

		local.iEnd = ArrayLen(arguments.diffResult.changeColumns);
		for (local.i = 1; local.i <= local.iEnd; local.i++) {
			local.col = arguments.diffResult.changeColumns[local.i];
			local.upBody &= local.tab & local.tab
				& 'changeColumn(table="' & arguments.diffResult.tableName
				& '", columnName="' & local.col.name
				& '", columnType="' & local.col.to.type & '");' & local.nl;
			local.downBody &= local.tab & local.tab
				& 'changeColumn(table="' & arguments.diffResult.tableName
				& '", columnName="' & local.col.name
				& '", columnType="' & local.col.from.type & '");' & local.nl;
		}

		// Append reversed renames to down() (after other reversals)
		for (local.i = 1; local.i <= ArrayLen(local.renameColumns); local.i++) {
			local.r = local.renameColumns[local.i];
			local.downBody &= local.tab & local.tab
				& 'renameColumn(table="' & arguments.diffResult.tableName
				& '", columnName="' & local.r.to
				& '", newColumnName="' & local.r.from & '");' & local.nl;
		}

		if (!Len(Trim(local.upBody))) {
			local.upBody = local.tab & local.tab & '// No changes detected' & local.nl;
		}
		if (!Len(Trim(local.downBody))) {
			local.downBody = local.tab & local.tab & '// No changes to reverse' & local.nl;
		}

		local.content = 'component extends="wheels.migrator.Migration" hint="' & arguments.migrationName & '" {' & local.nl;
		local.content &= local.nl;
		local.content &= local.tab & 'public void function up() {' & local.nl;
		local.content &= local.upBody;
		local.content &= local.tab & '}' & local.nl;
		local.content &= local.nl;
		local.content &= local.tab & 'public void function down() {' & local.nl;
		local.content &= local.downBody;
		local.content &= local.tab & '}' & local.nl;
		local.content &= local.nl;
		local.content &= '}' & local.nl;

		return local.content;
	}

	/**
	 * Generates a timestamp-prefixed filename and writes the migration CFC
	 * to the app/migrator/migrations/ directory.
	 *
	 * @diffResult The diff struct returned by diff().
	 * @migrationName Optional human-readable name. Defaults to "auto_[modelName]_changes".
	 */
	public void function writeMigration(required struct diffResult, string migrationName = "") {
		if (!Len(arguments.migrationName)) {
			arguments.migrationName = "auto_" & LCase(arguments.diffResult.modelName) & "_changes";
		}

		local.content = generateMigrationCFC(arguments.diffResult, arguments.migrationName);

		// Use millisecond precision to reduce filename collision risk on rapid successive calls.
		local.now = Now();
		local.timestamp = DateFormat(local.now, "yyyymmdd") & TimeFormat(local.now, "HHmmssL");
		local.fileName = local.timestamp & "_" & $sanitizeFileName(arguments.migrationName) & ".cfc";

		local.migrationDir = ExpandPath("/app/migrator/migrations/");
		if (!DirectoryExists(local.migrationDir)) {
			DirectoryCreate(local.migrationDir);
		}

		$file(
			action = "write",
			file = local.migrationDir & local.fileName,
			output = local.content,
			addNewLine = false
		);
	}

	/**
	 * Sanitizes a string for use as a filename component.
	 * Lowercases, collapses non-alphanumeric chars to underscores, and trims edge underscores.
	 */
	public string function $sanitizeFileName(required string name) {
		local.safe = LCase(arguments.name);
		local.safe = ReReplace(local.safe, "[^a-z0-9_]+", "_", "all");
		local.safe = ReReplace(local.safe, "_+", "_", "all");
		local.safe = ReReplace(local.safe, "^_|_$", "", "all");
		return Len(local.safe) ? local.safe : "migration";
	}

	/**
	 * Maps cf_sql types (as stored in model properties) to Wheels migration column types.
	 */
	public string function $cfSqlTypeToMigrationType(required string cfSqlType) {
		switch (LCase(arguments.cfSqlType)) {
			case "cf_sql_integer":
			case "cf_sql_int":
				return "integer";
			case "cf_sql_varchar":
			case "cf_sql_char":
				return "string";
			case "cf_sql_longvarchar":
			case "cf_sql_clob":
				return "text";
			case "cf_sql_timestamp":
				return "datetime";
			case "cf_sql_date":
				return "date";
			case "cf_sql_time":
				return "time";
			case "cf_sql_bit":
			case "cf_sql_boolean":
				return "boolean";
			case "cf_sql_decimal":
			case "cf_sql_numeric":
			case "cf_sql_money":
				return "decimal";
			case "cf_sql_float":
			case "cf_sql_double":
			case "cf_sql_real":
				return "float";
			case "cf_sql_bigint":
				return "biginteger";
			case "cf_sql_binary":
			case "cf_sql_blob":
			case "cf_sql_varbinary":
				return "binary";
			case "cf_sql_smallint":
			case "cf_sql_tinyint":
				return "integer";
			default:
				return "string";
		}
	}

	/**
	 * Maps raw database type names (from cfdbinfo) to Wheels migration types.
	 * Used to compare the actual DB schema against the model's expected types.
	 */
	public string function $dbTypeToMigrationType(required string dbType) {
		switch (LCase(arguments.dbType)) {
			case "int":
			case "int4":
			case "integer":
			case "mediumint":
			case "smallint":
			case "tinyint":
				return "integer";
			case "bigint":
			case "int8":
			case "int64":
				return "biginteger";
			case "varchar":
			case "character varying":
			case "nvarchar":
			case "char":
			case "nchar":
				return "string";
			case "text":
			case "ntext":
			case "clob":
			case "character large object":
			case "mediumtext":
			case "longtext":
			case "tinytext":
				return "text";
			case "datetime":
			case "timestamp":
			case "timestamp without time zone":
			case "timestamp with time zone":
				return "datetime";
			case "date":
				return "date";
			case "time":
			case "time without time zone":
			case "time with time zone":
				return "time";
			case "bit":
			case "boolean":
			case "bool":
				return "boolean";
			case "decimal":
			case "numeric":
			case "money":
			case "smallmoney":
				return "decimal";
			case "float":
			case "float4":
			case "float8":
			case "double":
			case "double precision":
			case "real":
				return "float";
			case "binary":
			case "varbinary":
			case "image":
			case "blob":
			case "bytea":
			case "longblob":
			case "mediumblob":
			case "tinyblob":
				return "binary";
			case "uniqueidentifier":
				return "string";
			default:
				return "unknown";
		}
	}

}
