component extends="wheels.databaseAdapters.Base" output=false {

	/**
	 * H2 reports unquoted identifiers in uppercase, so lowercase auto-derived
	 * property names — otherwise models expose `FIRSTNAME` instead of
	 * `firstname`. See Base.$lowerCaseColumnNames().
	 */
	public boolean function $lowerCaseColumnNames() {
		return true;
	}

	/**
	 * The case this H2 datasource folds unquoted identifiers to: `upper` (H2's
	 * default), `lower` (`DATABASE_TO_LOWER=TRUE`) or `none` (case folding
	 * disabled with `DATABASE_TO_UPPER=FALSE`, no datasource, or an unreadable
	 * settings table). Probed once per datasource per application lifetime and
	 * cached in the application's Wheels settings beside `schemaColumnCache`, so
	 * a tenant datasource gets its own value, a reload re-probes, and the probe
	 * never runs per identifier. A failed probe degrades to `none`, which is the
	 * unquoted SQL H2 received before #4440.
	 */
	public string function $identifierCase() {
		if (!StructKeyExists(variables, "dataSource") || !Len(variables.dataSource)) {
			// A bare adapter (unit tests) has no datasource: leave identifiers alone.
			return "none";
		}
		local.dataSource = $effectiveDataSource();
		local.appKey = $appKey();
		try {
			if (
				StructKeyExists(application, local.appKey)
				&& StructKeyExists(application[local.appKey], "h2IdentifierCase")
				&& StructKeyExists(application[local.appKey].h2IdentifierCase, local.dataSource)
			) {
				return application[local.appKey].h2IdentifierCase[local.dataSource];
			}
		} catch (any e) {
			// fall through to a fresh probe
		}
		local.identifierCase = $readIdentifierCase(dataSource = local.dataSource);
		try {
			if (StructKeyExists(application, local.appKey)) {
				lock name="wheels.h2IdentifierCase" type="exclusive" timeout="10" {
					if (!StructKeyExists(application[local.appKey], "h2IdentifierCase")) {
						application[local.appKey].h2IdentifierCase = {};
					}
					application[local.appKey].h2IdentifierCase[local.dataSource] = local.identifierCase;
				}
			}
		} catch (any e) {
			// Caching is best-effort; the probed value is still correct for this call.
		}
		return local.identifierCase;
	}

	/**
	 * Internal function. Reads H2's identifier folding settings. H2 2.x exposes
	 * `SETTING_NAME` / `SETTING_VALUE`; H2 1.3.x exposes `NAME` / `VALUE`, and
	 * has no `DATABASE_TO_LOWER` row at all. `NON_KEYWORDS` is read for the log
	 * line only — it never changes the classification.
	 */
	public string function $readIdentifierCase(required string dataSource) {
		local.options = {datasource = arguments.dataSource};
		if (StructKeyExists(variables, "username") && Len(variables.username)) {
			local.options.username = variables.username;
		}
		if (StructKeyExists(variables, "password") && Len(variables.password)) {
			local.options.password = variables.password;
		}

		local.settings = {};
		local.rows = "";
		try {
			local.rows = QueryExecute(
				"SELECT SETTING_NAME, SETTING_VALUE FROM INFORMATION_SCHEMA.SETTINGS WHERE SETTING_NAME IN ('DATABASE_TO_UPPER', 'DATABASE_TO_LOWER', 'NON_KEYWORDS')",
				[],
				local.options
			);
		} catch (any e) {
			try {
				local.rows = QueryExecute(
					"SELECT NAME, VALUE FROM INFORMATION_SCHEMA.SETTINGS WHERE NAME IN ('DATABASE_TO_UPPER', 'DATABASE_TO_LOWER', 'NON_KEYWORDS')",
					[],
					local.options
				);
			} catch (any e2) {
				writeLog(
					type = "warning",
					file = "wheels_h2_identifier_case",
					text = "Could not read identifier folding settings for H2 datasource `#arguments.dataSource#`; identifiers will not be quoted. #e2.message#"
				);
				return "none";
			}
		}

		local.nameColumn = ListFindNoCase(local.rows.columnList, "SETTING_NAME") ? "SETTING_NAME" : "NAME";
		local.valueColumn = ListFindNoCase(local.rows.columnList, "SETTING_VALUE") ? "SETTING_VALUE" : "VALUE";
		for (local.i = 1; local.i <= local.rows.recordCount; local.i++) {
			local.settings[UCase(Trim(local.rows[local.nameColumn][local.i]))] = UCase(Trim(local.rows[local.valueColumn][local.i]));
		}

		if (!StructKeyExists(local.settings, "DATABASE_TO_LOWER")) {
			// H2 1.3.x: no DATABASE_TO_LOWER setting, and quoted identifiers there are
			// case-insensitive, so the default upper folding is always safe.
			local.identifierCase = "upper";
		} else if (local.settings.DATABASE_TO_LOWER == "TRUE") {
			local.identifierCase = "lower";
		} else if (StructKeyExists(local.settings, "DATABASE_TO_UPPER") && local.settings.DATABASE_TO_UPPER == "FALSE") {
			local.identifierCase = "none";
		} else {
			local.identifierCase = "upper";
		}

		local.nonKeywords = StructKeyExists(local.settings, "NON_KEYWORDS") ? local.settings.NON_KEYWORDS : "";
		writeLog(
			type = "information",
			file = "wheels_h2_identifier_case",
			text = "H2 datasource `#arguments.dataSource#` folds identifiers to #local.identifierCase#; NON_KEYWORDS=#local.nonKeywords#"
		);
		return local.identifierCase;
	}

	/**
	 * Quote a table or column name when H2 folds it, so reserved words such as
	 * `order` and `group` are usable. The name is quoted in the datasource's own
	 * fold case and embedded double quotes are doubled. With folding off the name
	 * is returned unchanged — byte-for-byte the unquoted SQL H2 got before #4440,
	 * which also keeps duplicate-by-case schemas (only possible with folding off)
	 * unambiguous. Aliases are never quoted: table aliases stay bare and the
	 * select-list aliases read back by $lowerCaseColumnNames() are unchanged.
	 */
	public string function $quoteIdentifier(required string name) {
		local.identifierCase = $identifierCase();
		if (local.identifierCase == "none") {
			return arguments.name;
		}
		local.folded = (local.identifierCase == "upper") ? UCase(arguments.name) : LCase(arguments.name);
		return """" & Replace(local.folded, """", """""", "all") & """";
	}

	/**
	 * H2 1.3.172 (the driver Lucee bundles) returns rows in the wrong order once
	 * LIMIT + OFFSET exceeds the 32-bit maximum (#3684), and the query builder's
	 * offset() without limit() passes exactly that maximum as "no limit" (#3665).
	 * Clamp the limit so the sum stays at 2147483647: still effectively
	 * unlimited, and correct on H2 1.3.172 and 2.x alike. There is no
	 * version-independent sentinel: 1.3.172 has no OFFSET-only form, and H2 2.x
	 * rejects LIMIT -1 and LIMIT NULL.
	 */
	public string function $limitOffsetClause(required numeric limit, required numeric offset) {
		local.maxInt = 2147483647;
		local.limit = arguments.limit;
		if (arguments.offset > 0 && arguments.offset < local.maxInt && local.limit + arguments.offset > local.maxInt) {
			// NumberFormat keeps a large computed value out of scientific notation.
			local.limit = NumberFormat(local.maxInt - arguments.offset, "0");
		}
		return super.$limitOffsetClause(limit = local.limit, offset = arguments.offset);
	}

	variables.h2TypeMap = {
		"bigint": "cf_sql_bigint",
		"int8": "cf_sql_bigint",
		"binary": "cf_sql_binary",
		"bytea": "cf_sql_binary",
		"raw": "cf_sql_binary",
		"binary varying": "cf_sql_binary",
		"bit": "cf_sql_bit",
		"bool": "cf_sql_bit",
		"boolean": "cf_sql_bit",
		"binary large object": "cf_sql_blob",
		"blob": "cf_sql_blob",
		"tinyblob": "cf_sql_blob",
		"mediumblob": "cf_sql_blob",
		"longblob": "cf_sql_blob",
		"image": "cf_sql_blob",
		"oid": "cf_sql_blob",
		"char": "cf_sql_char",
		"character": "cf_sql_char",
		"nchar": "cf_sql_char",
		"uuid": "cf_sql_char",
		"date": "cf_sql_date",
		"dec": "cf_sql_decimal",
		"decimal": "cf_sql_decimal",
		"number": "cf_sql_decimal",
		"numeric": "cf_sql_decimal",
		"double": "cf_sql_double",
		"double precision": "cf_sql_double",
		"float": "cf_sql_float",
		"float4": "cf_sql_float",
		"float8": "cf_sql_float",
		"real": "cf_sql_float",
		"int": "cf_sql_integer",
		"int4": "cf_sql_integer",
		"integer": "cf_sql_integer",
		"mediumint": "cf_sql_integer",
		"signed": "cf_sql_integer",
		"identity": "cf_sql_integer",
		"int2": "cf_sql_smallint",
		"smallint": "cf_sql_smallint",
		"year": "cf_sql_smallint",
		"time": "cf_sql_time",
		"datetime": "cf_sql_timestamp",
		"smalldatetime": "cf_sql_timestamp",
		"timestamp": "cf_sql_timestamp",
		"tinyint": "cf_sql_tinyint",
		"varbinary": "cf_sql_varbinary",
		"longvarbinary": "cf_sql_varbinary",
		"varchar": "cf_sql_varchar",
		"varchar2": "cf_sql_varchar",
		"longvarchar": "cf_sql_varchar",
		"varchar_ignorecase": "cf_sql_varchar",
		"nvarchar": "cf_sql_varchar",
		"nvarchar2": "cf_sql_varchar",
		"clob": "cf_sql_varchar",
		"nclob": "cf_sql_varchar",
		"text": "cf_sql_varchar",
		"tinytext": "cf_sql_varchar",
		"mediumtext": "cf_sql_varchar",
		"longtext": "cf_sql_varchar",
		"ntext": "cf_sql_varchar",
		"enum": "cf_sql_varchar",
		"character varying": "cf_sql_varchar",
		"character large object": "cf_sql_varchar",
		"nvarchar_casesensitive": "cf_sql_nvarchar",
		"json": "cf_sql_longvarchar"
	};

	/**
	 * Map database types to the ones used in CFML.
	 */
	public string function $getType(required string type, string scale, string details) {
		local.key = LCase(arguments.type);
		if (StructKeyExists(variables.h2TypeMap, local.key)) {
			return variables.h2TypeMap[local.key];
		}
		$throwUnknownColumnType(arguments.type);
	}

	/**
	 * Call functions to make adapter specific changes to arguments before executing query.
	 */
	public struct function $querySetup(
		required array sql,
		numeric limit = 0,
		numeric offset = 0,
		required boolean parameterize,
		string $primaryKey = ""
	) {
		$convertMaxRowsToLimit(args = arguments);
		$removeColumnAliasesInOrderClause(args = arguments);
		$addColumnsToSelectAndGroupBy(args = arguments);
		$moveAggregateToHaving(args = arguments);
		return $performQuery(argumentCollection = arguments);
	}

	/**
	 * H2 does not support advisory locks.
	 */
	public void function $acquireAdvisoryLock(required string name, numeric timeout = 10) {
		Throw(
			type = "Wheels.AdvisoryLockNotSupported",
			message = "H2 does not support advisory locks.",
			extendedInfo = "Advisory locks are not available in H2. Consider using a different database for features that require advisory locking."
		);
	}

	/**
	 * H2 does not support advisory locks.
	 */
	public void function $releaseAdvisoryLock(required string name) {
		Throw(
			type = "Wheels.AdvisoryLockNotSupported",
			message = "H2 does not support advisory locks.",
			extendedInfo = "Advisory locks are not available in H2."
		);
	}

	/**
	 * Override Base adapter's function.
	 * When using H2, cfdbinfo incorrectly returns information_schema tables.
	 * To fix we create a new query result that excludes these tables.
	 * Yes, it should actually be "table_schem" below, not a typo.
	 */
	public query function $getColumns() {
		local.columns = super.$getColumns(argumentCollection = arguments);
		local.rv = QueryNew(local.columns.columnList);
		local.iEnd = local.columns.recordCount;
		for (local.i = 1; local.i <= local.iEnd; local.i++) {
			if (local.columns["table_schem"][local.i] != "information_schema") {
				QueryAddRow(local.rv);
				local.jEnd = ListLen(local.columns.columnList);
				for (local.j = 1; local.j <= local.jEnd; local.j++) {
					local.item = ListGetAt(local.columns.columnList, local.j);
					QuerySetCell(local.rv, local.item, local.columns[local.item][local.i]);
				}
			}
		}
		return local.rv;
	}

	/**
	 * Override Base adapter's function.
	 * When using H2, cfdbinfo does not return the primarykey flag
	 * We need to check the indexes and look for an index with a name starting with primary_key
	 */
	public query function $getColumnInfo(
		required string table,
		required string datasource,
		required string username,
		required string password
	) {
		arguments.type = "index";
		local.index = $dbinfo(argumentCollection = arguments);
		local.pkList = "";
		for (local.row in local.index) {
			if (Find('primary_key', local.row.INDEX_NAME)) {
				local.pkList = ListAppend(local.pkList, local.row.COLUMN_NAME);
			}
		}
		arguments.type = "columns";
		local.columns = $dbinfo(argumentCollection = arguments);
		for (local.i = 1; local.i <= local.columns.recordCount; local.i++) {
			if (ListFind(local.pkList, local.columns["COLUMN_NAME"][local.i])) {
				QuerySetCell(local.columns, "IS_PRIMARYKEY", "YES", local.i);
			}
		}

		return local.columns;
	}

	/**
	 * H2 upsert using single MERGE INTO with multi-row VALUES.
	 * H2 syntax: MERGE INTO t (cols) KEY (uniqueBy) VALUES (row1), (row2), ...
	 */
	public array function $upsertSQL(
		required string tableName,
		required array columns,
		required array uniqueBy,
		required array updateColumns,
		required array validProperties,
		required array records,
		required numeric batchStart,
		required numeric batchEnd,
		required struct propertyInfo
	) {
		local.sql = [];

		// Build column list.
		local.colList = "";
		for (local.col in arguments.columns) {
			if (Len(local.colList)) local.colList &= ", ";
			local.colList &= $quoteIdentifier(local.col);
		}

		// Build KEY clause.
		local.keyList = "";
		for (local.u in arguments.uniqueBy) {
			if (Len(local.keyList)) local.keyList &= ", ";
			local.keyList &= $quoteIdentifier(local.u);
		}

		ArrayAppend(local.sql, "MERGE INTO #arguments.tableName# (#local.colList#) KEY (#local.keyList#) VALUES ");

		// Build value rows.
		for (local.r = arguments.batchStart; local.r <= arguments.batchEnd; local.r++) {
			if (local.r > arguments.batchStart) {
				ArrayAppend(local.sql, ", ");
			}
			ArrayAppend(local.sql, "(");
			for (local.p = 1; local.p <= ArrayLen(arguments.validProperties); local.p++) {
				if (local.p > 1) ArrayAppend(local.sql, ", ");
				local.propName = arguments.validProperties[local.p];
				local.val = StructKeyExists(arguments.records[local.r], local.propName) ? arguments.records[local.r][local.propName] : "";
				ArrayAppend(local.sql, $buildBulkParam(value=local.val, propName=local.propName, propertyInfo=arguments.propertyInfo));
			}
			ArrayAppend(local.sql, ")");
		}

		return local.sql;
	}

}
