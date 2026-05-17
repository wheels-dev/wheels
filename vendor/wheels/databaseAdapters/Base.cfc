component output=false extends="wheels.Global"{

	public struct function $executeQuery(
		required struct queryAttributes,
		required array  sql,
		required boolean parameterize,
		required numeric limit,
		required numeric offset,
		required string comment,
		required string debugName,
		required string primaryKey
	) {
		// local variables
		local.wheels   = { rv: {} };
		local.newLine  = chr(13) & chr(10);
		local.args     = arguments;
		local.sqlArray = args.sql;
		local.sqlLen   = arrayLen(sqlArray);

		// Detect datasource info once
		local.ds = args.queryAttributes;
		local.dsInfo = ( structKeyExists(ds, "DATASOURCE") && len(ds.DATASOURCE) )
			? $dbinfo(type="version", datasource=ds.DATASOURCE)
			: $dbinfo(
				type     = "version",
				datasource = application.wheels.dataSourceName,
				username   = application.wheels.dataSourceUserName,
				password   = application.wheels.dataSourcePassword
			);

		// Build query
		cfquery(attributeCollection = args.queryAttributes) {
			local.pos = 1;
			local.prev = "";

			for (; pos <= sqlLen; pos++) {
				local.part = sqlArray[pos];

				if (isStruct(part)) {
					local.qp = $queryParams(part);

					// Handle NULL for "IS NULL" or "IS NOT NULL"
					if (
						!isBinary(part.value) &&
						part.value == "null" &&
						pos > 1 &&
						( right(prev, 2) == "IS" || right(prev, 6) == "IS NOT" )
					) {
						writeOutput("NULL");
					}
					// Handle parameter lists "(?,?,?)"
					else if (structKeyExists(qp, "list")) {
						writeOutput("(");
						if (args.parameterize) {
							cfqueryParam(attributeCollection = qp);
						} else {
							writeOutput("(" & preserveSingleQuotes(part.value) & ")");
						}
						writeOutput(")");
					}
					// Normal parameter
					else {
						if (args.parameterize) {
							cfqueryParam(attributeCollection = qp);
						} else {
							writeOutput($quoteValue(str = part.value, sqlType = part.type));
						}
					}
				}
				else {
					// regular SQL string part
					part = replace(preserveSingleQuotes(part), "[[comma]]", ",", "all");
					writeOutput(preserveSingleQuotes(part));
				}

				writeOutput(newLine);
				prev = part;
			}

			// LIMIT / OFFSET logic
			if (args.limit) {
				if (findNoCase("Oracle", dsInfo.database_productname)) {
					if (args.offset) {
						writeOutput("OFFSET " & args.offset & " ROWS" & newLine & "FETCH NEXT " & args.limit & " ROWS ONLY");
					} else {
						writeOutput("FETCH FIRST " & args.limit & " ROWS ONLY");
					}
				} else {
					writeOutput("LIMIT " & args.limit);
					if (args.offset) {
						writeOutput(newLine & "OFFSET " & args.offset);
					}
				}
			}

			// Comment block
			if (len(args.comment)) {
				writeOutput(args.comment);
			}
		}

		// Retrieve debug query if needed
		if (structKeyExists(local, args.debugName)) {
			wheels.rv.query = local[args.debugName];
		}

		// Manual identity retrieval for Lucee / ACF
		// Pass the query result (if any) as returningIdentity — needed by adapters
		// that use RETURNING clauses (e.g. CockroachDB) to retrieve generated keys.
		wheels.id = $identitySelect(
			primaryKey         = args.primaryKey,
			queryAttributes    = args.queryAttributes,
			result             = wheels.result,
			returningIdentity  = structKeyExists(local, args.debugName) ? local[args.debugName] : ""
		);

		if (structKeyExists(wheels,"id") && isStruct(wheels.id) && !structIsEmpty(wheels.id)) {
			// BoxLang-safe: ensure modifiable
			wheels.result = duplicate(wheels.result);
			structAppend(wheels.result, wheels.id);
		}

		wheels.rv.result = wheels.result;
		return wheels.rv;
	}

	/**
	 * Initialize and return the adapter object.
	 */
	public any function $init(required string dataSource, required string username, required string password) {
		variables.dataSource = arguments.dataSource;
		variables.username = arguments.username;
		variables.password = arguments.password;
		variables.$sharedModel = false;
		return this;
	}

	/**
	 * Mark this adapter's model as shared (immune to tenant datasource overrides).
	 * Shared models always use the default application datasource.
	 *
	 * [section: Model Configuration]
	 * [category: Multi-Tenancy]
	 */
	public void function $setSharedModel(required boolean flag) {
		variables.$sharedModel = arguments.flag;
	}

	/**
	 * Returns whether this adapter's model is shared.
	 */
	public boolean function $isSharedModel() {
		return variables.$sharedModel;
	}

	/**
	 * Set a default for the column name that holds the last inserted auto-incrementing primary key value.
	 * Individual database adapters will override when necessary.
	 */
	public string function $generatedKey() {
		return "generated_key";
	}

	/**
	 * Called after a query has executed.
	 * If the query was an INSERT and the generated auto-incrementing primary key is not in the result we get it manually.
	 * If the primary key was part of the INSERT (i.e. it wasn't auto-incrementing) we don't need to check it though.
	 * This process is typically needed on non-supported databases (example: H2) and drivers (example: jTDS).
	 * We return void or a struct containing the key name / value.
	 */
	public any function $identitySelect(
		required struct queryAttributes,
		required struct result,
		required string primaryKey,
		any returningIdentity = ""
	) {
		local.query = {};
		local.sql = Trim(arguments.result.sql);
		if (Left(local.sql, 11) == "INSERT INTO" && !StructKeyExists(arguments.result, $generatedKey())) {
			local.startPar = Find("(", local.sql) + 1;
			local.endPar = Find(")", local.sql);
			local.columnList = ReplaceList(
				Mid(local.sql, local.startPar, (local.endPar - local.startPar)),
				"#Chr(10)#,#Chr(13)#, ",
				",,"
			);
			// Strip identifier quotes from column list for comparison
			local.columnList = $stripIdentifierQuotes(local.columnList);
			if (!ListFindNoCase(local.columnList, ListFirst(arguments.primaryKey))) {
				local.rv = {};
				query = $query(sql = "SELECT LAST_INSERT_ID() AS lastId", argumentCollection = arguments.queryAttributes);
				local.rv[$generatedKey()] = query.lastId;
				return local.rv;
			}
		}
	}

	/**
	 * Set a default for the string to use to order records randomly.
	 * Individual database adapters will override when necessary.
	 */
	public string function $randomOrder() {
		return "RAND()";
	}

	/**
	 * Set a default for the string to use when inserting a record with default values only.
	 * Individual database adapters will override when necessary.
	 */
	public string function $defaultValues() {
		return " DEFAULT VALUES";
	}

	/**
	 * Quote a database identifier (table or column name) using the adapter's quoting character.
	 * Base implementation is a no-op; individual adapters override with their specific quoting.
	 * This prevents reserved word conflicts across all supported databases.
	 */
	public string function $quoteIdentifier(required string name) {
		return arguments.name;
	}

	/**
	 * Strip all identifier quote characters from a string.
	 * Used when parsing rendered SQL to compare column names without quoting artifacts.
	 */
	public string function $stripIdentifierQuotes(required string str) {
		return ReReplace(arguments.str, '`|\[|\]|"', "", "all");
	}

	/**
	 * Set a default for the table alias string (e.g. "users AS users2").
	 * Individual database adapters will override when necessary.
	 */
	public string function $tableAlias(required string table, required string alias) {
		return arguments.table & " AS " & arguments.alias;
	}

	/**
	 * Internal function.
	 */
	public string function $tableName(required string list, required string action) {
		local.rv = "";
		local.iEnd = ListLen(arguments.list);
		for (local.i = 1; local.i <= local.iEnd; local.i++) {
			local.item = ListGetAt(arguments.list, local.i);

			// Remove table name if specified.
			if (arguments.action == "remove") {
				local.item = ListRest(local.item, ".");
			}

			local.rv = ListAppend(local.rv, local.item);
		}
		return local.rv;
	}

	/**
	 * Internal function.
	 */
	public string function $columnAlias(required string list, required string action) {
		local.rv = "";
		local.iEnd = ListLen(arguments.list);
		for (local.i = 1; local.i <= local.iEnd; local.i++) {
			local.item = ListGetAt(arguments.list, local.i);
			if (Find(" AS ", local.item)) {
				local.sort = "";
				if (Right(local.item, 4) == " ASC" || Right(local.item, 5) == " DESC") {
					local.sort = " " & Reverse(SpanExcluding(Reverse(local.item), " "));
					local.item = Mid(local.item, 1, Len(local.item) - Len(local.sort));
				}
				local.alias = Reverse(SpanExcluding(Reverse(local.item), " "));

				// Keep or remove the alias.
				if (arguments.action == "keep") {
					local.item = local.alias;
				} else if (arguments.action == "remove") {
					local.item = Replace(local.item, " AS " & local.alias, "");
				}

				local.item &= local.sort;
			}
			local.rv = ListAppend(local.rv, local.item);
		}
		return local.rv;
	}

	/**
	 * Remove the column aliases from the order by clause (this is passed in so that we can handle sub queries with calculated properties).
	 * The args argument is the original arguments passed in by reference so we just modify it without passing it back.
	 */
	public void function $removeColumnAliasesInOrderClause(required struct args) {
		if (
			IsSimpleValue(arguments.args.sql[ArrayLen(arguments.args.sql)])
			&& Left(arguments.args.sql[ArrayLen(arguments.args.sql)], 9) == "ORDER BY "
		) {
			local.pos = ArrayLen(arguments.args.sql);
			local.list = ReplaceNoCase(arguments.args.sql[local.pos], "ORDER BY ", "");
			arguments.args.sql[local.pos] = "ORDER BY " & $columnAlias(list = local.list, action = "remove");
		}
	}

	/**
	 * Internal function.
	 */
	public boolean function $isAggregateFunction(required string sql) {
		// Find "(FUNCTION(..." pattern inside the sql.
		local.match = ReFind("^\([A-Z]+\(", arguments.sql, 0, true);

		// Guard against invalid match.
		if (ArrayLen(local.match.pos) == 0) {
			local.rv = false;
		} else if (local.match.len[1] <= 2) {
			local.rv = false;
		} else {
			// Extract and analyze the function name.
			local.name = Mid(arguments.sql, local.match.pos[1] + 1, local.match.len[1] - 2);
			local.rv = ListContains("AVG,COUNT,MAX,MIN,SUM", local.name) ? true : false;
		}
		return local.rv;
	}

	/**
	 * The args argument is the original arguments passed in by reference so we just modify it without passing it back.
	 */
	public void function $addColumnsToSelectAndGroupBy(required struct args) {
		if (
			IsSimpleValue(arguments.args.sql[ArrayLen(arguments.args.sql)])
			&& Left(arguments.args.sql[ArrayLen(arguments.args.sql)], 8) == "ORDER BY"
			&& IsSimpleValue(arguments.args.sql[ArrayLen(arguments.args.sql) - 1])
			&& Left(arguments.args.sql[ArrayLen(arguments.args.sql) - 1], 8) == "GROUP BY"
		) {
			local.iEnd = ListLen(arguments.args.sql[ArrayLen(arguments.args.sql)]);
			// cfformat-ignore-start
			for (local.i = 1; local.i <= local.iEnd; local.i++) {
				local.item = Trim(ReplaceNoCase(ReplaceNoCase(ReplaceNoCase(ListGetAt(arguments.args.sql[ArrayLen(arguments.args.sql)], local.i), "ORDER BY ", ""), " ASC",""), " DESC", ""));
				if (
					!ListFindNoCase(ReplaceNoCase(arguments.args.sql[ArrayLen(arguments.args.sql) - 1], "GROUP BY ", ""), local.item)
					&& !$isAggregateFunction(local.item)
				) {
					local.key = ArrayLen(arguments.args.sql) - 1;
					arguments.args.sql[local.key] = ListAppend(arguments.args.sql[local.key], local.item);
				}
			}
			// cfformat-ignore-end
		}
	}

	/**
	 * Retrieves all the column information from a table.
	 */
	public query function $getColumns(required string tableName) {
		local.args = {};
		local.args.dataSource = variables.dataSource;
		local.args.username = variables.username;
		local.args.password = variables.password;
		local.args.table = arguments.tableName;
		if ($get("showErrorInformation")) {
			try {
				local.rv = $getColumnInfo(argumentCollection = local.args);
			} catch (any e) {
				Throw(
					type = "Wheels.TableNotFound",
					message = "The `#arguments.tableName#` table could not be found in the database.<br>`#e.message#`<br>`#e.detail#.`",
					extendedInfo = "Add a table named `#arguments.tableName#` to your database or tell Wheels to use a different table for this model. For example you can tell a `user` model to use a table called `tbl_users` by creating a `User.cfc` file in the `app/models` folder, creating a `config` method inside it and then calling `table(""tbl_users"")` from within it. You can also issue a reload request, if you have made changes to your files, to make Wheels pick up on those changes."
				);
			}
		} else {
			local.rv = $getColumnInfo(argumentCollection = local.args);
		}
		return local.rv;
	}

	/**
	 * Internal function.
	 */
	public string function $getValidationType(required string type) {
		switch (arguments.type) {
			case "CF_SQL_DECIMAL":
			case "CF_SQL_DOUBLE":
			case "CF_SQL_FLOAT":
			case "CF_SQL_MONEY":
			case "CF_SQL_MONEY4":
			case "CF_SQL_NUMERIC":
			case "CF_SQL_REAL":
				return "float";
			case "CF_SQL_INTEGER":
			case "CF_SQL_BIGINT":
			case "CF_SQL_SMALLINT":
			case "CF_SQL_TINYINT":
				return "integer";
			case "CF_SQL_BINARY":
			case "CF_SQL_VARBINARY":
			case "CF_SQL_LONGVARBINARY":
			case "CF_SQL_BLOB":
			case "CF_SQL_CLOB":
				return "binary";
			case "CF_SQL_DATE":
			case "CF_SQL_TIME":
			case "CF_SQL_TIMESTAMP":
				return "datetime";
			case "CF_SQL_BIT":
				return "boolean";
			case "CF_SQL_ARRAY":
				return "array";
			case "CF_SQL_STRUCT":
				return "struct";
			case "CF_SQL_LONGVARCHAR":
			case "CF_SQL_LONGNVARCHAR":
				return "text";
			default:
				return "string";
		}
	}

	/**
	 * Internal function.
	 */
	public string function $cleanInStatementValue(required string statement) {
		local.rv = arguments.statement;
		local.delim = ",";
		if (Find("'", local.rv)) {
			local.delim = "','";
			local.rv = RemoveChars(local.rv, 1, 1);
			local.rv = Reverse(RemoveChars(Reverse(local.rv), 1, 1));
			local.rv = Replace(local.rv, "''", "'", "all");
		}
		return ReplaceNoCase(local.rv, local.delim, Chr(7), "all");
	}

	/**
	 * Internal function.
	 */
	public struct function $queryParams(required struct settings) {
		if (!StructKeyExists(arguments.settings, "value")) {
			Throw(
				type = "Wheels.QueryParamValue",
				message = "The value for `cfqueryparam` cannot be determined for property `#arguments.settings.property#`.<br>This usually happens due to a syntax error in the WHERE clause (e.g., using unquoted strings or invalid values).",
				extendedInfo = "This is usually caused by a syntax error in the `WHERE` statement, such as forgetting to quote strings for example."
			);
		}
		local.rv = {};
		local.rv.cfsqltype = arguments.settings.type;
		local.rv.value = arguments.settings.value;
		if (StructKeyExists(arguments.settings, "null")) {
			local.rv.null = arguments.settings.null;
		}
		if (StructKeyExists(arguments.settings, "scale") && arguments.settings.scale > 0) {
			local.rv.scale = arguments.settings.scale;
		}
		if (StructKeyExists(arguments.settings, "list") && arguments.settings.list) {
			local.rv.list = arguments.settings.list;
			local.rv.separator = Chr(7);
			local.rv.value = $cleanInStatementValue(local.rv.value);
		}
		return local.rv;
	}

	/**
	 * Get information about the table using cfdbinfo.
	 * Individual database adapters will override when necessary.
	 */
	public query function $getColumnInfo(
		required string table,
		required string datasource,
		required string username,
		required string password
	) {
		arguments.type = "columns";
		return $dbinfo(argumentCollection = arguments);
	}

	/**
	 * Internal function.
	 *
	 * For integer/float/boolean columns this returns the value unquoted so the
	 * downstream WHERE-clause regex can re-extract bare numerics into
	 * cfqueryparam placeholders. That contract is unsafe by itself — a string
	 * like "0 OR 1=1" would land verbatim in the SQL — so we validate the value
	 * shape here before passing it through. This closes SQL injection across
	 * every caller (chainable QueryBuilder, $keyWhereString used by findByKey/
	 * updateByKey/deleteByKey, dynamic finders findByX/findOneByX/findAllByX,
	 * the uniqueness-check $buildWhereClausePart, and any future caller).
	 *
	 * String columns are unaffected — the adapter still wraps and escapes the
	 * value, so classic single-quote payloads land harmlessly inside a literal.
	 */
	public string function $quoteValue(required string str, string sqlType = "CF_SQL_VARCHAR", string type) {
		if (!StructKeyExists(arguments, "type")) {
			arguments.type = $getValidationType(arguments.sqlType);
		}
		if (!ListFindNoCase("integer,float,boolean", arguments.type) || !Len(arguments.str)) {
			local.rv = "'#Replace(arguments.str, "'", "''", "all")#'";
		} else {
			$validateValueShape(arguments.str, arguments.type);
			local.rv = arguments.str;
		}
		return local.rv;
	}

	/**
	 * Validate that a value matches the shape this adapter expects for its
	 * declared column type. Throws Wheels.InvalidValue when the shape doesn't
	 * match — closing the SQL-injection vector through which strings like
	 * "0 OR 1=1" would otherwise land in the unquoted numeric/boolean path.
	 *
	 * Intentionally narrow: only fires for integer/float/boolean columns,
	 * which is exactly the set of types $quoteValue passes through unquoted.
	 * String columns are wrapped + escaped above and don't need this check.
	 */
	public void function $validateValueShape(required string str, required string type) {
		switch (arguments.type) {
			case "integer":
				if (!ReFind("^-?[0-9]+$", arguments.str)) {
					$throwInvalidValue(arguments.str, "integer");
				}
				break;
			case "float":
				if (!ReFind("^-?[0-9]+(\.[0-9]+)?$", arguments.str)) {
					$throwInvalidValue(arguments.str, "float");
				}
				break;
			case "boolean":
				if (!ListFindNoCase("0,1,true,false,yes,no", arguments.str)) {
					$throwInvalidValue(arguments.str, "boolean");
				}
				break;
		}
	}

	public void function $throwInvalidValue(required string str, required string expectedType) {
		Throw(
			type = "Wheels.InvalidValue",
			message = "The value `#EncodeForHTML(arguments.str)#` is not a valid #arguments.expectedType#.",
			extendedInfo = "Values bound to #arguments.expectedType# columns must be valid #arguments.expectedType# literals so they can be safely interpolated into the WHERE clause. This check protects every Wheels query path against SQL injection through typed-numeric/boolean payloads."
		);
	}

	/**
	 * Acquire a database advisory lock with the given name.
	 * Advisory locks are application-level locks that don't lock rows or tables.
	 * Individual database adapters override this with their specific implementation.
	 *
	 * @name A unique name identifying the lock.
	 * @timeout Maximum seconds to wait for the lock.
	 */
	public void function $acquireAdvisoryLock(required string name, numeric timeout = 10) {
		Throw(
			type = "Wheels.AdvisoryLockNotSupported",
			message = "Advisory locks are not supported for this database adapter.",
			extendedInfo = "The #GetMetaData(this).name# adapter does not implement advisory locking. Use a database that supports advisory locks (PostgreSQL, MySQL, or SQL Server) or implement application-level locking."
		);
	}

	/**
	 * Release a previously acquired advisory lock.
	 * Individual database adapters override this with their specific implementation.
	 *
	 * @name The name of the lock to release.
	 */
	public void function $releaseAdvisoryLock(required string name) {
		Throw(
			type = "Wheels.AdvisoryLockNotSupported",
			message = "Advisory locks are not supported for this database adapter.",
			extendedInfo = "The #GetMetaData(this).name# adapter does not implement advisory locking."
		);
	}

	/**
	 * Reports whether this adapter supports standalone advisory locks — i.e.,
	 * `$acquireAdvisoryLock` / `$releaseAdvisoryLock` can be invoked directly
	 * (no enclosing transaction or extension setup required) and will succeed.
	 *
	 * Adapters that throw `Wheels.AdvisoryLockNotSupported` from the lock
	 * methods, or that require additional context (transaction wrapper,
	 * DBMS package setup) should leave this default in place. Adapters that
	 * accept a direct call override to return `true`. Used by the test suite
	 * to skip lock specs on adapters where the primitive isn't standalone
	 * callable; callers in application code can also consult it before
	 * dispatching to `withAdvisoryLock`.
	 */
	public boolean function $supportsAdvisoryLocks() {
		return false;
	}

	/**
	 * Returns the SQL clause for pessimistic row locking (e.g., "FOR UPDATE").
	 * Individual database adapters override this when the default is not appropriate.
	 */
	public string function $forUpdateClause() {
		return "FOR UPDATE";
	}

	/**
	 * Remove the maxRows argument and add a limit argument instead.
	 * The args argument is the original arguments passed in by reference so we just modify it without passing it back.
	 */
	public void function $convertMaxRowsToLimit(required struct args) {
		if (StructKeyExists(arguments.args, "maxRows") && arguments.args.maxRows > 0) {
			arguments.args.limit = arguments.args.maxRows;
			StructDelete(arguments.args, "maxRows");
		}
	}

	/**
	 * Internal function.
	 */
	public string function $comment(required string text) {
		return "/* " & arguments.text & " */";
	}

	/**
	 * Check if SQL contains a GROUP BY clause and an aggregate function in the WHERE clause.
	 * If so, move the SQL to a new HAVING clause instead (after GROUP BY).
	 * The args argument is the original arguments passed in by reference so we just modify it without passing it back.
	 */
	public void function $moveAggregateToHaving(required struct args) {
		local.hasAggregate = false;
		local.hasGroupBy = false;
		local.havingPos = 0;
		local.iEnd = ArrayLen(arguments.args.sql);
		for (local.i = 1; local.i <= local.iEnd; local.i++) {
			if (IsSimpleValue(arguments.args.sql[local.i]) && Left(arguments.args.sql[local.i], 8) == "GROUP BY") {
				local.hasGroupBy = true;
				local.havingPos = local.i + 1;
			}
			if (IsSimpleValue(arguments.args.sql[local.i]) && $isAggregateFunction(arguments.args.sql[local.i])) {
				local.hasAggregate = true;
			}
		}
		if (local.hasGroupBy && local.hasAggregate) {
			ArrayAppend(arguments.args.sql, "");
			ArrayInsertAt(arguments.args.sql, local.havingPos, "HAVING");
			local.sql = [];
			local.iEnd = ArrayLen(arguments.args.sql);
			for (local.i = 1; local.i <= local.iEnd; local.i++) {
				if (IsSimpleValue(arguments.args.sql[local.i])) {
					if ($isAggregateFunction(arguments.args.sql[local.i])) {
						ArrayDeleteAt(local.sql, ArrayLen(local.sql));
						local.i++;
						local.havingPos = local.havingPos - 3;
					} else {
						ArrayAppend(local.sql, arguments.args.sql[local.i]);
					}
				} else {
					ArrayAppend(local.sql, arguments.args.sql[local.i]);
				}
			}
			local.pos = local.havingPos;
			local.iEnd = ArrayLen(arguments.args.sql);
			for (local.i = 1; local.i <= local.iEnd; local.i++) {
				if (IsSimpleValue(arguments.args.sql[local.i]) && $isAggregateFunction(arguments.args.sql[local.i])) {
					if (local.pos != local.havingPos) {
						local.pos++;
						ArrayInsertAt(local.sql, local.pos, arguments.args.sql[local.i - 1]);
					}
					local.pos++;
					ArrayInsertAt(local.sql, local.pos, arguments.args.sql[local.i]);
					local.pos++;
					ArrayInsertAt(local.sql, local.pos, arguments.args.sql[local.i + 1]);
				}
			}
			arguments.args.sql = local.sql;
		}
	}

	/**
	 * Internal function.
	 */
	public struct function $performQuery(
		required array sql,
		required boolean parameterize,
		numeric limit = 0,
		numeric offset = 0,
		string dataSource = variables.dataSource,
		string $primaryKey = "",
		string $debugName = "query"
	) {
		// Multi-tenant datasource override: if a tenant is active and this model
		// is not shared, route the query to the tenant's datasource.
		// Use IsDefined() for safe nested scope traversal — StructKeyExists on
		// the request scope can throw during app startup when request.wheels is absent.
		if (
			!variables.$sharedModel
			&& arguments.dataSource == variables.dataSource
			&& IsDefined("request.wheels.tenant.dataSource")
			&& Len(request.wheels.tenant.dataSource)
		) {
			arguments.dataSource = request.wheels.tenant.dataSource;
		}

		local.queryAttributes = {};
		local.queryAttributes.dataSource = arguments.dataSource;
		local.queryAttributes.username = variables.username;
		local.queryAttributes.password = variables.password;
		local.queryAttributes.result = "local.wheels.result";
		local.queryAttributes.name = "local." & arguments.$debugName;
		if (StructKeyExists(local.queryAttributes, "username") && !Len(local.queryAttributes.username)) {
			StructDelete(local.queryAttributes, "username");
		}
		if (StructKeyExists(local.queryAttributes, "password") && !Len(local.queryAttributes.password)) {
			StructDelete(local.queryAttributes, "password");
		}

		// Set queries in Lucee to not preserve single quotes on the entire cfquery block (we'll handle this individually in the SQL statement instead).
		if ($get("serverName") == "Lucee") {
			local.queryAttributes.psq = false;
		}

		// Add a key as a comment for cached queries to ensure query is unique for the life of this application.
		local.comment = "";
		if (StructKeyExists(arguments, "cachedwithin")) {
			local.comment = $comment("cachekey:#$get("cacheKey")#");
		}

		// Overloaded arguments are settings for the query.
		local.orgArgs = Duplicate(arguments);
		StructDelete(local.orgArgs, "sql");
		StructDelete(local.orgArgs, "parameterize");
		StructDelete(local.orgArgs, "$debugName");
		StructDelete(local.orgArgs, "limit");
		StructDelete(local.orgArgs, "offset");
		StructDelete(local.orgArgs, "$primaryKey");
		StructAppend(local.queryAttributes, local.orgArgs);
		return $executeQuery(
			queryAttributes = local.queryAttributes,
			sql = arguments.sql,
			parameterize = arguments.parameterize,
			limit = arguments.limit,
			offset = arguments.offset,
			comment = local.comment,
			debugName = arguments.$debugName,
			primaryKey = arguments.$primaryKey
		);
	}

	/**
	 * Generates a multi-row INSERT statement as an array compatible with `$querySetup()`.
	 * Default shape is `INSERT INTO ... VALUES (?,?), (?,?), ...` (SQL standard table value
	 * constructor) — used by every adapter except Oracle, which overrides this method to
	 * emit `INSERT ALL ... SELECT 1 FROM dual` because Oracle 23 rejects multi-row VALUES
	 * combined with the JDBC driver's implicit RETURNING (RETURN_GENERATED_KEYS) handling
	 * with `ORA: returning clause is not allowed with INSERT and Table Value Constructor`.
	 */
	public array function $bulkInsertSQL(
		required string tableName,
		required array columns,
		required array validProperties,
		required array records,
		required numeric batchStart,
		required numeric batchEnd,
		required struct propertyInfo
	) {
		local.sql = [];

		local.colList = "";
		for (local.col in arguments.columns) {
			if (Len(local.colList)) {
				local.colList &= ", ";
			}
			local.colList &= $quoteIdentifier(local.col);
		}

		ArrayAppend(local.sql, "INSERT INTO #arguments.tableName# (#local.colList#) VALUES ");

		local.propCount = ArrayLen(arguments.validProperties);
		for (local.r = arguments.batchStart; local.r <= arguments.batchEnd; local.r++) {
			if (local.r > arguments.batchStart) {
				ArrayAppend(local.sql, ", ");
			}
			ArrayAppend(local.sql, "(");
			for (local.p = 1; local.p <= local.propCount; local.p++) {
				if (local.p > 1) {
					ArrayAppend(local.sql, ", ");
				}
				local.propName = arguments.validProperties[local.p];
				local.val = StructKeyExists(arguments.records[local.r], local.propName) ? arguments.records[local.r][local.propName] : "";
				ArrayAppend(local.sql, $buildBulkParam(
					value = local.val,
					propName = local.propName,
					propertyInfo = arguments.propertyInfo
				));
			}
			ArrayAppend(local.sql, ")");
		}

		return local.sql;
	}

	/**
	 * Generates database-specific UPSERT SQL as an array compatible with `$querySetup()`.
	 * Base implementation throws an error — each adapter must override with its own syntax.
	 *
	 * @tableName The quoted table name.
	 * @columns Array of column names to insert/update.
	 * @uniqueBy Array of column names forming the unique constraint.
	 * @updateColumns Array of column names to update on conflict.
	 * @validProperties Array of model property names corresponding to `columns`.
	 * @records Array of record structs.
	 * @batchStart Starting index in the records array.
	 * @batchEnd Ending index in the records array.
	 * @propertyInfo Struct of model property metadata.
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
		Throw(
			type = "Wheels.UpsertNotSupported",
			message = "Upsert is not supported by this database adapter.",
			extendedInfo = "Override `$upsertSQL()` in the specific database adapter to enable upsert support."
		);
	}

	/**
	 * Builds parameter struct for a single value in a bulk operation.
	 * Used by adapter bulk insert and upsert implementations.
	 */
	public struct function $buildBulkParam(
		required string value,
		required string propName,
		required struct propertyInfo
	) {
		local.propInfo = arguments.propertyInfo[arguments.propName];
		return {
			value: arguments.value,
			type: local.propInfo.type,
			dataType: local.propInfo.dataType,
			scale: local.propInfo.scale,
			null: (!Len(arguments.value) && local.propInfo.nullable)
		};
	}

}
