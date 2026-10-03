component extends="wheels.databaseAdapters.Base" output=false {

	/**
	 * Internal function. This database converts a high-precision decimal sent as text exactly,
	 * in an insert and in a comparison (#4172).
	 */
	public string function $wideDecimalBindType() {
		return "cf_sql_varchar";
	}

	/**
	 * Internal function. SQL Server converts a text value to the column's DECIMAL type, rounding
	 * it to the column's scale, so a high-precision decimal also binds inside an exact cast (#4172).
	 */
	public struct function $wideDecimalCastLimits() {
		return {precision = 38, scale = 38};
	}

	/**
	 * Internal function. Splits IN lists that would exceed the parameter limit into one parameter
	 * each (#4103), then casts high-precision decimal params exactly (#4172), before running the query.
	 */
	public struct function $performQuery(
		required array sql,
		required boolean parameterize,
		numeric limit = 0,
		numeric offset = 0,
		string dataSource = variables.dataSource,
		string $primaryKey = "",
		string $debugName = "query",
		boolean $captureResult = true
	) {
		$splitLargeInLists(args = arguments);
		$castWideDecimalParams(args = arguments);
		return super.$performQuery(argumentCollection = arguments);
	}

	/**
	 * Internal function. When a statement would bind more parameters than SQL Server accepts,
	 * rewrites IN lists, largest first until it fits, to one parameter each (#4103):
	 * `(SELECT CAST(value AS <type>) FROM STRING_SPLIT(?, NCHAR(31)))`. A statement that fits keeps
	 * its SQL. STRING_SPLIT needs compatibility level 130; below it, and for lists of other types
	 * (dates and times among them), the statement is left for $assertBoundParameterCount() to refuse.
	 */
	public void function $splitLargeInLists(required struct args) {
		local.limit = $inListSplitLimit();
		if (!arguments.args.parameterize || $boundParameterCount(arguments.args.sql) <= local.limit) {
			return;
		}
		if (!$supportsStringSplit(arguments.args.dataSource)) {
			return;
		}
		local.convert = $inListsToSplit(sql = arguments.args.sql, limit = local.limit);
		local.rv = [];
		local.iEnd = ArrayLen(arguments.args.sql);
		for (local.i = 1; local.i <= local.iEnd; local.i++) {
			// Adobe CF passes arrays by value, so the parts are returned and appended here.
			if (StructKeyExists(local.convert, local.i)) {
				local.parts = $stringSplitParts(arguments.args.sql[local.i]);
			} else {
				local.parts = [arguments.args.sql[local.i]];
			}
			for (local.item in local.parts) {
				ArrayAppend(local.rv, local.item);
			}
		}
		arguments.args.sql = local.rv;
	}

	/**
	 * Internal function. The positions of the IN lists to split, largest first, until the statement
	 * binds no more than `limit` parameters (as a struct keyed by position).
	 */
	public struct function $inListsToSplit(required array sql, required numeric limit) {
		local.sizes = {};
		local.iEnd = ArrayLen(arguments.sql);
		for (local.i = 1; local.i <= local.iEnd; local.i++) {
			local.split = $stringSplitList(arguments.sql[local.i]);
			if (!StructIsEmpty(local.split) && ArrayLen(local.split.values) > 1) {
				local.sizes[local.i] = ArrayLen(local.split.values);
			}
		}
		local.count = $boundParameterCount(arguments.sql);
		local.rv = {};
		while (local.count > arguments.limit && !StructIsEmpty(local.sizes)) {
			local.largest = "";
			for (local.key in local.sizes) {
				if (!Len(local.largest) || local.sizes[local.key] > local.sizes[local.largest]) {
					local.largest = local.key;
				}
			}
			local.rv[local.largest] = true;
			local.count -= local.sizes[local.largest] - 1;
			StructDelete(local.sizes, local.largest);
		}
		return local.rv;
	}

	/**
	 * Internal function. The SQL parts for an IN list bound as one STRING_SPLIT parameter.
	 */
	public array function $stringSplitParts(required struct part) {
		local.split = $stringSplitList(arguments.part);
		return [
			"(SELECT " & local.split.expression & " FROM STRING_SPLIT(",
			{type = "cf_sql_nvarchar", value = ArrayToList(local.split.values, Chr(31))},
			", NCHAR(31)))"
		];
	}

	/**
	 * Internal function. For an IN list STRING_SPLIT can carry, its values and the expression that
	 * turns each split value back into the list's type: integers and decimals are validated here
	 * and CAST (never TRY_CAST, which turns '' into 0), strings are compared as they are. An empty
	 * struct for any other list, including dates and times, or one with a value that doesn't
	 * validate.
	 */
	public struct function $stringSplitList(required any part) {
		if (
			!IsStruct(arguments.part)
			|| !StructKeyExists(arguments.part, "list")
			|| !arguments.part.list
			|| !StructKeyExists(arguments.part, "value")
			|| !StructKeyExists(arguments.part, "type")
		) {
			return {};
		}
		local.values = ListToArray($queryParams(arguments.part).value, Chr(7));
		local.integerType = $stringSplitIntegerType(arguments.part.type);
		if (Len(local.integerType)) {
			return $stringSplitNumbers(values = local.values, pattern = "^-?[0-9]+$", sqlType = local.integerType);
		}
		if (ListFindNoCase("cf_sql_decimal,cf_sql_numeric", arguments.part.type)) {
			return $stringSplitDecimals(local.values);
		}
		if (ListFindNoCase("cf_sql_varchar,cf_sql_char", arguments.part.type)) {
			return $stringSplitStrings(local.values);
		}
		return {};
	}

	/**
	 * Internal function. The SQL Server type an integer IN list is cast to, or "" for other types.
	 */
	public string function $stringSplitIntegerType(required string sqlType) {
		local.types = {cf_sql_tinyint = "TINYINT", cf_sql_smallint = "SMALLINT", cf_sql_integer = "INT", cf_sql_bigint = "BIGINT"};
		return StructKeyExists(local.types, arguments.sqlType) ? local.types[arguments.sqlType] : "";
	}

	/**
	 * Internal function. Trimmed values cast to `sqlType`, when every value matches `pattern`.
	 */
	public struct function $stringSplitNumbers(required array values, required string pattern, required string sqlType) {
		local.rv = [];
		for (local.value in arguments.values) {
			local.value = Trim(local.value);
			if (!ReFind(arguments.pattern, local.value)) {
				return {};
			}
			ArrayAppend(local.rv, local.value);
		}
		return {expression = "CAST(value AS #arguments.sqlType#)", values = local.rv};
	}

	/**
	 * Internal function. Plain decimal values cast exactly to DECIMAL(38, s), `s` being the most
	 * fraction digits of any value; empty when a value isn't a plain decimal or doesn't fit 38 digits.
	 */
	public struct function $stringSplitDecimals(required array values) {
		local.scale = 0;
		local.integerDigits = 0;
		for (local.value in arguments.values) {
			local.value = Trim(local.value);
			if (!ReFind("^-?[0-9]+(\.[0-9]+)?$", local.value)) {
				return {};
			}
			local.scale = Max(local.scale, $fractionDigitCount(local.value));
			local.integerDigits = Max(local.integerDigits, $integerDigitCount(local.value));
		}
		if (local.integerDigits + local.scale > 38) {
			return {};
		}
		return $stringSplitNumbers(
			values = arguments.values,
			pattern = "^-?[0-9]+(\.[0-9]+)?$",
			sqlType = "DECIMAL(38, #local.scale#)"
		);
	}

	/**
	 * Internal function. String values, compared as they are. A value holding the NCHAR(31)
	 * delimiter can't be split, so it is refused with a clear error.
	 */
	public struct function $stringSplitStrings(required array values) {
		for (local.value in arguments.values) {
			if (Find(Chr(31), local.value)) {
				Throw(
					type = "Wheels.QueryParamValue",
					message = "An IN list value contains the control character Chr(31), which Wheels uses to bind long IN lists on SQL Server.",
					extendedInfo = "Remove the character from the value, or query the values in batches of fewer than #$maxBoundParameters()#."
				);
			}
		}
		return {expression = "value", values = arguments.values};
	}

	/**
	 * Internal function. The parameter count above which IN lists are split: the database limit,
	 * or a lower value set by $setInListSplitLimit() (used by the specs to exercise the split path).
	 */
	public numeric function $inListSplitLimit() {
		if (StructKeyExists(variables, "inListSplitLimit") && variables.inListSplitLimit > 0) {
			return variables.inListSplitLimit;
		}
		return $maxBoundParameters();
	}

	/**
	 * Internal function. Sets the split limit; 0 restores the database limit.
	 */
	public void function $setInListSplitLimit(required numeric limit) {
		variables.inListSplitLimit = arguments.limit;
	}

	/**
	 * Internal function. True when the datasource's database has compatibility level 130 or higher,
	 * which STRING_SPLIT needs. Read once per datasource and kept in the application's Wheels
	 * settings, so an application reload reads it again.
	 */
	public boolean function $supportsStringSplit(required string dataSource) {
		local.appKey = $appKey();
		local.dataSource = $effectiveDataSource(arguments.dataSource);
		if (!StructKeyExists(application[local.appKey], "sqlServerCompatibilityLevels")) {
			application[local.appKey].sqlServerCompatibilityLevels = {};
		}
		local.levels = application[local.appKey].sqlServerCompatibilityLevels;
		if (!StructKeyExists(local.levels, local.dataSource)) {
			local.levels[local.dataSource] = $readCompatibilityLevel(local.dataSource);
		}
		return local.levels[local.dataSource] >= 130;
	}

	/**
	 * Internal function. The database's compatibility level, or 0 when it can't be read.
	 */
	public numeric function $readCompatibilityLevel(required string dataSource) {
		local.options = {datasource = arguments.dataSource};
		if (Len(variables.username)) {
			local.options.username = variables.username;
		}
		if (Len(variables.password)) {
			local.options.password = variables.password;
		}
		try {
			local.query = QueryExecute("SELECT compatibility_level AS lvl FROM sys.databases WHERE name = DB_NAME()", [], local.options);
			return local.query.recordCount ? Val(local.query.lvl) : 0;
		} catch (any e) {
			return 0;
		}
	}

	/**
	 * SQL Server accepts at most 2100 parameters in one request, and the JDBC drivers use some of them
	 * themselves: mssql-jdbc (Lucee, BoxLang) runs 2098 bound values and fails at 2099, Adobe's
	 * driver runs 2097 and fails at 2098. 2097 is the highest count that runs on every engine (#3906).
	 */
	public numeric function $maxBoundParameters() {
		return 2097;
	}

	/**
	 * SQL Server's TINYINT is unsigned, 0 to 255 (#4087).
	 */
	public struct function $integerKeyRange(required string sqlType) {
		if (arguments.sqlType == "cf_sql_tinyint") {
			return {min = "0", max = "255"};
		}
		return super.$integerKeyRange(argumentCollection = arguments);
	}

	variables.mssqlTypeMap = {
		"bigint": "cf_sql_bigint",
		"binary": "cf_sql_binary",
		"geography": "cf_sql_binary",
		"geometry": "cf_sql_binary",
		"timestamp": "cf_sql_binary",
		"bit": "cf_sql_bit",
		"char": "cf_sql_char",
		"nchar": "cf_sql_char",
		"uniqueidentifier": "cf_sql_char",
		"date": "cf_sql_date",
		"datetime": "cf_sql_timestamp",
		"datetime2": "cf_sql_timestamp",
		"smalldatetime": "cf_sql_timestamp",
		"datetimeoffset": "cf_sql_timestamp",
		"decimal": "cf_sql_decimal",
		"money": "cf_sql_decimal",
		"smallmoney": "cf_sql_decimal",
		"float": "cf_sql_float",
		"int": "cf_sql_integer",
		"image": "cf_sql_longvarbinary",
		"text": "cf_sql_longvarchar",
		"ntext": "cf_sql_longvarchar",
		"xml": "cf_sql_longvarchar",
		"numeric": "cf_sql_numeric",
		"real": "cf_sql_real",
		"smallint": "cf_sql_smallint",
		"time": "cf_sql_time",
		"tinyint": "cf_sql_tinyint",
		"varbinary": "cf_sql_varbinary",
		"varchar": "cf_sql_varchar",
		"nvarchar": "cf_sql_varchar",
		"hierarchyid": "cf_sql_varchar",
		"cursor": "cf_sql_refcursor"
	};

	/**
	 * Map database types to the ones used in CFML.
	 */
	public string function $getType(required string type, string scale, string details) {
		local.key = LCase(arguments.type);
		if (StructKeyExists(variables.mssqlTypeMap, local.key)) {
			return variables.mssqlTypeMap[local.key];
		}
		$throwUnknownColumnType(arguments.type);
	}

	/**
	 * The nested TOP queries in $querySetup() return the last `limit` rows rather than the requested
	 * window when limit + offset exceeds the matching rows, so callers must clamp the limit first.
	 */
	public boolean function $offsetNeedsRowCount() {
		return true;
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
		// An INSERT that supplies its own primary-key value may need IDENTITY_INSERT
		// (#3647). This runs before the BoxLang branch below on purpose: a wrapped
		// statement no longer starts with INSERT INTO, so no SCOPE_IDENTITY() is
		// appended — correctly, since the caller already has the key.
		if (
			Len(Trim(arguments.$primaryKey))
			&& IsSimpleValue(arguments.sql[1])
			&& Left(arguments.sql[1], 11) == "INSERT INTO"
		) {
			arguments.sql = $identityInsertSQL(sql = arguments.sql, primaryKey = arguments.$primaryKey);
		}

		// Same-batch identity retrieval for engines whose query result carries no
		// driver-supplied generated key (currently BoxLang). SCOPE_IDENTITY() is
		// batch-scoped, so it must ride in the INSERT's own batch; Base.$executeQuery
		// passes the resulting resultset to $identitySelect as returningIdentity
		// (the same plumbing the CockroachDB adapter uses for RETURNING). Bulk paths
		// pass no primary-key hint and are skipped.
		if (
			$isBoxLangEngine()
			&& Len(Trim(arguments.$primaryKey))
			&& IsSimpleValue(arguments.sql[1])
			&& Left(arguments.sql[1], 11) == "INSERT INTO"
		) {
			ArrayAppend(arguments.sql, ";SELECT SCOPE_IDENTITY() AS lastId");
		}

		if (StructKeyExists(arguments, "maxrows") && arguments.maxrows > 0) {
			if (arguments.maxrows > 0) {
				arguments.sql[1] = ReplaceNoCase(arguments.sql[1], "SELECT ", "SELECT TOP #arguments.maxrows# ", "one");
			}
			StructDelete(arguments, "maxrows");
		}
		if (arguments.limit + arguments.offset > 0) {
			local.containsGroup = false;
			local.afterWhere = "";
			if (
				IsSimpleValue(arguments.sql[ArrayLen(arguments.sql) - 1])
				&& FindNoCase("GROUP BY", arguments.sql[ArrayLen(arguments.sql) - 1])
			) {
				local.containsGroup = true;
			}

			// Fix for pagination issue when ordering multiple columns with same name.
			if (Find(",", arguments.sql[ArrayLen(arguments.sql)])) {
				local.order = arguments.sql[ArrayLen(arguments.sql)];
				local.newOrder = "";
				local.doneColumns = "";
				local.done = 0;
				local.iEnd = ListLen(local.order);
				for (local.i = 1; local.i <= local.iEnd; local.i++) {
					local.item = ListGetAt(local.order, local.i);
					local.column = SpanExcluding(Reverse(SpanExcluding(Reverse(local.item), ".")), " ");
					if (ListFind(local.doneColumns, local.column)) {
						local.done++;
						local.item &= " AS tmp" & local.done;
					}
					local.doneColumns = ListAppend(local.doneColumns, local.column);
					local.newOrder = ListAppend(local.newOrder, local.item);
				}
				arguments.sql[ArrayLen(arguments.sql)] = local.newOrder;
			}

			// Select clause always comes first in the array, the order by clause last, remove the leading keywords leaving only the columns and set to the ones used in the inner most sub query.
			local.thirdSelect = ReplaceNoCase(ReplaceNoCase(arguments.sql[1], "SELECT DISTINCT ", ""), "SELECT ", "");
			local.thirdOrder = ReplaceNoCase(arguments.sql[ArrayLen(arguments.sql)], "ORDER BY ", "");
			if (local.containsGroup) {
				local.thirdGroup = ReplaceNoCase(arguments.sql[ArrayLen(arguments.sql) - 1], "GROUP BY ", "");
			}

			// The first select is the outer most in the query and need to contain columns without table names and using aliases when they exist.
			local.firstSelect = $columnAlias(list = $tableName(list = local.thirdSelect, action = "remove"), action = "keep");

			// We need to add columns from the inner order clause to the select clauses in the inner two queries.
			// Strip identifier quotes once up front (and keep the stripped list in sync with appends below)
			// instead of re-stripping the whole select list on every loop iteration.
			local.thirdSelectStripped = $stripIdentifierQuotes(local.thirdSelect);
			local.iEnd = ListLen(local.thirdOrder);
			for (local.i = 1; local.i <= local.iEnd; local.i++) {
				local.item = ReReplace(ReReplace(ListGetAt(local.thirdOrder, local.i), " ASC\b", ""), " DESC\b", "");
				// Strip identifier quotes for comparison since SELECT may have different quoting than ORDER BY
				local.itemStripped = $stripIdentifierQuotes(local.item);
				if (!ListFindNoCase(local.thirdSelectStripped, local.itemStripped) && !ListFindNoCase(local.thirdSelect, local.item)) {
					// The test "order_clause_with_paginated_include_and_ambiguous_columns" passes in a complex order (CASE WHEN registration IN ('foo') THEN 0 ELSE 1 END DESC).
					// This gets moved up to the SELECT clause to support pagination.
					// However, we need to add "AS" to it otherwise we get a "No column name was specified" error.
					// We check if it's complex simply by looking for a space in the table / column name and that it's not a calculated property (the "AS" part).
					if (Find(" ", local.item) && !Find(" AS ", local.item)) {
						local.item &= " AS tmpSelect" & local.i;
					}

					local.thirdSelect = ListAppend(local.thirdSelect, local.item);
					local.thirdSelectStripped = ListAppend(local.thirdSelectStripped, $stripIdentifierQuotes(local.item));
				}
				if (local.containsGroup) {
					local.item = ReReplace(local.item, "[[:space:]]AS[[:space:]][A-Za-z1-9]+", "", "all");
					if (!ListFindNoCase(local.thirdGroup, local.item)) {
						local.thirdGroup = ListAppend(local.thirdGroup, local.item);
					}
				}
			}

			// The second select also needs to contain columns without table names and using aliases when they exist (but now including the columns added above).
			local.secondSelect = $columnAlias(list = $tableName(list = local.thirdSelect, action = "remove"), action = "keep");

			// First order also needs the table names removed, the column aliases can be kept since they are removed before running the query anyway.
			local.firstOrder = $tableName(list = local.thirdOrder, action = "remove");

			// Second order clause is the same as the first but with the ordering reversed.
			local.secondOrder = Replace(
				ReReplace(ReReplace(local.firstOrder, " DESC\b", Chr(7), "all"), " ASC\b", " DESC", "all"),
				Chr(7),
				" ASC",
				"all"
			);

			// Fix column aliases from order by clauses.
			local.thirdOrder = $columnAlias(list = local.thirdOrder, action = "remove");
			local.secondOrder = $columnAlias(list = local.secondOrder, action = "keep");
			local.firstOrder = $columnAlias(list = local.firstOrder, action = "keep");

			// Build new SQL string and replace the old one with it.
			local.beforeWhere = "SELECT " & local.firstSelect & " FROM (SELECT TOP " & arguments.limit & " " & local.secondSelect & " FROM (SELECT ";
			if (Find(" ", ListRest(arguments.sql[2], " "))) {
				local.beforeWhere &= "DISTINCT ";
			}
			local.beforeWhere &= "TOP " & arguments.limit + arguments.offset & " " & local.thirdSelect & " " & arguments.sql[2];
			if (local.containsGroup) {
				local.afterWhere = "GROUP BY " & local.thirdGroup & " ";
			}
			local.afterWhere &= "ORDER BY " & local.thirdOrder & ") AS tmp1 ORDER BY " & local.secondOrder & ") AS tmp2 ORDER BY " & local.firstOrder;
			ArrayDeleteAt(arguments.sql, 1);
			ArrayDeleteAt(arguments.sql, 1);
			ArrayDeleteAt(arguments.sql, ArrayLen(arguments.sql));
			if (local.containsGroup) {
				ArrayDeleteAt(arguments.sql, ArrayLen(arguments.sql));
			}
			ArrayPrepend(arguments.sql, local.beforeWhere);
			ArrayAppend(arguments.sql, local.afterWhere);
		} else {
			$removeColumnAliasesInOrderClause(args = arguments);
		}

		// SQL Server doesn't support limit and offset in SQL.
		StructDelete(arguments, "limit");
		StructDelete(arguments, "offset");

		$moveAggregateToHaving(args = arguments);
		return $performQuery(argumentCollection = arguments);
	}

	/**
	 * SQL Server rejects an explicit value for an IDENTITY column unless
	 * IDENTITY_INSERT is ON for the table, so `create(id = 41, ...)` failed here while
	 * every other supported database accepts it (#3647). This wraps an INSERT whose
	 * column list includes a primary-key column (the caller supplied that value) in the
	 * ON/OFF pair. Three rules shape the wrapper:
	 *
	 * - One batch. IDENTITY_INSERT is session-scoped, so the ON, the INSERT and the OFF
	 *   must share a connection; a single statement guarantees that whether or not the
	 *   caller opened a transaction.
	 * - Guarded by the catalog. The ON/OFF only runs when one of those key columns is
	 *   in sys.identity_columns. A natural or UUID key has no identity property, and
	 *   SET IDENTITY_INSERT on such a table is an error.
	 * - No TRY/CATCH. The OFF must run even when the INSERT fails: with inlined values
	 *   (parameterize=false) the batch runs as-is and the setting outlives it, so the
	 *   pooled connection's next insert into the table would fail. A constraint
	 *   violation only ends its own statement, so the trailing OFF still runs.
	 *   Re-raising from a CATCH block (THROW) does not work: Lucee drops an error raised
	 *   after a batch's first result, so a duplicate key came back as success.
	 *
	 * Returns the SQL array unchanged when no primary-key column is supplied.
	 *
	 * @sql The INSERT statement as a `$querySetup()` SQL array.
	 * @primaryKey The table's primary-key column name(s).
	 */
	public array function $identityInsertSQL(required array sql, required string primaryKey) {
		// Parse the INSERT's column list from the fragment strings only (the values are
		// param structs), the same parse $identitySelect uses.
		local.text = "";
		for (local.part in arguments.sql) {
			if (IsSimpleValue(local.part)) {
				local.text &= local.part;
			}
		}
		local.insertColumns = $parseInsertColumnList(local.text);

		local.names = "";
		for (local.key in ListToArray(arguments.primaryKey)) {
			local.column = $stripIdentifierQuotes(Trim(local.key));
			if (ListFindNoCase(local.insertColumns, local.column)) {
				local.names = ListAppend(local.names, "N'" & Replace(local.column, "'", "''", "all") & "'");
			}
		}
		if (!Len(local.names)) {
			return arguments.sql;
		}

		// "INSERT INTO [table] (" -> "[table]"
		local.table = Trim(SpanExcluding(Mid(arguments.sql[1], 12, Len(arguments.sql[1])), "("));
		local.tableLiteral = Replace(local.table, "'", "''", "all");

		ArrayPrepend(
			arguments.sql,
			"DECLARE @wheelsIdentityInsert bit = CASE WHEN EXISTS (SELECT 1 FROM sys.identity_columns"
			& " WHERE object_id = OBJECT_ID(N'" & local.tableLiteral & "') AND name IN (" & local.names & "))"
			& " THEN 1 ELSE 0 END; IF @wheelsIdentityInsert = 1 SET IDENTITY_INSERT " & local.table & " ON;"
		);
		ArrayAppend(arguments.sql, "; IF @wheelsIdentityInsert = 1 SET IDENTITY_INSERT " & local.table & " OFF;");
		return arguments.sql;
	}

	/**
	 * Acquire a SQL Server application lock using sp_getapplock.
	 * The lock is scoped to the current session.
	 */
	public void function $acquireAdvisoryLock(required string name, numeric timeout = 10) {
		queryExecute(
			"EXEC sp_getapplock @Resource = ?, @LockMode = 'Exclusive', @LockTimeout = ?",
			[arguments.name, arguments.timeout * 1000],
			{datasource: variables.dataSource, username: variables.username, password: variables.password}
		);
	}

	/**
	 * Release a SQL Server application lock.
	 */
	public void function $releaseAdvisoryLock(required string name) {
		queryExecute(
			"EXEC sp_releaseapplock @Resource = ?",
			[arguments.name],
			{datasource: variables.dataSource, username: variables.username, password: variables.password}
		);
	}

	/**
	 * SQL Server's sp_getapplock requires an active user transaction; calling
	 * `withAdvisoryLock` outside one raises "The statement or function must be
	 * executed in the context of a user transaction." Until the locking path
	 * grows an implicit transaction wrapper, report as unsupported so the test
	 * suite (and any capability-aware callers) skip rather than error.
	 */
	public boolean function $supportsAdvisoryLocks() {
		return false;
	}

	/**
	 * SQL Server uses table hints (WITH (UPDLOCK)) instead of trailing FOR UPDATE.
	 * Table hints require modifying the FROM clause which is too complex for initial implementation.
	 * Returns empty string to no-op.
	 */
	public string function $forUpdateClause() {
		return "";
	}

	/**
	 * Override Base adapter's function.
	 */
	public string function $generatedKey() {
		return "identitycol";
	}

	/**
	 * Override Base adapter's $identitySelect hook.
	 */
	public any function $lastIdLookup(
		required struct queryAttributes,
		required struct result,
		required string primaryKey,
		any returningIdentity = "",
		required string insertSql
	) {
		// Prefer the driver-supplied generated key: mssql-jdbc retrieves it in the
		// insert's own batch, so it is both scope-safe and trigger-safe — a trigger
		// that inserts into another identity table cannot leak its key in here.
		// StructKeyExists is case-insensitive, so Lucee's lowercase `generatedkey`
		// result key matches. ListFirst because multi-row inserts can return a list.
		if (StructKeyExists(arguments.result, "generatedKey") && Len(arguments.result.generatedKey)) {
			return ListFirst(arguments.result.generatedKey);
		}

		// Same-batch retrieval: when the engine surfaces no driver key, $querySetup
		// appended `;SELECT SCOPE_IDENTITY() AS lastId` to the INSERT's own batch
		// (SCOPE_IDENTITY() is batch-scoped, so it must ride along — a standalone
		// `SELECT SCOPE_IDENTITY()` executes in its own scope and returns NULL).
		// Base.$executeQuery pipes the batch's resultset in here as returningIdentity.
		if (
			IsQuery(arguments.returningIdentity)
			&& arguments.returningIdentity.recordCount
			&& ListFindNoCase(arguments.returningIdentity.columnList, "lastId")
			&& Len(arguments.returningIdentity.lastId[1])
		) {
			return arguments.returningIdentity.lastId[1];
		}

		$throwIdentityNotFound();
	}

	/**
	 * Override Base adapter's function.
	 */
	public string function $randomOrder() {
		return "NEWID()";
	}

	/**
	 * Override Base adapter's function.
	 * SQL Server uses square brackets to quote identifiers.
	 */
	public string function $quoteIdentifier(required string name) {
		return "[#arguments.name#]";
	}

	/**
	 * SQL Server upsert using MERGE statement syntax.
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

		// Build column list for SELECT.
		local.colList = "";
		local.selectCols = "";
		for (local.c = 1; local.c <= ArrayLen(arguments.columns); local.c++) {
			if (Len(local.colList)) {
				local.colList &= ", ";
				local.selectCols &= ", ";
			}
			local.colList &= $quoteIdentifier(arguments.columns[local.c]);
			local.selectCols &= "source." & $quoteIdentifier(arguments.columns[local.c]);
		}

		// MERGE INTO target USING (VALUES rows) AS source(cols) ON match
		ArrayAppend(local.sql, "MERGE INTO #arguments.tableName# WITH (HOLDLOCK) AS target USING (VALUES ");

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

		ArrayAppend(local.sql, ") AS source (#local.colList#) ON ");

		// ON clause.
		local.onClause = "";
		for (local.u in arguments.uniqueBy) {
			if (Len(local.onClause)) local.onClause &= " AND ";
			local.onClause &= "target." & $quoteIdentifier(local.u) & " = source." & $quoteIdentifier(local.u);
		}
		ArrayAppend(local.sql, local.onClause);

		// WHEN MATCHED THEN UPDATE.
		if (ArrayLen(arguments.updateColumns)) {
			local.setClause = "";
			for (local.uc in arguments.updateColumns) {
				if (Len(local.setClause)) local.setClause &= ", ";
				local.setClause &= "target." & $quoteIdentifier(local.uc) & " = source." & $quoteIdentifier(local.uc);
			}
			ArrayAppend(local.sql, " WHEN MATCHED THEN UPDATE SET #local.setClause#");
		}

		// WHEN NOT MATCHED THEN INSERT.
		ArrayAppend(local.sql, " WHEN NOT MATCHED THEN INSERT (#local.colList#) VALUES (#local.selectCols#);");

		return local.sql;
	}

}
