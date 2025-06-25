component output=false extends="wheels.Global"{

	public struct function $executeQuery(
		required struct queryAttributes,
		required array sql,
		required boolean parameterize,
		required numeric limit,
		required numeric offset,
		required string comment,
		required string debugName,
		required string primaryKey
	) {
    // Since we allow the developer to pass in the name to use for the query variable we need to avoid name clashing.
		// We do this by putting all our own variables inside a $wheels struct.
		local.$wheels = {};
		local.$wheels.rv = {};

    cfquery(attributeCollection=arguments.queryAttributes){
      local.$wheels.pos = 0;

      for (local.$wheels.i in arguments.sql) {
        local.$wheels.pos += 1;
        if (isStruct(local.$wheels.i)) {
          local.$wheels.queryParamAttributes = $queryParams(local.$wheels.i);
          if (!isBinary(local.$wheels.i.value) && local.$wheels.i.value == "null" && local.$wheels.pos > 1 &&
            (right(arguments.sql[local.$wheels.pos - 1], 2) == "IS" || right(arguments.sql[local.$wheels.pos - 1], 6) == "IS NOT")) {
            writeOutput("NULL");
          } else if (structKeyExists(local.$wheels.queryParamAttributes, "list")) {
            if (arguments.parameterize) {
							writeOutput("(");
              cfqueryParam(attributeCollection=local.$wheels.queryParamAttributes);
							writeOutput(")");
            } else {
              writeOutput("(" & preserveSingleQuotes(local.$wheels.i.value) & ")");
            }
          } else {
            if (arguments.parameterize) {
              cfqueryParam(attributeCollection=local.$wheels.queryParamAttributes);
            } else {
              writeOutput($quoteValue(str=local.$wheels.i.value, sqlType=local.$wheels.i.type));
            }
          }
        } else {
          local.$wheels.i = replace(preserveSingleQuotes(local.$wheels.i), "[[comma]]", ",", "all");
          writeOutput(preserveSingleQuotes(local.$wheels.i));
        }
        writeOutput(chr(13) & chr(10));
      }

      if (arguments.limit) {
        writeOutput("LIMIT " & arguments.limit);
        if (arguments.offset) {
          writeOutput(chr(13) & chr(10) & "OFFSET " & arguments.offset);
        }
      }

      if (len(arguments.comment)) {
        writeOutput(arguments.comment);
      }
    }

    if(StructKeyExists(local, arguments.debugName)){
      local.$wheels.rv.query = local[arguments.debugName];
    }
    // Get / set the primary key name / value when Lucee / ACF cannot retrieve it for us.
		local.$wheels.id = $identitySelect(
			primaryKey = arguments.primaryKey,
			queryAttributes = arguments.queryAttributes,
			result = local.$wheels.result
		);
		if (StructKeyExists(local.$wheels, "id") && IsStruct(local.$wheels.id) && !StructIsEmpty(local.$wheels.id)) {
			StructAppend(local.$wheels.result, local.$wheels.id);
		}

		local.$wheels.rv.result = local.$wheels.result;
		return local.$wheels.rv;
	}

	/**
	 * Initialize and return the adapter object.
	 */
	public any function $init(required string dataSource, required string username, required string password) {
		variables.dataSource = arguments.dataSource;
		variables.username = arguments.username;
		variables.password = arguments.password;
		return this;
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
		required string primaryKey
	) {
		var query = {};
		local.sql = Trim(arguments.result.sql);
		if (Left(local.sql, 11) == "INSERT INTO" && !StructKeyExists(arguments.result, $generatedKey())) {
			local.startPar = Find("(", local.sql) + 1;
			local.endPar = Find(")", local.sql);
			local.columnList = ReplaceList(
				Mid(local.sql, local.startPar, (local.endPar - local.startPar)),
				"#Chr(10)#,#Chr(13)#, ",
				",,"
			);
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
					extendedInfo = "Add a table named `#arguments.tableName#` to your database or tell CFWheels to use a different table for this model. For example you can tell a `user` model to use a table called `tbl_users` by creating a `User.cfc` file in the `app/models` folder, creating a `config` method inside it and then calling `table(""tbl_users"")` from within it. You can also issue a reload request, if you have made changes to your files, to make CFWheels pick up on those changes."
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
	 */
	public string function $quoteValue(required string str, string sqlType = "CF_SQL_VARCHAR", string type) {
		if (!StructKeyExists(arguments, "type")) {
			arguments.type = $getValidationType(arguments.sqlType);
		}
		if (!ListFindNoCase("integer,float,boolean", arguments.type) || !Len(arguments.str)) {
			local.rv = "'#arguments.str#'";
		} else {
			local.rv = arguments.str;
		}
		return local.rv;
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
		local.queryAttributes = {};
		local.queryAttributes.dataSource = arguments.dataSource;
		local.queryAttributes.username = variables.username;
		local.queryAttributes.password = variables.password;
		local.queryAttributes.result = "local.$wheels.result";
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


}
