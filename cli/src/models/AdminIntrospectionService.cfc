component {

	property name="helpers" inject="helpers@wheels-cli";

	/**
	 * Initialize the service
	 */
	public function init() {
		return this;
	}

	/**
	 * Introspect a model and return a struct of metadata suitable for admin CRUD template generation.
	 *
	 * The returned struct contains:
	 * - modelName (string): singular PascalCase name
	 * - pluralName (string): plural PascalCase name
	 * - displayName (string): human-readable singular
	 * - displayNamePlural (string): human-readable plural
	 * - tableName (string): database table name
	 * - primaryKey (string): primary key property name(s)
	 * - softDeletion (boolean): whether model uses soft delete
	 * - fields (array): ordered field metadata for templates
	 * - associations (array): association metadata
	 * - validationSummary (struct): property-keyed validation rules
	 * - enums (struct): enum definitions
	 * - scopes (array): scope names
	 *
	 * @modelInstance A Wheels model instance (from model("ModelName"))
	 */
	public struct function introspect(required any modelInstance) {
		var classData = arguments.modelInstance.classInfo();
		var result = {};

		// Core naming
		result.modelName = classData.modelName;
		result.pluralName = capitalize(pluralizeWord(classData.modelName));
		result.displayName = humanizeWord(classData.modelName);
		result.displayNamePlural = humanizeWord(pluralizeWord(classData.modelName));
		result.tableName = classData.tableName;
		result.primaryKey = classData.primaryKeys;
		result.softDeletion = classData.softDeletion;

		// Build validation summary (property -> rules) for quick lookup
		result.validationSummary = buildValidationSummary(classData.validations);

		// Build enum metadata
		result.enums = classData.enums;

		// Build scope list
		result.scopes = listToArray(structKeyList(classData.scopes));

		// Build association metadata
		result.associations = buildAssociationList(classData.associations);

		// Build ordered field list — the main output for templates
		result.fields = buildFieldList(
			properties = classData.properties,
			primaryKeys = classData.primaryKeys,
			associations = classData.associations,
			validationSummary = result.validationSummary,
			enums = classData.enums
		);

		return result;
	}

	/**
	 * Build an ordered array of field metadata for template consumption.
	 * Each field struct contains everything a template needs to render form inputs,
	 * table columns, and display labels.
	 */
	private array function buildFieldList(
		required struct properties,
		required string primaryKeys,
		required struct associations,
		required struct validationSummary,
		required struct enums
	) {
		var fields = [];
		var pkList = arguments.primaryKeys;
		var fkSet = buildForeignKeySet(arguments.associations);

		for (var propName in arguments.properties) {
			var prop = arguments.properties[propName];
			var field = {};

			field.name = propName;
			field.column = structKeyExists(prop, "column") ? prop.column : propName;
			field.label = structKeyExists(prop, "label") ? prop.label : humanizeWord(propName);
			field.dataType = structKeyExists(prop, "type") ? prop.type : "string";
			field.sqlType = structKeyExists(prop, "dataType") ? prop.dataType : "cf_sql_varchar";
			field.maxLength = structKeyExists(prop, "size") ? prop.size : 0;
			field.nullable = structKeyExists(prop, "nullable") ? prop.nullable : true;
			field.defaultValue = structKeyExists(prop, "columnDefault") ? prop.columnDefault : "";
			field.scale = structKeyExists(prop, "scale") ? prop.scale : 0;
			field.isPrimaryKey = listFindNoCase(pkList, propName) > 0;
			field.isForeignKey = structKeyExists(fkSet, propName);
			field.foreignKeyTo = field.isForeignKey ? fkSet[propName] : "";

			// Validation hints from summary
			var propValidations = structKeyExists(arguments.validationSummary, propName)
				? arguments.validationSummary[propName]
				: {};
			field.required = structKeyExists(propValidations, "presence") ? true : false;
			field.unique = structKeyExists(propValidations, "uniqueness") ? true : false;
			field.validations = propValidations;

			// Enum detection
			field.isEnum = structKeyExists(arguments.enums, propName);
			field.enumValues = field.isEnum ? arguments.enums[propName].values : {};

			// Determine HTML input type
			field.inputType = resolveInputType(
				dataType = field.dataType,
				sqlType = field.sqlType,
				propName = propName,
				isEnum = field.isEnum,
				isForeignKey = field.isForeignKey
			);

			// Display hints for templates
			field.inList = !field.isPrimaryKey && !listFindNoCase("text,binary", field.dataType);
			field.inForm = !field.isPrimaryKey;
			field.inShow = true;

			arrayAppend(fields, field);
		}

		return fields;
	}

	/**
	 * Map model data types and property names to HTML input types for form generation.
	 */
	private string function resolveInputType(
		required string dataType,
		required string sqlType,
		required string propName,
		required boolean isEnum,
		required boolean isForeignKey
	) {
		// Foreign keys -> select dropdown
		if (arguments.isForeignKey) {
			return "select";
		}

		// Enums -> select dropdown
		if (arguments.isEnum) {
			return "select";
		}

		// Name-based heuristics
		var nameLower = lCase(arguments.propName);
		if (findNoCase("email", nameLower)) return "email";
		if (findNoCase("password", nameLower)) return "password";
		if (findNoCase("url", nameLower) || findNoCase("website", nameLower)) return "url";
		if (findNoCase("phone", nameLower) || findNoCase("tel", nameLower)) return "tel";
		if (findNoCase("color", nameLower) || findNoCase("colour", nameLower)) return "color";
		if (findNoCase("search", nameLower)) return "search";

		// Type-based mapping
		switch (arguments.dataType) {
			case "string":
				return "text";
			case "text":
				return "textarea";
			case "integer": case "float": case "decimal": case "biginteger":
				return "number";
			case "boolean":
				return "checkbox";
			case "date":
				return "date";
			case "datetime": case "timestamp":
				return "datetime-local";
			case "time":
				return "time";
			case "binary":
				return "file";
			default:
				break;
		}

		// SQL type fallback
		if (findNoCase("text", arguments.sqlType) || findNoCase("clob", arguments.sqlType)) {
			return "textarea";
		}
		if (findNoCase("int", arguments.sqlType)) {
			return "number";
		}
		if (findNoCase("bit", arguments.sqlType) || findNoCase("boolean", arguments.sqlType)) {
			return "checkbox";
		}
		if (findNoCase("date", arguments.sqlType) && findNoCase("time", arguments.sqlType)) {
			return "datetime-local";
		}
		if (findNoCase("date", arguments.sqlType)) {
			return "date";
		}
		if (findNoCase("time", arguments.sqlType)) {
			return "time";
		}

		return "text";
	}

	/**
	 * Build a set of foreign key property names mapped to their associated model name.
	 */
	private struct function buildForeignKeySet(required struct associations) {
		var fkSet = {};
		for (var assocName in arguments.associations) {
			var assoc = arguments.associations[assocName];
			if (structKeyExists(assoc, "type") && assoc.type == "belongsTo" && structKeyExists(assoc, "foreignKey")) {
				var fkList = assoc.foreignKey;
				var modelName = structKeyExists(assoc, "modelName") ? assoc.modelName : assocName;
				for (var fk in listToArray(fkList)) {
					fkSet[fk] = modelName;
				}
			}
		}
		return fkSet;
	}

	/**
	 * Transform the raw validations struct (keyed by trigger) into a property-keyed summary.
	 * Returns a struct where each key is a property name, and the value is a struct of validation types.
	 *
	 * Example output:
	 * {
	 *   email: {presence: true, uniqueness: true, format: {regEx: "..."}},
	 *   firstName: {presence: true}
	 * }
	 */
	private struct function buildValidationSummary(required struct validations) {
		var summary = {};

		// Map internal method names to friendly validation types
		var methodMap = {
			"$validatesPresenceOf": "presence",
			"$validatesUniquenessOf": "uniqueness",
			"$validatesFormatOf": "format",
			"$validatesLengthOf": "length",
			"$validatesNumericalityOf": "numericality",
			"$validatesInclusionOf": "inclusion",
			"$validatesExclusionOf": "exclusion",
			"$validatesConfirmationOf": "confirmation"
		};

		// Iterate over all trigger types (onSave, onCreate, onUpdate)
		for (var trigger in arguments.validations) {
			var rules = arguments.validations[trigger];
			if (!isArray(rules)) continue;

			for (var rule in rules) {
				// Wheels stores validations as {method, args: {property, message, ...}}
				if (!structKeyExists(rule, "args") || !structKeyExists(rule.args, "property")) continue;

				var validationType = structKeyExists(methodMap, rule.method)
					? methodMap[rule.method]
					: rule.method;

				// Build a params struct from args (exclude property itself)
				var params = {};
				for (var argKey in rule.args) {
					if (argKey != "property") {
						params[argKey] = rule.args[argKey];
					}
				}

				var propName = rule.args.property;
				if (!structKeyExists(summary, propName)) {
					summary[propName] = {};
				}
				// Store params if any, otherwise just true
				if (structIsEmpty(params)) {
					summary[propName][validationType] = true;
				} else {
					summary[propName][validationType] = params;
				}
			}
		}

		return summary;
	}

	/**
	 * Build a clean array of association metadata for templates.
	 */
	private array function buildAssociationList(required struct associations) {
		var result = [];
		for (var assocName in arguments.associations) {
			var assoc = arguments.associations[assocName];
			var item = {};
			item.name = assocName;
			item.type = structKeyExists(assoc, "type") ? assoc.type : "";
			item.modelName = structKeyExists(assoc, "modelName") ? assoc.modelName : "";
			item.foreignKey = structKeyExists(assoc, "foreignKey") ? assoc.foreignKey : "";
			item.joinKey = structKeyExists(assoc, "joinKey") ? assoc.joinKey : "";
			item.dependent = structKeyExists(assoc, "dependent") ? assoc.dependent : "";
			item.nested = structKeyExists(assoc, "nested") ? assoc.nested : {};
			arrayAppend(result, item);
		}
		return result;
	}

	/**
	 * Local capitalize fallback
	 */
	private string function capitalize(required string str) {
		if (structKeyExists(variables, "helpers") && isObject(variables.helpers)) {
			return variables.helpers.capitalize(arguments.str);
		}
		if (len(arguments.str) == 0) return "";
		return uCase(left(arguments.str, 1)) & mid(arguments.str, 2, len(arguments.str) - 1);
	}

	/**
	 * Local pluralize fallback
	 */
	private string function pluralizeWord(required string word) {
		if (structKeyExists(variables, "helpers") && isObject(variables.helpers)) {
			return variables.helpers.pluralize(arguments.word);
		}
		return arguments.word & "s";
	}

	/**
	 * Local humanize fallback — converts camelCase/PascalCase to "Human Readable"
	 */
	private string function humanizeWord(required string text) {
		if (structKeyExists(variables, "helpers") && isObject(variables.helpers)) {
			return variables.helpers.humanize(arguments.text);
		}
		// Simple fallback: insert space before capitals, capitalize first letter
		var result = reReplace(arguments.text, "([A-Z])", " \1", "all");
		result = trim(result);
		return uCase(left(result, 1)) & mid(result, 2, len(result) - 1);
	}

}
