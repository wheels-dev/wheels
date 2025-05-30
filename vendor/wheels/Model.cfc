component output="false" displayName="Model" extends="wheels.Global"{

	property name="Mixins" inject="id:Plugins";

	function init(){
		$integrateComponents("wheels.model");
		return this;
	}

	/**
	 * Internal function.
	 */
	public any function $initModelClass(required string name, required string path) {
		variables.wheels = {};
		variables.wheels.errors = [];
		variables.wheels.class = {};
		variables.wheels.class.modelName = arguments.name;
		variables.wheels.class.modelId = Hash(GetMetadata(this).name);
		variables.wheels.class.path = arguments.path;

		// If our name has pathing in it, remove it and add it to the end of of the $class.path variable.
		if (Find("/", arguments.name)) {
			variables.wheels.class.modelName = ListLast(arguments.name, "/");
			variables.wheels.class.path = ListAppend(
				arguments.path,
				ListDeleteAt(arguments.name, ListLen(arguments.name, "/"), "/"),
				"/"
			);
		}

		variables.wheels.class.RESQLAs = "[[:space:]]AS[[:space:]][A-Za-z1-9]+";
		variables.wheels.class.RESQLOperators = "((?:\s+(?:NOT\s+)?LIKE)|(?:\s+(?:NOT\s+)?IN)|(?:\s+IS(?:\s+NOT)?)|(?:<>)|(?:<=)|(?:>=)|(?:!=)|(?:!<)|(?:!>)|=|<|>)";
		variables.wheels.class.RESQLWhere = "\s*(#variables.wheels.class.RESQLOperators#)\s*(\('.+?'\)|\(((?:\+|-)?[0-9\.],?)+\)|'.+?'()|''|((?:\+|-)?[0-9\.]+)()|NULL)((\s*$|\s*\)|\s+(AND|OR)))";
		variables.wheels.class.mapping = {};
		variables.wheels.class.properties = {};
		variables.wheels.class.accessibleProperties = {};
		variables.wheels.class.calculatedProperties = {};
		variables.wheels.class.ignoredColumns = {};
		variables.wheels.class.associations = {};
		variables.wheels.class.callbacks = {};
		variables.wheels.class.keys = "";
		variables.wheels.class.dataSource = application.wheels.dataSourceName;
		variables.wheels.class.username = application.wheels.dataSourceUserName;
		variables.wheels.class.password = application.wheels.dataSourcePassword;
		variables.wheels.class.automaticValidations = application.wheels.automaticValidations;
		setTableNamePrefix($get("tableNamePrefix"));
		table(LCase(pluralize(variables.wheels.class.modelName)));
		local.callbacks = "afterNew,afterFind,afterInitialization,beforeDelete,afterDelete,beforeSave,afterSave,beforeCreate,afterCreate,beforeUpdate,afterUpdate,beforeValidation,afterValidation,beforeValidationOnCreate,afterValidationOnCreate,beforeValidationOnUpdate,afterValidationOnUpdate";
		local.iEnd = ListLen(local.callbacks);
		for (local.i = 1; local.i <= local.iEnd; local.i++) {
			variables.wheels.class.callbacks[ListGetAt(local.callbacks, local.i)] = [];
		}
		local.validations = "onSave,onCreate,onUpdate";
		local.iEnd = ListLen(local.validations);
		for (local.i = 1; local.i <= local.iEnd; local.i++) {
			variables.wheels.class.validations[ListGetAt(local.validations, local.i)] = [];
		}

		variables.wheels.class.propertyStruct = StructNew("ordered");
		variables.wheels.class.columnStruct = StructNew("ordered");

		// TODO: deprecate these lists in favour of the structs to avoid ListFind (use StructKeyList to create the list)
		variables.wheels.class.propertyList = "";
		variables.wheels.class.aliasedPropertyList = "";
		variables.wheels.class.columnList = "";
		variables.wheels.class.calculatedPropertyList = "";

		// Run developer's config method if it exists.
		if (StructKeyExists(variables, "config")) {
			config();
		} else if ($get("modelRequireConfig")) {
			Throw(
				type = "Wheels.ModelConfigMissing",
				message = "A ´config´ function is required for ´#variables.wheels.class.modelName#´ model.",
				extendedInfo = "Create a ´config´ function in ´/models/#variables.wheels.class.modelName#´."
			);
		}

		// set calculated properties
		for (local.key in variables.wheels.class.mapping) {
			if (
				StructKeyExists(variables.wheels.class.mapping[local.key], "type")
				&& variables.wheels.class.mapping[local.key].type != "column"
			) {
				// TODO: deprecate (use StructKeyList of calculatedPropertyStruct)
				variables.wheels.class.calculatedPropertyList = ListAppend(
					variables.wheels.class.calculatedPropertyList,
					local.key
				);
				variables.wheels.class.calculatedProperties[local.key] = {};
				variables.wheels.class.calculatedProperties[local.key][variables.wheels.class.mapping[local.key].type] = variables.wheels.class.mapping[
					local.key
				].value;
				variables.wheels.class.calculatedProperties[local.key].select = variables.wheels.class.mapping[local.key].select;
				variables.wheels.class.calculatedProperties[local.key].dataType = variables.wheels.class.mapping[local.key].dataType;
			}
		}

		// Make sure that the tablename has the respected prefix.
		table(getTableNamePrefix() & tableName());

		if (!IsBoolean(variables.wheels.class.tableName) || variables.wheels.class.tableName) {
			// load the database adapter
			variables.wheels.class.adapter = $assignAdapter();

			// get columns for the table
			local.columns = variables.wheels.class.adapter.$getColumns(tableName()).filter(function(r) {
				return !StructKeyExists(variables.wheels.class.ignoredColumns, arguments.r.column_name);
			});

			// do not process columns already assigned to a calculated property
			local.processedColumns = {};
			for (local.key in StructKeyArray(variables.wheels.class.calculatedProperties)) {
				local.processedColumns[local.key] = true;
			}

			local.iEnd = local.columns.recordCount;
			for (local.i = 1; local.i <= local.iEnd; local.i++) {
				// set up properties and column mapping
				if (!StructKeyExists(local.processedColumns, local.columns["column_name"][local.i])) {
					// default the column to map to a property with the same name
					local.property = local.columns["column_name"][local.i];
					for (local.key in variables.wheels.class.mapping) {
						if (
							StructKeyExists(variables.wheels.class.mapping[local.key], "type")
							&& variables.wheels.class.mapping[local.key].type == "column"
							&& variables.wheels.class.mapping[local.key].value == local.property
						) {
							// developer has chosen to map this column to a property with a different name so set that here
							local.property = local.key;
							break;
						}
					}

					// Extract type and details, like if it's signed or not, from the "type_name"" information we got from cfdbinfo.
					// It can be "int" or "int unsigned" for example (in which case we set type to "int" and details to "unsigned").
					// Done below by treating the value as a space delimited list.
					// We also ignore anything inside parentheses.
					local.typeName = Trim(SpanExcluding(local.columns["type_name"][local.i], "("));
					if (ListLen(local.typeName, " ") == 2) {
						local.type = ListFirst(local.typeName, " ");
						local.details = ListLast(local.typeName, " ");
					} else {
						local.type = local.typeName;
						local.details = "";
					}

					// set the info we need for each property
					variables.wheels.class.properties[local.property] = {};
					variables.wheels.class.properties[local.property].dataType = local.type;
					variables.wheels.class.properties[local.property].type = variables.wheels.class.adapter.$getType(
						local.type,
						local.columns["decimal_digits"][local.i],
						local.details
					);
					variables.wheels.class.properties[local.property].column = local.columns["column_name"][local.i];
					variables.wheels.class.properties[local.property].scale = local.columns["decimal_digits"][local.i];
					variables.wheels.class.properties[local.property].columndefault = local.columns["column_default_value"][local.i];

					// get a boolean value for whether this column can be set to null or not
					// if we don't get a boolean back we try to translate y/n to proper boolean values in cfml (yes/no)
					variables.wheels.class.properties[local.property].nullable = Trim(local.columns["is_nullable"][local.i]);
					if (!IsBoolean(variables.wheels.class.properties[local.property].nullable)) {
						variables.wheels.class.properties[local.property].nullable = ReplaceList(
							variables.wheels.class.properties[local.property].nullable,
							"N,Y",
							"No,Yes"
						);
					}

					variables.wheels.class.properties[local.property].size = local.columns["column_size"][local.i];

					// If property is id, then make it all-caps "ID."
					if (local.property == "id") {
						variables.wheels.class.properties[local.property].label = "ID";
						// Otherwise, humanize it.
					} else {
						variables.wheels.class.properties[local.property].label = humanize(local.property);
					}

					variables.wheels.class.properties[local.property].validationtype = variables.wheels.class.adapter.$getValidationType(
						variables.wheels.class.properties[local.property].type
					);
					if (StructKeyExists(variables.wheels.class.mapping, local.property)) {
						if (StructKeyExists(variables.wheels.class.mapping[local.property], "label")) {
							variables.wheels.class.properties[local.property].label = variables.wheels.class.mapping[local.property].label;
						}
						if (StructKeyExists(variables.wheels.class.mapping[local.property], "defaultValue")) {
							variables.wheels.class.properties[local.property].defaultValue = variables.wheels.class.mapping[
								local.property
							].defaultValue;
						}
					}
					if (local.columns["is_primarykey"][local.i]) {
						setPrimaryKey(local.property);
					}
					if (
						variables.wheels.class.automaticValidations && !ListFindNoCase(
							"#application.wheels.timeStampOnCreateProperty#,#application.wheels.timeStampOnUpdateProperty#,#application.wheels.softDeleteProperty#",
							local.property
						)
					) {
						// check if automatic validations have been turned off specifically for this property before proceeding
						local.propertyAllowsAutomaticValidations = true;
						if (
							StructKeyExists(variables.wheels.class.mapping, local.property)
							&& StructKeyExists(variables.wheels.class.mapping[local.property], "automaticValidations")
							&& !variables.wheels.class.mapping[local.property].automaticValidations
						) {
							local.propertyAllowsAutomaticValidations = false;
						}

						if (local.propertyAllowsAutomaticValidations) {
							local.defaultValidationsAllowBlank = variables.wheels.class.properties[local.property].nullable;

							// primary keys should be allowed to be blank
							if (ListFindNoCase(primaryKeys(), local.property)) {
								local.defaultValidationsAllowBlank = true;
							}
							if (
								!ListFindNoCase(primaryKeys(), local.property)
								&& !variables.wheels.class.properties[local.property].nullable
								&& !$validationExists(property = local.property, validation = "validatesPresenceOf")
							) {
								if (Len(local.columns["column_default_value"][local.i])) {
									validatesPresenceOf(properties = local.property, when = "onUpdate");
								} else {
									validatesPresenceOf(properties = local.property);
								}
							}

							// always allow blank if a database default or validatesPresenceOf() has been set
							if (
								Len(local.columns["column_default_value"][local.i])
								|| $validationExists(property = local.property, validation = "validatesPresenceOf")
							) {
								local.defaultValidationsAllowBlank = true;
							}

							// set length validations if the developer has not
							if (
								variables.wheels.class.properties[local.property].validationtype == "string"
								&& !$validationExists(property = local.property, validation = "validatesLengthOf")
							) {
								validatesLengthOf(
									properties = local.property,
									allowBlank = local.defaultValidationsAllowBlank,
									maximum = variables.wheels.class.properties[local.property].size
								);
							}

							// set numericality validations if the developer has not
							if (
								ListFindNoCase("integer,float", variables.wheels.class.properties[local.property].validationtype)
								&& !$validationExists(property = local.property, validation = "validatesNumericalityOf")
							) {
								validatesNumericalityOf(
									properties = local.property,
									allowBlank = local.defaultValidationsAllowBlank,
									onlyInteger = (variables.wheels.class.properties[local.property].validationtype == "integer")
								);
							}

							// set date validations if the developer has not (checks both dates or times as per the IsDate() function)
							if (
								variables.wheels.class.properties[local.property].validationtype == "datetime"
								&& !$validationExists(property = local.property, validation = "validatesFormatOf")
							) {
								validatesFormatOf(
									properties = local.property,
									allowBlank = local.defaultValidationsAllowBlank,
									type = "date"
								);
							}
						}
					}

					variables.wheels.class.propertyStruct[local.property] = true;
					variables.wheels.class.columnStruct[variables.wheels.class.properties[local.property].column] = true;

					variables.wheels.class.propertyList = ListAppend(variables.wheels.class.propertyList, local.property);

					/*
						To fix the issue below:
						https://github.com/cfwheels/cfwheels/issues/580

						Added a new property called aliasedPropertyList in model class that will contain column names list that are prepended with the tablename.
						For example, if there is a "user" table then the columns "id,createdat,updatedat,deletedat" will be added in the list with "user" prepended to it.

						Then the list will contain, userid,usercreatedat,userupdatedat,userdeletedat.
						*/
					variables.wheels.class.aliasedPropertyList = ListAppend(variables.wheels.class.aliasedPropertyList, variables.wheels.class.modelname & local.property);
					variables.wheels.class.columnList = ListAppend(
						variables.wheels.class.columnList,
						variables.wheels.class.properties[local.property].column
					);
					local.processedColumns[local.columns["column_name"][local.i]] = true;
				}
			}

			// Raise error when no primary key has been defined for the table.
			if (!Len(primaryKeys())) {
				Throw(
					type = "Wheels.NoPrimaryKey",
					message = "No primary key exists on the `#tableName()#` table.",
					extendedInfo = "Set an appropriate primary key on the `#tableName()#` table."
				);
			}
		}

		// set up soft deletion and time stamping if the necessary columns in the table exist
		variables.wheels.class.timeStampMode = application.wheels.timeStampMode;
		if (
			Len(application.wheels.softDeleteProperty)
			&& StructKeyExists(variables.wheels.class.properties, application.wheels.softDeleteProperty)
		) {
			variables.wheels.class.softDeletion = true;
			variables.wheels.class.softDeleteColumn = variables.wheels.class.properties[application.wheels.softDeleteProperty].column;
		} else {
			variables.wheels.class.softDeletion = false;
		}
		if (
			Len(application.wheels.timeStampOnCreateProperty)
			&& StructKeyExists(variables.wheels.class.properties, application.wheels.timeStampOnCreateProperty)
		) {
			variables.wheels.class.timeStampingOnCreate = true;
			variables.wheels.class.timeStampOnCreateProperty = application.wheels.timeStampOnCreateProperty;
		} else {
			variables.wheels.class.timeStampingOnCreate = false;
		}
		if (
			Len(application.wheels.timeStampOnUpdateProperty)
			&& StructKeyExists(variables.wheels.class.properties, application.wheels.timeStampOnUpdateProperty)
		) {
			variables.wheels.class.timeStampingOnUpdate = true;
			variables.wheels.class.timeStampOnUpdateProperty = application.wheels.timeStampOnUpdateProperty;
		} else {
			variables.wheels.class.timeStampingOnUpdate = false;
		}
		return this;
	}

	/**
	 * Internal function.
	 */
	public any function $assignAdapter() {
		if ($get("showErrorInformation")) {
			try {
				local.info = $dbinfo(
					type = "version",
					dataSource = variables.wheels.class.dataSource,
					username = variables.wheels.class.username,
					password = variables.wheels.class.password
				);
			} catch (any e) {
				Throw(
					type = "Wheels.DataSourceNotFound",
					message = "The data source could not be reached.",
					extendedInfo = "Make sure your database is reachable and that your data source settings are correct. You either need to setup a data source with the name `#variables.wheels.class.dataSource#` in the Administrator or tell CFWheels to use a different data source in `app/config/settings.cfm`."
				);
			}
		} else {
			local.info = $dbinfo(
				type = "version",
				dataSource = variables.wheels.class.dataSource,
				username = variables.wheels.class.username,
				password = variables.wheels.class.password
			);
		}
		if (FindNoCase("SQLServer", local.info.driver_name) || FindNoCase("SQL Server", local.info.driver_name)) {
			local.adapterName = "SQLServer";
		} else if (FindNoCase("MySQL", local.info.driver_name) || FindNoCase("MariaDB", local.info.driver_name)) {
			local.adapterName = "MySQL";
		} else if (FindNoCase("PostgreSQL", local.info.driver_name)) {
			local.adapterName = "PostgreSQL";
		} else if (FindNoCase("H2", local.info.driver_name)) {
			local.adapterName = "H2";
		} else if (FindNoCase("Oracle", local.info.driver_name)) {
			local.adapterName = "Oracle";
		} else {
			Throw(
				type = "Wheels.DatabaseNotSupported",
				message = "#local.info.database_productname# is not supported by CFWheels.",
				extendedInfo = "Use SQL Server, MySQL, MariaDB, PostgreSQL or H2."
			);
		}
		$set(adapterName = local.adapterName);
		return CreateObject("component", "wheels.model.adapters.#local.adapterName#").$init(
			dataSource = variables.wheels.class.dataSource,
			username = variables.wheels.class.username,
			password = variables.wheels.class.password
		);
	}

	/**
	 * Internal function.
	 */
	public any function $initModelObject(
		required string name,
		required any properties,
		required boolean persisted,
		numeric row = 1,
		boolean base = true,
		boolean useFilterLists = true
	) {
		variables.wheels = {};
		variables.wheels.instance = {};
		variables.wheels.errors = [];

		// assign an object id for the instance (only use the last 12 digits to avoid creating an exponent)
		request.wheels.tickCountId = Right(request.wheels.tickCountId, 12) + 1;
		variables.wheels.tickCountId = request.wheels.tickCountId;

		// copy class variables from the object in the application scope
		if (!StructKeyExists(variables.wheels, "class")) {
			local.lockName = "classLock_#arguments.name#_#application.applicationName#";
			$simpleLock(
				execute = "$modelInitializationLock",
				name = local.lockName,
				type = "exclusive"
			);

			if (StructKeyExists(application.wheels.models, arguments.name)) {
				variables.wheels.class = application.wheels.models[arguments.name].$classData();
			} else {
				// if the model is not in the application cache, attempt to load it dynamically in case of race conditions
				try {
					// dynamically load the model by name
					model(arguments.name);
					if (StructKeyExists(application.wheels.models, arguments.name)) {
						// if successfully loaded, retrieve class data from it
						variables.wheels.class = application.wheels.models[arguments.name].$classData();
					} else {
						// if still not found, fall back to an empty default structure to prevent runtime errors
						variables.wheels.class = {};
						variables.wheels.class.modelName = arguments.name;
						variables.wheels.class.properties = {};
						variables.wheels.class.associations = {};
					}
				} catch (any e) {
					// as a safety net, catch any loading errors and use a blank fallback structure
					variables.wheels.class = {};
					variables.wheels.class.modelName = arguments.name;
					variables.wheels.class.properties = {};
					variables.wheels.class.associations = {};
				}
			}
		}

		// setup object properties in the this scope
		if (IsQuery(arguments.properties) && arguments.properties.recordCount != 0) {
			arguments.properties = $queryRowToStruct(argumentCollection = arguments);
		}

		if (IsStruct(arguments.properties) && !StructIsEmpty(arguments.properties)) {
			$setProperties(properties = arguments.properties, setOnModel = true, $useFilterLists = arguments.useFilterLists);
		}
		if (arguments.persisted) {
			$updatePersistedProperties();
		}
		variables.wheels.instance.persistedOnInitialization = arguments.persisted;
		return this;
	}

	/**
	 * Internal function.
	 */
	public struct function $classData() {
		return variables.wheels.class;
	}
	
	/**
	 * Empty function for use with $simpleLock in $initModelObject.
	 * This is just a placeholder that gets called within the lock.
	 */
	public void function $modelInitializationLock() {
		// This function intentionally left empty
	}


	/**
	 * Internal function.
	 */
	public boolean function $softDeletion() {
		return variables.wheels.class.softDeletion;
	}

	/**
	 * Internal function.
	 */
	public string function $softDeleteColumn() {
		return variables.wheels.class.softDeleteColumn;
	}

	/**
	 * Gets all the component files from the provided path
	 *
	 * @path The path to get component files from
	 */
	private function $integrateComponents(required string path) {
    local.basePath = arguments.path;
    local.folderPath = expandPath("/#replace(local.basePath, ".", "/", "all")#");

    // Get a list of all CFC files in the folder
    local.fileList = directoryList(local.folderPath, false, "name", "*.cfc");
    for (local.fileName in local.fileList) {
      // Remove the file extension to get the component name
      local.componentName = replace(local.fileName, ".cfc", "", "all");

      $integrateFunctions(createObject("component", "#local.basePath#.#local.componentName#"));
    }
	}

	/**
	 * Dynamically mix methods from a given component into this component
	 */
	private function $integrateFunctions(componentInstance) {
		// Get all methods from the given component
		local.methods = getMetaData(componentInstance).functions;

		for (local.method in local.methods) {
			local.functionName = local.method.name;

			// Only add public, non-inherited methods
			if (
				local.method.access eq "public"
				&& !structKeyExists(variables, local.method.name)
				&& !structKeyExists(this, local.method.name)
			) {
				variables[local.functionName] = componentInstance[local.functionName];
				this[local.functionName] = componentInstance[local.functionName];
			}
		}
	}

	function onDIcomplete(){
		Mixins.$initializeMixins(variables);
	}
}
