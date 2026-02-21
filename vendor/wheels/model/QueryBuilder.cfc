/**
 * A chainable, injection-safe query builder for Wheels models.
 * Provides a fluent API alternative to the traditional `findAll(where="...")` string approach.
 *
 * Usage:
 *   model("User")
 *       .where("status", "active")
 *       .where("age", ">", 18)
 *       .orderBy("name", "ASC")
 *       .limit(25)
 *       .get();
 *
 * All values are safely quoted using the model's database adapter, preventing SQL injection.
 * The builder ultimately delegates to the model's standard finder methods (findAll, findOne, etc.).
 */
component output="false" {

	/**
	 * Initialize the query builder with a reference to the model.
	 *
	 * @modelReference The model class instance to build queries for.
	 * @scopeSpecs Optional array of scope specification structs to merge in.
	 */
	public any function init(required any modelReference, array scopeSpecs = []) {
		variables.modelReference = arguments.modelReference;
		variables.scopeSpecs = arguments.scopeSpecs;
		variables.whereClauses = [];
		variables.orderClauses = [];
		variables.selectClause = "";
		variables.includeClause = "";
		variables.limitValue = -1;
		variables.offsetValue = 0;
		variables.distinctValue = false;
		variables.groupClause = "";
		return this;
	}

	/**
	 * Add a WHERE condition. Supports multiple calling conventions:
	 *   .where("status", "active")           -> status = 'active'
	 *   .where("age", ">", 18)               -> age > 18
	 *   .where("status = 'active'")           -> status = 'active' (raw string passthrough)
	 *
	 * @property The property name, or a raw WHERE string if only one argument is provided.
	 * @operatorOrValue The operator (if 3 args) or the value (if 2 args).
	 * @value The value to compare against (when using 3-argument form).
	 */
	public any function where() {
		if (StructCount(arguments) == 1) {
			// Raw WHERE string: .where("status = 'active'")
			ArrayAppend(variables.whereClauses, {type: "AND", clause: arguments[1]});
		} else if (StructCount(arguments) == 2) {
			// Property + value: .where("status", "active") -> status = 'active'
			local.clause = $buildCondition(arguments[1], "=", arguments[2]);
			ArrayAppend(variables.whereClauses, {type: "AND", clause: local.clause});
		} else if (StructCount(arguments) == 3) {
			// Property + operator + value: .where("age", ">", 18) -> age > 18
			local.clause = $buildCondition(arguments[1], arguments[2], arguments[3]);
			ArrayAppend(variables.whereClauses, {type: "AND", clause: local.clause});
		}
		return this;
	}

	/**
	 * Add an OR WHERE condition. Same calling conventions as where().
	 */
	public any function orWhere() {
		if (StructCount(arguments) == 1) {
			ArrayAppend(variables.whereClauses, {type: "OR", clause: arguments[1]});
		} else if (StructCount(arguments) == 2) {
			local.clause = $buildCondition(arguments[1], "=", arguments[2]);
			ArrayAppend(variables.whereClauses, {type: "OR", clause: local.clause});
		} else if (StructCount(arguments) == 3) {
			local.clause = $buildCondition(arguments[1], arguments[2], arguments[3]);
			ArrayAppend(variables.whereClauses, {type: "OR", clause: local.clause});
		}
		return this;
	}

	/**
	 * Add a WHERE IS NULL condition.
	 *
	 * @property The property name to check for NULL.
	 */
	public any function whereNull(required string property) {
		ArrayAppend(variables.whereClauses, {type: "AND", clause: "#arguments.property# IS NULL"});
		return this;
	}

	/**
	 * Add a WHERE IS NOT NULL condition.
	 *
	 * @property The property name to check for NOT NULL.
	 */
	public any function whereNotNull(required string property) {
		ArrayAppend(variables.whereClauses, {type: "AND", clause: "#arguments.property# IS NOT NULL"});
		return this;
	}

	/**
	 * Add a WHERE BETWEEN condition.
	 *
	 * @property The property name to check.
	 * @low The lower bound value.
	 * @high The upper bound value.
	 */
	public any function whereBetween(required string property, required any low, required any high) {
		local.lowQuoted = $quoteValue(arguments.property, arguments.low);
		local.highQuoted = $quoteValue(arguments.property, arguments.high);
		ArrayAppend(variables.whereClauses, {type: "AND", clause: "#arguments.property# BETWEEN #local.lowQuoted# AND #local.highQuoted#"});
		return this;
	}

	/**
	 * Add a WHERE IN condition.
	 *
	 * @property The property name to check.
	 * @values A list or array of values to match against.
	 */
	public any function whereIn(required string property, required any values) {
		local.valueList = $quoteValueList(arguments.property, arguments.values);
		ArrayAppend(variables.whereClauses, {type: "AND", clause: "#arguments.property# IN (#local.valueList#)"});
		return this;
	}

	/**
	 * Add a WHERE NOT IN condition.
	 *
	 * @property The property name to check.
	 * @values A list or array of values to exclude.
	 */
	public any function whereNotIn(required string property, required any values) {
		local.valueList = $quoteValueList(arguments.property, arguments.values);
		ArrayAppend(variables.whereClauses, {type: "AND", clause: "#arguments.property# NOT IN (#local.valueList#)"});
		return this;
	}

	/**
	 * Add an ORDER BY clause.
	 *
	 * @property The property name to order by.
	 * @direction The sort direction: "ASC" or "DESC". Defaults to "ASC".
	 */
	public any function orderBy(required string property, string direction = "ASC") {
		ArrayAppend(variables.orderClauses, "#arguments.property# #arguments.direction#");
		return this;
	}

	/**
	 * Set the maximum number of records to return.
	 *
	 * @value The maximum number of records.
	 */
	public any function limit(required numeric value) {
		variables.limitValue = arguments.value;
		return this;
	}

	/**
	 * Set the number of records to skip.
	 *
	 * @value The number of records to skip.
	 */
	public any function offset(required numeric value) {
		variables.offsetValue = arguments.value;
		return this;
	}

	/**
	 * Set the SELECT clause.
	 *
	 * @properties A list of properties to select.
	 */
	public any function select(required string properties) {
		variables.selectClause = arguments.properties;
		return this;
	}

	/**
	 * Set the include (JOIN) clause.
	 *
	 * @associations Associations to include.
	 */
	public any function include(required string associations) {
		variables.includeClause = arguments.associations;
		return this;
	}

	/**
	 * Set the GROUP BY clause.
	 *
	 * @properties Properties to group by.
	 */
	public any function group(required string properties) {
		variables.groupClause = arguments.properties;
		return this;
	}

	/**
	 * Enable DISTINCT.
	 */
	public any function distinct() {
		variables.distinctValue = true;
		return this;
	}

	/**
	 * Build the accumulated arguments into a struct suitable for finder methods.
	 */
	public struct function $buildFinderArgs(struct extraArgs = {}) {
		local.args = {};

		// Start with scope specs if present
		if (ArrayLen(variables.scopeSpecs)) {
			local.scopeChain = new ScopeChain(modelReference = variables.modelReference, specs = variables.scopeSpecs);
			local.args = local.scopeChain.$mergeSpecs();
		}

		// Build WHERE clause from accumulated conditions
		if (ArrayLen(variables.whereClauses)) {
			local.whereStr = "";
			for (local.i = 1; local.i <= ArrayLen(variables.whereClauses); local.i++) {
				local.item = variables.whereClauses[local.i];
				if (local.i == 1) {
					local.whereStr = local.item.clause;
				} else {
					local.whereStr = local.whereStr & " " & local.item.type & " " & local.item.clause;
				}
			}
			// Merge with any existing where from scopes
			if (StructKeyExists(local.args, "where") && Len(local.args.where)) {
				local.args.where = "(#local.args.where#) AND (#local.whereStr#)";
			} else {
				local.args.where = local.whereStr;
			}
		}

		// Build ORDER BY
		if (ArrayLen(variables.orderClauses)) {
			local.orderStr = ArrayToList(variables.orderClauses);
			if (StructKeyExists(local.args, "order") && Len(local.args.order)) {
				local.args.order = ListAppend(local.args.order, local.orderStr);
			} else {
				local.args.order = local.orderStr;
			}
		}

		// Apply SELECT
		if (Len(variables.selectClause)) {
			local.args.select = variables.selectClause;
		}

		// Apply INCLUDE
		if (Len(variables.includeClause)) {
			if (StructKeyExists(local.args, "include") && Len(local.args.include)) {
				local.args.include = ListAppend(local.args.include, variables.includeClause);
			} else {
				local.args.include = variables.includeClause;
			}
		}

		// Apply GROUP
		if (Len(variables.groupClause)) {
			local.args.group = variables.groupClause;
		}

		// Apply DISTINCT
		if (variables.distinctValue) {
			local.args.distinct = true;
		}

		// Apply LIMIT
		if (variables.limitValue > 0) {
			local.args.maxRows = variables.limitValue;
		}

		// Merge in any extra arguments passed to the terminal method
		StructAppend(local.args, arguments.extraArgs, false);

		return local.args;
	}

	/**
	 * Terminal method: execute the query and return all matching records.
	 * Alias: `get()` is the same as `findAll()`.
	 */
	public any function get() {
		return findAll(argumentCollection = arguments);
	}

	/**
	 * Terminal method: execute the query and return all matching records.
	 */
	public any function findAll() {
		local.args = $buildFinderArgs(arguments);
		return variables.modelReference.findAll(argumentCollection = local.args);
	}

	/**
	 * Terminal method: return the first matching record.
	 * Alias: `first()` is the same as `findOne()`.
	 */
	public any function first() {
		return findOne(argumentCollection = arguments);
	}

	/**
	 * Terminal method: return the first matching record.
	 */
	public any function findOne() {
		local.args = $buildFinderArgs(arguments);
		return variables.modelReference.findOne(argumentCollection = local.args);
	}

	/**
	 * Terminal method: return the count of matching records.
	 */
	public any function count() {
		local.args = $buildFinderArgs(arguments);
		return variables.modelReference.count(argumentCollection = local.args);
	}

	/**
	 * Terminal method: check if any matching records exist.
	 */
	public any function exists() {
		local.args = $buildFinderArgs(arguments);
		return variables.modelReference.exists(argumentCollection = local.args);
	}

	/**
	 * Terminal method: update all matching records.
	 */
	public any function updateAll() {
		local.args = $buildFinderArgs(arguments);
		return variables.modelReference.updateAll(argumentCollection = local.args);
	}

	/**
	 * Terminal method: delete all matching records.
	 */
	public any function deleteAll() {
		local.args = $buildFinderArgs(arguments);
		return variables.modelReference.deleteAll(argumentCollection = local.args);
	}

	/**
	 * Terminal method: process records one at a time in batches.
	 */
	public void function findEach() {
		local.args = $buildFinderArgs(arguments);
		variables.modelReference.findEach(argumentCollection = local.args);
	}

	/**
	 * Terminal method: process records in batch groups.
	 */
	public void function findInBatches() {
		local.args = $buildFinderArgs(arguments);
		variables.modelReference.findInBatches(argumentCollection = local.args);
	}

	/**
	 * Handle scope chaining from the query builder.
	 */
	public any function onMissingMethod(required string missingMethodName, required struct missingMethodArguments) {
		// Check if this is a named scope
		if (StructKeyExists(variables.modelReference.$classData(), "scopes") && StructKeyExists(variables.modelReference.$classData().scopes, arguments.missingMethodName)) {
			local.scopeDef = variables.modelReference.$classData().scopes[arguments.missingMethodName];

			if (StructKeyExists(local.scopeDef, "handler") && Len(local.scopeDef.handler)) {
				local.spec = variables.modelReference.$invoke(
					method = local.scopeDef.handler,
					invokeArgs = arguments.missingMethodArguments
				);
			} else {
				local.spec = Duplicate(local.scopeDef);
			}
			ArrayAppend(variables.scopeSpecs, local.spec);
			return this;
		}

		Throw(
			type = "Wheels.MethodNotFound",
			message = "The method `#arguments.missingMethodName#` was not found on the query builder for `#variables.modelReference.$classData().modelName#`.",
			extendedInfo = "Available methods: where, orWhere, whereNull, whereNotNull, whereBetween, whereIn, whereNotIn, orderBy, limit, offset, select, include, group, distinct, get, first, findAll, findOne, count, exists, updateAll, deleteAll, findEach, findInBatches."
		);
	}

	// ----- Private Helpers -----

	/**
	 * Build a single condition clause with proper value quoting.
	 */
	private string function $buildCondition(required string property, required string operator, required any value) {
		local.quotedValue = $quoteValue(arguments.property, arguments.value);
		return "#arguments.property# #arguments.operator# #local.quotedValue#";
	}

	/**
	 * Quote a value using the model's adapter for SQL injection safety.
	 */
	private string function $quoteValue(required string property, required any value) {
		local.type = "string";
		local.classData = variables.modelReference.$classData();
		if (StructKeyExists(local.classData.properties, arguments.property)) {
			local.type = local.classData.properties[arguments.property].validationtype;
		}
		return local.classData.adapter.$quoteValue(str = ToString(arguments.value), type = local.type);
	}

	/**
	 * Quote a list of values for IN clauses.
	 */
	private string function $quoteValueList(required string property, required any values) {
		if (IsArray(arguments.values)) {
			local.valueArray = arguments.values;
		} else {
			local.valueArray = ListToArray(arguments.values);
		}
		local.result = [];
		for (local.val in local.valueArray) {
			ArrayAppend(local.result, $quoteValue(arguments.property, local.val));
		}
		return ArrayToList(local.result);
	}

}
