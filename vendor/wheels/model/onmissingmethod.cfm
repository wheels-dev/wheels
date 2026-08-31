<cfscript>
	/**
	 * This method is not designed to be called directly from your code, but provides functionality for dynamic finders such as `findOneByEmail()`
	 *
	 * [section: Model Class]
	 * [category: Miscellaneous Functions]
	 */
	public any function onMissingMethod(required string missingMethodName, required struct missingMethodArguments) {
		// --- Query Scopes ---
		// Check if the called method matches a named scope defined in config().
		// Returns a ScopeChain proxy that supports further chaining and terminal finder methods.
		local.scopeResult = $onMissingMethodResolveScope(arguments.missingMethodName, arguments.missingMethodArguments);
		if (local.scopeResult.handled) {
			return local.scopeResult.rv;
		}

		// --- Enum is<Value>() boolean checkers ---
		// For a property with enum(property="status", values="draft,published,archived"),
		// generates isDraft(), isPublished(), isArchived() that return true/false.
		local.enumResult = $onMissingMethodResolveEnumChecker(arguments.missingMethodName);
		if (local.enumResult.handled) {
			return local.enumResult.rv;
		}

		// --- Chainable Query Builder entry points ---
		// Allow calling .where(), .select(), .orderBy() etc. directly on a model to start a query builder chain.
		// Note: user-defined scopes and enum checkers above take precedence, and a real model method with one of
		// these names bypasses onMissingMethod entirely. The dynamic-finder and association-method branches below
		// run AFTER this list, so an association named e.g. "select" resolves to the builder instead. Keep this
		// list in sync with the scope-to-builder transition list in wheels.model.query.ScopeChain (where user
		// scopes are checked first).
		if (ListFindNoCase("where,orWhere,whereNull,whereNotNull,whereBetween,whereIn,whereNotIn,orderBy,limit,offset,select,include,group,distinct,forUpdate", arguments.missingMethodName)) {
			local.builder = new wheels.model.query.QueryBuilder(modelReference = this);
			// Delegate the call to the query builder
			return Invoke(local.builder, arguments.missingMethodName, arguments.missingMethodArguments);
		}

		// --- Dynamic property helpers (hasChanged, changedFrom, isPresent, isBlank, columnFor, toggle, has<Property>, update<Property>) ---
		local.propertyResult = $onMissingMethodResolveDynamicProperty(arguments.missingMethodName, arguments.missingMethodArguments);
		if (local.propertyResult.handled) {
			local.rv = local.propertyResult.rv;
		} else {
			// --- Dynamic finders (findOneBy / findAllBy / findOrCreateBy) and associations ---
			local.finderResult = $onMissingMethodResolveDynamicFinder(arguments.missingMethodName, arguments.missingMethodArguments);
			if (local.finderResult.handled) {
				local.rv = local.finderResult.rv;
			} else {
				local.rv = $associationMethod(argumentCollection = arguments);
			}
		}

		if (!StructKeyExists(local, "rv")) {
			Throw(
				type = "Wheels.MethodNotFound",
				message = "The method `#arguments.missingMethodName#` was not found in the `#variables.wheels.class.modelName#` model.",
				extendedInfo = "Check your spelling or add the method to the model's CFC file."
			);
		}

		return local.rv;
	}

	/**
	 * Internal function. Resolves a dynamic method call against the named query scopes
	 * defined in config(). Returns `{ handled, rv }` with `handled = true` when the
	 * method matches a scope and `rv` holding the resulting ScopeChain.
	 */
	public any function $onMissingMethodResolveScope(required string missingMethodName, required struct missingMethodArguments) {
		local.result = { handled = false, rv = "" };
		if (
			StructKeyExists(variables.wheels.class, "scopes")
			&& StructKeyExists(variables.wheels.class.scopes, arguments.missingMethodName)
		) {
			local.scopeDef = variables.wheels.class.scopes[arguments.missingMethodName];
			if (StructKeyExists(local.scopeDef, "handler") && Len(local.scopeDef.handler)) {
				local.sanitizedArgs = $sanitizeScopeHandlerArgs(arguments.missingMethodArguments);
				local.spec = $invoke(method = local.scopeDef.handler, invokeArgs = local.sanitizedArgs);
			} else {
				local.spec = Duplicate(local.scopeDef);
			}
			local.result.rv = new wheels.model.query.ScopeChain(modelReference = this, specs = [local.spec]);
			local.result.handled = true;
		}
		return local.result;
	}

	/**
	 * Internal function. Resolves the enum `is<Value>()` boolean checker form.
	 * Returns `{ handled, rv }` with `handled = true` when the method name matches an
	 * enum value name.
	 */
	public any function $onMissingMethodResolveEnumChecker(required string missingMethodName) {
		local.result = { handled = false, rv = false };
		if (
			Left(arguments.missingMethodName, 2) == "is"
			&& Len(arguments.missingMethodName) > 2
			&& StructKeyExists(variables.wheels.class, "enums")
		) {
			local.valueName = Right(arguments.missingMethodName, Len(arguments.missingMethodName) - 2);
			// Check against each enum definition
			for (local.enumProp in variables.wheels.class.enums) {
				local.enumDef = variables.wheels.class.enums[local.enumProp];
				// Match case-insensitively against enum value names
				for (local.name in ListToArray(local.enumDef.names)) {
					if (CompareNoCase(local.valueName, local.name) == 0) {
						// Found a match — return true if the property equals the stored value
						if (StructKeyExists(this, local.enumProp)) {
							local.result.rv = (Compare(this[local.enumProp], local.enumDef.values[local.name]) == 0);
						} else {
							local.result.rv = false;
						}
						local.result.handled = true;
						return local.result;
					}
				}
			}
		}
		return local.result;
	}

	/**
	 * Internal function. Resolves the dynamic property method forms (`hasChanged`,
	 * `changedFrom`, `isPresent`, `isBlank`, `columnFor`, `toggle`, `has<Property>`,
	 * `update<Property>`). Returns `{ handled, rv }`.
	 */
	public any function $onMissingMethodResolveDynamicProperty(required string missingMethodName, required struct missingMethodArguments) {
		local.result = { handled = false, rv = "" };
		if (
			Right(arguments.missingMethodName, 10) == "hasChanged"
			&& StructKeyExists(variables.wheels.class.properties, ReplaceNoCase(arguments.missingMethodName, "hasChanged", ""))
		) {
			local.result.rv = hasChanged(property = ReplaceNoCase(arguments.missingMethodName, "hasChanged", ""));
			local.result.handled = true;
		} else if (
			Right(arguments.missingMethodName, 11) == "changedFrom"
			&& StructKeyExists(variables.wheels.class.properties, ReplaceNoCase(arguments.missingMethodName, "changedFrom", ""))
		) {
			local.result.rv = changedFrom(property = ReplaceNoCase(arguments.missingMethodName, "changedFrom", ""));
			local.result.handled = true;
		} else if (
			Right(arguments.missingMethodName, 9) == "IsPresent"
			&& StructKeyExists(variables.wheels.class.properties, ReplaceNoCase(arguments.missingMethodName, "IsPresent", ""))
		) {
			local.result.rv = propertyIsPresent(property = ReplaceNoCase(arguments.missingMethodName, "IsPresent", ""));
			local.result.handled = true;
		} else if (
			Right(arguments.missingMethodName, 7) == "IsBlank"
			&& StructKeyExists(variables.wheels.class.properties, ReplaceNoCase(arguments.missingMethodName, "IsBlank", ""))
		) {
			local.result.rv = propertyIsBlank(property = ReplaceNoCase(arguments.missingMethodName, "IsBlank", ""));
			local.result.handled = true;
		} else if (
			Left(arguments.missingMethodName, 9) == "columnFor"
			&& StructKeyExists(variables.wheels.class.properties, ReplaceNoCase(arguments.missingMethodName, "columnFor", ""))
		) {
			local.result.rv = columnForProperty(property = ReplaceNoCase(arguments.missingMethodName, "columnFor", ""));
			local.result.handled = true;
		} else if (
			Left(arguments.missingMethodName, 6) == "toggle"
			&& StructKeyExists(variables.wheels.class.properties, ReplaceNoCase(arguments.missingMethodName, "toggle", ""))
		) {
			local.result.rv = toggle(
				property = ReplaceNoCase(arguments.missingMethodName, "toggle", ""),
				argumentCollection = arguments.missingMethodArguments
			);
			local.result.handled = true;
		} else if (
			Left(arguments.missingMethodName, 3) == "has"
			&& StructKeyExists(variables.wheels.class.properties, ReplaceNoCase(arguments.missingMethodName, "has", ""))
		) {
			local.result.rv = hasProperty(property = ReplaceNoCase(arguments.missingMethodName, "has", ""));
			local.result.handled = true;
		} else if (
			Left(arguments.missingMethodName, 6) == "update"
			&& StructKeyExists(variables.wheels.class.properties, ReplaceNoCase(arguments.missingMethodName, "update", ""))
		) {
			if (!StructKeyExists(arguments.missingMethodArguments, "value")) {
				Throw(
					type = "Wheels.IncorrectArguments",
					message = "The `value` argument is required but was not passed in.",
					extendedInfo = "Pass in a value to the dynamic updateProperty in the `value` argument."
				);
			}
			local.result.rv = updateProperty(
				property = ReplaceNoCase(arguments.missingMethodName, "update", ""),
				value = arguments.missingMethodArguments.value
			);
			local.result.handled = true;
		}
		return local.result;
	}

	/**
	 * Internal function. Resolves the dynamic finder forms (`findOneByX`, `findAllByX`,
	 * `findOrCreateByX`). Mutates `missingMethodArguments` in place and returns
	 * `{ handled, rv }`.
	 */
	public any function $onMissingMethodResolveDynamicFinder(required string missingMethodName, required struct missingMethodArguments) {
		local.result = { handled = false, rv = "" };
		if (
			Left(arguments.missingMethodName, 9) == "findOneBy"
			|| Left(arguments.missingMethodName, 9) == "findAllBy"
		) {
			// cfformat-ignore-start
			local.finderPrefix = Left(arguments.missingMethodName, 9) == "findOneBy" ? "findOneBy" : "findAllBy";
			local.finderProperties = $engineAdapter().dynamicFinderProperties(arguments.missingMethodName, local.finderPrefix);
			// cfformat-ignore-end

			// sometimes values will have commas in them, allow the developer to change the delimiter
			local.delimiter = ",";
			if (StructKeyExists(arguments.missingMethodArguments, "delimiter")) {
				local.delimiter = arguments.missingMethodArguments["delimiter"];
			}

			// split the values into an array for easier processing
			local.values = "";
			if (StructKeyExists(arguments.missingMethodArguments, "value")) {
				local.values = arguments.missingMethodArguments.value;
			} else if (StructKeyExists(arguments.missingMethodArguments, "values")) {
				local.values = arguments.missingMethodArguments.values;
			} else {
				local.values = arguments.missingMethodArguments[1];
			}

			if (!IsArray(local.values)) {
				if (ArrayLen(local.finderProperties) == 1) {
					// don't know why but this screws up in CF8
					local.temp = [];
					ArrayAppend(local.temp, local.values);
					local.values = local.temp;
				} else {
					local.values = $listClean(list = local.values, delim = local.delimiter, returnAs = "array");
				}
			}

			// where clause
			local.addToWhere = [];

			// loop through all the properties they want to query and assign values
			local.iEnd = ArrayLen(local.finderProperties);
			for (local.i = 1; local.i <= local.iEnd; local.i++) {
				local.property = local.finderProperties[local.i];
				if (ArrayLen(local.values) >= local.i) {
					local.value = local.values[local.i];
				} else if (StructKeyExists(arguments.missingMethodArguments, local.property)) {
					local.value = arguments.missingMethodArguments[local.property];
				}
				ArrayAppend(
					local.addToWhere,
					"#local.property# #$dynamicFinderOperator(local.property)# #variables.wheels.class.adapter.$quoteValue(str = local.value, type = validationTypeForProperty(local.property))#"
				);
			}

			// construct where clause
			local.addToWhere = ArrayToList(local.addToWhere, " AND ");

			if (StructKeyExists(arguments.missingMethodArguments, "where") && Len(arguments.missingMethodArguments.where)) {
				arguments.missingMethodArguments.where = "(" & arguments.missingMethodArguments.where & ") AND (" & local.addToWhere & ")";
			} else {
				arguments.missingMethodArguments.where = local.addToWhere;
			}

			// remove unneeded arguments
			StructDelete(arguments.missingMethodArguments, "delimiter");
			StructDelete(arguments.missingMethodArguments, "1");
			StructDelete(arguments.missingMethodArguments, "value");
			StructDelete(arguments.missingMethodArguments, "values");

			// call finder method
			if (Left(arguments.missingMethodName, 9) == "findOneBy") {
				local.result.rv = findOne(argumentCollection = arguments.missingMethodArguments);
			} else {
				local.result.rv = findAll(argumentCollection = arguments.missingMethodArguments);
			}
			local.result.handled = true;
		} else if (Left(arguments.missingMethodName, 14) == "findOrCreateBy") {
			local.result.rv = $findOrCreateBy(argumentCollection = arguments);
			local.result.handled = true;
		}
		return local.result;
	}

	/**
	 * Internal function.
	 */
	public any function $findOrCreateBy() {
		// default save to true but set to passed in value if it exists and then delete from arguments
		local.save = true;
		if (StructKeyExists(arguments.missingMethodArguments, "save")) {
			local.save = arguments.missingMethodArguments.save;
			StructDelete(arguments.missingMethodArguments, "save");
		}

		// get the property name from the last part of the function name
		local.property = ReplaceNoCase(arguments.missingMethodName, "findOrCreateBy", "");

		// get the value from the parameter that matches the property name or the first one if named arguments were not used or just one argument was passed in
		if (StructKeyExists(arguments.missingMethodArguments, "1")) {
			arguments.missingMethodArguments[local.property] = arguments.missingMethodArguments[1];
			StructDelete(arguments.missingMethodArguments, "1");
		} else if (StructCount(arguments.missingMethodArguments) == 1) {
			local.key = ListGetAt(StructKeyList(arguments.missingMethodArguments), 1);
			if (local.key != local.property) {
				arguments.missingMethodArguments[local.property] = arguments.missingMethodArguments[local.key];
				StructDelete(arguments.missingMethodArguments, local.key);
			}
		}
		local.value = arguments.missingMethodArguments[local.property];

		// setup arguments for passing in to findOne and create
		StructDelete(arguments, "missingMethodName");
		StructDelete(arguments.missingMethodArguments, local.property);
		StructAppend(arguments, arguments.missingMethodArguments);
		StructDelete(arguments, "missingMethodArguments");

		// add where argument for findOne and remove afterwards
		arguments.where = $keyWhereString(local.property, local.value);
		local.object = findOne(argumentCollection = arguments);
		StructDelete(arguments, "where");

		if (IsObject(local.object)) {
			local.rv = local.object;
		} else {
			arguments[local.property] = local.value;
			if (local.save) {
				local.rv = create(argumentCollection = arguments);
			} else {
				local.rv = new (argumentCollection = arguments);
			}
		}
		return local.rv;
	}

	/**
	 * Internal function.
	 */
	public string function $dynamicFinderOperator(required string property) {
		if (
			StructKeyExists(variables.wheels.class.properties, arguments.property)
			&& variables.wheels.class.properties[arguments.property].dataType == "text"
		) {
			return "LIKE";
		} else {
			return "=";
		}
	}

	/**
	 * Internal function.
	 * Handles the `shortcut` association form — a `findAll` through a join model.
	 * Extracted from $associationMethod to keep its cyclomatic complexity down.
	 * Mutates `missingMethodArguments` in place and returns the resolved method +
	 * componentReference for the caller's final $invoke.
	 */
	public struct function $handleShortcutAssociation(required string key, required struct missingMethodArguments) {
		local.joinAssociation = $expandedAssociations(include = arguments.key);
		local.joinAssociation = local.joinAssociation[1];
		local.info = model(local.joinAssociation.modelName).$expandedAssociations(
			include = ListFirst(variables.wheels.class.associations[arguments.key].through)
		);
		local.info = local.info[1];
		local.componentReference = model(local.info.modelName);
		local.include = ListLast(variables.wheels.class.associations[arguments.key].through);
		if (StructKeyExists(arguments.missingMethodArguments, "include")) {
			local.include = "#local.include#(#arguments.missingMethodArguments.include#)";
		}
		arguments.missingMethodArguments.include = local.include;
		local.where = $keyWhereString(
			properties = local.joinAssociation.foreignKey,
			keys = primaryKeys()
		);
		if (StructKeyExists(arguments.missingMethodArguments, "where")) {
			local.where = "(#local.where#) AND (#arguments.missingMethodArguments.where#)";
		}
		arguments.missingMethodArguments.where = local.where;
		if (!StructKeyExists(arguments.missingMethodArguments, "returnIncluded")) {
			arguments.missingMethodArguments.returnIncluded = false;
		}
		return { method = "findAll", componentReference = local.componentReference };
	}

	/**
	 * Internal function.
	 */
	public any function $associationMethod() {
		for (local.key in variables.wheels.class.associations) {
			local.method = "";
			if (
				StructKeyExists(variables.wheels.class.associations[local.key], "shortcut")
				&& arguments.missingMethodName == variables.wheels.class.associations[local.key].shortcut
			) {
				local.shortcut = $handleShortcutAssociation(local.key, arguments.missingMethodArguments);
				local.method = local.shortcut.method;
				local.componentReference = local.shortcut.componentReference;
			} else if (ListFindNoCase(variables.wheels.class.associations[local.key].methods, arguments.missingMethodName)) {
				local.assoc = variables.wheels.class.associations[local.key];

				// Polymorphic belongsTo: resolve model dynamically from the type column.
				if (
					StructKeyExists(local.assoc, "polymorphic")
					&& local.assoc.polymorphic
					&& local.assoc.type == "belongsTo"
				) {
					local.polyResult = $associationMethodResolvePolymorphicBelongsTo(
						missingMethodName = arguments.missingMethodName,
						key = local.key,
						assoc = local.assoc,
						missingMethodArguments = arguments.missingMethodArguments
					);
					if (local.polyResult.handled) {
						local.rv = local.polyResult.rv;
					}
					continue;
				}

				local.resolved = $associationMethodResolve(
					key = local.key,
					missingMethodName = arguments.missingMethodName,
					missingMethodArguments = arguments.missingMethodArguments
				);
				local.method = local.resolved.method;
				local.componentReference = local.resolved.componentReference;
			}
			if (Len(local.method)) {
				local.rv = $invoke(
					componentReference = local.componentReference,
					method = local.method,
					invokeArgs = arguments.missingMethodArguments
				);
			}
		}

		if (StructKeyExists(local, "rv")) {
			return local.rv;
		}
	}

	/**
	 * Internal function. Resolves a polymorphic `belongsTo` association method, reading
	 * the type column to choose the target model. Returns `{ handled, rv }` where
	 * `handled` is true only when the original code would have set `local.rv` (either
	 * `false` for an empty key or the `$invoke` result).
	 */
	public any function $associationMethodResolvePolymorphicBelongsTo(
		required string missingMethodName,
		required string key,
		required struct assoc,
		required struct missingMethodArguments
	) {
		local.result = { handled = false, rv = "" };
		local.name = ReplaceNoCase(arguments.missingMethodName, arguments.key, "object");
		local.foreignKeyProp = arguments.assoc.foreignKey;
		local.foreignTypeProp = arguments.assoc.foreignType;
		local.method = "";

		if (local.name == "object") {
			// Read the type column to determine which model to query.
			if (StructKeyExists(this, local.foreignTypeProp) && Len(this[local.foreignTypeProp])
				&& StructKeyExists(this, local.foreignKeyProp) && Len(this[local.foreignKeyProp])) {
				local.componentReference = model(this[local.foreignTypeProp]);
				local.method = "findByKey";
				arguments.missingMethodArguments.key = this[local.foreignKeyProp];
			}
		} else if (local.name == "hasObject") {
			// Check if the foreign key is non-empty.
			if (StructKeyExists(this, local.foreignKeyProp) && Len(this[local.foreignKeyProp])
				&& StructKeyExists(this, local.foreignTypeProp) && Len(this[local.foreignTypeProp])) {
				local.componentReference = model(this[local.foreignTypeProp]);
				local.method = "exists";
				arguments.missingMethodArguments.key = this[local.foreignKeyProp];
			} else {
				local.result.rv = false;
				local.result.handled = true;
			}
		}

		if (Len(local.method) && StructKeyExists(local, "componentReference")) {
			local.result.rv = $invoke(
				componentReference = local.componentReference,
				method = local.method,
				invokeArgs = arguments.missingMethodArguments
			);
			local.result.handled = true;
		}
		return local.result;
	}

	/**
	 * Internal function. Resolves a non-polymorphic association method by expanding the
	 * association, resolving the target component, and dispatching on the association
	 * type. Returns `{ method, componentReference }`.
	 */
	public any function $associationMethodResolve(
		required string key,
		required string missingMethodName,
		required struct missingMethodArguments
	) {
		local.info = $expandedAssociations(include = arguments.key);
		local.info = local.info[1];
		local.componentReference = model(local.info.modelName);
		if (local.info.type == "hasOne") {
			return $associationMethodResolveHasOne(
				info = local.info,
				componentReference = local.componentReference,
				missingMethodArguments = arguments.missingMethodArguments,
				key = arguments.key,
				missingMethodName = arguments.missingMethodName
			);
		} else if (local.info.type == "hasMany") {
			return $associationMethodResolveHasMany(
				info = local.info,
				componentReference = local.componentReference,
				missingMethodArguments = arguments.missingMethodArguments,
				key = arguments.key,
				missingMethodName = arguments.missingMethodName
			);
		} else if (local.info.type == "belongsTo") {
			return $associationMethodResolveBelongsTo(
				info = local.info,
				componentReference = local.componentReference,
				missingMethodArguments = arguments.missingMethodArguments,
				key = arguments.key,
				missingMethodName = arguments.missingMethodName
			);
		}
		return { method = "", componentReference = local.componentReference };
	}

	/**
	 * Internal function. Resolves a `hasOne` association method. Mutates
	 * `missingMethodArguments` in place and returns `{ method, componentReference }`.
	 */
	public any function $associationMethodResolveHasOne(
		required struct info,
		required any componentReference,
		required struct missingMethodArguments,
		required string key,
		required string missingMethodName
	) {
		local.componentReference = arguments.componentReference;
		local.isPolymorphic = StructKeyExists(arguments.info, "as") && Len(arguments.info.as) && StructKeyExists(arguments.info, "foreignType");
		local.method = "";
		local.where = $keyWhereString(properties = arguments.info.foreignKey, keys = primaryKeys());
		if (local.isPolymorphic) {
			local.where = "(#local.where#) AND (#arguments.info.foreignType# = '#variables.wheels.class.modelName#')";
		}
		if (StructKeyExists(arguments.missingMethodArguments, "where") && Len(arguments.missingMethodArguments.where)) {
			local.where = "(#local.where#) AND (#arguments.missingMethodArguments.where#)";
		}

		// create a generic method name (example: "hasProfile" becomes "hasObject")
		local.name = ReplaceNoCase(arguments.missingMethodName, arguments.key, "object");

		if (local.name == "object") {
			local.method = "findOne";
			arguments.missingMethodArguments.where = local.where;
		} else if (local.name == "hasObject") {
			local.method = "exists";
			arguments.missingMethodArguments.where = local.where;
		} else if (local.name == "newObject") {
			local.method = "new";
			$setForeignKeyValues(missingMethodArguments = arguments.missingMethodArguments, keys = arguments.info.foreignKey);
			if (local.isPolymorphic) {
				arguments.missingMethodArguments[arguments.info.foreignType] = variables.wheels.class.modelName;
			}
		} else if (local.name == "createObject") {
			local.method = "create";
			$setForeignKeyValues(missingMethodArguments = arguments.missingMethodArguments, keys = arguments.info.foreignKey);
			if (local.isPolymorphic) {
				arguments.missingMethodArguments[arguments.info.foreignType] = variables.wheels.class.modelName;
			}
		} else if (local.name == "removeObject") {
			local.method = "updateOne";
			arguments.missingMethodArguments.where = local.where;
			$setForeignKeyValues(
				missingMethodArguments = arguments.missingMethodArguments,
				keys = arguments.info.foreignKey,
				setToNull = true
			);
		} else if (local.name == "deleteObject") {
			local.method = "deleteOne";
			arguments.missingMethodArguments.where = local.where;
		} else if (local.name == "setObject") {
			local.resolved = $resolveAssociationTarget(
				missingMethodArguments = arguments.missingMethodArguments,
				componentReference = local.componentReference,
				argumentName = arguments.key,
				methodName = local.name,
				objectMethod = "update",
				keyMethod = "updateByKey"
			);
			local.method = local.resolved.method;
			local.componentReference = local.resolved.componentReference;
			$setForeignKeyValues(missingMethodArguments = arguments.missingMethodArguments, keys = arguments.info.foreignKey);
		}
		return { method = local.method, componentReference = local.componentReference };
	}

	/**
	 * Internal function. Resolves a `hasMany` association method. Mutates
	 * `missingMethodArguments` in place and returns `{ method, componentReference }`.
	 */
	public any function $associationMethodResolveHasMany(
		required struct info,
		required any componentReference,
		required struct missingMethodArguments,
		required string key,
		required string missingMethodName
	) {
		local.componentReference = arguments.componentReference;
		local.isPolymorphic = StructKeyExists(arguments.info, "as") && Len(arguments.info.as) && StructKeyExists(arguments.info, "foreignType");
		local.method = "";
		if (structKeyExists(arguments.info, "joinKey") AND Len(arguments.info.joinKey) AND arguments.info.joinKey NEQ primaryKeys()) {
			local.where = $keyWhereString(properties = arguments.info.foreignKey, keys = arguments.info.joinKey);
		} else {
			local.where = $keyWhereString(properties = arguments.info.foreignKey, keys = primaryKeys());
		}
		if (local.isPolymorphic) {
			local.where = "(#local.where#) AND (#arguments.info.foreignType# = '#variables.wheels.class.modelName#')";
		}
		if (StructKeyExists(arguments.missingMethodArguments, "where") && Len(arguments.missingMethodArguments.where)) {
			local.where = "(#local.where#) AND (#arguments.missingMethodArguments.where#)";
		}
		local.singularKey = singularize(arguments.key);

		// create a generic method name (example: "hasComments" becomes "hasObjects")
		local.name = ReplaceNoCase(arguments.missingMethodName, arguments.key, "objects");
		if (local.name == arguments.missingMethodName) {
			// we should never change anything more than once so if the plural version was already replaced we do not need to replace the singular one
			local.name = ReplaceNoCase(local.name, local.singularKey, "object");
		}

		if (local.name == "objects") {
			local.method = "findAll";
			arguments.missingMethodArguments.where = local.where;
		} else if (local.name == "addObject") {
			local.resolved = $resolveAssociationTarget(
				missingMethodArguments = arguments.missingMethodArguments,
				componentReference = local.componentReference,
				argumentName = local.singularKey,
				methodName = local.name,
				objectMethod = "update",
				keyMethod = "updateByKey"
			);
			local.method = local.resolved.method;
			local.componentReference = local.resolved.componentReference;
			$setForeignKeyValues(missingMethodArguments = arguments.missingMethodArguments, keys = arguments.info.foreignKey);
		} else if (local.name == "removeObject") {
			local.resolved = $resolveAssociationTarget(
				missingMethodArguments = arguments.missingMethodArguments,
				componentReference = local.componentReference,
				argumentName = local.singularKey,
				methodName = local.name,
				objectMethod = "update",
				keyMethod = "updateByKey"
			);
			local.method = local.resolved.method;
			local.componentReference = local.resolved.componentReference;
			$setForeignKeyValues(
				missingMethodArguments = arguments.missingMethodArguments,
				keys = arguments.info.foreignKey,
				setToNull = true
			);
		} else if (local.name == "deleteObject") {
			local.resolved = $resolveAssociationTarget(
				missingMethodArguments = arguments.missingMethodArguments,
				componentReference = local.componentReference,
				argumentName = local.singularKey,
				methodName = local.name,
				objectMethod = "delete",
				keyMethod = "deleteByKey"
			);
			local.method = local.resolved.method;
			local.componentReference = local.resolved.componentReference;
			$setForeignKeyValues(missingMethodArguments = arguments.missingMethodArguments, keys = arguments.info.foreignKey);
		} else if (local.name == "hasObjects") {
			local.method = "exists";
			arguments.missingMethodArguments.where = local.where;
		} else if (local.name == "newObject") {
			local.method = "new";
			$setForeignKeyValues(missingMethodArguments = arguments.missingMethodArguments, keys = arguments.info.foreignKey);
			if (local.isPolymorphic) {
				arguments.missingMethodArguments[arguments.info.foreignType] = variables.wheels.class.modelName;
			}
		} else if (local.name == "createObject") {
			local.method = "create";
			$setForeignKeyValues(missingMethodArguments = arguments.missingMethodArguments, keys = arguments.info.foreignKey);
			if (local.isPolymorphic) {
				arguments.missingMethodArguments[arguments.info.foreignType] = variables.wheels.class.modelName;
			}
		} else if (local.name == "objectCount") {
			local.method = "count";
			arguments.missingMethodArguments.where = local.where;
		} else if (local.name == "findOneObject") {
			local.method = "findOne";
			arguments.missingMethodArguments.where = local.where;
		} else if (local.name == "removeAllObjects") {
			local.method = "updateAll";
			arguments.missingMethodArguments.where = local.where;
			$setForeignKeyValues(
				missingMethodArguments = arguments.missingMethodArguments,
				keys = arguments.info.foreignKey,
				setToNull = true
			);
		} else if (local.name == "deleteAllObjects") {
			local.method = "deleteAll";
			arguments.missingMethodArguments.where = local.where;
		}
		return { method = local.method, componentReference = local.componentReference };
	}

	/**
	 * Internal function. Resolves a non-polymorphic `belongsTo` association method.
	 * Mutates `missingMethodArguments` in place and returns `{ method, componentReference }`.
	 */
	public any function $associationMethodResolveBelongsTo(
		required struct info,
		required any componentReference,
		required struct missingMethodArguments,
		required string key,
		required string missingMethodName
	) {
		local.method = "";
		local.where = $keyWhereString(keys = arguments.info.foreignKey, properties = arguments.componentReference.primaryKeys());
		if (StructKeyExists(arguments.missingMethodArguments, "where") && Len(arguments.missingMethodArguments.where)) {
			local.where = "(#local.where#) AND (#arguments.missingMethodArguments.where#)";
		}

		// create a generic method name (example: "hasAuthor" becomes "hasObject")
		local.name = ReplaceNoCase(arguments.missingMethodName, arguments.key, "object");

		if (local.name == "object") {
			local.method = "findByKey";
			arguments.missingMethodArguments.key = $propertyValue(name = arguments.info.foreignKey);
		} else if (local.name == "hasObject") {
			local.method = "exists";
			arguments.missingMethodArguments.key = $propertyValue(name = arguments.info.foreignKey);
		}
		return { method = local.method, componentReference = arguments.componentReference };
	}

	/**
	 * Internal function.
	 */
	public string function $propertyValue(required string name) {
		local.rv = "";
		local.iEnd = ListLen(arguments.name);
		for (local.i = 1; local.i <= local.iEnd; local.i++) {
			local.item = ListGetAt(arguments.name, local.i);
			local.rv = ListAppend(local.rv, this[local.item]);
		}
		return local.rv;
	}

	/**
	 * Internal function.
	 */
	public void function $setForeignKeyValues(
		required struct missingMethodArguments,
		required string keys,
		boolean setToNull = "false"
	) {
		local.iEnd = ListLen(arguments.keys);
		for (local.i = 1; local.i <= local.iEnd; local.i++) {
			local.item = ListGetAt(arguments.keys, local.i);
			if (arguments.setToNull) {
				arguments.missingMethodArguments[local.item] = "";
			} else {
				arguments.missingMethodArguments[local.item] = this[primaryKeys(local.i)];
			}
		}
	}

	/**
	 * Internal function. Resolves the "key or object" argument convention shared by the dynamic
	 * association methods (setObject, addObject, removeObject and deleteObject). Mutates
	 * `missingMethodArguments` in place and returns a struct with the method to invoke plus the
	 * component reference to invoke it on (the supplied object when one was passed, otherwise
	 * the `componentReference` given in the arguments).
	 */
	public struct function $resolveAssociationTarget(
		required struct missingMethodArguments,
		required any componentReference,
		required string argumentName,
		required string methodName,
		required string objectMethod,
		required string keyMethod
	) {
		local.rv = {};
		local.rv.method = "";
		local.rv.componentReference = arguments.componentReference;

		if (StructCount(arguments.missingMethodArguments) == 1) {
			// Single argument, must be either the key or the object.
			if (IsObject(arguments.missingMethodArguments[1])) {
				local.rv.componentReference = arguments.missingMethodArguments[1];
				local.rv.method = arguments.objectMethod;
			} else {
				arguments.missingMethodArguments.key = arguments.missingMethodArguments[1];
				local.rv.method = arguments.keyMethod;
			}
			StructClear(arguments.missingMethodArguments);
		} else {
			// Multiple arguments so ensure that either `key` or the association argument exists.
			if (
				StructKeyExists(arguments.missingMethodArguments, arguments.argumentName)
				&& IsObject(arguments.missingMethodArguments[arguments.argumentName])
			) {
				local.rv.componentReference = arguments.missingMethodArguments[arguments.argumentName];
				local.rv.method = arguments.objectMethod;
				StructDelete(arguments.missingMethodArguments, arguments.argumentName);
			} else if (StructKeyExists(arguments.missingMethodArguments, "key")) {
				local.rv.method = arguments.keyMethod;
			} else {
				Throw(
					type = "Wheels.IncorrectArguments",
					message = "The `#arguments.argumentName#` or `key` named argument is required.",
					extendedInfo = "When using multiple arguments for #arguments.methodName#() you must supply an object using the argument `#arguments.argumentName#` or a key using the argument `key`, e.g. #arguments.methodName#(#arguments.argumentName#=post) or #arguments.methodName#(key=post.id)."
				);
			}
		}
		return local.rv;
	}
</cfscript>
