component extends="wheels.databaseAdapters.Base" output=false {

	/**
	 * Map database types to the ones used in CFML.
	 */
	public string function $getType(required string type, string scale, string details) {
		switch (arguments.type) {
			case "bigint":
				local.rv = "cf_sql_bigint";
				break;
			case "binary":
			case "geography":
			case "geometry":
			case "timestamp":
				local.rv = "cf_sql_binary";
				break;
			case "bit":
				local.rv = "cf_sql_bit";
				break;
			case "char":
			case "nchar":
			case "uniqueidentifier":
				local.rv = "cf_sql_char";
				break;
			case "date":
				local.rv = "cf_sql_date";
				break;
			case "datetime":
			case "datetime2":
			case "smalldatetime":
			case "datetimeoffset":
				local.rv = "cf_sql_timestamp";
				break;
			case "decimal":
			case "money":
			case "smallmoney":
				local.rv = "cf_sql_decimal";
				break;
			case "float":
				local.rv = "cf_sql_float";
				break;
			case "int":
				local.rv = "cf_sql_integer";
				break;
			case "image":
				local.rv = "cf_sql_longvarbinary";
				break;
			case "text":
			case "ntext":
			case "xml":
				local.rv = "cf_sql_longvarchar";
				break;
			case "numeric":
				local.rv = "cf_sql_numeric";
				break;
			case "real":
				local.rv = "cf_sql_real";
				break;
			case "smallint":
				local.rv = "cf_sql_smallint";
				break;
			case "time":
				local.rv = "cf_sql_time";
				break;
			case "tinyint":
				local.rv = "cf_sql_tinyint";
				break;
			case "varbinary":
				local.rv = "cf_sql_varbinary";
				break;
			case "varchar":
			case "nvarchar":
			case "hierarchyid":
				local.rv = "cf_sql_varchar";
				break;
			case "cursor":
				local.rv = "cf_sql_refcursor";
				break;
		}
		return local.rv;
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

		// Absolute last resort — only reached when the multi-statement batch did not
		// surface a usable resultset on this engine/driver combo. @@IDENTITY is
		// session-scoped and can return a trigger-generated identity from another
		// table, but keeping it means a same-batch miss degrades to the pre-fix
		// behavior instead of losing the key entirely.
		local.query = $query(sql = "SELECT @@IDENTITY AS lastId", argumentCollection = arguments.queryAttributes);

		// Fallback to SCOPE_IDENTITY() if @@IDENTITY returned nothing (other CFML engines).
		if (!Len(local.query.lastId)) {
			local.query = $query(sql = "SELECT SCOPE_IDENTITY() AS lastId", argumentCollection = arguments.queryAttributes);
		}

		return local.query.lastId;
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
