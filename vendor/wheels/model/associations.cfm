<cfscript>
	/**
	 * Sets up a `belongsTo` association between this model and the specified one.
	 * Use this association when this model contains a foreign key referencing another model.
	 *
	 * [section: Model Configuration]
	 * [category: Association Functions]
	 *
	 * @name Gives the association a name that you refer to when working with the association (in the `include` argument to `findAll`, to name one example).
	 * @modelName Name of associated model (usually not needed if you follow Wheels conventions because the model name will be deduced from the `name` argument).
	 * @foreignKey Foreign key property name (usually not needed if you follow Wheels conventions since the foreign key name will be deduced from the `name` argument).
	 * @joinKey Column name to join to if not the primary key (usually not needed if you follow Wheels conventions since the join key will be the table's primary key/keys).
	 * @joinType Use to set the join type when joining associated tables. Possible values are `inner` (for `INNER JOIN`) and `outer` (for `LEFT OUTER JOIN`).
	 * @polymorphic Set to `true` to declare a polymorphic `belongsTo` association. The foreign key defaults to `{name}Id` and a `{name}Type` column is used to store the owning model name at runtime.
	 * @foreignType The column that stores the owning model's name in a polymorphic association. Defaults to `{name}Type`. Pass it, with `foreignKey`, when the columns are named differently, e.g. `notable_type` / `notable_id` as `t.references(polymorphic = true)` writes them when `useUnderscoreReferenceColumns` is on.
	 */
	public void function belongsTo(
		required string name,
		string modelName = "",
		string foreignKey = "",
		string joinKey = "",
		string joinType,
		boolean polymorphic = false,
		string foreignType = ""
	) {
		$args(name = "belongsTo", args = arguments);
		arguments.type = "belongsTo";

		// Polymorphic belongsTo: the name is the interface name (e.g. "commentable").
		// foreignKey defaults to {name}Id and foreignType to {name}Type; both can be passed.
		if (arguments.polymorphic) {
			// Derived names are checked against the schema on first use ($resolvePolymorphicColumns).
			arguments.$derivedPolymorphicColumns = "";
			if (!Len(arguments.foreignKey)) {
				arguments.foreignKey = "#arguments.name#id";
				arguments.$derivedPolymorphicColumns = ListAppend(arguments.$derivedPolymorphicColumns, "foreignKey");
			}
			if (!Len(arguments.foreignType)) {
				arguments.foreignType = "#arguments.name#type";
				arguments.$derivedPolymorphicColumns = ListAppend(arguments.$derivedPolymorphicColumns, "foreignType");
			}
			// Don't infer modelName — it's resolved at runtime from the type column.
			arguments.modelName = "";
		}

		// The dynamic shortcut methods to add to this class (e.g. "post" , "hasPost").
		arguments.methods = "";
		arguments.methods = ListAppend(arguments.methods, arguments.name);
		arguments.methods = ListAppend(arguments.methods, "has#capitalize(arguments.name)#");

		$registerAssociation(argumentCollection = arguments);
	}

	/**
	 * Sets up a `hasMany` association between this model and the specified one.
	 *
	 * [section: Model Configuration]
	 * [category: Association Functions]
	 *
	 * @name [see:belongsTo].
	 * @modelName [see:belongsTo].
	 * @foreignKey [see:belongsTo].
	 * @joinKey [see:belongsTo].
	 * @joinType [see:belongsTo].
	 * @dependent Defines how to handle dependent model objects when you delete an object from this model. `delete` / `deleteAll` deletes the record(s) (`deleteAll` bypasses object instantiation). `remove` / `removeAll` sets the forein key field(s) to `NULL` (`removeAll` bypasses object instantiation).
	 * @shortcut Set this argument to create an additional dynamic method that gets the object(s) from the other side of a many-to-many association.
	 * @through Set this argument if you need to override Wheels conventions when using the `shortcut` argument. Accepts a list of two association names representing the chain from the opposite side of the many-to-many relationship to this model.
	 * @as Set this argument to declare a polymorphic `hasMany` association. The child model stores the parent type in a `{as}Type` column alongside the foreign key `{as}Id`.
	 * @foreignType The child's column that stores the parent type in a polymorphic (`as`) association. Defaults to `{as}Type`. [see:belongsTo].
	 */
	public void function hasMany(
		required string name,
		string modelName = "",
		string foreignKey = "",
		string joinKey = "",
		string joinType,
		string dependent,
		string shortcut = "",
		string through = "#singularize(arguments.shortcut)#,#arguments.name#",
		string as = "",
		string foreignType = ""
	) {
		$args(name = "hasMany", args = arguments);
		if (StructKeyExists(arguments, "dependent")) {
			$validateDependent(arguments.dependent);
		}
		local.singularizedName = capitalize(singularize(arguments.name));
		local.capitalizedName = capitalize(arguments.name);
		arguments.type = "hasMany";

		// Polymorphic hasMany: `as` is the polymorphic interface name on the child side.
		// foreignKey defaults to {as}Id and foreignType to {as}Type; both can be passed.
		if (Len(arguments.as)) {
			// Derived names are checked against the schema on first use ($resolvePolymorphicColumns).
			arguments.$derivedPolymorphicColumns = "";
			if (!Len(arguments.foreignKey)) {
				arguments.foreignKey = "#arguments.as#id";
				arguments.$derivedPolymorphicColumns = ListAppend(arguments.$derivedPolymorphicColumns, "foreignKey");
			}
			if (!Len(arguments.foreignType)) {
				arguments.foreignType = "#arguments.as#type";
				arguments.$derivedPolymorphicColumns = ListAppend(arguments.$derivedPolymorphicColumns, "foreignType");
			}
		}

		// The dynamic shortcut methods to add to this class (e.g. "comment", "commentCount", "addComment" etc).
		arguments.methods = "";
		arguments.methods = ListAppend(arguments.methods, arguments.name);
		arguments.methods = ListAppend(arguments.methods, "#local.singularizedName#Count");
		arguments.methods = ListAppend(arguments.methods, "add#local.singularizedName#");
		arguments.methods = ListAppend(arguments.methods, "create#local.singularizedName#");
		arguments.methods = ListAppend(arguments.methods, "delete#local.singularizedName#");
		arguments.methods = ListAppend(arguments.methods, "deleteAll#local.capitalizedName#");
		arguments.methods = ListAppend(arguments.methods, "findOne#local.singularizedName#");
		arguments.methods = ListAppend(arguments.methods, "has#local.capitalizedName#");
		arguments.methods = ListAppend(arguments.methods, "new#local.singularizedName#");
		arguments.methods = ListAppend(arguments.methods, "remove#local.singularizedName#");
		arguments.methods = ListAppend(arguments.methods, "removeAll#local.capitalizedName#");

		$registerAssociation(argumentCollection = arguments);
	}

	/**
	 * Sets up a `hasOne` association between this model and the specified one.
	 *
	 * [section: Model Configuration]
	 * [category: Association Functions]
	 *
	 * @name [see:belongsTo].
	 * @modelName [see:belongsTo].
	 * @foreignKey [see:belongsTo].
	 * @joinKey [see:belongsTo].
	 * @joinType [see:belongsTo].
	 * @dependent [see:hasMany].
	 * @as Set this argument to declare a polymorphic `hasOne` association. The child model stores the parent type in a `{as}Type` column alongside the foreign key `{as}Id`.
	 * @foreignType The child's column that stores the parent type in a polymorphic (`as`) association. Defaults to `{as}Type`. [see:belongsTo].
	 */
	public void function hasOne(
		required string name,
		string modelName = "",
		string foreignKey = "",
		string joinKey = "",
		string joinType,
		string dependent,
		string as = "",
		string foreignType = ""
	) {
		$args(name = "hasOne", args = arguments);
		if (StructKeyExists(arguments, "dependent")) {
			$validateDependent(arguments.dependent);
		}
		local.capitalizedName = capitalize(arguments.name);
		arguments.type = "hasOne";

		// Polymorphic hasOne: `as` is the polymorphic interface name on the child side.
		// foreignKey defaults to {as}Id and foreignType to {as}Type; both can be passed.
		if (Len(arguments.as)) {
			// Derived names are checked against the schema on first use ($resolvePolymorphicColumns).
			arguments.$derivedPolymorphicColumns = "";
			if (!Len(arguments.foreignKey)) {
				arguments.foreignKey = "#arguments.as#id";
				arguments.$derivedPolymorphicColumns = ListAppend(arguments.$derivedPolymorphicColumns, "foreignKey");
			}
			if (!Len(arguments.foreignType)) {
				arguments.foreignType = "#arguments.as#type";
				arguments.$derivedPolymorphicColumns = ListAppend(arguments.$derivedPolymorphicColumns, "foreignType");
			}
		}

		// The dynamic shortcut methods to add to this class (e.g. "profile", "createProfile", "deleteProfile" etc).
		arguments.methods = "";
		arguments.methods = ListAppend(arguments.methods, arguments.name);
		arguments.methods = ListAppend(arguments.methods, "create#local.capitalizedName#");
		arguments.methods = ListAppend(arguments.methods, "delete#local.capitalizedName#");
		arguments.methods = ListAppend(arguments.methods, "has#local.capitalizedName#");
		arguments.methods = ListAppend(arguments.methods, "new#local.capitalizedName#");
		arguments.methods = ListAppend(arguments.methods, "remove#local.capitalizedName#");
		arguments.methods = ListAppend(arguments.methods, "set#local.capitalizedName#");

		$registerAssociation(argumentCollection = arguments);
	}

	/**
	 * Internal function. Maps an association's `joinType` to "inner" or "outer".
	 * "left" and "left outer" are accepted as aliases of "outer" (all emit
	 * `LEFT OUTER JOIN`); any other value throws. "left" used to be passed through
	 * as `LEFT JOIN`, which the nested-include grouping does not recognise, so a
	 * nested join under it was silently dropped.
	 */
	public string function $normalizeJoinType(required string joinType, required string associationName) {
		local.value = LCase(Trim(REReplace(arguments.joinType, "\s+", " ", "all")));
		if (local.value == "inner") {
			return "inner";
		}
		if (ListFindNoCase("outer|left|left outer", local.value, "|")) {
			return "outer";
		}
		Throw(
			type = "Wheels.InvalidJoinType",
			message = "Invalid joinType `#arguments.joinType#` on the `#arguments.associationName#` association.",
			extendedInfo = "Use `inner` (INNER JOIN) or `outer` (LEFT OUTER JOIN); `left` and `left outer` are accepted as aliases of `outer`."
		);
	}

	/*
	 * Registers the association info in the model object on the application scope.
	 */
	public void function $registerAssociation() {
		// Assign the name for the association.
		local.associationName = arguments.name;

		// Normalise the join type once, so everything downstream sees "inner" or "outer".
		if (StructKeyExists(arguments, "joinType")) {
			arguments.joinType = $normalizeJoinType(arguments.joinType, local.associationName);
		}

		// Default our nesting to false and set other nesting properties.
		arguments.nested = {};
		arguments.nested.allow = false;
		arguments.nested.delete = false;
		arguments.nested.autosave = false;
		arguments.nested.sortProperty = "";
		arguments.nested.rejectIfBlank = "";

		// Infer model name from association name unless developer specified it already.
		// Polymorphic belongsTo skips inference — the model is resolved at runtime from the type column.
		if (
			!Len(arguments.modelName)
			&& !(StructKeyExists(arguments, "polymorphic") && arguments.polymorphic)
		) {
			if (arguments.type == "hasMany") {
				arguments.modelName = singularize(local.associationName);
			} else {
				arguments.modelName = local.associationName;
			}
		}

		// Set pluralized association name, to be used when aliasing the table.
		arguments.pluralizedName = pluralize(local.associationName);

		// Set a friendly label for the foreign key on belongsTo associations (e.g. 'userid' becomes 'User');
		if (arguments.type == "belongsTo" && !(StructKeyExists(arguments, "polymorphic") && arguments.polymorphic)) {
			// Get the property name using the specified foreign key or the wheels convention of modelName + id;
			if (Len(arguments.foreignKey)) {
				local.propertyName = arguments.foreignKey; // custom foreign key column
			} else {
				local.propertyName = "#arguments.modelName#id"; // wheels convention
			}
			// Set the label (if it hasn't already been specified)
			if (
				!StructKeyExists(variables.wheels.class.mapping, local.propertyName)
				|| !StructKeyExists(variables.wheels.class.mapping[local.propertyName], "label")
			) {
				property(name = local.propertyName, label = humanize(arguments.name));
			}
			
			$registerBoxLangForeignKey(local.propertyName);
		}

		// BoxLang compatibility: Register foreign key properties for hasMany and hasOne associations.
		if (ListFindNoCase("hasMany,hasOne", arguments.type)) {
			local.foreignKeyName = Len(arguments.foreignKey) ? arguments.foreignKey : "#LCase(variables.wheels.class.modelName)#id";
			$registerBoxLangForeignKey(local.foreignKeyName);
		}

		// Store all the settings for the association in the class data.
		// One struct per association with the name of the association as the key.
		// We delete the name from the arguments because we use it as the key and don't need to store it elsewhere.
		StructDelete(arguments, "name");
		variables.wheels.class.associations[local.associationName] = arguments;
	}

	/**
	 * Internal function. Resolves a polymorphic association's DERIVED column names against the child's
	 * real columns on first use, the way the non-polymorphic defaults are (#3337): `<name>id` /
	 * `<name>type` when the child has them, else `<name>_id` / `<name>_type`, which
	 * `t.references(polymorphic = true)` writes with useUnderscoreReferenceColumns. When both shapes
	 * exist the legacy one wins; when neither does, or the schema can't be read, the legacy default
	 * stays. Names passed as foreignKey / foreignType are never changed. Memoized per association.
	 */
	public void function $resolvePolymorphicColumns(required string associationName) {
		if (!StructKeyExists(variables.wheels.class.associations, arguments.associationName)) {
			return;
		}
		local.association = variables.wheels.class.associations[arguments.associationName];
		if (!StructKeyExists(local.association, "$derivedPolymorphicColumns") || !Len(local.association.$derivedPolymorphicColumns)) {
			return;
		}
		lock name="wheelsPolymorphicColumns#application.applicationName#" type="exclusive" timeout="10" {
			if (Len(local.association.$derivedPolymorphicColumns)) {
				$applyPolymorphicColumnShapes(associationName = arguments.associationName, association = local.association);
				local.association.$derivedPolymorphicColumns = "";
			}
		}
	}

	/**
	 * Internal function. The schema read behind [see:$resolvePolymorphicColumns]: the child is this
	 * model for a polymorphic belongsTo, and the associated model for hasMany / hasOne with `as`. A
	 * failure to read it keeps the legacy names.
	 */
	public void function $applyPolymorphicColumnShapes(required string associationName, required struct association) {
		try {
			if (arguments.association.type == "belongsTo") {
				local.base = arguments.associationName;
				local.childProperties = variables.wheels.class.properties;
			} else {
				local.base = arguments.association.as;
				local.childProperties = model(arguments.association.modelName).$classData().properties;
			}
			for (local.column in ListToArray(arguments.association.$derivedPolymorphicColumns)) {
				local.suffix = local.column == "foreignKey" ? "id" : "type";
				if (
					!StructKeyExists(local.childProperties, local.base & local.suffix)
					&& StructKeyExists(local.childProperties, local.base & "_" & local.suffix)
				) {
					arguments.association[local.column] = local.base & "_" & local.suffix;
				}
			}
		} catch (any e) {
			writeLog(
				file = "wheels",
				type = "warning",
				text = "Wheels: couldn't read the columns for the polymorphic association `#arguments.associationName#`; using its default column names. #e.message#"
			);
		}
	}

	/**
	 * Internal function. Throws Wheels.InvalidArgument for a `dependent` value hasMany() and hasOne()
	 * don't support, so the mistake surfaces when the association is declared, not at the first delete.
	 */
	public void function $validateDependent(required any dependent) {
		if (IsBoolean(arguments.dependent) && !arguments.dependent) {
			return;
		}
		if (IsSimpleValue(arguments.dependent) && ListFindNoCase("delete,deleteAll,remove,removeAll", arguments.dependent)) {
			return;
		}
		Throw(
			type = "Wheels.InvalidArgument",
			message = "'#IsSimpleValue(arguments.dependent) ? arguments.dependent : "(complex value)"#' is not a valid dependency.",
			extendedInfo = "Use `delete`, `deleteAll`, `remove`, `removeAll` or `false`."
		);
	}

	/*
	 * Called when a model object is deleted (e.g. post.delete()).
	 * Deletes all associated records (or sets their foreign key values to NULL). When the object itself
	 * was soft-deleted (`parentSoftDeleted`), nothing a restore would need is destroyed or unlinked:
	 * dependents that can be soft-deleted are, and every other dependent is left alone. With
	 * `callbacks = false` the instantiated dependents skip their callbacks too.
	 */
	public void function $deleteDependents(
		boolean softDelete = true,
		boolean includeSoftDeletes = false,
		boolean callbacks = true,
		boolean parentSoftDeleted = false
	) {
		for (local.key in variables.wheels.class.associations) {
			local.association = variables.wheels.class.associations[local.key];
			if (
				ListFindNoCase("hasMany,hasOne", local.association.type)
				&& local.association.dependent != false
				&& !$dependentKeptBySoftDelete(association = local.association, parentSoftDeleted = arguments.parentSoftDeleted)
			) {
				local.all = "";
				if (local.association.type == "hasMany") {
					local.all = "All";
				}
				switch (local.association.dependent) {
					case "delete":
						local.invokeArgs = {};
						local.invokeArgs.instantiate = true;
						local.invokeArgs.callbacks = arguments.callbacks;
						local.invokeArgs.softDelete = arguments.softDelete;
						local.invokeArgs.includeSoftDeletes = arguments.includeSoftDeletes;
						$invoke(componentReference = this, method = "delete#local.all##local.key#", invokeArgs = local.invokeArgs);
						break;
					case "remove":
						local.invokeArgs = {};
						local.invokeArgs.instantiate = true;
						local.invokeArgs.callbacks = arguments.callbacks;
						$invoke(componentReference = this, method = "remove#local.all##local.key#", invokeArgs = local.invokeArgs);
						break;
					case "deleteAll":
						// a hasOne's deleteAll still instantiates (deleteOne), so it needs callbacks too
						local.invokeArgs = {};
						local.invokeArgs.callbacks = arguments.callbacks;
						local.invokeArgs.softDelete = arguments.softDelete;
						local.invokeArgs.includeSoftDeletes = arguments.includeSoftDeletes;
						$invoke(componentReference = this, method = "delete#local.all##local.key#", invokeArgs = local.invokeArgs);
						break;
					case "removeAll":
						local.invokeArgs = {};
						local.invokeArgs.callbacks = arguments.callbacks;
						$invoke(componentReference = this, method = "remove#local.all##local.key#", invokeArgs = local.invokeArgs);
						break;
					default:
						Throw(
							type = "Wheels.InvalidArgument",
							message = "'#local.association.dependent#' is not a valid dependency.",
							extendedInfo = "Use `delete`, `deleteAll`, `remove`, `removeAll` or `false`."
						);
				}
			}
		}
	}

	/**
	 * Internal function. True when a soft-deleted parent leaves this dependent association alone:
	 * `remove` / `removeAll` would unlink the children, and `delete` / `deleteAll` would destroy children
	 * whose model has no soft-delete column.
	 */
	public boolean function $dependentKeptBySoftDelete(required struct association, required boolean parentSoftDeleted) {
		if (!arguments.parentSoftDeleted) {
			return false;
		}
		if (ListFindNoCase("remove,removeAll", arguments.association.dependent)) {
			return true;
		}
		return !model(arguments.association.modelName).$softDeletion();
	}

	/**
	 * Internal function.
	 * Registers a foreign key property with integer type for BoxLang compatibility.
	 */
	public void function $registerBoxLangForeignKey(required string propertyName) {
		if ($engineAdapter().isBoxLang() && !StructKeyExists(variables.wheels.class.properties, arguments.propertyName)) {
			property(name = arguments.propertyName, type = "integer");
		}
	}
</cfscript>
