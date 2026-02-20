component {
	/**
	 * Calculates the average value for a given property.
	 * Uses the SQL function `AVG`.
	 * If no records can be found to perform the calculation on you can use the `ifNull` argument to decide what should be returned.
	 *
	 * [section: Model Class]
	 * [category: Statistics Functions]
	 *
	 * @property Name of the property to calculate the average for.
	 * @where [see:findAll].
	 * @include [see:findAll].
	 * @distinct When `true`, `AVG` will be performed only on each unique instance of a value, regardless of how many times the value occurs.
	 * @parameterize [see:findAll].
	 * @ifNull The value returned if no records are found. Common usage is to set this to `0` to make sure a numeric value is always returned instead of a blank string.
	 * @includeSoftDeletes [see:findAll].
	 * @group [see:findAll].
	 */
	public any function average(
		required string property,
		string where = "",
		string include = "",
		boolean distinct,
		any parameterize,
		any ifNull,
		boolean includeSoftDeletes = "false",
		string group
	) {
		$args(name = "average", args = arguments);
		arguments.type = "AVG";
		if (StructKeyExists(arguments, "group")) {
			local.rv = $calculate(argumentCollection = arguments);
		} else {
			if (
				ListFindNoCase(
					"cf_sql_integer,cf_sql_bigint,cf_sql_smallint,cf_sql_tinyint",
					variables.wheels.class.properties[arguments.property].type
				)
			) {
				// This is an integer column so we get all the values from the database and do the calculation in ColdFusion since we can't run a query to get the average value without type casting it.
				local.values = findAll(
					select = arguments.property,
					where = arguments.where,
					include = arguments.include,
					parameterize = arguments.parameterize,
					includeSoftDeletes = arguments.includeSoftDeletes
				);
				local.list = CreateObject("java", "java.lang.StringBuilder");
    		for (local.i = 1; local.i <= local.values.recordCount; local.i++) {
					if(local.i > 1){
						local.list.append(",");
					}
					local.list.append(local.values[arguments.property][local.i]);
				}
				local.values = ListToArray(local.list.toString());
				local.rv = arguments.ifNull;
				if (!ArrayIsEmpty(local.values)) {
					if (arguments.distinct) {
						local.tempValues = {};
						local.iEnd = ArrayLen(local.values);
						for (local.i = 1; local.i <= local.iEnd; local.i++) {
							StructInsert(local.tempValues, local.values[local.i], local.values[local.i], true);
						}
						local.values = ListToArray(StructKeyList(local.tempValues));
					}
					local.rv = ArrayAvg(local.values);
				}
			} else {
				// When the column's type is a float or similar we can run an AVG type query since it will always return a value of the same type as the column.
				local.rv = $calculate(argumentCollection = arguments);

				// We convert the result to a string so that it is the same as what would happen if you calculate an average in ColdFusion code (like we do for integers in this function for example).
				local.rv = Javacast("string", local.rv);
			}
		}
		return local.rv;
	}

	/**
	 * Returns the number of rows that match the arguments (or all rows if no arguments are passed in).
	 * Uses the SQL function `COUNT`.
	 * If no records can be found to perform the calculation on, `0` is returned.
	 *
	 * [section: Model Class]
	 * [category: Statistics Functions]
	 *
	 * @where [see:findAll].
	 * @include [see:findAll].
	 * @reload [see:findAll].
	 * @parameterize [see:findAll].
	 * @includeSoftDeletes [see:findAll].
	 * @group [see:findAll].
	 */
	public any function count(
		string where = "",
		string include = "",
		any parameterize,
		boolean includeSoftDeletes = "false",
		string group
	) {
		$args(name = "count", args = arguments);
		arguments.type = "COUNT";
		arguments.property = ListFirst(primaryKey());
		if (Len(arguments.include)) {
			arguments.distinct = true;
		} else {
			arguments.distinct = false;
		}
		local.rv = $calculate(argumentCollection = arguments);
		if (!StructKeyExists(arguments, "group") && !IsNumeric(local.rv)) {
			local.rv = 0;
		}
		return local.rv;
	}

	/**
	 * Calculates the maximum value for a given property.
	 * Uses the SQL function `MAX`.
	 * If no records can be found to perform the calculation on you can use the `ifNull` argument to decide what should be returned.
	 *
	 * [section: Model Class]
	 * [category: Statistics Functions]
	 *
	 * @property Name of the property to get the highest value for (must be a property of a numeric data type).
	 * @where [see:findAll].
	 * @include [see:findAll].
	 * @parameterize[see:findAll].
	 * @ifNull [see:average].
	 * @includeSoftDeletes [see:findAll].
	 * @group [see:findAll].
	 */
	public any function maximum(
		required string property,
		string where = "",
		string include = "",
		any parameterize,
		any ifNull,
		boolean includeSoftDeletes = "false",
		string group
	) {
		$args(name = "maximum", args = arguments);
		arguments.type = "MAX";
		return $calculate(argumentCollection = arguments);
	}

	/**
	 * Calculates the minimum value for a given property.
	 * Uses the SQL function `MIN`.
	 * If no records can be found to perform the calculation on you can use the `ifNull` argument to decide what should be returned.
	 *
	 * [section: Model Class]
	 * [category: Statistics Functions]
	 *
	 * @property Name of the property to get the lowest value for (must be a property of a numeric data type).
	 * @where [see:findAll].
	 * @include [see:findAll].
	 * @parameterize [see:findAll].
	 * @ifNull [see:average].
	 * @includeSoftDeletes [see:findAll].
	 * @group [see:findAll].
	 */
	public any function minimum(
		required string property,
		string where = "",
		string include = "",
		any parameterize,
		any ifNull,
		boolean includeSoftDeletes = "false",
		string group
	) {
		$args(name = "minimum", args = arguments);
		arguments.type = "MIN";
		return $calculate(argumentCollection = arguments);
	}

	/**
	 * Calculates the sum of values for a given property.
	 * Uses the SQL function `SUM`.
	 * If no records can be found to perform the calculation on you can use the `ifNull` argument to decide what should be returned.
	 *
	 * [section: Model Class]
	 * [category: Statistics Functions]
	 *
	 * @property Name of the property to get the sum for (must be a property of a numeric data type).
	 * @where [see:findAll].
	 * @include [see:findAll].
	 * @distinct When true, SUM returns the sum of unique values only.
	 * @parameterize [see:findAll].
	 * @ifNull [see:average].
	 * @includeSoftDeletes [see:findAll].
	 * @group [see:findAll].
	 */
	public any function sum(
		required string property,
		string where = "",
		string include = "",
		boolean distinct,
		any parameterize,
		any ifNull,
		boolean includeSoftDeletes = "false",
		string group
	) {
		$args(name = "sum", args = arguments);
		arguments.type = "SUM";
		return $calculate(argumentCollection = arguments);
	}

	/**
	 * Called from the functions above to perform the query and return the result.
	 */
	public any function $calculate(
		required string type,
		required string property,
		required string where,
		required string include,
		required any parameterize,
		boolean distinct = "false",
		any ifNull = "",
		required boolean includeSoftDeletes,
		string group
	) {
		// Start the select string with the type (SUM, COUNT etc).
		arguments.select = "#arguments.type#(";

		// add the DISTINCT keyword if necessary (generally used for COUNT operations when associated tables are joined in the query, means we'll only count the unique primary keys on the current model).
		if (arguments.distinct) {
			arguments.select &= "DISTINCT ";
		}

		// Create a list of columns for the SELECT clause either from regular properties on the model or calculated ones.
		local.properties = "";
		local.iEnd = ListLen(arguments.property);
		for (local.i = 1; local.i <= local.iEnd; local.i++) {
			local.item = Trim(ListGetAt(arguments.property, local.i));
			if (StructKeyExists(variables.wheels.class.propertyStruct, local.item)) {
				local.properties = ListAppend(
					local.properties,
					$quotedTableName() & "." & $quoteColumn(variables.wheels.class.properties[local.item].column)
				);
			} else if (StructKeyExists(variables.wheels.class.calculatedProperties, local.item)) {
				local.properties = ListAppend(local.properties, variables.wheels.class.calculatedProperties[local.item].sql);
			}
		}
		arguments.select &= local.properties;

		// Alias the result with AS, this means that Wheels will not try and change the string (which is why we have to add the table name above since it won't be done automatically).
		local.alias = LCase(arguments.type);
		local.alias = Replace(Replace(Replace(local.alias, "avg", "average"), "min", "minimum"), "max", "maximum");
		if (arguments.type != "count") {
			local.alias = arguments.property & local.alias;
		}
		arguments.select &= ") AS " & local.alias;

		if (StructKeyExists(arguments, "group")) {
			arguments.select = ListAppend(
				arguments.select,
				$createSQLFieldList(
					clause = "select",
					list = arguments.group,
					include = arguments.include,
					includeSoftDeletes = arguments.includeSoftDeletes,
					returnAs = "query"
				)
			);
		}

		// Call findAll with select, where, group, parameterize and include but delete all other arguments.
		StructDelete(arguments, "type");
		StructDelete(arguments, "property");
		StructDelete(arguments, "distinct");

		// Since we don't return any records for calculation methods we want to skip the callbacks.
		arguments.callbacks = false;

		local.rv = findAll(argumentCollection = arguments);

		// If not grouping by something we just return the value itself.
		if (!StructKeyExists(arguments, "group")) {
			local.rv = local.rv[local.alias];
			if (!Len(local.rv) && Len(arguments.ifNull)) {
				local.rv = arguments.ifNull;
			}
		}

		return local.rv;
	}
}
