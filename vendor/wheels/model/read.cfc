component {
	/**
	 * Returns records from the database table mapped to this model according to the arguments passed in (use the `where` argument to decide which records to get, use the `order` argument to set the order in which those records should be returned, and so on).
	 * The records will be returned as either a `cfquery` result set, an array of objects, or an array of structs (depending on what the `returnAs` argument is set to).
	 *
	 * [section: Model Class]
	 * [category: Read Functions]
	 *
	 * @where Maps to the `WHERE` clause of the query (or `HAVING` when necessary). The following operators are supported: `=`, `!=`, `<>`, `<`, `<=`, `>`, `>=`, `LIKE`, `NOT LIKE`, `IN`, `NOT IN`, `IS NULL`, `IS NOT NULL`, `AND`, and `OR` (note that the key words need to be written in upper case). You can also use parentheses to group statements. Nested queries not allowed. You do not need to specify the table name(s); CFWheels will do that for you.
	 * @order Maps to the `ORDER` BY clause of the query. You do not need to specify the table name(s); CFWheels will do that for you.
	 * @group Maps to the `GROUP BY` clause of the query. You do not need to specify the table name(s); CFWheels will do that for you.
	 * @select Determines how the `SELECT` clause for the query used to return data will look. You can pass in a list of the properties (which map to columns) that you want returned from your table(s). If you don't set this argument at all, CFWheels will select all properties from your table(s). If you specify a table name (e.g. `users.email`) or alias a column (e.g. `fn AS firstName`) in the list, then the entire list will be passed through unchanged and used in the `SELECT` clause of the query. By default, all column names in tables joined via the `include` argument will be prepended with the singular version of the included table name.
	 * @distinct Whether to add the `DISTINCT` keyword to your `SELECT` clause. CFWheels will, when necessary, add this automatically (when using pagination and a `hasMany` association is used in the `include` argument, to name one example).
	 * @include Associations that should be included in the query using `INNER` or `LEFT OUTER` joins (which join type that is used depends on how the association has been set up in your model). If all included associations are set on the current model, you can specify them in a list (e.g. `department,addresses,emails`). You can build more complex include strings by using parentheses when the association is set on an included model, like `album(artist(genre))`, for example. These complex `include` strings only work when `returnAs` is set to `query` though.
	 * @maxRows Maximum number of records to retrieve. Passed on to the `maxRows` `cfquery` attribute. The default, `-1`, means that all records will be retrieved.
	 * @page If you want to paginate records, you can do so by specifying a page number here. For example, getting records 11-20 would be page number 2 when `perPage` is kept at the default setting (10 records per page). The default, 0, means that records won't be paginated and that the `perPage` and `count` arguments will be ignored.
	 * @perPage When using pagination, you can specify how many records you want to fetch per page here. This argument is only used when the `page` argument has been passed in.
	 * @count When using pagination and you know in advance how many records you want to paginate through, you can pass in that value here. Doing so will prevent CFWheels from running a `COUNT` query to get this value. This argument is only used when the `page` argument has been passed in.
	 * @handle Handle to use for the query. This is used when you're paginating multiple queries and need to reference them individually in the `paginationLinks()` function. It's also used to set the name of the query in the debug output (which otherwise defaults to `userFindAllQuery` for example).
	 * @cache If you want to cache the query, you can do so by specifying the number of minutes you want to cache the query for here. If you set it to `true`, the default cache time will be used (60 minutes).
	 * @reload Set to `true` to force CFWheels to query the database even though an identical query for this model may have been run in the same request. (The default in CFWheels is to get the second query from the model's request-level cache.)
	 * @parameterize Set to `true` to use `cfqueryparam` on all columns, or pass in a list of property names to use `cfqueryparam` on those only.
	 * @returnAs Set to `objects` to return an array of objects, set to `structs` to return an array of structs, set to `query` to return a query result set, or set to 'sql' to return the executed SQL query as a string.
	 * @returnIncluded When `returnAs` is set to `objects`, you can set this argument to `false` to prevent returning objects fetched from associations specified in the `include` argument. This is useful when you only need to include associations for use in the `WHERE` clause only and want to avoid the performance hit that comes with object creation.
	 * @callbacks Set to `false` to disable callbacks for this method.
	 * @includeSoftDeletes Set to `true` to include soft-deleted records in the queries that this method runs.
	 * @useIndex If you want to specify table index hints, pass in a structure of index names using your model names as the structure keys. Eg: `{user="idx_users", post="idx_posts"}`. This feature is only supported by MySQL and SQL Server.
	 * @dataSource Override the default datasource
	 */
	public any function findAll(
		string where = "",
		string order,
		string group,
		string select = "",
		boolean distinct = "false",
		string include = "",
		numeric maxRows = "-1",
		numeric page = "0",
		numeric perPage,
		numeric count = "0",
		string handle = "query",
		any cache = "",
		boolean reload,
		any parameterize,
		string returnAs,
		boolean returnIncluded,
		boolean callbacks = "true",
		boolean includeSoftDeletes = "false",
		struct useIndex = {},
		string dataSource = variables.wheels.class.dataSource,
		numeric $limit = "0",
		numeric $offset = "0"
	) {
		$args(name = "findAll", args = arguments);
		$setDebugName(name = "findAll", args = arguments);
		arguments.include = $listClean(arguments.include);
		arguments.where = $cleanInList(arguments.where);

		// we only allow direct associations to be loaded when returning objects
		if (
			$get("showErrorInformation")
			&& Len(arguments.returnAs)
			&& arguments.returnAs != "query"
			&& Find("(", arguments.include)
			&& arguments.returnIncluded
		) {
			Throw(
				type = "Wheels",
				message = "Incorrect Arguments",
				extendedInfo = "You may only include direct associations to this object when returning an array of objects."
			);
		}

		// count records and get primary keys for pagination
		if (arguments.page) {
			if ($get("showErrorInformation") && arguments.perPage <= 0) {
				Throw(
					type = "Wheels",
					message = "Incorrect Argument",
					extendedInfo = "The `perPage` argument should be a positive numeric value."
				);
			}
			if (Len(arguments.order)) {
				// insert primary keys to order clause unless they are already there, this guarantees that the ordering is unique which is required to make pagination work properly
				local.compareList = $listClean(
					ReplaceNoCase(ReplaceNoCase(arguments.order, " ASC", "", "all"), " DESC", "", "all")
				);
				local.iEnd = ListLen(primaryKeys());
				for (local.i = 1; local.i <= local.iEnd; local.i++) {
					local.item = primaryKeys(local.i);
					if (
						!ListFindNoCase(local.compareList, local.item)
						&& !ListFindNoCase(local.compareList, tableName() & "." & local.item)
					) {
						arguments.order = ListAppend(arguments.order, "#tableName()#.#local.item#");
					}
				}
			} else {
				// we can't paginate without any order so we default to ascending ordering by the primary key column(s)
				arguments.order = primaryKey();
			}
			if (Len(arguments.include)) {
				local.distinct = true;
			} else {
				local.distinct = false;
			}
			if (arguments.count > 0) {
				local.totalRecords = arguments.count;
			} else {
				arguments.$debugName &= "PaginationCount";
				local.totalRecords = this.count(
					where = arguments.where,
					include = arguments.include,
					reload = arguments.reload,
					cache = arguments.cache,
					distinct = local.distinct,
					parameterize = arguments.parameterize,
					$debugName = arguments.$debugName,
					includeSoftDeletes = arguments.includeSoftDeletes,
					dataSource = arguments.dataSource
				);
			}
			local.currentPage = arguments.page;
			if (local.totalRecords == 0) {
				local.totalPages = 0;
				local.rv = "";
			} else {
				local.totalPages = Ceiling(local.totalRecords / arguments.perPage);
				local.limit = arguments.perPage;
				local.offset = (arguments.perPage * arguments.page) - arguments.perPage;

				// if the full range of records is not requested we correct the limit to get the exact amount instead
				// for example if totalRecords is 57, limit is 10 and offset 50 (i.e. requesting records 51-60) we change the limit to 7
				if ((local.limit + local.offset) > local.totalRecords) {
					local.limit = local.totalRecords - local.offset;
				}

				if (local.limit < 1) {
					// if limit is 0 or less it means that a page that has no records was asked for so we return an empty query
					local.rv = "";
				} else {
					arguments.$debugName = Replace(arguments.$debugName, "PaginationCount", "PaginationIds");
					local.values = findAll(
						$limit = local.limit,
						$offset = local.offset,
						select = primaryKeys(),
						where = arguments.where,
						order = arguments.order,
						include = arguments.include,
						reload = arguments.reload,
						cache = arguments.cache,
						distinct = local.distinct,
						parameterize = arguments.parameterize,
						$debugName = arguments.$debugName,
						includeSoftDeletes = arguments.includeSoftDeletes,
						dataSource = arguments.dataSource,
						callbacks = false
					);
					if (local.values.RecordCount) {
						local.paginationWhere = "";
						local.iEnd = local.values.recordCount;
						for (local.i = 1; local.i <= local.iEnd; local.i++) {
							local.keyComboValues = [];
							local.jEnd = ListLen(primaryKeys());
							for (local.j = 1; local.j <= local.jEnd; local.j++) {
								local.property = primaryKeys(local.j);
								ArrayAppend(
									local.keyComboValues,
									"#tableName()#.#local.property# = #variables.wheels.class.adapter.$quoteValue(
										str = local.values[local.property][local.i],
										type = validationTypeForProperty(local.property)
									)#"
								);
							}
							local.paginationWhere = ListAppend(
								local.paginationWhere,
								"(" & ArrayToList(local.keyComboValues, " AND ") & ")",
								Chr(7)
							);
						}
						local.paginationWhere = Replace(local.paginationWhere, Chr(7), " OR ", "all");

						// this can be improved to also check if the where clause checks on a joined table, if not we can use the simple where clause with just the ids
						if (Len(arguments.where) && Len(arguments.include)) {
							arguments.where = "(#arguments.where#) AND (#local.paginationWhere#)";
							if (IsNumeric(arguments.parameterize)) {
								arguments.parameterize += local.values.recordCount;
							}
						} else {
							arguments.where = local.paginationWhere;
							if (IsNumeric(arguments.parameterize)) {
								arguments.parameterize = local.values.recordCount;
							}
						}
					}
				}
			}
			// store pagination info in the request scope so all pagination methods can access it
			setPagination(local.totalRecords, local.currentPage, arguments.perPage, arguments.handle);
		}

		if (StructKeyExists(local, "rv") && !Len(local.rv)) {
			// No records were found using the pagination count query.
			// We don't need to run any more queries and can just set the return value based on the "returnAs" argument.
			if (arguments.returnAs == "query") {
				// We want to return an empty query but still include the column names.
				// Get those using the usual function for it and then remove table names, aliases and calculated property SQL.
				// E.g. users.name -> name, createdAt AS userCreatedAt -> userCreatedAt, (MAX(table.col)) AS x -> x.
				local.columns = $createSQLFieldList(
					clause = "select",
					include = arguments.include,
					includeSoftDeletes = arguments.includeSoftDeletes,
					list = arguments.select,
					returnAs = arguments.returnAs
				);
				local.columns = ReReplace(local.columns, "\w*?\.([\w\s]*?)(,|$)", "\1\2", "all");
				local.columns = ReReplace(local.columns, "\(.*?\)\sAS\s([\w\s]*?)(,|$)", "\1\2", "all");
				local.columns = ReReplace(local.columns, "\w*?\sAS\s([\w\s]*?)(,|$)", "\1\2", "all");
				local.rv = QueryNew(local.columns);
			} else if (singularize(arguments.returnAs) == arguments.returnAs) {
				local.rv = false;
			} else {
				local.rv = [];
			}
		} else if (!StructKeyExists(local, "rv")) {
			// make the where clause generic for use in caching
			local.originalWhere = arguments.where;
			arguments.where = ReReplace(arguments.where, variables.wheels.class.RESQLWhere, "\1?\8", "all");

			// get info from cache when available, otherwise create the generic select, from, where and order by clause
			local.queryShellKey = $hashedKey(variables.wheels.class.modelName, arguments);
			local.sql = $getFromCache(local.queryShellKey, "sql");
			if (!IsArray(local.sql)) {
				local.sql = [];
				ArrayAppend(
					local.sql,
					$selectClause(
						select = arguments.select,
						include = arguments.include,
						includeSoftDeletes = arguments.includeSoftDeletes,
						returnAs = arguments.returnAs
					)
				);
				ArrayAppend(
					local.sql,
					$fromClause(
						include = arguments.include,
						includeSoftDeletes = arguments.includeSoftDeletes,
						useIndex = arguments.useIndex
					)
				);
				local.sql = $addWhereClause(
					sql = local.sql,
					where = local.originalWhere,
					include = arguments.include,
					includeSoftDeletes = arguments.includeSoftDeletes
				);
				local.groupBy = $groupByClause(
					select = arguments.select,
					group = arguments.group,
					include = arguments.include,
					distinct = arguments.distinct,
					returnAs = arguments.returnAs
				);
				if (Len(local.groupBy)) {
					ArrayAppend(local.sql, local.groupBy);
				}
				local.orderBy = $orderByClause(order = arguments.order, include = arguments.include);
				if (Len(local.orderBy)) {
					ArrayAppend(local.sql, local.orderBy);
				}
				local.lockName = "findAllSQLLock" & application.applicationName;
				local.executeArgs = {key = local.queryShellKey, value = local.sql, category = "sql"};
				$simpleLock(
					name = local.lockName,
					type = "exclusive",
					execute = "$addToCache",
					executeArgs = local.executeArgs,
					timeout = 10
				);
			}

			// add where clause parameters to the generic sql info
			local.sql = $addWhereClauseParameters(
				sql = local.sql,
				where = local.originalWhere,
				parameterize = arguments.parameterize
			);

			// Create a struct in the request scope to store cached queries.
			if (!StructKeyExists(request.wheels, variables.wheels.class.modelName)) {
				request.wheels[variables.wheels.class.modelName] = {};
			}

			// return existing query result if it has been run already in current request, otherwise pass off the sql array to the query
			local.queryKey = $hashedKey(variables.wheels.class.modelName, arguments, local.originalWhere);
			if (
				application.wheels.cacheQueriesDuringRequest
				&& !arguments.reload
				&& StructKeyExists(request.wheels[variables.wheels.class.modelName], local.queryKey)
			) {
				local.findAll = request.wheels[variables.wheels.class.modelName][local.queryKey];
			} else {
				local.finderArgs = {};
				local.finderArgs.sql = local.sql;
				local.finderArgs.maxRows = arguments.maxRows;
				local.finderArgs.parameterize = arguments.parameterize;
				if (!arguments.$limit) {
					arguments.$debugName = Replace(arguments.$debugName, "PaginationIds", "PaginationData");
				}
				local.finderArgs.$debugName = arguments.$debugName;
				local.finderArgs.limit = arguments.$limit;
				local.finderArgs.offset = arguments.$offset;
				local.finderArgs.$primaryKey = primaryKeys();
				local.finderArgs.dataSource = arguments.dataSource;
				if (
					application.wheels.cacheQueries && (IsNumeric(arguments.cache) || (IsBoolean(arguments.cache) && arguments.cache))
				) {
					local.finderArgs.cachedWithin = $timeSpanForCache(arguments.cache);
				}
				// optional arguments
				for (local.argumentName in ["returnType","keyColumn"]) {
					if (StructKeyExists(arguments, local.argumentName)) {
						local.finderArgs[local.argumentName] = arguments[local.argumentName];
					}
				}
				local.findAll = variables.wheels.class.adapter.$querySetup(argumentCollection = local.finderArgs);
				request.wheels[variables.wheels.class.modelName][local.queryKey] = local.findAll; // <- store in request cache so we never run the exact same query twice in the same request
			}

			// return using the native cfml query returntype if the argument is present
			if (StructKeyExists(arguments, "returnType")) {
				return local.findAll.query;
			}

			switch (arguments.returnAs) {
				case "sql":
					local.rv = local.findAll.result.sql;
					break;
				case "query":
					local.rv = local.findAll.query;
					// execute callbacks unless we're currently running the count or primary key pagination queries (we only want the callback to run when we have the actual data)
					if (local.rv.columnList != "wheelsqueryresult" && !arguments.$limit && !arguments.$offset) {
						$callback("afterFind", arguments.callbacks, local.rv);
					}
					break;
				case "struct":
				case "structs":
					local.rv = $serializeQueryToStructs(query = local.findAll.query, argumentCollection = arguments);
					break;
				case "array":
					local.rv = $serializeQueryToArray(query = local.findAll.query, argumentCollection = arguments);
					break;
				case "object":
				case "objects":
					local.rv = $serializeQueryToObjects(query = local.findAll.query, argumentCollection = arguments);
					break;
				default:
					if (application.wheels.showErrorInformation) {
						Throw(
							type = "Wheels.IncorrectArgumentValue",
							message = "Incorrect Arguments",
							extendedInfo = "The `returnAs` may be either `query`, `struct(s)`, `object(s)`, `array` or `sql`."
						);
					}
			}
		}
		return local.rv;
	}

	/**
	 * Fetches the requested record by primary key and returns it as an object.
	 * Returns `false` if no record is found.
	 * You can override this behavior to return a `cfquery` result set instead, similar to what's described in the documentation for `findOne()`.
	 *
	 * [section: Model Class]
	 * [category: Read Functions]
	 *
	 * @key Primary key value(s) of the record. Separate with comma if passing in multiple primary key values. Accepts a string, list, or a numeric value.
	 * @select [see:findAll].
	 * @include [see:findAll].
	 * @handle Handle to use for the query. This is used to set the name of the query in the debug output (which otherwise defaults to `userFindOneQuery` for example).
	 * @cache [see:findAll].
	 * @reload [see:findAll].
	 * @parameterize [see:findAll].
	 * @returnAs [see:findAll].
	 * @callbacks [see:findAll].
	 * @includeSoftDeletes [see:findAll].
	 * @dataSource [see:findAll].
	 */
	public any function findByKey(
		required any key,
		string select = "",
		string include = "",
		string handle = "query",
		any cache = "",
		boolean reload,
		any parameterize,
		string returnAs,
		boolean callbacks = "true",
		boolean includeSoftDeletes = "false",
		string dataSource = variables.wheels.class.dataSource
	) {
		$args(name = "findByKey", args = arguments);
		$setDebugName(name = "FindByKey", args = arguments);
		arguments.include = $listClean(arguments.include);
		if (Len(arguments.key)) {
			$keyLengthCheck(arguments.key);
		}

		// Convert primary key column name(s) / value(s) to a WHERE clause.
		arguments.where = $keyWhereString(values = arguments.key);
		StructDelete(arguments, "key");

		return findOne(argumentCollection = arguments);
	}

	/**
	 * Fetches the first record found based on the `WHERE` and `ORDER BY` clauses.
	 * With the default settings (i.e. the `returnAs` argument set to `object`), a model object will be returned if the record is found and the boolean value `false` if not.
	 * Instead of using the `where` argument, you can create cleaner code by making use of a concept called Dynamic Finders.
	 *
	 * [section: Model Class]
	 * [category: Read Functions]
	 *
	 * @where [see:findAll].
	 * @order [see:findAll].
	 * @select [see:findAll].
	 * @include [see:findAll].
	 * @handle [see:findByKey].
	 * @cache [see:findAll].
	 * @reload [see:findAll].
	 * @parameterize [see:findAll].
	 * @returnAs [see:findAll].
	 * @includeSoftDeletes [see:findAll].
	 * @useIndex [see:findAll].
	 * @dataSource [see:findAll].
	 */
	public any function findOne(
		string where = "",
		string order = "",
		string select = "",
		string include = "",
		string handle = "query",
		any cache = "",
		boolean reload,
		any parameterize,
		string returnAs,
		boolean includeSoftDeletes = "false",
		struct useIndex = {},
		string dataSource = variables.wheels.class.dataSource
	) {
		$args(name = "findOne", args = arguments);
		$setDebugName(name = "findOne", args = arguments);
		arguments.include = $listClean(arguments.include);
		if (
			!Len(arguments.include)
			|| (
				StructKeyExists(variables.wheels.class.associations, arguments.include)
				&& variables.wheels.class.associations[arguments.include].type != "hasMany"
			)
		) {
			// No joins will be done or the join will be done to a single record so we can safely get just one record from the database.
			// Note that the check above can be improved to go through the entire include string and check if all associations are "single" (i.e. hasOne or belongsTo).
			arguments.maxRows = 1;
		} else {
			// since we're joining with associated tables (and not to just one record) we could potentially get duplicate records for one object and we work around this by using the pagination code which has this functionality built in
			arguments.page = 1;
			arguments.perPage = 1;
			arguments.count = 1;
		}
		local.rv = findAll(argumentCollection = arguments);
		if (IsArray(local.rv) && arguments.returnAs != 'array') {
			if (ArrayLen(local.rv)) {
				local.rv = local.rv[1];
			} else {
				local.rv = false;
			}
		}
		return local.rv;
	}

	/**
	 * Fetches the first record ordered by primary key value.
	 * Use the `property` argument to order by something else.
	 * Returns a model object.
	 *
	 * [section: Model Class]
	 * [category: Read Functions]
	 *
	 * @property Name of the property to order by. This argument is also aliased as `properties`.
	 */
	public any function findFirst(string property = "#primaryKey()#", string $sort = "ASC") {
		$args(args = arguments, name = "findFirst", combine = "property/properties");
		arguments.order = "";
		local.iEnd = ListLen(arguments.property);
		for (local.i = 1; local.i <= local.iEnd; local.i++) {
			local.item = ListGetAt(arguments.property, local.i);
			arguments.order = ListAppend(arguments.order, local.item & " " & arguments.$sort);
		}
		StructDelete(arguments, "property");
		StructDelete(arguments, "$sort");
		return findOne(argumentCollection = arguments);
	}

	/**
	 * Fetches the last record ordered by primary key value.
	 * Use the `property` argument to order by something else.
	 * Returns a model object. Formerly known as findLast.
	 *
	 * [section: Model Class]
	 * [category: Read Functions]
	 *
	 * @property [see:findFirst].
	 */
	public any function findLastOne(string property) {
		arguments.$sort = "DESC";
		return findFirst(argumentCollection = arguments);
	}

	/**
	 * Returns all primary key values in a list.
	 * In addition to `quoted` and `delimiter` you can pass in any argument that `findAll()` accepts.
	 *
	 * [section: Model Class]
	 * [category: Read Functions]
	 *
	 * @quoted Set to `true` to enclose each value in single-quotation marks.
	 * @delimiter The delimiter character to separate the list items with.
	 */
	public string function findAllKeys(boolean quoted = "false", string delimiter = ",") {
		local.quoted = arguments.quoted;
		StructDelete(arguments, "quoted");
		local.delimiter = arguments.delimiter;
		StructDelete(arguments, "delimiter");
		arguments.select = primaryKey();
		arguments.callbacks = false;
		local.query = findAll(argumentCollection = arguments);
    local.list = CreateObject("java", "java.lang.StringBuilder");
    for (local.i = 1; local.i <= local.query.recordCount; local.i++) {
      local.value = local.query[arguments.select][local.i];
      if (local.i > 1) {
        local.list.append(local.delimiter);
      }
      if (local.quoted) {
        local.list.append("'").append(local.value).append("'");
      } else {
        local.list.append(local.value);
      }
    }

    return local.list.toString();
	}

	/**
	 * Reloads the property values of this object from the database.
	 *
	 * [section: Model Object]
	 * [category: Miscellaneous Functions]
	 */
	public void function reload() {
		local.query = findByKey(key = key(), reload = true, returnAs = "query");
		local.properties = propertyNames();
		local.iEnd = ListLen(local.properties);
		for (local.i = 1; local.i <= local.iEnd; local.i++) {
			// Wrap in try / catch since Coldfusion has a problem with blank boolean values in the query.
			try {
				local.property = ListGetAt(local.properties, local.i);
				this[local.property] = local.query[local.property][1];
				if (isNumeric(this[local.property]) && !reFind("^0\d*$", this[local.property])) {
					if (this[local.property] <= 2147483647) {
						this[local.property] =  JavaCast("int", this[local.property]);
					} else if (this[local.property] <= 9223372036854775807) {
						this[local.property] = JavaCast("long", this[local.property]);
					}
				}
			} catch (any e) {
				this[local.property] = "";
			}
		}
	}

	/**
	 * Set what variable name to use for the query (shows in debugging output for example).
	 */
	public void function $setDebugName(required struct args) {
		if (!StructKeyExists(arguments.args, "$debugName")) {
			if (arguments.args.handle == "query") {
				arguments.args.$debugName = "#variables.wheels.class.modelName##arguments.name#Query";
			} else {
				arguments.args.$debugName = arguments.args.handle;
			}
			arguments.args.$debugName = Replace(Replace(arguments.args.$debugName, " ", "", "all"), ".", "", "all");
		}
	}
}
