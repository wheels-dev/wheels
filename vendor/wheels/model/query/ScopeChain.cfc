/**
 * A proxy object that accumulates query scope specifications and delegates to model finders.
 * Returned when calling a named scope on a model, allowing scopes to be chained together.
 *
 * Usage:
 * model("User").active().recent().findAll();
 * model("User").byRole("admin").findAll(page=1, perPage=25);
 */
component output="false" {

	/**
	 * Initialize the scope chain with a reference to the model and optional initial scope specs.
	 *
	 * @modelReference The model class instance that owns the scopes.
	 * @specs An array of scope specification structs accumulated so far.
	 */
	public any function init(required any modelReference, array specs = []) {
		variables.modelReference = arguments.modelReference;
		variables.specs = arguments.specs;
		return this;
	}

	/**
	 * Merge accumulated scope specs into a single arguments struct for a finder method.
	 * WHERE clauses are AND'd together, ORDER BY clauses are appended, etc.
	 */
	public struct function $mergeSpecs(struct finderArgs = {}) {
		local.merged = Duplicate(arguments.finderArgs);
		for (local.spec in variables.specs) {
			// Merge WHERE clauses with AND
			if (StructKeyExists(local.spec, "where") && Len(local.spec.where)) {
				if (StructKeyExists(local.merged, "where") && Len(local.merged.where)) {
					local.merged.where = "(#local.merged.where#) AND (#local.spec.where#)";
				} else {
					local.merged.where = local.spec.where;
				}
			}
			// Append ORDER BY clauses
			if (StructKeyExists(local.spec, "order") && Len(local.spec.order)) {
				if (StructKeyExists(local.merged, "order") && Len(local.merged.order)) {
					local.merged.order = ListAppend(local.merged.order, local.spec.order);
				} else {
					local.merged.order = local.spec.order;
				}
			}
			// Override SELECT if specified
			if (StructKeyExists(local.spec, "select") && Len(local.spec.select)) {
				local.merged.select = local.spec.select;
			}
			// Append includes
			if (StructKeyExists(local.spec, "include") && Len(local.spec.include)) {
				if (StructKeyExists(local.merged, "include") && Len(local.merged.include)) {
					local.merged.include = ListAppend(local.merged.include, local.spec.include);
				} else {
					local.merged.include = local.spec.include;
				}
			}
			// Use the smallest maxRows if specified
			if (StructKeyExists(local.spec, "maxRows") && local.spec.maxRows > 0) {
				if (!StructKeyExists(local.merged, "maxRows") || local.merged.maxRows == -1 || local.spec.maxRows < local.merged.maxRows) {
					local.merged.maxRows = local.spec.maxRows;
				}
			}
		}
		return local.merged;
	}

	/**
	 * Terminal method: delegates to model.findAll() with accumulated scope specs merged in.
	 */
	public any function findAll() {
		local.args = $mergeSpecs(arguments);
		return variables.modelReference.findAll(argumentCollection = local.args);
	}

	/**
	 * Terminal method: delegates to model.findOne() with accumulated scope specs merged in.
	 */
	public any function findOne() {
		local.args = $mergeSpecs(arguments);
		return variables.modelReference.findOne(argumentCollection = local.args);
	}

	/**
	 * Terminal method: delegates to model.findByKey() with accumulated scope specs merged in.
	 */
	public any function findByKey() {
		local.args = $mergeSpecs(arguments);
		return variables.modelReference.findByKey(argumentCollection = local.args);
	}

	/**
	 * Terminal method: delegates to model.findFirst() with accumulated scope specs merged in.
	 */
	public any function findFirst() {
		local.args = $mergeSpecs(arguments);
		return variables.modelReference.findFirst(argumentCollection = local.args);
	}

	/**
	 * Terminal method: delegates to model.findLastOne() with accumulated scope specs merged in.
	 */
	public any function findLastOne() {
		local.args = $mergeSpecs(arguments);
		return variables.modelReference.findLastOne(argumentCollection = local.args);
	}

	/**
	 * Terminal method: delegates to model.count() with accumulated scope specs merged in.
	 */
	public any function count() {
		local.args = $mergeSpecs(arguments);
		return variables.modelReference.count(argumentCollection = local.args);
	}

	/**
	 * Terminal method: delegates to model.exists() with accumulated scope specs merged in.
	 */
	public any function exists() {
		local.args = $mergeSpecs(arguments);
		return variables.modelReference.exists(argumentCollection = local.args);
	}

	/**
	 * Terminal method: delegates to model.average() with accumulated scope specs merged in.
	 */
	public any function average() {
		local.args = $mergeSpecs(arguments);
		return variables.modelReference.average(argumentCollection = local.args);
	}

	/**
	 * Terminal method: delegates to model.sum() with accumulated scope specs merged in.
	 */
	public any function sum() {
		local.args = $mergeSpecs(arguments);
		return variables.modelReference.sum(argumentCollection = local.args);
	}

	/**
	 * Terminal method: delegates to model.maximum() with accumulated scope specs merged in.
	 */
	public any function maximum() {
		local.args = $mergeSpecs(arguments);
		return variables.modelReference.maximum(argumentCollection = local.args);
	}

	/**
	 * Terminal method: delegates to model.minimum() with accumulated scope specs merged in.
	 */
	public any function minimum() {
		local.args = $mergeSpecs(arguments);
		return variables.modelReference.minimum(argumentCollection = local.args);
	}

	/**
	 * Terminal method: delegates to model.updateAll() with accumulated scope specs merged in.
	 */
	public any function updateAll() {
		local.args = $mergeSpecs(arguments);
		return variables.modelReference.updateAll(argumentCollection = local.args);
	}

	/**
	 * Terminal method: delegates to model.deleteAll() with accumulated scope specs merged in.
	 */
	public any function deleteAll() {
		local.args = $mergeSpecs(arguments);
		return variables.modelReference.deleteAll(argumentCollection = local.args);
	}

	/**
	 * Terminal method: delegates to model.findEach() with accumulated scope specs merged in.
	 */
	public void function findEach() {
		local.args = $mergeSpecs(arguments);
		variables.modelReference.findEach(argumentCollection = local.args);
	}

	/**
	 * Terminal method: delegates to model.findInBatches() with accumulated scope specs merged in.
	 */
	public void function findInBatches() {
		local.args = $mergeSpecs(arguments);
		variables.modelReference.findInBatches(argumentCollection = local.args);
	}

	/**
	 * Intercept calls to named scopes and chain them.
	 * Also supports the chainable query builder methods (where, orWhere, orderBy, etc.)
	 */
	public any function onMissingMethod(required string missingMethodName, required struct missingMethodArguments) {
		// Check if this is a scope call on the model
		if (StructKeyExists(variables.modelReference.$classData(), "scopes") && StructKeyExists(variables.modelReference.$classData().scopes, arguments.missingMethodName)) {
			local.scopeDef = variables.modelReference.$classData().scopes[arguments.missingMethodName];

			// If the scope has a handler, call it to get dynamic spec
			if (StructKeyExists(local.scopeDef, "handler") && Len(local.scopeDef.handler)) {
				local.spec = variables.modelReference.$invoke(
					method = local.scopeDef.handler,
					invokeArgs = arguments.missingMethodArguments
				);
			} else {
				local.spec = Duplicate(local.scopeDef);
			}
			ArrayAppend(variables.specs, local.spec);
			return this;
		}

		// Check if this is a QueryBuilder method — transition from scope chain to query builder
		if (ListFindNoCase("where,orWhere,whereNull,whereNotNull,whereBetween,whereIn,whereNotIn,orderBy,limit,offset,select,include,group,distinct", arguments.missingMethodName)) {
			local.builder = new QueryBuilder(modelReference = variables.modelReference, scopeSpecs = variables.specs);
			return Invoke(local.builder, arguments.missingMethodName, arguments.missingMethodArguments);
		}

		Throw(
			type = "Wheels.MethodNotFound",
			message = "The method `#arguments.missingMethodName#` was not found on the scope chain for `#variables.modelReference.$classData().modelName#`.",
			extendedInfo = "Available scopes: #StructKeyList(variables.modelReference.$classData().scopes)#. Terminal methods: findAll, findOne, findByKey, count, exists, average, sum, maximum, minimum, updateAll, deleteAll, findEach, findInBatches."
		);
	}

}
