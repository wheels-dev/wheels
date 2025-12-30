component {
	/**
	 * Internal function.
	 */
	public array function $addDeleteClause(required array sql, required boolean softDelete, struct useIndex = {}) {
		if (variables.wheels.class.softDeletion && arguments.softDelete) {
			if (structKeyExists(arguments, "useIndex") && !structIsEmpty(arguments.useIndex)) {
				local.indexHint = this.$indexHint(
					useIndex = arguments.useIndex,
					modelName = variables.wheels.class.modelName,
					adapterName = get("adapterName")
				);
				if (Len(local.indexHint)) {
					ArrayAppend(arguments.sql, "UPDATE #tableName()# #local.indexHint# SET #variables.wheels.class.softDeleteColumn# = ");
				} else {
					ArrayAppend(arguments.sql, "UPDATE #tableName()# SET #variables.wheels.class.softDeleteColumn# = ");
				}
			} else {
				ArrayAppend(arguments.sql, "UPDATE #tableName()# SET #variables.wheels.class.softDeleteColumn# = ");
			}
			// Use cf_sql_varchar in SQLite for TEXT timestamps
			if(get("adapterName") eq "SQLite") {
				local.type = "cf_sql_varchar";
			} else {
				local.type = "cf_sql_timestamp";
			}
			local.param = {value = $timestamp(variables.wheels.class.timeStampMode), type = local.type};
			ArrayAppend(arguments.sql, local.param);
		} else {
			if (structKeyExists(arguments, "useIndex") && !structIsEmpty(arguments.useIndex)) {
				ArrayAppend(arguments.sql, "DELETE tbl FROM #tableName()# tbl");
			} else {
				ArrayAppend(arguments.sql, "DELETE FROM #tableName()#");
			}
		}
		return arguments.sql;
	}

	public string function $indexHint(required struct useIndex, required string modelName, required string adapterName) {
		local.rv = "";
		if (StructKeyExists(arguments.useIndex, arguments.modelName)) {
			local.indexName = arguments.useIndex[arguments.modelName];
			if (arguments.adapterName == "MySQLModel") {
				local.rv = "USE INDEX(#local.indexName#)";
			} else if (arguments.adapterName == "MicrosoftSQLServerModel") {
				local.rv = "WITH (INDEX(#local.indexName#))";
			}
		}
		return local.rv;
	}

	/**
	 * Internal function.
	 */
	public string function $fromClause(
		required string include,
		boolean includeSoftDeletes = "false",
		struct useIndex = {},
		string adapterName = get("adapterName")
	) {
		// start the from statement with the SQL keyword and the table name for the current model
		local.rv = "FROM " & tableName();

		// add the index hint
		local.indexHint = this.$indexHint(
			useIndex = arguments.useIndex,
			modelName = variables.wheels.class.modelName,
			adapterName = arguments.adapterName
		);
		if (Len(local.indexHint)) {
			local.rv = ListAppend(local.rv, local.indexHint, " ");
		}

		// add join statements if associations have been specified through the include argument
		if (Len(arguments.include)) {
			// get info for all associations
			local.associations = $expandedAssociations(
				include = arguments.include,
				includeSoftDeletes = arguments.includeSoftDeletes
			);

			// Check if we need to nest inner joins (when both inner and outer joins are present)
			// Only apply nesting for HABTM patterns, not for all mixed join scenarios
			local.hasInnerJoins = false;
			local.hasOuterJoins = false;
			local.hasThroughAssociation = false;
			local.iEnd = ArrayLen(local.associations);
			
			// Check if this is specifically a through association pattern
			local.originalInclude = Replace(arguments.include, " ", "", "all");
			if (Find("(", local.originalInclude)) {
				// Parse the include to see if it matches through pattern: intermediate(target)
				local.includePattern = ReFindNoCase("^([^(]+)\(([^)]+)\)$", local.originalInclude, 1, true);
				if (ArrayLen(local.includePattern.pos) >= 3) {
					local.hasThroughAssociation = true;
				}
			}
			
			for (local.i = 1; local.i <= local.iEnd; local.i++) {
				if (FindNoCase("INNER", local.associations[local.i].join)) {
					local.hasInnerJoins = true;
				}
				if (FindNoCase("OUTER", local.associations[local.i].join) || FindNoCase("LEFT", local.associations[local.i].join)) {
					local.hasOuterJoins = true;
				}
			}
			
			// Only apply nesting for through associations with mixed join types
			local.needsNesting = local.hasInnerJoins && local.hasOuterJoins && local.hasThroughAssociation;

			// build the join statements
			if (local.needsNesting) {
				// group inner joins with parentheses and outer joins separately
				local.innerJoins = [];
				local.outerJoins = [];
				
				for (local.i = 1; local.i <= local.iEnd; local.i++) {
					local.indexHint = this.$indexHint(
						useIndex = arguments.useIndex,
						modelName = local.associations[local.i].modelName,
						adapterName = arguments.adapterName
					);
					local.join = local.associations[local.i].join;
					if (Len(local.indexHint)) {
						// replace the table name with the table name & index hint
						// TODO: factor in table aliases.. the index hint is placed after the table alias
						local.join = Replace(
							local.join,
							" #local.associations[local.i].tableName# ",
							" #local.associations[local.i].tableName# #local.indexHint# ",
							"one"
						);
					}
					
					if (FindNoCase("INNER", local.join)) {
						ArrayAppend(local.innerJoins, local.join);
					} else {
						ArrayAppend(local.outerJoins, local.join);
					}
				}
				
				for (local.i = 1; local.i <= ArrayLen(local.outerJoins); local.i++) {
					local.outerJoin = local.outerJoins[local.i];
					
					// If we have inner joins, we need to group them in the outer join
					if (ArrayLen(local.innerJoins) > 0) {
						// Find the table being joined in the outer join
						local.joinTableMatch = ReFindNoCase("LEFT OUTER JOIN ([^\s]+)", local.outerJoin, 1, true);
						if (ArrayLen(local.joinTableMatch.pos) >= 2 && local.joinTableMatch.pos[2] > 0) {
							local.joinTable = Mid(local.outerJoin, local.joinTableMatch.pos[2], local.joinTableMatch.len[2]);
							
							// Build grouped inner joins: (subscriptions INNER JOIN magazines ON ...)
							local.groupedInner = "(" & local.joinTable;
							for (local.j = 1; local.j <= ArrayLen(local.innerJoins); local.j++) {
								local.groupedInner &= " " & local.innerJoins[local.j];
							}
							local.groupedInner &= ")";
							
							// Replace in the outer join
							local.outerJoin = Replace(local.outerJoin, "LEFT OUTER JOIN " & local.joinTable, "LEFT OUTER JOIN " & local.groupedInner);
						}
					}
					
					local.rv = ListAppend(local.rv, local.outerJoin, " ");
				}
			} else {
				// original logic for when nesting is not needed
				for (local.i = 1; local.i <= local.iEnd; local.i++) {
					local.indexHint = this.$indexHint(
						useIndex = arguments.useIndex,
						modelName = local.associations[local.i].modelName,
						adapterName = arguments.adapterName
					);
					local.join = local.associations[local.i].join;
					if (Len(local.indexHint)) {
						// replace the table name with the table name & index hint
						// TODO: factor in table aliases.. the index hint is placed after the table alias
						local.join = Replace(
							local.join,
							" #local.associations[local.i].tableName# ",
							" #local.associations[local.i].tableName# #local.indexHint# ",
							"one"
						);
					}
					local.rv = ListAppend(local.rv, local.join, " ");
				}
			}
		}
		return local.rv;
	}

	/**
	 * Internal function.
	 */
	public array function $addKeyWhereClause(required array sql) {
		ArrayAppend(arguments.sql, " WHERE ");
		local.iEnd = ListLen(primaryKeys());
		for (local.i = 1; local.i <= local.iEnd; local.i++) {
			local.key = primaryKeys(local.i);
			ArrayAppend(arguments.sql, variables.wheels.class.properties[local.key].column & " = ");
			if (hasChanged(local.key)) {
				local.value = changedFrom(local.key);
			} else {
				local.value = this[local.key];
			}
			if (Len(local.value)) {
				local.null = false;
			} else {
				local.null = true;
			}
			local.param = {
				value = local.value,
				type = variables.wheels.class.properties[local.key].type,
				dataType = variables.wheels.class.properties[local.key].dataType,
				scale = variables.wheels.class.properties[local.key].scale,
				null = local.null
			};
			ArrayAppend(arguments.sql, local.param);
			if (local.i < local.iEnd) {
				ArrayAppend(arguments.sql, " AND ");
			}
		}
		return arguments.sql;
	}

	/**
	 * Internal function.
	 */
	public string function $orderByClause(required string order, required string include) {
		local.rv = "";
		if (Len(arguments.order)) {
			if (arguments.order == "random") {
				local.rv = variables.wheels.class.adapter.$randomOrder();
			} else if (Find("(", arguments.order)) {
				local.rv = arguments.order;
			} else {
				// Setup an array containing class info for current class and all the ones that should be included.
				local.classes = [];
				if (Len(arguments.include)) {
					local.classes = $expandedAssociations(include = arguments.include);
				}
				ArrayPrepend(local.classes, variables.wheels.class);

				local.rv = "";
				local.orderArray = ListToArray(arguments.order);
				local.iEnd = ArrayLen(local.orderArray);
				for (local.i = 1; local.i <= local.iEnd; local.i++) {
					local.iItem = Trim(local.orderArray[local.i]);
					if (!Find(" ASC", local.iItem) && !Find(" DESC", local.iItem)) {
						local.iItem &= " ASC";
					}
					if (Find(".", local.iItem)) {
						local.rv = ListAppend(local.rv, local.iItem);
					} else {
						local.property = ListLast(SpanExcluding(local.iItem, " "), ".");
						local.jEnd = ArrayLen(local.classes);
						for (local.j = 1; local.j <= local.jEnd; local.j++) {
							local.toAdd = "";
							local.classData = local.classes[local.j];
							if (StructKeyExists(local.classData.propertyStruct, local.property)) {
								local.toAdd = local.classData.tableName & "." & local.classData.properties[local.property].column;
							} else if (StructKeyExists(local.classData.calculatedProperties, local.property)) {
								local.sql = local.classData.calculatedProperties[local.property].sql;
								local.toAdd = "(" & Replace(local.sql, ",", "[[comma]]", "all") & ")";
							}
							if (Len(local.toAdd)) {
								if (!StructKeyExists(local.classData.columnStruct, local.property)) {
									local.toAdd &= " AS " & local.property;
								}
								local.toAdd &= " " & UCase(ListLast(local.iItem, " "));
								if (!ListFindNoCase(local.rv, local.toAdd)) {
									local.rv = ListAppend(local.rv, local.toAdd);
									break;
								}
							}
						}
						if (application.wheels.showErrorInformation && !Len(local.toAdd)) {
							Throw(
								type = "Wheels.ColumnNotFound",
								message = "Wheels looked for the column mapped to the `#local.property#` property but couldn't find it in the database table.",
								extendedInfo = "Verify the `order` argument and/or your property to column mappings done with the `property` method inside the model's `config` method to make sure everything is correct."
							);
						}
					}
				}
			}
			local.rv = "ORDER BY " & local.rv;
		}
		return local.rv;
	}

	/**
	 * Internal function.
	 */
	public string function $groupByClause(
		required string select,
		required string include,
		required string group,
		required boolean distinct,
		required string returnAs
	) {
		local.rv = "";
		local.args = {};
		local.args.include = arguments.include;
		local.args.returnAs = arguments.returnAs;
		local.args.clause = "groupBy";
		if (arguments.distinct) {
			// if we want a distinct statement, we can do it grouping every field in the select
			local.args.list = arguments.select;
			local.rv = $createSQLFieldList(argumentCollection = local.args);

			// Remove any [[duplicate]] markers in the GROUP BY clause
			local.rv = ReReplaceNoCase(local.rv, "\[\[duplicate\]\]\d+", "", "all");

			local.groupByItems = [];
			local.selectItems = ListToArray(local.rv);

			for (local.item in local.selectItems) {
				// Only skip subqueries (items with SELECT inside parentheses)
				if (!Find("(", local.item) || !FindNoCase("SELECT", local.item)) {
					ArrayAppend(local.groupByItems, local.item);
				}
			}

			local.rv = ArrayToList(local.groupByItems);
		} else if (Len(arguments.group)) {
			local.args.list = arguments.group;
			local.rv = $createSQLFieldList(argumentCollection = local.args);
		}
		if (Len(local.rv)) {
			local.rv = "GROUP BY " & local.rv;
		}
		return local.rv;
	}

	/**
	 * Internal function.
	 */
	public string function $selectClause(
		required string select,
		required string include,
		boolean includeSoftDeletes = "false",
		required string returnAs
	) {
		local.rv = $createSQLFieldList(
			clause = "select",
			list = arguments.select,
			include = arguments.include,
			includeSoftDeletes = arguments.includeSoftDeletes,
			returnAs = arguments.returnAs
		);
		
		// Look for " AS " followed by text containing multiple dots (namespaced aliases)
		if (Find(" AS ", local.rv)) {
			// Wrap column aliases that contain multiple dots with double quotes (ANSI SQL standard)
			local.rv = REReplace(local.rv, " AS ([^,\s]+\.[^,\s]*\.[^,\s]*)", " AS ""\1""", "all");
		}
		
		local.rv = "SELECT " & local.rv;
		return local.rv;
	}

	/**
	 * Internal function.
	 */
	public string function $createSQLFieldList(
		required string clause,
		required string list,
		required string include,
		required string returnAs,
		boolean includeSoftDeletes = "false",
		boolean useExpandedColumnAliases = "#application.wheels.useExpandedColumnAliases#"
	) {
		// setup an array containing class info for current class and all the ones that should be included
		local.classes = [];
		if (Len(arguments.include)) {
			local.classes = $expandedAssociations(
				include = arguments.include,
				includeSoftDeletes = arguments.includeSoftDeletes
			);
		}
		ArrayPrepend(local.classes, variables.wheels.class);

		// if the developer passes in tablename.*, translate it into the list of fields for the developer, this is so we don't get *'s in the group by
		if (Find(".*", arguments.list)) {
			arguments.list = $expandProperties(list = arguments.list, classes = local.classes);
		}

		// add properties to select if the developer did not specify any
		if (!Len(arguments.list)) {
			local.iEnd = ArrayLen(local.classes);
			for (local.i = 1; local.i <= local.iEnd; local.i++) {
				local.classData = local.classes[local.i];
				arguments.list = ListAppend(arguments.list, local.classData.propertyList);
				if (StructCount(local.classData.calculatedProperties)) {
					for (local.key in local.classData.calculatedProperties) {
						if (local.classData.calculatedProperties[local.key].select) {
							arguments.list = ListAppend(arguments.list, local.key);
						}
					}
				}
			}
		}

		// go through the properties and map them to the database unless the developer passed in a table name or an alias in which case we assume they know what they're doing and leave the select clause as is

		/* To fix the issue below:
			https://github.com/wheels-dev/wheels/issues/1048

			The original issue was due to the alias not being passed in to identify the same columns in multiple tables. When we pass in the alias/dot notation in the select clause, it does not add the calculated properties due to the below condition which causes the original name of calculated property to be passed in the final query instead of the definition of calculated property, and that gives an invalid column when executed. Commented the below if and else condition and made fixes in case "." and " AS " is passed in.
		*/
		// if (!Find(".", arguments.list) && !Find(" AS ", arguments.list)) {
			local.rv = "";
			local.addedProperties = "";
			local.addedPropertiesByModel = {};
			local.selectArray = $splitOutsideFunctions(arguments.list, ",");
			local.iEnd = arrayLen(local.selectArray);
			for (local.i = 1; local.i <= local.iEnd; local.i++) {
				local.iItem = Trim(local.selectArray[i]);

				// look for duplicates
				local.duplicateCount = ListValueCountNoCase(local.addedProperties, local.iItem);
				local.addedProperties = ListAppend(local.addedProperties, local.iItem);

				/* To fix the issue below:
					https://github.com/wheels-dev/wheels/issues/1048

					In case "." or " AS " is passed in the column name item, append that as it is in the select query and then move onto the next iteration.
				*/
				if (Find(".", local.iItem) || Find(" AS ", local.iItem)) {
					local.rv = ListAppend(local.rv, local.iItem);
					continue;
				}

				// loop through all classes (current and all included ones)
				local.jEnd = ArrayLen(local.classes);
				for (local.j = 1; local.j <= local.jEnd; local.j++) {
					local.toAppend = "";
					local.classData = local.classes[local.j];

					local.associationKey = local.classData.modelName;
					if (structKeyExists(local.classData, "pluralizedName") && local.classData.pluralizedName != "") {
						local.associationKey &= "_" & local.classData.pluralizedName;
					}

					// Init the tracking list for this association
					if (!structKeyExists(local.addedPropertiesByModel, local.associationKey)) {
						local.addedPropertiesByModel[local.associationKey] = "";
					}

					// if we find the property in this model and it's not already added we go ahead and add it to the select clause
					if (
						(
							StructKeyExists(local.classData.propertyStruct, local.iItem)
							|| StructKeyExists(local.classData.calculatedProperties, local.iItem)
							|| ListFindNoCase(local.classData.aliasedPropertyList, local.iItem)
						)
						&& !ListFindNoCase(local.addedPropertiesByModel[local.associationKey], local.iItem)
					) {
						// if expanded column aliases is enabled then mark all columns from included classes as duplicates in order to prepend them with their class name
						local.flagAsDuplicate = false;

						/*
							To fix the issue below:
							https://github.com/wheels-dev/wheels/issues/580

							Get the column passed in the select argument with the included table's name prepended to it and replace table name to get the original name.

							For example,
							If the developer includes "comment" table and passes commentCreatedAt column name in select, then get the createdAt column in comment table and return that.

							This is only valid for id,createdAt,updatedAt,deletedAt columns.
						*/
						if(Len(arguments.include) && ListFindNoCase(local.classData.aliasedPropertyList, local.iItem)){
							local.iItem = replaceNoCase(local.iItem, local.classData.modelName, '');
							local.flagAsDuplicate = true;
						}

						if (arguments.clause == "select") {
							if (local.duplicateCount) {
								// always flag as a duplicate when a property with this name has already been added
								local.flagAsDuplicate = true;
							} else if (local.j > 1) {
								if (arguments.useExpandedColumnAliases) {
									// when on included models and using the new setting we flag every property as a duplicate so that the model name always gets prepended
									local.flagAsDuplicate = true;
								} else if (!arguments.useExpandedColumnAliases && arguments.returnAs != "query") {
									// with the old setting we only do it when we're returning object(s) since when creating instances on none base models we need the model name prepended
									local.flagAsDuplicate = true;
								}
							}
						}
						if (local.flagAsDuplicate) {
							local.toAppend &= "[[duplicate]]" & local.j;
						}
						if (StructKeyExists(local.classData.propertyStruct, local.iItem)) {
							local.toAppend &= local.classData.tableName & ".";
							if (StructKeyExists(local.classData.columnStruct, local.iItem)) {
								local.toAppend &= local.iItem;
							} else {
								local.toAppend &= local.classData.properties[local.iItem].column;
								if (arguments.clause == "select") {
									local.toAppend &= " AS " & local.iItem;
								}
							}
						} else if (StructKeyExists(local.classData.calculatedProperties, local.iItem)) {
							local.sql = Replace(local.classData.calculatedProperties[local.iItem].sql, ",", "[[comma]]", "all");
							if (arguments.clause == "select" || !ReFind("^(SELECT )?(AVG|COUNT|MAX|MIN|SUM)\(.*\)", local.sql)) {
								local.toAppend &= "(" & local.sql & ")";
								if (arguments.clause == "select") {
									local.toAppend &= " AS " & local.iItem;
								}
							}
						}
						local.addedPropertiesByModel[local.associationKey] = ListAppend(
							local.addedPropertiesByModel[local.associationKey],
							local.iItem
						);
						break;
					}
				}

				/*
					To fix the bug below:
					https://github.com/wheels-dev/wheels/issues/591

					Added an exception in case the column specified in the select or group argument does not exist in the database.
					This will only be in case when not using "table.column" or "column AS something" since in those cases Wheels passes through the select clause unchanged.
				*/
				if (application.wheels.showErrorInformation && !Len(local.toAppend) && arguments.clause == "select" && ListFindNoCase(local.addedPropertiesByModel[local.associationKey], local.iItem) EQ 0) {
					Throw(
						type = "Wheels.ColumnNotFound",
						message = "Wheels looked for the column mapped to the `#local.iItem#` property but couldn't find it in the database table.",
						extendedInfo = "Verify the `#arguments.clause#` argument and/or your property to column mappings done with the `property` method inside the model's `config` method to make sure everything is correct."
					);
				}

				if (Len(local.toAppend)) {
					local.rv = ListAppend(local.rv, local.toAppend);
				}
			}

			// let's replace eventual duplicates in the clause by prepending the class name
			if (Len(arguments.include) && arguments.clause == "select") {
				local.newSelect = "";
				local.addedProperties = "";
				local.filteredArray = ListToArray(local.rv);
				local.iEnd = ArrayLen(local.filteredArray);
				for (local.i = 1; local.i <= local.iEnd; local.i++) {
					local.iItem = local.filteredArray[local.i];

					// get the property part, done by taking everything from the end of the string to a . or a space (which would be found when using " AS ")
					local.property = Reverse(SpanExcluding(Reverse(local.iItem), ". "));

					// check if this one has been flagged as a duplicate, we get the number of classes to skip and also remove the flagged info from the item
					local.duplicateCount = 0;
					local.matches = ReFind("^\[\[duplicate\]\](\d+)(.+)$", local.iItem, 1, true);
					if (local.matches.pos[1] > 0) {
						local.duplicateCount = Mid(local.iItem, local.matches.pos[2], local.matches.len[2]);
						local.iItem = Mid(local.iItem, local.matches.pos[3], local.matches.len[3]);
					}

					if (!local.duplicateCount) {
						// this is not a duplicate so we can just insert it as is
						local.newItem = local.iItem;
						local.newProperty = local.property;
					} else {
						// this is a duplicate so we prepend the class name and then insert it unless a property with the resulting name already exist
						local.classData = local.classes[local.duplicateCount];

						// Initialize aliasFound
						local.aliasFound = false;
						local.alias = "";

						// Check for join and extract alias
						if (StructKeyExists(local.classData, "join")) {
							local.match = ReFindNoCase("\sAS\s+(\w+)", local.classData.join, 1, true);
							if (ArrayLen(local.match.len) >= 2 && local.match.len[2] > 0) {
								local.alias = Mid(local.classData.join, local.match.pos[2], local.match.len[2]);
								local.aliasFound = CompareNoCase(local.alias, local.classData.pluralizedName) EQ 0;
							}
						}

						// Construct newProperty using alias or modelName
						local.newProperty = (local.aliasFound ? local.alias : local.classData.modelName) & local.property;

						// Determine newItem based on presence of " AS " in iItem
						if (Find(" AS ", local.iItem)) {
							local.newItem = ReplaceNoCase(local.iItem, " AS " & local.property, " AS " & local.newProperty);
						} else {
							if (local.aliasFound) {
								local.newItem = local.alias & "." & local.property & " AS " & local.newProperty;
							} else {
								local.newItem = local.iItem & " AS " & local.newProperty;
							}
						}
					}
					if (!ListFindNoCase(local.addedProperties, local.newProperty)) {
						local.newSelect = ListAppend(local.newSelect, local.newItem);
						local.addedProperties = ListAppend(local.addedProperties, local.newProperty);
					}
				}
				local.rv = local.newSelect;
			}

			if (arguments.clause == "groupBy" && Find(" AS ", local.rv)) {
				local.rv = ReReplace(local.rv, variables.wheels.class.RESQLAs, "", "all");
			}
		// } else {
		// 	local.rv = arguments.list;
		// 	if (arguments.clause == "groupBy" && Find(" AS ", local.rv)) {
		// 		local.rv = ReReplace(local.rv, variables.wheels.class.RESQLAs, "", "all");
		// 	}
		// }
		return local.rv;
	}

	/**
	 * Internal function.
	 */
	public array function $addWhereClause(
		required array sql,
		required string where,
		required string include,
		required boolean includeSoftDeletes,
		boolean softDelete = true,
		struct useIndex = {}
	) {
		// Issue#1273: Added this section to allow included tables to be referenced in the query
		local.migration = CreateObject("component", "wheels.migrator.Migration").init();
		local.tempSql = "";
		if(arguments.include != "" && ListFind('PostgreSQL,H2,MicrosoftSQLServer,Oracle,SQLite', local.migration.adapter.adapterName()) && structKeyExists(arguments, "sql")){
			local.tempSql = arguments.sql;
		}
		local.whereClause = $whereClause(
			where = arguments.where,
			include = arguments.include,
			includeSoftDeletes = arguments.includeSoftDeletes,
			softDelete = arguments.softDelete,
			useIndex = arguments.useIndex,
			sql = local.tempSql
		);
		if(arguments.include != "" && ListFind('PostgreSQL', local.migration.adapter.adapterName()) && structKeyExists(arguments, "sql")){
			if(left(arguments.sql[1], 6) == 'UPDATE'){
				ArrayAppend(arguments.sql, "FROM #arguments.include#");
			}
		}
		else if(arguments.include != "" && ListFind('MicrosoftSQLServer', local.migration.adapter.adapterName()) && structKeyExists(arguments, "sql")){
			if(left(arguments.sql[1], 6) == 'UPDATE'){
				ArrayAppend(arguments.sql, "FROM #tablename()#");
			}
		}
		else if(arguments.include != "" && ListFind('H2,Oracle,SQLite', local.migration.adapter.adapterName()) && structKeyExists(arguments, "sql")){
			if(left(arguments.sql[1], 6) == 'UPDATE'){
				ArrayAppend(arguments.sql, "WHERE EXISTS (SELECT 1 FROM #arguments.include#");
			}
		}
		local.iEnd = ArrayLen(local.whereClause);
		for (local.i = 1; local.i <= local.iEnd; local.i++) {
			ArrayAppend(arguments.sql, local.whereClause[local.i]);
		}
		return arguments.sql;
	}

	/**
	 * Internal function.
	 */
	public array function $whereClause(required string where, string include = "", boolean includeSoftDeletes = "false", sql = "", boolean softDelete = "true", useIndex = {}) {
		local.rv = [];
		if (Len(arguments.where)) {
			// setup an array containing class info for current class and all the ones that should be included
			local.classes = [];
			if (Len(arguments.include)) {
				local.classes = $expandedAssociations(include = arguments.include);
			}
			ArrayPrepend(local.classes, variables.wheels.class);
			// Issue#1273: Added this section to allow included tables to be referenced in the query
			local.joinclause = "";
			local.migration = CreateObject("component", "wheels.migrator.Migration").init();
			if(arguments.include != "" && ListFind('PostgreSQL,H2', local.migration.adapter.adapterName()) && left(arguments.sql[1], 6) == 'UPDATE'){
				for(local.i = 1; local.i<= arrayLen(local.classes); i++){
					if(structKeyExists(local.classes[local.i], "JOIN")){
						local.joinclause &= local.classes[local.i].JOIN.Split("ON")[2];
					}
				}
				ArrayAppend(local.rv, "WHERE #local.joinclause# AND");
			}
			else if(arguments.include != "" && ListFind('MicrosoftSQLServer', local.migration.adapter.adapterName()) && left(arguments.sql[1], 6) == 'UPDATE'){
				for(local.i = 1; local.i<= arrayLen(local.classes); i++){
					if(structKeyExists(local.classes[local.i], "JOIN")){
						local.joinclause &= local.classes[local.i].JOIN;
					}
				}
				ArrayAppend(local.rv, "#local.joinclause# WHERE ");
			}
			else if(arguments.include != "" && ListFind('Oracle,SQLite', local.migration.adapter.adapterName()) && left(arguments.sql[1], 6) == 'UPDATE'){
				ArrayAppend(local.rv, "WHERE");
				ArrayAppend(local.rv, local.classes[2].JOIN.Split("ON")[2] & " AND");
			}
			else {
				ArrayAppend(local.rv, "WHERE");
			}
			local.wherePos = ArrayLen(local.rv) + 1;
			local.params = [];
			local.where = ReReplace(
				ReReplace(arguments.where, variables.wheels.class.RESQLWhere, "\1?\8", "all"),
				"([^a-zA-Z0-9])(AND|OR)([^a-zA-Z0-9])",
				"\1#Chr(7)#\2\3",
				"all"
			);
			local.whereArray = ListToArray(local.where, Chr(7));
			local.iEnd = ArrayLen(local.whereArray);
			for (local.i = 1; local.i <= local.iEnd; local.i++) {
				local.param = {};
				local.element = local.whereArray[local.i];
				if (Find("(", local.element) && Find(")", local.element)) {
					local.elementDataPart = SpanExcluding(Reverse(SpanExcluding(Reverse(local.element), "(")), ")");
				} else if (Find("(", local.element)) {
					local.elementDataPart = Reverse(SpanExcluding(Reverse(local.element), "("));
				} else if (Find(")", local.element)) {
					local.elementDataPart = SpanExcluding(local.element, ")");
				} else {
					local.elementDataPart = local.element;
				}
				local.elementDataPart = Trim(ReReplace(local.elementDataPart, "^(AND|OR)", ""));
				local.temp = ReFind(
					"^([a-zA-Z0-9-_\.]*) ?#variables.wheels.class.RESQLOperators#",
					local.elementDataPart,
					1,
					true
				);
				if (ArrayLen(local.temp.len) > 1) {
					local.where = Replace(local.where, local.element, Replace(local.element, local.elementDataPart, "?", "one"));
					local.param.property = Mid(local.elementDataPart, local.temp.pos[2], local.temp.len[2]);
					local.jEnd = ArrayLen(local.classes);
					for (local.j = 1; local.j <= local.jEnd; local.j++) {
						local.param.dataType = "char";
						local.param.type = "CF_SQL_CHAR";
						local.param.scale = 0;
						local.param.list = false;
						local.classData = local.classes[local.j];
						local.table = ListFirst(local.param.property, ".");
						local.column = ListLast(local.param.property, ".");
						if (!Find(".", local.param.property) || local.table == local.classData.tableName) {
							if (StructKeyExists(local.classData.propertyStruct, local.column)) {
								if ((structKeyExists(arguments, "useIndex") && !structIsEmpty(arguments.useIndex)) && !($softDeletion() && arguments.softDelete)) {
									local.param.column = "tbl." & local.classData.properties[local.column].column;
								} else {
									local.param.column = local.classData.tableName & "." & local.classData.properties[local.column].column;
								}								
								local.param.dataType = local.classData.properties[local.column].dataType;
								local.param.type = local.classData.properties[local.column].type;
								local.param.scale = local.classData.properties[local.column].scale;
								break;
							} else if (StructKeyExists(local.classData.calculatedProperties, local.column)) {
								local.param.column = "(" & local.classData.calculatedProperties[local.column].sql & ")";
								if (StructKeyExists(local.classData.calculatedProperties[local.column], "dataType")) {
									local.param.dataType = local.classData.calculatedProperties[local.column].dataType;
									local.param.type = variables.wheels.class.adapter.$getType(local.param.dataType);
								}
								break;
							}
						}
					}
					if (application.wheels.showErrorInformation && !StructKeyExists(local.param, "column")) {
						Throw(
							type = "Wheels.ColumnNotFound",
							message = "Wheels looked for the column mapped to the `#local.param.property#` property but couldn't find it in the database table.",
							extendedInfo = "Verify the `where` argument and/or your property to column mappings done with the `property` method inside the model's `config` method to make sure everything is correct."
						);
					}
					local.temp = ReFind(
						"^[a-zA-Z0-9-_\.]* ?#variables.wheels.class.RESQLOperators#",
						local.elementDataPart,
						1,
						true
					);
					local.param.operator = Trim(Mid(local.elementDataPart, local.temp.pos[2], local.temp.len[2]));
					if (Right(local.param.operator, 2) == "IN") {
						local.param.list = true;
					}
					ArrayAppend(local.params, local.param);
				}
			}
			local.where = ReplaceList(local.where, "#Chr(7)#AND,#Chr(7)#OR", "AND,OR");

			// add to sql array
			local.where = " " & local.where & " ";
			local.whereArray = ListToArray(local.where, "?");
			local.iEnd = ArrayLen(local.whereArray);
			for (local.i = 1; local.i <= local.iEnd; local.i++) {
				local.item = local.whereArray[local.i];
				if (Len(Trim(local.item))) {
					ArrayAppend(local.rv, local.item);
				}
				if (local.i < ArrayLen(local.whereArray)) {
					local.column = local.params[local.i].column;
					ArrayAppend(local.rv, local.column & " " & local.params[local.i].operator);
					local.param = {
						type = local.params[local.i].type,
						dataType = local.params[local.i].dataType,
						scale = local.params[local.i].scale,
						list = local.params[local.i].list,
						property = local.column
					};
					ArrayAppend(local.rv, local.param);
				}
			}
		}

		// add soft delete sql
		if (!arguments.includeSoftDeletes) {
			local.addToWhere = "";
			if ($softDeletion() && arguments.softDelete) {
				local.addToWhere = ListAppend(local.addToWhere, tableName() & "." & $softDeleteColumn() & " IS NULL");
			} else if ($softDeletion()) {
				if (structKeyExists(arguments, "useIndex") && !structIsEmpty(arguments.useIndex)) {
					local.addToWhere = ListAppend(local.addToWhere, "tbl." & $softDeleteColumn() & " IS NULL");
				} else {
					local.addToWhere = ListAppend(local.addToWhere, tableName() & "." & $softDeleteColumn() & " IS NULL");
				}
			}
			local.addToWhere = Replace(local.addToWhere, ",", " AND ", "all");
			if (Len(local.addToWhere)) {
				if (Len(arguments.where)) {
					if(!(ListFind('Oracle,SQLite', local.migration.adapter.adapterName()) && (isArray(arguments.sql) && left(arguments.sql[1], 6) == 'UPDATE'))){
						ArrayInsertAt(local.rv, local.wherePos, " (");
					}
					ArrayAppend(local.rv, ") AND (");
					ArrayAppend(local.rv, local.addToWhere);
					ArrayAppend(local.rv, ")");
				} else {
					ArrayAppend(local.rv, "WHERE ");
					ArrayAppend(local.rv, local.addToWhere);
				}
			}
		}
		return local.rv;
	}

	/**
	 * Internal function.
	 */
	public array function $addWhereClauseParameters(required array sql, required string where) {
		if (Len(arguments.where)) {
			local.start = 1;
			local.originalValues = [];
			while (!StructKeyExists(local, "temp") || ArrayLen(local.temp.len) > 1) {
				local.temp = ReFind(variables.wheels.class.RESQLWhere, arguments.where, local.start, true);
				if (ArrayLen(local.temp.len) > 1) {
					local.start = local.temp.pos[4] + local.temp.len[4];
					local.extractedValue = Mid(arguments.where, local.temp.pos[4], local.temp.len[4]);

					// BoxLang compatibility: Handle comma-separated values in IN clauses differently
					if (StructKeyExists(server, "boxlang")) {
						local.processedValue = local.extractedValue;
						// Remove outer parentheses if present (e.g., "(1,2,3)" -> "1,2,3")
						if (Left(local.processedValue, 1) == "(" && Right(local.processedValue, 1) == ")") {
							local.processedValue = Mid(local.processedValue, 2, Len(local.processedValue) - 2);
						}
						
						// BoxLang: Only apply quote cleanup if the value contains quotes
						if (Find("'", local.processedValue) > 0 || Find(Chr(34), local.processedValue) > 0) {
							local.cleanedValue = local.processedValue;							
							local.cleanedValue = ReReplace(local.cleanedValue, "'([^']*)'", "\1", "ALL");
							local.doubleQuote = Chr(34);
							local.cleanedValue = ReReplace(local.cleanedValue, "#local.doubleQuote#([^#local.doubleQuote#]*)#local.doubleQuote#", "\1", "ALL");
							
							ArrayAppend(local.originalValues, local.cleanedValue);
						} else {
							ArrayAppend(local.originalValues, local.processedValue);
						}
					} else {
						ArrayAppend(
							local.originalValues,
							ReplaceList(
								Chr(7) & local.extractedValue & Chr(7),
								"#Chr(7)#(,)#Chr(7)#,#Chr(7)#','#Chr(7)#,#Chr(7)#"",""#Chr(7)#,#Chr(7)#",
								",,,,,,"
							)
						);
					}
				}
			}
			if (
				StructKeyExists(arguments, "parameterize")
				&& IsNumeric(arguments.parameterize)
				&& arguments.parameterize != ArrayLen(local.originalValues)
			) {
				Throw(
					type = "Wheels.ParameterMismatch",
					message = "Wheels found #ArrayLen(local.originalValues)# parameters in the query string but was instructed to parameterize #arguments.parameterize#.",
					extendedInfo = "Verify that the number of parameters specified in the `where` argument matches the number in the parameterize argument."
				);
			}
			local.pos = ArrayLen(local.originalValues);
			local.iEnd = ArrayLen(arguments.sql);
			for (local.i = local.iEnd; local.i > 0; local.i--) {
				if (IsStruct(arguments.sql[local.i]) && local.pos > 0) {
					if (structKeyExists(arguments.sql[local.i], 'property') && local.originalValues[local.pos] != 'null'){
						structDelete(arguments.sql[local.i], 'property');
					}
					arguments.sql[local.i].value = local.originalValues[local.pos];
					if (local.originalValues[local.pos] == "") {
						arguments.sql[local.i].null = true;
					}
					local.pos--;
				}
			}
		}
		return arguments.sql;
	}

	/**
	 * Internal function.
	 */
	public string function $expandProperties(required string list, required array classes) {
		local.rv = arguments.list;
		local.matches = ReMatch("[A-Za-z1-9_]+\.\*", local.rv);
		local.iEnd = ArrayLen(local.matches);
		for (local.i = 1; local.i <= local.iEnd; local.i++) {
			local.match = local.matches[local.i];
			local.fields = "";
			local.tableName = ListGetAt(local.match, 1, ".");
			local.jEnd = ArrayLen(arguments.classes);
			for (local.j = 1; local.j <= local.jEnd; local.j++) {
				local.class = arguments.classes[local.j];
				if (local.class.tableName == local.tableName) {
					for (local.item in local.class.properties) {
						local.fields = ListAppend(local.fields, "#local.class.tableName#.#local.item#");
					}
					break;
				}
			}
			if (Len(local.fields)) {
				local.rv = Replace(local.rv, local.match, local.fields, "all");
			} else if (application.wheels.showErrorInformation) {
				Throw(
					type = "Wheels.ModelNotFound",
					message = "Wheels looked for the model mapped to table name `#local.tableName#` but couldn't find it.",
					extendedInfo = "Verify the `select` argument and/or your model association mappings are correct."
				);
			}
		}
		return local.rv;
	}

	/**
	 * Internal function.
	 */
	public string function $expandThroughAssociations(required string include) {
		local.rv = "";
		local.associations = variables.wheels.class.associations;
		
		// If the include string contains parentheses, it's already a complex nested include
		// Don't try to process it for through associations - return as-is
		if (Find("(", arguments.include)) {
			return arguments.include;
		}
		
		// Split the include string by commas to handle multiple simple includes
		local.includeList = ListToArray(arguments.include);
		
		for (local.i = 1; local.i <= ArrayLen(local.includeList); local.i++) {
			local.currentInclude = Trim(local.includeList[local.i]);
			
			// Check if this association has a 'through' defined
			if (StructKeyExists(local.associations, local.currentInclude) 
				&& StructKeyExists(local.associations[local.currentInclude], "through")
				&& Len(local.associations[local.currentInclude].through)) {
				
				local.throughPath = local.associations[local.currentInclude].through;
				
				if (ListLen(local.throughPath) == 1) {
					local.intermediateAssociationName = local.throughPath;
					
					// Get the current association info for the target we're trying to include
					local.currentAssociation = local.associations[local.currentInclude];
					
					// Check if we have a direct association to the intermediate model
					if (StructKeyExists(local.associations, local.intermediateAssociationName)) {
						local.intermediateAssociation = local.associations[local.intermediateAssociationName];
						
						// Get the intermediate model to find what it relates to
						local.intermediateModel = model(local.intermediateAssociation.modelName);
						local.intermediateAssociations = local.intermediateModel.$classData().associations;
						
						// Find the association that leads to our target model
						local.targetModelName = local.currentAssociation.modelName;
						local.targetAssociation = "";
						
						for (local.assocName in local.intermediateAssociations) {
							local.assoc = local.intermediateAssociations[local.assocName];
							if (local.assoc.modelName == local.targetModelName) {
								local.targetAssociation = local.assocName;
								break;
							}
						}
						
						if (Len(local.targetAssociation)) {
							local.expandedInclude = local.intermediateAssociationName & "(" & local.targetAssociation & ")";
							local.rv = ListAppend(local.rv, local.expandedInclude);
						} else {
							// Fallback to original include if we can't determine the path
							local.rv = ListAppend(local.rv, local.currentInclude);
						}
					} else {
						// Intermediate association not found, use as-is
						local.rv = ListAppend(local.rv, local.currentInclude);
					}
				} else {
					local.firstAssociation = ListFirst(local.throughPath);
					local.targetAssociation = ListLast(local.throughPath);
					
					local.expandedInclude = local.firstAssociation & "(" & local.targetAssociation & ")";
					local.rv = ListAppend(local.rv, local.expandedInclude);
				}
			} else {
				// No through association, use as-is
				local.rv = ListAppend(local.rv, local.currentInclude);
			}
		}
		
		return local.rv;
	}

	/**
	 * Internal function.
	 */
	public array function $expandedAssociations(required string include, boolean includeSoftDeletes = "false") {
		local.rv = [];

		// add the current class name so that the levels list start at the lowest level
		local.levels = variables.wheels.class.modelName;

		// expand through associations before processing
		local.include = $expandThroughAssociations(arguments.include);

		// count the included associations
		local.iEnd = ListLen(Replace(local.include, "(", ",", "all"));

		// clean up spaces in list and add a comma at the end to indicate end of string
		local.include = Replace(local.include, " ", "", "all") & ",";

		// store all tables used in the query so we can alias them when needed
		local.tables = tableName();

		local.pos = 1;

		for (local.i = 1; local.i <= local.iEnd; local.i++) {
			// look for the next delimiter sequence in the string and set it (can be single delims or a chain, e.g ',' or ')),'
			local.delimFind = ReFind("[(\(|\)|,)]+", local.include, local.pos, true);
			local.delimSequence = Mid(local.include, local.delimFind.pos[1], local.delimFind.len[1]);

			// set current association name and set new position to start search in the next loop
			local.name = Mid(local.include, local.pos, local.delimFind.pos[1] - local.pos);
			local.pos = ReFindNoCase("[a-z]", local.include, local.delimFind.pos[1]);

			// create a reference to current class in include string and get its association info
			local.class = model(ListLast(local.levels));
			local.classAssociations = local.class.$classData().associations;

			// throw an error if the association was not found
			if (application.wheels.showErrorInformation && !StructKeyExists(local.classAssociations, local.name)) {
				Throw(
					type = "Wheels.AssociationNotFound",
					message = "An association named `#local.name#` could not be found on the `#ListLast(local.levels)#` model.",
					extendedInfo = "Setup an association in the `config` method of the `models/#capitalize(ListLast(local.levels))#.cfc` file and name it `#local.name#`. You can use the `belongsTo`, `hasOne` or `hasMany` method to set it up."
				);
			}

			// create a reference to the associated class
			local.associatedClass = model(local.classAssociations[local.name].modelName);

			if (!Len(local.classAssociations[local.name].foreignKey)) {
				// cfformat-ignore-start
				if (local.classAssociations[local.name].type == "belongsTo") {
					local.classAssociations[local.name].foreignKey = local.associatedClass.$classData().modelName & Replace(local.associatedClass.$classData().keys, ",", ",#local.associatedClass.$classData().modelName#", "all");
				} else {
					local.classAssociations[local.name].foreignKey = local.class.$classData().modelName & Replace(local.class.$classData().keys, ",", ",#local.class.$classData().modelName#", "all");
				}
				// cfformat-ignore-end
			}
			if (!Len(local.classAssociations[local.name].joinKey)) {
				if (local.classAssociations[local.name].type == "belongsTo") {
					local.classAssociations[local.name].joinKey = local.associatedClass.$classData().keys;
				} else {
					local.classAssociations[local.name].joinKey = local.class.$classData().keys;
				}
			}
			local.classAssociations[local.name].tableName = local.associatedClass.$classData().tableName;
			local.classAssociations[local.name].columnList = local.associatedClass.$classData().columnList;
			local.classAssociations[local.name].properties = local.associatedClass.$classData().properties;
			local.classAssociations[local.name].propertyList = local.associatedClass.$classData().propertyList;

			/*
				To fix the issue below:
				https://github.com/wheels-dev/wheels/issues/580

				Add aliasedPropertyList in the associated class that will be used to check the duplicate column
			*/
			local.classAssociations[local.name].aliasedPropertyList = local.associatedClass.$classData().aliasedPropertyList;

			local.classAssociations[local.name].calculatedProperties = local.associatedClass.$classData().calculatedProperties;
			local.classAssociations[local.name].calculatedPropertyList = local.associatedClass.$classData().calculatedPropertyList;
			// TODO: deprecate the lists above in favour of these structs to avoid listFind
			local.classAssociations[local.name].columnStruct = local.associatedClass.$classData().columnStruct;
			local.classAssociations[local.name].propertyStruct = local.associatedClass.$classData().propertyStruct;

			// create the join string if it hasn't already been done
			if (!StructKeyExists(local.classAssociations[local.name], "join")) {
				local.joinType = UCase(ReplaceNoCase(local.classAssociations[local.name].joinType, "outer", "left outer", "one"));
				local.join = local.joinType & " JOIN " & local.classAssociations[local.name].tableName;
				// alias the table as the association name when joining to itself
				if (ListFindNoCase(local.tables, local.classAssociations[local.name].tableName)) {
					local.join = variables.wheels.class.adapter.$tableAlias(
						local.join,
						local.classAssociations[local.name].pluralizedName
					);
				}

				local.join &= " ON ";
				local.toAppend = "";
				local.jEnd = ListLen(local.classAssociations[local.name].foreignKey);
				for (local.j = 1; local.j <= local.jEnd; local.j++) {
					local.key1 = ListGetAt(local.classAssociations[local.name].foreignKey, local.j);
					if (local.classAssociations[local.name].type == "belongsTo") {
						local.key2 = ListFindNoCase(local.classAssociations[local.name].joinKey, local.key1);
						if (local.key2) {
							local.key2 = ListGetAt(local.classAssociations[local.name].joinKey, local.key2);
						} else {
							local.key2 = ListGetAt(local.classAssociations[local.name].joinKey, local.j);
						}
						local.first = local.key1;
						local.second = local.key2;
					} else {
						local.key2 = ListFindNoCase(local.classAssociations[local.name].joinKey, local.key1);
						if (local.key2) {
							local.key2 = ListGetAt(local.classAssociations[local.name].joinKey, local.key2);
						} else {
							local.key2 = ListGetAt(local.classAssociations[local.name].joinKey, local.j);
						}
						local.first = local.key2;
						local.second = local.key1;
					}

					// alias the table as the association name when joining to itself
					local.tableName = local.classAssociations[local.name].tableName;
					if (ListFindNoCase(local.tables, local.classAssociations[local.name].tableName)) {
						local.tableName = local.classAssociations[local.name].pluralizedName;
						;
					}
					local.toAppend = ListAppend(
						local.toAppend,
						"#local.class.$classData().tableName#.#local.class.$classData().properties[local.first].column# = #local.tableName#.#local.associatedClass.$classData().properties[local.second].column#"
					);
					if (!arguments.includeSoftDeletes && local.associatedClass.$softDeletion()) {
						local.toAppend = ListAppend(
							local.toAppend,
							"#local.associatedClass.tableName()#.#local.associatedClass.$softDeleteColumn()# IS NULL"
						);
					}
				}
				local.classAssociations[local.name].join = local.join & Replace(local.toAppend, ",", " AND ", "all");
			}

			// loop over each character in the delimiter sequence and move up / down the levels as appropriate
			local.jEnd = Len(local.delimSequence);
			for (local.j = 1; local.j <= local.jEnd; local.j++) {
				local.delimChar = Mid(local.delimSequence, local.j, 1);
				if (local.delimChar == "(") {
					local.levels = ListAppend(local.levels, local.classAssociations[local.name].modelName);
				} else if (local.delimChar == ")") {
					local.levels = ListDeleteAt(local.levels, ListLen(local.levels));
				}
			}

			// add table name to the list of used ones so we know to alias it when used a second time
			local.tables = ListAppend(local.tables, local.classAssociations[local.name].tableName);

			// add info to the array that we will return
			ArrayAppend(local.rv, local.classAssociations[local.name]);
		}
		return local.rv;
	}

	/**
	 * Internal function.
	 */
	public string function $keyWhereString(any properties = primaryKeys(), any values = "", any keys = "") {
		local.rv = "";
		local.propertiesArray = ListToArray(arguments.properties);
		local.iEnd = ArrayLen(local.propertiesArray);
		local.valuesArray = Len(arguments.values) ? ListToArray(arguments.values) : [];
		local.keysArray = Len(arguments.keys) ? ListToArray(arguments.keys) : [];
		for (local.i = 1; local.i <= local.iEnd; local.i++) {
			local.key = Trim(local.propertiesArray[local.i]);
			if (ArrayLen(local.valuesArray)) {
				local.value = local.valuesArray[local.i];
			} else if (ArrayLen(local.keysArray)) {
				local.value = this[local.keysArray[local.i]];
			} else {
				local.value = "";
			}
			local.type = validationTypeForProperty(local.key);
			local.toAppend = local.key & "=" & variables.wheels.class.adapter.$quoteValue(str = local.value, type = local.type);
			local.rv = ListAppend(local.rv, local.toAppend, " ");
			if (local.i < local.iEnd) {
				local.rv = ListAppend(local.rv, "AND", " ");
			}
		}
		return local.rv;
	}


}
