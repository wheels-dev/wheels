component {
	/**
	 * Deletes all queries stored during the request for this model.
	 */
	public void function $clearRequestCache() {
		request.wheels[variables.wheels.class.modelName] = {};
	}

	/**
	 * Use this method to override the data source connection information for this model.
	 *
	 * [section: Model Configuration]
	 * [category: Miscellaneous Functions]
	 *
	 * @datasource The data source name to connect to.
	 * @username The username for the data source.
	 * @password The password for the data source.
	 */
	public void function dataSource(required string datasource, string username = "", string password = "") {
		variables.wheels.class.datasource = arguments.datasource;
		variables.wheels.class.username = arguments.username;
		variables.wheels.class.password = arguments.password;
	}

	/**
	 * Use this method to tell CFWheels what database table to connect to for this model.
	 * You only need to use this method when your table naming does not follow the standard CFWheels convention of a singular object name mapping to a plural table name.
	 * To not use a table for your model at all, call `table(false)`.
	 *
	 * [section: Model Configuration]
	 * [category: Miscellaneous Functions]
	 *
	 * @name Name of the table to map this model to.
	 */
	public void function table(required any name) {
		variables.wheels.class.tableName = arguments.name;
	}

	/**
	 * Sets a prefix to prepend to the table name when this model runs SQL queries.
	 *
	 * [section: Model Configuration]
	 * [category: Miscellaneous Functions]
	 *
	 * @prefix A prefix to prepend to the table name.
	 */
	public void function setTableNamePrefix(required string prefix) {
		variables.wheels.class.tableNamePrefix = arguments.prefix;
	}

	/**
	 * Allows you to pass in the name(s) of the property(s) that should be used as the primary key(s).
	 * Pass as a list if defining a composite primary key.
	 * This function is also aliased as `setPrimaryKeys()`.
	 *
	 * [section: Model Configuration]
	 * [category: Miscellaneous Functions]
	 *
	 * @property Property (or list of properties) to set as the primary key.
	 */
	public void function setPrimaryKey(required string property) {
		local.iEnd = ListLen(arguments.property);
		for (local.i = 1; local.i <= local.iEnd; local.i++) {
			local.item = ListGetAt(arguments.property, local.i);
			if (!ListFindNoCase(variables.wheels.class.keys, local.item)) {
				variables.wheels.class.keys = ListAppend(variables.wheels.class.keys, local.item);
			}
		}
	}

	/**
	 * Alias for `setPrimaryKey()`.
	 * Use this for better readability when you're setting multiple properties as the primary key.
	 *
	 * [section: Model Configuration]
	 * [category: Miscellaneous Functions]
	 *
	 * @property [see:setPrimaryKey].
	 */
	public void function setPrimaryKeys(required string property) {
		setPrimaryKey(argumentCollection = arguments);
	}

	/**
	 * Checks if a record exists in the table.
	 * You can pass in either a primary key value to the `key` argument or a string to the `where` argument.
	 * If you don't pass in either of those, it will simply check if any record exists in the table.
	 *
	 * [section: Model Class]
	 * [category: Miscellaneous Functions]
	 *
	 * @key Primary key value(s) of the record. Separate with comma if passing in multiple primary key values. Accepts a string, list, or a numeric value.
	 * @where [see:findAll].
	 * @reload [see:findAll].
	 * @parameterize [see:findAll].
	 * @includeSoftDeletes [see:findAll].
	 */
	public boolean function exists(any key, string where, boolean reload, any parameterize, boolean includeSoftDeletes) {
		$args(name = "exists", args = arguments);
		if ($get("showErrorInformation") && StructKeyExists(arguments, "key") && StructKeyExists(arguments, "where")) {
			Throw(type = "Wheels.IncorrectArguments", message = "You cannot pass in both `key` and `where`.");
		}
		arguments.select = primaryKey();
		arguments.returnAs = "query";
		arguments.callbacks = false;
		if (StructKeyExists(arguments, "key")) {
			// BoxLang compatibility: Handle null key values
			if (StructKeyExists(server, "boxlang") && (!StructKeyExists(arguments, "key") || arguments.key == "" || arguments.key == "null" || !Len(arguments.key))) {
				local.rv = 0;
			} else {
				local.result = findByKey(argumentCollection = arguments);
				// BoxLang compatibility: Handle case where findByKey returns boolean false for null keys  
				if (StructKeyExists(server, "boxlang") && IsBoolean(local.result)) {
					local.rv = 0;
				} else {
					local.rv = local.result.recordCount;
				}
			}
		} else {
			local.result = findOne(argumentCollection = arguments);
			// BoxLang compatibility: Handle case where findOne returns boolean false
			if (StructKeyExists(server, "boxlang") && IsBoolean(local.result)) {
				local.rv = 0;
			} else {
				local.rv = local.result.recordCount;
			}
		}
		return local.rv;
	}

	/**
	 * Returns a list of column names in the table mapped to this model.
	 * The list is ordered according to the columns' ordinal positions in the database table.
	 *
	 * [section: Model Class]
	 * [category: Miscellaneous Functions]
	 */
	public string function columnNames() {
		return variables.wheels.class.columnList;
	}

	/**
	 * Returns the name of the primary key for this model's table.
	 * This is determined through database introspection.
	 * If composite primary keys have been used, they will both be returned in a list.
	 * This function is also aliased as `primaryKeys()`.
	 *
	 * [section: Model Class]
	 * [category: Miscellaneous Functions]
	 *
	 * @position If you are accessing a composite primary key, pass the position of a single key to fetch.
	 */
	public string function primaryKey(numeric position = 0) {
		if (arguments.position > 0) {
			return ListGetAt(variables.wheels.class.keys, arguments.position);
		} else {
			return variables.wheels.class.keys;
		}
	}

	/**
	 * Alias for `primaryKey()`.
	 * Use this for better readability when you're accessing multiple primary keys.
	 *
	 * [section: Model Class]
	 * [category: Miscellaneous Functions]
	 *
	 * @position [see:primaryKey].
	 */
	public string function primaryKeys(numeric position = 0) {
		return primaryKey(argumentCollection = arguments);
	}

	/**
	 * Returns the name of the database table that this model is mapped to.
	 *
	 * [section: Model Class]
	 * [category: Miscellaneous Functions]
	 */
	public string function tableName() {
		if ($get("lowerCaseTableNames")) {
			return LCase(variables.wheels.class.tableName);
		} else {
			return variables.wheels.class.tableName;
		}
	}

	/**
	 * Returns the table name prefix set for the table.
	 *
	 * [section: Model Class]
	 * [category: Miscellaneous Functions]
	 */
	public string function getTableNamePrefix() {
		return variables.wheels.class.tableNamePrefix;
	}

	/**
	 * Use this method to check whether you are currently in a class-level object.
	 *
	 * [section: Model Class]
	 * [category: Miscellaneous Functions]
	 */
	public string function isClass() {
		return !isInstance(argumentCollection = arguments);
	}

	/**
	 * Returns `true` if this object hasn't been saved yet (in other words, no matching record exists in the database yet).
	 * Returns `false` if a record exists.
	 *
	 * [section: Model Object]
	 * [category: Miscellaneous Functions]
	 */
	public boolean function isNew() {
		// The object is new when no values have been persisted to the database.
		if (!StructKeyExists(variables, "$persistedProperties")) {
			return true;
		} else {
			return false;
		}
	}

	/**
	 * Returns `true` if this object has been persisted to the database or was loaded from the database via a finder.
	 * Returns `false` if the record has not been persisted to the database.
	 *
	 * [section: Model Object]
	 * [category: Miscellaneous Functions]
	 */
	public boolean function isPersisted() {
		return !this.isNew();
	}

	/**
	 * Pass in another model object to see if the two objects are the same.
	 *
	 * [section: Model Object]
	 * [category: Miscellaneous Functions]
	 */
	public boolean function compareTo(required component object) {
		return Compare(this.$objectId(), arguments.object.$objectId()) IS 0;
	}

	/**
	 * Use this method to check whether you are currently in an instance object.
	 *
	 * [section: Model Class]
	 * [category: Miscellaneous Functions]
	 */
	public boolean function isInstance() {
		return StructKeyExists(variables.wheels, "instance");
	}

	/**
	 * Internal function.
	 */
	public string function $objectId() {
		return variables.wheels.tickCountId;
	}

	/**
	 * Internal function.
	 */
	public struct function $buildQueryParamValues(required string property) {
		local.rv = {};
		local.rv.value = this[arguments.property];
		local.rv.type = variables.wheels.class.properties[arguments.property].type;
		local.rv.dataType = variables.wheels.class.properties[arguments.property].dataType;
		local.rv.scale = variables.wheels.class.properties[arguments.property].scale;
		local.rv.null = (!Len(this[arguments.property]) && variables.wheels.class.properties[arguments.property].nullable);

		// BoxLang/JDK compatibility: Convert date strings to proper date for datetime types
		if (structKeyExists(server, "boxlang") && (Len(local.rv.value) && !local.rv.null && 
		    (local.rv.type == "CF_SQL_DATE" || local.rv.type == "CF_SQL_TIME" || local.rv.type == "CF_SQL_TIMESTAMP") &&
		    IsSimpleValue(local.rv.value) && !IsDate(local.rv.value))) {

			// Handle DD/MM/YYYY and DD-MM-YYYY formats common in European locales
			if (REFind("^\d{1,2}[\/\-]\d{1,2}[\/\-]\d{4}$", local.rv.value)) {
				local.parts = ListToArray(local.rv.value, "/-");
				if (ArrayLen(local.parts) == 3 && IsNumeric(local.parts[1]) && IsNumeric(local.parts[2]) && IsNumeric(local.parts[3])) {
					try {
						local.rv.value = CreateDate(local.parts[3], local.parts[2], local.parts[1]);
					} catch (any e) {
						local.rv.value = CreateDate(local.parts[3], local.parts[1], local.parts[2]);
					}
				}
			}
		}
		
		if(local.rv.datatype eq 'geography'){
			local.sqlQuery = "select type from geography_columns where f_table_name = '#tableName()#' and f_geography_column = '#arguments.property#'";
			local.result = queryExecute(local.sqlQuery,[],{datasource: "#variables.wheels.class.datasource#"});
			if(local.result.type eq 'point'){
				local.rv.value = 'POINT(#this[arguments.property]#)';
			}
			else if(local.result.type eq 'linestring'){
				local.rv.value = 'LINESTRING(#this[arguments.property]#)';
			}
			else if(local.result.type eq 'polygon'){
				local.rv.value = 'POLYGON(#this[arguments.property]#)';
			}
			else if(local.result.type eq 'multipoint'){
				local.rv.value = 'MULTIPOINT(#this[arguments.property]#)';
			}
			else if(local.result.type eq 'multilinestring'){
				local.rv.value = 'MULTILINESTRING(#this[arguments.property]#)';
			}
			else if(local.result.type eq 'multipolygon'){
				local.rv.value = 'MULTIPOLYGON(#this[arguments.property]#)';
			}
			else if(local.result.type eq 'geometrycollection'){
				local.rv.value = 'GEOMETRYCOLLECTION(#this[arguments.property]#)';
			}
			local.rv.column = arguments.property;
			local.rv.table = tableName();
		}
		return local.rv;
	}

	/**
	 * Internal function.
	 */
	public void function $keyLengthCheck(required any key) {
		// throw error if the number of keys passed in is not the same as the number of keys defined for the model
		if (ListLen(primaryKeys()) != ListLen(arguments.key)) {
			Throw(
				type = "Wheels.InvalidArgumentValue",
				message = "The `key` argument contains an invalid value.",
				extendedInfo = "The `key` argument contains a list, however this table doesn't have a composite key. A list of values is allowed for the `key` argument, but this only applies in the case when the table contains a composite key."
			);
		}
	}

	/**
	 * Internal function.
	 */
	public void function $timestampProperty(required string property) {
		this[arguments.property] = $timestamp(variables.wheels.class.timeStampMode);
	}
}
