component {
	/**
	 * Use this method to specify which properties can be set through mass assignment.
	 *
	 * [section: Model Configuration]
	 * [category: Miscellaneous Functions]
	 *
	 * @properties Property name (or list of property names) that are allowed to be altered through mass assignment.
	 */
	public void function accessibleProperties(string properties = "") {
		if (StructKeyExists(arguments, "property")) {
			arguments.properties = ListAppend(arguments.properties, arguments.property);
		}

		// see if any associations should be included in the white list
		for (local.association in variables.wheels.class.associations) {
			if (variables.wheels.class.associations[local.association].nested.allow) {
				arguments.properties = ListAppend(arguments.properties, local.association);
			}
		}
		variables.wheels.class.accessibleProperties.whiteList = $listToStruct(arguments.properties);
	}

	/**
	 * Use this method to specify which properties cannot be set through mass assignment.
	 *
	 * [section: Model Configuration]
	 * [category: Miscellaneous Functions]
	 *
	 * @properties Property name (or list of property names) that are not allowed to be altered through mass assignment.
	 */
	public void function protectedProperties(string properties = "") {
		if (StructKeyExists(arguments, "property")) {
			arguments.properties = ListAppend(arguments.properties, arguments.property);
		}
		variables.wheels.class.accessibleProperties.blackList = $listToStruct(arguments.properties);
	}

	/**
	 * Use this method to specify which columns cannot be used by the wheels ORM.
	 *
	 * [section: Model Configuration]
	 * [category: Miscellaneous Functions]
	 *
	 * @columns Array of columns names that will be ignored.
	 */
	public void function ignoredColumns(array columns = []) {
		local.rv = {};
		for (local.column in arguments.columns) {
			local.rv[local.column] = 1;
		}
		variables.wheels.class.ignoredColumns = local.rv;
	}

	/**
	 * Use this method to map an object property to either a table column with a different name than the property or to a SQL expression.
	 * You only need to use this method when you want to override the default object relational mapping that Wheels performs.
	 *
	 * [section: Model Configuration]
	 * [category: Miscellaneous Functions]
	 *
	 * @name The name that you want to use for the column or SQL function result in the CFML code.
	 * @column The name of the column in the database table to map the property to.
	 * @sql An SQL expression to use to calculate the property value.
	 * @label A custom label for this property to be referenced in the interface and error messages.
	 * @defaultValue A default value for this property.
	 * @select Whether to include this property by default in SELECT statements
	 * @dataType Specify the column dataType for this property
	 * @automaticValidations Enable / disable automatic validations for this property.
	 */
	public void function property(
		required string name,
		string column = "",
		string sql = "",
		string label = "",
		string defaultValue,
		boolean select = "true",
		string dataType = "char",
		boolean automaticValidations
	) {
		// validate setup
		if (Len(arguments.column) && Len(arguments.sql)) {
			Throw(
				type = "Wheels",
				message = "Incorrect Arguments",
				extendedInfo = "You cannot specify both a column and a sql statement when setting up the mapping for this property."
			);
		}
		if (Len(arguments.sql) && StructKeyExists(arguments, "defaultValue")) {
			Throw(
				type = "Wheels",
				message = "Incorrect Arguments",
				extendedInfo = "You cannot specify a default value for calculated properties."
			);
		}

		// create the key
		if (!StructKeyExists(variables.wheels.class.mapping, arguments.name)) {
			variables.wheels.class.mapping[arguments.name] = {};
		}

		if (Len(arguments.column)) {
			variables.wheels.class.mapping[arguments.name].type = "column";
			variables.wheels.class.mapping[arguments.name].value = arguments.column;
		}
		if (Len(arguments.sql)) {
			$validateCalculatedPropertySql(sql=arguments.sql, propertyName=arguments.name);
			variables.wheels.class.mapping[arguments.name].type = "sql";
			variables.wheels.class.mapping[arguments.name].value = arguments.sql;
			variables.wheels.class.mapping[arguments.name].select = arguments.select;
			variables.wheels.class.mapping[arguments.name].dataType = arguments.dataType;
		}
		if (Len(arguments.label)) {
			variables.wheels.class.mapping[arguments.name].label = arguments.label;
		}
		if (StructKeyExists(arguments, "defaultValue")) {
			variables.wheels.class.mapping[arguments.name].defaultValue = arguments.defaultValue;
		}
		if (StructKeyExists(arguments, "automaticValidations")) {
			variables.wheels.class.mapping[arguments.name].automaticValidations = arguments.automaticValidations;
		}
	}

	/**
	 * Returns a list of property names ordered by their respective column's ordinal position in the database table.
	 * Also includes calculated property names that will be generated by the Wheels ORM.
	 *
	 * [section: Model Class]
	 * [category: Miscellaneous Functions]
	 */
	public string function propertyNames() {
		local.rv = variables.wheels.class.propertyList;
		if (ListLen(variables.wheels.class.calculatedPropertyList)) {
			local.rv = ListAppend(local.rv, variables.wheels.class.calculatedPropertyList);
		}
		return local.rv;
	}

	/**
	 * Returns an array of columns names for the table associated with this class.
	 * Does not include calculated properties that will be generated by the Wheels ORM.
	 *
	 * [section: Model Class]
	 * [category: Miscellaneous Functions]
	 */
	public array function columns() {
		return ListToArray(variables.wheels.class.columnList);
	}

	/**
	 * Returns the column name mapped for the named model property.
	 *
	 * [section: Model Class]
	 * [category: Miscellaneous Functions]
	 *
	 * @property Name of property to inspect.
	 */
	public any function columnForProperty(required string property) {
		if (StructKeyExists(variables.wheels.class.properties, arguments.property)) {
			return variables.wheels.class.properties[arguments.property].column;
		} else {
			return false;
		}
	}

	/**
	 * Returns a struct with data for the named property.
	 *
	 * [section: Model Class]
	 * [category: Miscellaneous Functions]
	 *
	 * @property Name of property to inspect.
	 */
	public any function columnDataForProperty(required string property) {
		if (StructKeyExists(variables.wheels.class.properties, arguments.property)) {
			return variables.wheels.class.properties[arguments.property];
		} else {
			return false;
		}
	}

	/**
	 * Returns the validation type for the property.
	 *
	 * [section: Model Class]
	 * [category: Miscellaneous Functions]
	 *
	 * @property Name of column to retrieve data for.
	 */
	public any function validationTypeForProperty(required string property) {
		if (StructKeyExists(variables.wheels.class.properties, arguments.property)) {
			return variables.wheels.class.properties[arguments.property].validationtype;
		} else {
			return "string";
		}
	}

	/**
	 * Returns the value of the primary key for the object.
	 * If you have a single primary key named id, then `someObject.key()` is functionally equivalent to `someObject.id`.
	 * This method is more useful when you do dynamic programming and don't know the name of the primary key or when you use composite keys (in which case it's convenient to use this method to get a list of both key values returned).
	 *
	 * [section: Model Object]
	 * [category: Miscellaneous Functions]
	 */
	public string function key(boolean $persisted = false, boolean $returnTickCountWhenNew = false) {
		local.rv = "";
		local.iEnd = ListLen(primaryKeys());
		for (local.i = 1; local.i <= local.iEnd; local.i++) {
			local.property = primaryKeys(local.i);
			if (StructKeyExists(this, local.property)) {
				if (arguments.$persisted && hasChanged(local.property)) {
					local.rv = ListAppend(local.rv, changedFrom(local.property));
				} else {
					local.rv = ListAppend(local.rv, this[local.property]);
				}
			}
		}
		if (!Len(local.rv) && arguments.$returnTickCountWhenNew) {
			local.rv = variables.wheels.tickCountId;
		}

		/* To fix the bug below:
			https://github.com/wheels-dev/wheels/issues/1029

			This will return a numeric value if the primary key is Numeric and a String otherwise.
		*/
		if (isNumeric(local.rv) && !reFind("^0\d*$", local.rv) && !Find(",", local.rv)) {
			if (local.rv <= 2147483647) {
				return JavaCast("int", local.rv);
			} else if (local.rv <= 9223372036854775807) {
				return JavaCast("long", local.rv);
			} else {
				return local.rv;
			}
		} else {
			return local.rv;
		}
	}

	/**
	 * Returns `true` if the specified property name exists on the model.
	 *
	 * [section: Model Object]
	 * [category: Miscellaneous Functions]
	 *
	 * @property Name of property to inspect.
	 */
	public boolean function hasProperty(required string property) {
		if (StructKeyExists(this, arguments.property) && !IsCustomFunction(this[arguments.property])) {
			return true;
		} else {
			return false;
		}
	}

	/**
	 * Returns `true` if the specified property exists on the model and is not a blank string.
	 *
	 * [section: Model Object]
	 * [category: Miscellaneous Functions]
	 *
	 * @property Name of property to inspect.
	 */
	public boolean function propertyIsPresent(required string property) {
		if (this.hasProperty(arguments.property) && IsSimpleValue(this[arguments.property]) && Len(this[arguments.property])) {
			return true;
		} else {
			return false;
		}
	}

	/**
	 * Returns `true` if the specified property doesn't exist on the model or is an empty string.
	 * This method is the inverse of `propertyIsPresent()`.
	 *
	 * [section: Model Object]
	 * [category: Miscellaneous Functions]
	 *
	 * @property Name of property to inspect.
	 */
	public boolean function propertyIsBlank(required string property) {
		return !this.propertyIsPresent(arguments.property);
	}

	/**
	 * Assigns to the property specified the opposite of the property's current boolean value.
	 * Throws an error if the property cannot be converted to a boolean value.
	 * Returns this object if save called internally is `false`.
	 *
	 * [section: Model Object]
	 * [category: CRUD Functions]
	 *
	 * @save Argument to decide whether save the property after it has been toggled.
	 */
	public boolean function toggle(required string property, boolean save) {
		$args(name = "toggle", args = arguments);
		if (!StructKeyExists(this, arguments.property)) {
			Throw(
				type = "Wheels.PropertyDoesNotExist",
				message = "Property Does Not Exist",
				extendedInfo = "You may only toggle a property that exists on this model."
			);
		}
		if (!IsBoolean(this[arguments.property])) {
			Throw(
				type = "Wheels.PropertyIsIncorrectType",
				message = "Incorrect Arguments",
				extendedInfo = "You may only toggle a property that evaluates to the boolean value."
			);
		}
		this[arguments.property] = !this[arguments.property];
		local.rv = true;
		if (arguments.save) {
			local.rv = updateProperty(property = arguments.property, value = this[arguments.property]);
		}
		return local.rv;
	}

	/**
	 * Returns a structure of all the properties with their names as keys and the values of the property as values.
	 *
	 * [section: Model Object]
	 * [category: Miscellaneous Functions]
	 *
	 * @returnIncluded Whether to return nested properties or not.
	 */
	public struct function properties(boolean returnIncluded = true) {
		local.rv = {};
		local.propNames = propertyNames();
		// loop through all properties and functions in the this scope
		for (local.key in this) {
			// don't return nested properties if returnIncluded is false
			if (!arguments.returnIncluded && !IsSimpleValue(this[local.key])) {
				continue;
			}
			// don't return functions
			if (IsCustomFunction(this[local.key])) {
				continue;
			}
			if ($get("resetPropertiesStructKeyCase")) {
				// try to get the property name from the list set on the object, this is just to avoid returning everything in ugly upper case which Adobe ColdFusion does by default
				local.listPosition = ListFindNoCase(local.propNames, local.key);
				if (local.listPosition) {
					local.key = ListGetAt(local.propNames, local.listPosition);
				}
			}
			// set property from the this scope in the struct that we will return
			local.rv[local.key] = this[local.key];
		}
		return local.rv;
	}

	/**
	 * Allows you to set all the properties of an object at once by passing in a structure with keys matching the property names.
	 *
	 * [section: Model Object]
	 * [category: Miscellaneous Functions]
	 *
	 * @properties The properties you want to set on the object (can also be passed in as named arguments).
	 */
	public void function setProperties(struct properties = {}) {
		$setProperties(argumentCollection = arguments);
	}

	/**
	 * Returns `true` if the specified property (or any if none was passed in) has been changed but not yet saved to the database.
	 * Will also return `true` if the object is new and no record for it exists in the database.
	 *
	 * [section: Model Object]
	 * [category: Change Functions]
	 *
	 * @property Name of property to check for change.
	 */
	public boolean function hasChanged(string property = "") {
		// always return true if $persistedProperties does not exists
		if (!StructKeyExists(variables, "$persistedProperties")) {
			return true;
		}

		if (!Len(arguments.property)) {
			// they haven't specified a particular property so loop through them all
			arguments.property = StructKeyList(variables.wheels.class.properties);
		}
		arguments.property = ListToArray(arguments.property);
		local.iEnd = ArrayLen(arguments.property);
		for (local.i = 1; local.i <= local.iEnd; local.i++) {
			local.key = arguments.property[local.i];
			if (StructKeyExists(this, local.key)) {
				if (!StructKeyExists(variables.$persistedProperties, local.key)) {
					return true;
				} else {
					// convert each datatype to a string for easier comparison
					local.type = validationTypeForProperty(local.key);
					local.a = $convertToString(this[local.key], local.type);
					local.b = $convertToString(variables.$persistedProperties[local.key], local.type);
					if (Compare(local.a, local.b) != 0) {
						return true;
					}
				}
			}
		}
		// if we get here, it means that all of the properties that were checked had a value in
		// $persistedProperties and it matched or some of the properties did not exist in the this scope
		return false;
	}

	/**
	 * Returns a list of the object properties that have been changed but not yet saved to the database.
	 *
	 * [section: Model Object]
	 * [category: Change Functions]
	 */
	public string function changedProperties() {
		local.rv = "";
		for (local.key in variables.wheels.class.properties) {
			if (hasChanged(local.key)) {
				local.rv = ListAppend(local.rv, local.key);
			}
		}
		return local.rv;
	}

	/**
	 * Returns the previous value of a property that has changed.
	 * Returns an empty string if no previous value exists.
	 * Wheels will keep a note of the previous property value until the object is saved to the database.
	 *
	 * [section: Model Object]
	 * [category: Change Functions]
	 *
	 * @property Name of property to get the previous value for.
	 */
	public string function changedFrom(required string property) {
		if (
			StructKeyExists(variables, "$persistedProperties")
			&& StructKeyExists(variables.$persistedProperties, arguments.property)
		) {
			return variables.$persistedProperties[arguments.property];
		} else {
			return "";
		}
	}

	/**
	 * Returns a struct detailing all changes that have been made on the object but not yet saved to the database.
	 *
	 * [section: Model Object]
	 * [category: Change Functions]
	 */
	public struct function allChanges() {
		local.rv = {};
		if (hasChanged()) {
			local.changedProperties = changedProperties();
			local.iEnd = ListLen(local.changedProperties);
			for (local.i = 1; local.i <= local.iEnd; local.i++) {
				local.item = ListGetAt(local.changedProperties, local.i);
				local.rv[local.item] = {};
				local.rv[local.item].changedFrom = changedFrom(local.item);
				if (StructKeyExists(this, local.item)) {
					local.rv[local.item].changedTo = this[local.item];
				} else {
					local.rv[local.item].changedTo = "";
				}
			}
		}
		return local.rv;
	}

	/**
	 * Clears all internal knowledge of the current state of the object.
	 *
	 * [section: Model Object]
	 * [category: Change Functions]
	 *
	 * @property string false Name of property to clear information for.
	 */
	public void function clearChangeInformation(string property) {
		$updatePersistedProperties(argumentCollection = arguments);
	}

	/**
	 * Internal function.
	 */
	public any function $setProperties(
		required struct properties,
		string filterList = "",
		boolean setOnModel = "true",
		boolean $useFilterLists = "true"
	) {
		local.rv = {};
		arguments.filterList = ListAppend(arguments.filterList, "properties,filterList,setOnModel,$useFilterLists");

		// add eventual named arguments to properties struct (named arguments will take precedence)
		for (local.key in arguments) {
			if (!ListFindNoCase(arguments.filterList, local.key)) {
				arguments.properties[local.key] = arguments[local.key];
			}
		}

		// loop through the properties and see if they can be set based off of the accessible properties lists
		for (local.key in arguments.properties) {
			// required to ignore null keys
			if (StructKeyExists(arguments.properties, local.key)) {
				local.accessible = true;
				if (
					arguments.$useFilterLists &&
					StructKeyExists(variables.wheels.class.accessibleProperties, "whiteList")
					&& !StructKeyExists(variables.wheels.class.accessibleProperties.whiteList, local.key)
				) {
					local.accessible = false;
				}
				if (
					arguments.$useFilterLists
					&& StructKeyExists(variables.wheels.class.accessibleProperties, "blackList")
					&& StructKeyExists(variables.wheels.class.accessibleProperties.blackList, local.key)
				) {
					local.accessible = false;
				}
				if (local.accessible) {
					local.rv[local.key] = arguments.properties[local.key];
				}
				if (local.accessible && arguments.setOnModel) {
					$setProperty(property = local.key, value = local.rv[local.key]);
				}
			}
		}

		if (arguments.setOnModel) {
			return;
		}
		return local.rv;
	}

	/**
	 * Internal function.
	 */
	public void function $setProperty(
		required string property,
		required any value,
		struct associations = variables.wheels.class.associations
	) {
		if (IsObject(arguments.value)) {
			this[arguments.property] = $resolveObjectValue(arguments.value);
		} else if (
			IsStruct(arguments.value)
			&& StructKeyExists(arguments.associations, arguments.property)
			&& arguments.associations[arguments.property].nested.allow
			&& ListFindNoCase("belongsTo,hasOne", arguments.associations[arguments.property].type)
		) {
			$setOneToOneAssociationProperty(
				property = arguments.property,
				value = arguments.value,
				association = arguments.associations[arguments.property]
			);
		} else if (
			IsStruct(arguments.value)
			&& StructKeyExists(arguments.associations, arguments.property)
			&& arguments.associations[arguments.property].nested.allow
			&& arguments.associations[arguments.property].type == "hasMany"
		) {
			$setCollectionAssociationProperty(
				property = arguments.property,
				value = arguments.value,
				association = arguments.associations[arguments.property]
			);
		} else if (
			IsArray(arguments.value)
			&& ArrayLen(arguments.value)
			&& !IsObject(arguments.value[1])
			&& StructKeyExists(arguments.associations, arguments.property)
			&& arguments.associations[arguments.property].nested.allow
			&& arguments.associations[arguments.property].type == "hasMany"
		) {
			$setCollectionAssociationProperty(
				property = arguments.property,
				value = arguments.value,
				association = arguments.associations[arguments.property]
			);
		} else if (
			(IsStruct(arguments.value) || IsArray(arguments.value))
			&& StructKeyExists(variables.wheels.class, "properties")
			&& StructKeyExists(variables.wheels.class.properties, arguments.property)
			&& !(IsArray(arguments.value) && $propertyIsBinaryColumn(arguments.property))
		) {
			// Scoped to real DB columns; exempts array-on-binary so BoxLang / Lucee 6 byte uploads reach JDBC. See #2412, #2660.
			Throw(
				type = "Wheels.PropertyIsIncorrectType",
				message = "Cannot assign a #(IsArray(arguments.value) ? 'array' : 'struct')# value to scalar column `#arguments.property#` on the `#variables.wheels.class.modelName#` model.",
				extendedInfo = "Property `#arguments.property#` is a scalar database column, but `setProperties()` was called with a #(IsArray(arguments.value) ? 'array' : 'struct')# value for it. This usually means upstream form data arrived in an unexpected shape — most commonly a curl POST body using bracket-nested keys without an `=` separator (e.g. `user[email][nested@key]`), which Lucee's form parser turns into a nested-struct path so `params.user.email` ends up shaped like a struct instead of a string. If you actually want to accept structured data here, the property must be declared as an association with `hasOne`, `hasMany`, or `belongsTo` and have mass-assignment enabled via `nestedProperties()`."
			);
		} else {
			this[arguments.property] = arguments.value;
		}
	}

	/**
	 * Resolves an object value, converting Oracle JDBC objects via the engine adapter.
	 */
	public any function $resolveObjectValue(required any value) {
		return $engineAdapter().coerceOracleObject(arguments.value);
	}

	// Returns true when the named property maps to a binary DB column. See #2660.
	public boolean function $propertyIsBinaryColumn(required string property) {
		if (
			!StructKeyExists(variables.wheels.class, "properties")
			|| !StructKeyExists(variables.wheels.class.properties, arguments.property)
			|| !StructKeyExists(variables.wheels.class.properties[arguments.property], "validationtype")
		) {
			return false;
		}
		return variables.wheels.class.properties[arguments.property].validationtype == "binary";
	}

	/**
	 * Internal function.
	 */
	public void function $updatePersistedProperties(string property) {
		variables.$persistedProperties = {};
		for (local.key in variables.wheels.class.properties) {
			if (StructKeyExists(this, local.key) && (!StructKeyExists(arguments, "property") || arguments.property == local.key)) {
				variables.$persistedProperties[local.key] = this[local.key];
			}
		}
	}

	/**
	 * Internal function.
	 */
	public any function $setDefaultValues() {
		// Set defaults from both persisted properties and non-persisted mappings
		local.sources = [variables.wheels.class.properties, variables.wheels.class.mapping];
		for (local.source in local.sources) {
			for (local.key in local.source) {
				if (
					StructKeyExists(local.source[local.key], "defaultValue")
					&& (!StructKeyExists(this, local.key) || !Len(this[local.key]))
				) {
					this[local.key] = local.source[local.key].defaultValue;
				}
			}
		}
	}

	/**
	 * Internal function.
	 */
	public struct function $propertyInfo(required string property) {
		if (StructKeyExists(variables.wheels.class.properties, arguments.property)) {
			return variables.wheels.class.properties[arguments.property];
		} else {
			return {};
		}
	}

	/**
	 * Internal function.
	 */
	public string function $label(required string property) {
		// Prefer label set via `properties` initializer if it exists.
		if (
			StructKeyExists(variables.wheels.class.properties, arguments.property)
			&& StructKeyExists(variables.wheels.class.properties[arguments.property], "label")
		) {
			local.rv = variables.wheels.class.properties[arguments.property].label;
			// Check to see if the mapping has a label to base the name on.
		} else if (
			StructKeyExists(variables.wheels.class.mapping, arguments.property)
			&& StructKeyExists(variables.wheels.class.mapping[arguments.property], "label")
		) {
			local.rv = variables.wheels.class.mapping[arguments.property].label;
			// Fall back on property name otherwise.
		} else {
			local.rv = humanize(arguments.property);
		}

		return local.rv;
	}

	/**
	 * Returns a struct containing all association definitions for this model.
	 * Each key is the association name, and the value is a struct with association metadata
	 * including `type` (belongsTo, hasMany, hasOne), `modelName`, `foreignKey`, `joinKey`, and `dependent`.
	 *
	 * [section: Model Class]
	 * [category: Miscellaneous Functions]
	 */
	public struct function associationInfo() {
		return variables.wheels.class.associations;
	}

	/**
	 * Returns a list of association names defined on this model.
	 *
	 * [section: Model Class]
	 * [category: Miscellaneous Functions]
	 */
	public string function associationNames() {
		return StructKeyList(variables.wheels.class.associations);
	}

	/**
	 * Returns a struct containing all validation rules for this model, keyed by trigger (`onSave`, `onCreate`, `onUpdate`).
	 * Each trigger contains an array of validation rule structs with `method`, `properties`, `message`, and other parameters.
	 *
	 * [section: Model Class]
	 * [category: Miscellaneous Functions]
	 */
	public struct function validationInfo() {
		return variables.wheels.class.validations;
	}

	/**
	 * Returns a struct containing all enum definitions for this model.
	 * Each key is the property name, and the value contains `values` (name-to-stored-value mapping) and `names` (list of enum names).
	 *
	 * [section: Model Class]
	 * [category: Miscellaneous Functions]
	 */
	public struct function enumInfo() {
		return variables.wheels.class.enums;
	}

	/**
	 * Returns a struct containing all named scope definitions for this model.
	 * Each key is the scope name, and the value is a struct with query fragment keys like `where`, `order`, `select`, `include`.
	 *
	 * [section: Model Class]
	 * [category: Miscellaneous Functions]
	 */
	public struct function scopeInfo() {
		return variables.wheels.class.scopes;
	}

	/**
	 * Escapes a string value for safe inclusion in a SQL literal.
	 * Strips null bytes, doubles backslashes (MySQL escape sequences), and doubles single quotes.
	 *
	 * DEPRECATED: Prefer parameterized queries (cfqueryparam / whereParams) over string escaping.
	 * This function is retained for backwards compatibility with existing scope handlers
	 * that use string interpolation in WHERE clauses.
	 *
	 * @value The string value to escape.
	 */
	public string function $escapeSqlValue(required string value) {
		local.rv = Replace(arguments.value, Chr(0), "", "all");
		local.rv = Replace(local.rv, "\", "\\", "all");
		local.rv = Replace(local.rv, "'", "''", "all");
		return local.rv;
	}

	/**
	 * Escapes simple-value arguments passed to dynamic scope handler functions so that
	 * QUOTED string interpolation in WHERE clauses (`where = "col = '##args.x##'"`) is safe:
	 * the quoted literal is subsequently re-extracted by `$whereClause`'s RESQLWhere pass
	 * and bound via cfqueryparam, so escaping the quotes is sufficient to keep the value
	 * inside the literal. Values are never keyword-filtered or rewritten beyond escaping —
	 * "Union Pacific" round-trips unchanged.
	 *
	 * WARNING: escaping does NOT make UNQUOTED interpolation (`where = "age > ##args.age##"`)
	 * safe. Handlers that interpolate unquoted must validate/cast the value themselves, or
	 * better, return `whereParams` in the scope spec for full parameterization (supported by
	 * `ScopeChain.$mergeSpecs()` — see the enum scope implementation in this file).
	 *
	 * @args The struct of arguments to escape (typically missingMethodArguments).
	 */
	public struct function $sanitizeScopeHandlerArgs(required struct args) {
		local.sanitized = {};
		for (local.key in arguments.args) {
			local.val = arguments.args[local.key];
			if (IsSimpleValue(local.val)) {
				local.sanitized[local.key] = $escapeSqlValue(local.val);
			} else {
				local.sanitized[local.key] = local.val;
			}
		}
		return local.sanitized;
	}

	/**
	 * Returns a struct containing all callback definitions for this model, keyed by callback type
	 * (e.g., `beforeSave`, `afterCreate`). Each callback type contains an array of callback method names.
	 *
	 * [section: Model Class]
	 * [category: Miscellaneous Functions]
	 */
	public struct function callbackInfo() {
		return variables.wheels.class.callbacks;
	}

	/**
	 * Returns a comprehensive struct of all model metadata suitable for code generation and introspection tools.
	 * Includes model name, table name, primary keys, properties, associations, validations, enums, scopes, and callbacks.
	 *
	 * [section: Model Class]
	 * [category: Miscellaneous Functions]
	 */
	public struct function classInfo() {
		local.rv = {};
		local.rv.modelName = variables.wheels.class.modelName;
		local.rv.tableName = tableName();
		local.rv.primaryKeys = primaryKeys();
		local.rv.propertyNames = propertyNames();
		local.rv.properties = variables.wheels.class.properties;
		local.rv.associations = variables.wheels.class.associations;
		local.rv.validations = variables.wheels.class.validations;
		local.rv.enums = variables.wheels.class.enums;
		local.rv.scopes = variables.wheels.class.scopes;
		local.rv.callbacks = variables.wheels.class.callbacks;
		local.rv.calculatedProperties = variables.wheels.class.calculatedProperties;
		local.rv.softDeletion = StructKeyExists(variables.wheels.class, "softDeletion") ? variables.wheels.class.softDeletion : false;
		return local.rv;
	}

	/**
	 * Defines a named query scope that can be chained onto finders.
	 * Scopes allow you to define reusable query fragments in the model config and compose them together.
	 *
	 * [section: Model Configuration]
	 * [category: Scope Functions]
	 *
	 * @name The name of the scope. This becomes a callable method on the model (e.g. `model("User").active()`).
	 * @where A `WHERE` clause fragment to apply when this scope is used.
	 * @order An `ORDER BY` clause fragment to apply when this scope is used.
	 * @select A `SELECT` clause override to apply when this scope is used.
	 * @include Associations to include when this scope is used.
	 * @maxRows Maximum number of records to return when this scope is used.
	 * @handler The name of a method on this model that returns a struct of query arguments. Use for dynamic scopes that accept parameters. The method receives any arguments passed to the scope call.
	 */
	public void function scope(
		required string name,
		string where = "",
		string order = "",
		string select = "",
		string include = "",
		numeric maxRows = 0,
		string handler = ""
	) {
		if (!StructKeyExists(variables.wheels.class, "scopes")) {
			variables.wheels.class.scopes = {};
		}
		local.scopeDef = {};
		if (Len(arguments.where)) {
			local.scopeDef.where = arguments.where;
		}
		if (Len(arguments.order)) {
			local.scopeDef.order = arguments.order;
		}
		if (Len(arguments.select)) {
			local.scopeDef.select = arguments.select;
		}
		if (Len(arguments.include)) {
			local.scopeDef.include = arguments.include;
		}
		if (arguments.maxRows > 0) {
			local.scopeDef.maxRows = arguments.maxRows;
		}
		if (Len(arguments.handler)) {
			local.scopeDef.handler = arguments.handler;
		}
		variables.wheels.class.scopes[arguments.name] = local.scopeDef;
	}

	/**
	 * Maps a property to a set of named values (like Rails enums).
	 * Generates boolean checker methods (`is<Value>()`), scopes for each value,
	 * and validates that the property value is one of the allowed values.
	 *
	 * [section: Model Configuration]
	 * [category: Enum Functions]
	 *
	 * @property The name of the model property to map as an enum.
	 * @values Either a comma-delimited list of string values (e.g. `"draft,published,archived"`) or a struct mapping names to stored values (e.g. `{low: 0, medium: 1, high: 2}`).
	 */
	public void function enum(
		required string property,
		required any values
	) {
		// Validate property name: alphanumeric and underscore only (prevents SQL injection via property name)
		if (!ReFind("^[a-zA-Z_][a-zA-Z0-9_]*$", arguments.property)) {
			Throw(
				type = "Wheels.InvalidPropertyName",
				message = "The property name `#arguments.property#` is invalid.",
				extendedInfo = "Property names must contain only letters, numbers, and underscores, and must start with a letter or underscore."
			);
		}

		if (!StructKeyExists(variables.wheels.class, "enums")) {
			variables.wheels.class.enums = {};
		}
		local.enumDef = {};
		local.enumDef.property = arguments.property;

		if (IsStruct(arguments.values)) {
			// Struct mapping: name -> stored value
			local.enumDef.values = arguments.values;
			local.enumDef.names = StructKeyList(arguments.values);
		} else {
			// Comma-delimited list: each name is also the stored value
			local.enumDef.names = arguments.values;
			local.enumDef.values = {};
			local.nameArray = ListToArray(arguments.values);
			for (local.name in local.nameArray) {
				local.enumDef.values[local.name] = local.name;
			}
		}
		variables.wheels.class.enums[arguments.property] = local.enumDef;

		// Auto-register inclusion validation for this property
		validatesInclusionOf(
			properties = arguments.property,
			list = StructKeyList(local.enumDef.values),
			allowBlank = true
		);

		// Auto-register scopes for each enum value
		if (!StructKeyExists(variables.wheels.class, "scopes")) {
			variables.wheels.class.scopes = {};
		}
		for (local.name in ListToArray(local.enumDef.names)) {
			local.storedValue = local.enumDef.values[local.name];
			// Validate enum stored values: only allow alphanumeric, underscore, hyphen, space, and dot.
			// Enum values are developer-defined in model config(), so this is a strict allowlist.
			if (IsSimpleValue(local.storedValue) && ReFind("[^a-zA-Z0-9_\- .]", ToString(local.storedValue))) {
				Throw(
					type = "Wheels.InvalidEnumValue",
					message = "The enum value `#local.storedValue#` for property `#arguments.property#` contains invalid characters.",
					extendedInfo = "Enum values must contain only alphanumeric characters, underscores, hyphens, spaces, and dots. Received: `#local.storedValue#`"
				);
			}
			local.scopeDef = {};
			// Store value in whereParams for parameterized execution rather than
			// interpolating into the WHERE string. ScopeChain.$mergeSpecs() resolves
			// these into quoted values that $whereClause() re-parameterizes via cfqueryparam.
			local.scopeDef.where = "#arguments.property# = ?";
			local.scopeDef.whereParams = [{
				value: ToString(local.storedValue),
				type: "CF_SQL_VARCHAR"
			}];
			variables.wheels.class.scopes[local.name] = local.scopeDef;
		}
	}

	/**
	 * Validates that a calculated property SQL expression does not contain dangerous patterns.
	 * Called at model config time when property(sql="...") is used. This is a defense-in-depth
	 * measure: calculated property SQL is developer-defined, but this catches supply-chain attacks
	 * or accidental interpolation of user input into SQL expressions.
	 *
	 * [section: Model Configuration]
	 * [category: Miscellaneous Functions]
	 */
	public string function $validateCalculatedPropertySql(required string sql, required string propertyName) {
		local.dangerous = ";|\bUNION\b|INTO\s+(?:OUT|DUMP)|\bEXEC(UTE)?\b|xp_|LOAD_FILE|BENCHMARK|SLEEP\s*\(";
		if (ReFindNoCase(local.dangerous, arguments.sql)) {
			Throw(
				type = "Wheels.InvalidCalculatedProperty",
				message = "The calculated property `#arguments.propertyName#` contains potentially dangerous SQL patterns.",
				extendedInfo = "Calculated property SQL must not contain semicolons, UNION, EXEC/EXECUTE, or other dangerous SQL constructs. Expression: #arguments.sql#"
			);
		}
		return arguments.sql;
	}
}
