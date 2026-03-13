/**
 * Template processing service for code generation.
 *
 * Reads template files from cli/src/templates/ (shared with CommandBox CLI),
 * processes {{variable}} and |Pipe| placeholders, and writes generated files.
 * App snippets in app/snippets/ override shared templates.
 *
 * Ported from cli/src/models/TemplateService.cfc — no WireBox dependencies.
 */
component {

	public function init(
		required any helpers,
		required string projectRoot,
		required string moduleRoot
	) {
		variables.helpers = arguments.helpers;
		variables.projectRoot = arguments.projectRoot;
		variables.moduleRoot = arguments.moduleRoot;
		// Resolve shared template directory
		variables.templateDir = resolveTemplateDir();
		return this;
	}

	/**
	 * Generate file from template
	 */
	public struct function generateFromTemplate(
		required string template,
		required string destination,
		required struct context
	) {
		// Find the template file
		var templatePath = findTemplate(arguments.template);

		if (!len(templatePath)) {
			return {success: false, error: "Template not found: #arguments.template#", path: ""};
		}

		var templateContent = fileRead(templatePath);
		var processedContent = processTemplate(templateContent, arguments.context);

		var destinationPath = variables.projectRoot & "/" & arguments.destination;

		// Ensure destination directory exists
		var destinationDir = getDirectoryFromPath(destinationPath);
		if (!directoryExists(destinationDir)) {
			directoryCreate(destinationDir, true);
		}

		fileWrite(destinationPath, processedContent);

		return {success: true, path: destinationPath, message: "Generated from template"};
	}

	/**
	 * Process template content with context replacements
	 */
	public string function processTemplate(required string content, required struct context) {
		var processed = arguments.content;

		// Replace {{variable}} with context values (skip special keys)
		var skipKeys = ["belongsTo", "hasMany", "hasOne", "belongsToRelationships", "hasManyRelationships", "properties", "actions"];
		for (var key in arguments.context) {
			if (arrayFindNoCase(skipKeys, key)) continue;
			var value = arguments.context[key];
			if (isSimpleValue(value)) {
				processed = reReplace(processed, "\{\{#key#\}\}", toString(value), "all");
			}
		}

		// Handle name variations
		if (structKeyExists(arguments.context, "name")) {
			var name = arguments.context.name;
			processed = reReplace(processed, "\{\{nameSingular\}\}", name, "all");
			processed = reReplace(processed, "\{\{namePlural\}\}", variables.helpers.pluralize(name), "all");
			processed = reReplace(processed, "\{\{nameSingularLower\}\}", lCase(name), "all");
			processed = reReplace(processed, "\{\{namePluralLower\}\}", lCase(variables.helpers.pluralize(name)), "all");
			processed = reReplace(processed, "\{\{nameSingularUpper\}\}", uCase(name), "all");
			processed = reReplace(processed, "\{\{namePluralUpper\}\}", uCase(variables.helpers.pluralize(name)), "all");
		}

		// Process relationship placeholders
		processed = processRelationships(processed, arguments.context);

		// Process attributes/validations
		if (structKeyExists(arguments.context, "attributes") && len(arguments.context.attributes)) {
			var attributesStruct = parseAttributes(arguments.context.attributes);
			var validationCode = generateValidationCode(attributesStruct);
			processed = reReplace(processed, "\{\{validations\}\}", validationCode, "all");
		} else {
			processed = reReplace(processed, "\{\{validations\}\}", "", "all");
		}

		// Process actions for controllers
		if (structKeyExists(arguments.context, "actions") && isArray(arguments.context.actions)) {
			var actionsCode = generateActionsCode(arguments.context.actions);
			processed = replace(processed, "|Actions|", actionsCode, "all");
		} else {
			processed = replace(processed, "|Actions|", "", "all");
		}

		// Process description comment
		if (structKeyExists(arguments.context, "description") && len(trim(arguments.context.description))) {
			var descComment = "/**" & chr(10) & " * " & arguments.context.description & chr(10) & " */" & chr(10);
			processed = replace(processed, "|DescriptionComment|", descComment, "all");
		} else {
			processed = replace(processed, "|DescriptionComment|", "", "all");
		}

		// Process custom table name
		if (structKeyExists(arguments.context, "tableName") && len(trim(arguments.context.tableName))) {
			var tableNameCall = 'table("' & arguments.context.tableName & '");' & chr(10) & chr(9) & chr(9);
			processed = replace(processed, "|TableName|", tableNameCall, "all");
		} else {
			processed = replace(processed, "|TableName|", "", "all");
		}

		// Process form fields
		if (structKeyExists(arguments.context, "properties") && isArray(arguments.context.properties) && arrayLen(arguments.context.properties) && structKeyExists(arguments.context, "modelName")) {
			var belongsToList = structKeyExists(arguments.context, "belongsTo") ? arguments.context.belongsTo : "";
			var formFieldsCode = generateFormFieldsCode(arguments.context.properties, arguments.context.modelName, belongsToList);
			processed = replace(processed, "|FormFields|", formFieldsCode, "all");
		} else {
			processed = replace(processed, "|FormFields|", "", "all");
		}

		// Process controller includes for associations
		if (structKeyExists(arguments.context, "belongsTo") && len(arguments.context.belongsTo)) {
			processed = addControllerIncludes(processed, arguments.context.belongsTo);
		}

		// Process CLI-Appends markers for index/show views
		if (structKeyExists(arguments.context, "properties") && isArray(arguments.context.properties) && arrayLen(arguments.context.properties)) {
			var belongsToList = structKeyExists(arguments.context, "belongsTo") ? arguments.context.belongsTo : "";
			processed = processViewMarkers(processed, arguments.context, belongsToList);
		}

		// Process pipe-delimited object name placeholders (must be last)
		if (structKeyExists(arguments.context, "modelName")) {
			var modelName = listLast(arguments.context.modelName, "/");
			processed = replace(processed, "|ObjectNameSingular|", lCase(modelName), "all");
			processed = replace(processed, "|ObjectNamePlural|", lCase(variables.helpers.pluralize(modelName)), "all");
			processed = replace(processed, "|ObjectNameSingularC|", modelName, "all");
			processed = replace(processed, "|ObjectNamePluralC|", variables.helpers.pluralize(modelName), "all");
		}

		return processed;
	}

	// ── Private helpers ──────────────────────────────

	/**
	 * Resolve the shared template directory
	 */
	private string function resolveTemplateDir() {
		// In monorepo: cli/src/templates/ relative to project root's cli/ directory
		var monorepoPath = variables.moduleRoot;
		// Walk up from cli/lucli/ to cli/src/templates/
		var File = createObject("java", "java.io.File");
		var lucliDir = File.init(monorepoPath);
		var cliDir = lucliDir.getParentFile(); // cli/
		var srcTemplates = cliDir.getCanonicalPath() & "/src/templates";
		if (directoryExists(srcTemplates)) {
			return srcTemplates;
		}
		// Fallback: relative to project root
		if (directoryExists(variables.projectRoot & "/cli/src/templates")) {
			return variables.projectRoot & "/cli/src/templates";
		}
		return "";
	}

	/**
	 * Find a template file — app/snippets/ overrides, then shared templates
	 */
	private string function findTemplate(required string template) {
		// 1. Check app/snippets/ override
		var snippetPath = variables.projectRoot & "/app/snippets/" & arguments.template;
		if (fileExists(snippetPath)) return snippetPath;

		// 2. Check shared template directory
		if (len(variables.templateDir)) {
			var sharedPath = variables.templateDir & "/" & arguments.template;
			if (fileExists(sharedPath)) return sharedPath;
		}

		return "";
	}

	/**
	 * Process relationship placeholders (belongsTo, hasMany, hasOne)
	 */
	private string function processRelationships(required string template, required struct context) {
		var processed = arguments.template;

		// belongsTo
		var belongsToValue = "";
		if (structKeyExists(arguments.context, "belongsTo")) belongsToValue = arguments.context.belongsTo;
		else if (structKeyExists(arguments.context, "BELONGSTO")) belongsToValue = arguments.context.BELONGSTO;

		if (len(belongsToValue)) {
			processed = reReplace(processed, "\{\{belongsToRelationships\}\}", generateRelationshipCode("belongsTo", belongsToValue), "all");
		} else {
			processed = reReplace(processed, "\{\{belongsToRelationships\}\}", "", "all");
		}

		// hasMany
		var hasManyValue = "";
		if (structKeyExists(arguments.context, "hasMany")) hasManyValue = arguments.context.hasMany;
		else if (structKeyExists(arguments.context, "HASMANY")) hasManyValue = arguments.context.HASMANY;

		if (len(hasManyValue)) {
			processed = reReplace(processed, "\{\{hasManyRelationships\}\}", generateRelationshipCode("hasMany", hasManyValue), "all");
		} else {
			processed = reReplace(processed, "\{\{hasManyRelationships\}\}", "", "all");
		}

		// hasOne
		var hasOneValue = "";
		if (structKeyExists(arguments.context, "hasOne")) hasOneValue = arguments.context.hasOne;
		else if (structKeyExists(arguments.context, "HASONE")) hasOneValue = arguments.context.HASONE;

		if (len(hasOneValue)) {
			processed = reReplace(processed, "\{\{hasOneRelationships\}\}", generateRelationshipCode("hasOne", hasOneValue), "all");
		} else {
			processed = reReplace(processed, "\{\{hasOneRelationships\}\}", "", "all");
		}

		return processed;
	}

	/**
	 * Generate relationship code line(s)
	 */
	private string function generateRelationshipCode(required string type, required string names) {
		var code = [];
		for (var rel in listToArray(arguments.names)) {
			arrayAppend(code, "		#arguments.type#('#trim(rel)#');");
		}
		return arrayToList(code, chr(10));
	}

	/**
	 * Generate controller actions code
	 */
	private string function generateActionsCode(required array actions) {
		var code = [];
		for (var action in arguments.actions) {
			arrayAppend(code, "");
			arrayAppend(code, "    /**");
			arrayAppend(code, "     * #action# action");
			arrayAppend(code, "     */");
			arrayAppend(code, "    function #action#() {");
			arrayAppend(code, "        // TODO: Implement #action# action");
			arrayAppend(code, "    }");
		}
		return arrayToList(code, chr(10));
	}

	/**
	 * Parse attributes string into struct
	 */
	private struct function parseAttributes(required string attributes) {
		var result = {};
		for (var attr in listToArray(arguments.attributes)) {
			if (find(":", attr)) {
				var parts = listToArray(attr, ":");
				result[trim(parts[1])] = trim(parts[2]);
			} else {
				result[trim(attr)] = "string";
			}
		}
		return result;
	}

	/**
	 * Generate validation code from attributes
	 */
	private string function generateValidationCode(required struct attributes) {
		var code = [];
		for (var attr in arguments.attributes) {
			var type = arguments.attributes[attr];
			switch (type) {
				case "email":
					arrayAppend(code, "        validatesFormatOf(property='#attr#', type='email');");
					break;
				case "integer": case "numeric":
					arrayAppend(code, "        validatesNumericalityOf(property='#attr#');");
					break;
				case "boolean":
					arrayAppend(code, "        validatesInclusionOf(property='#attr#', list='true,false,0,1');");
					break;
				default:
					arrayAppend(code, "        validatesPresenceOf(property='#attr#');");
			}
		}
		return arrayToList(code, chr(10));
	}

	/**
	 * Generate form fields based on properties
	 */
	private string function generateFormFieldsCode(required array properties, required string modelName, string belongsTo = "") {
		var fields = [];
		var foreignKeys = buildForeignKeyList(arguments.belongsTo);

		for (var prop in arguments.properties) {
			var fieldName = prop.name;
			var fieldType = prop.keyExists("type") ? prop.type : "string";
			var fieldLabel = variables.helpers.capitalize(fieldName);
			var fieldCode = "";

			if (arrayFindNoCase(foreignKeys, fieldName)) {
				var associationName = left(fieldName, len(fieldName) - 2);
				var associationModel = variables.helpers.capitalize(associationName);
				fieldCode = '##select(objectName="|ObjectNameSingular|", property="#fieldName#", options=model("#associationModel#").findAll(), textField="name", valueField="id", includeBlank="Select #associationModel#", label="#fieldLabel#")##';
			} else {
				switch (lCase(fieldType)) {
					case "boolean":
						fieldCode = '##checkBox(objectName="|ObjectNameSingular|", property="#fieldName#", label="#fieldLabel#")##';
						break;
					case "text": case "longtext":
						fieldCode = '##textArea(objectName="|ObjectNameSingular|", property="#fieldName#", label="#fieldLabel#")##';
						break;
					case "date":
						fieldCode = '##dateSelect(objectName="|ObjectNameSingular|", property="#fieldName#", label="#fieldLabel#")##';
						break;
					case "datetime": case "timestamp":
						fieldCode = '##dateTimeSelect(objectName="|ObjectNameSingular|", property="#fieldName#", label="#fieldLabel#")##';
						break;
					case "time":
						fieldCode = '##timeSelect(objectName="|ObjectNameSingular|", property="#fieldName#", label="#fieldLabel#")##';
						break;
					default:
						fieldCode = '##textField(objectName="|ObjectNameSingular|", property="#fieldName#", label="#fieldLabel#")##';
				}
			}
			arrayAppend(fields, fieldCode);
		}
		return arrayToList(fields, chr(10));
	}

	/**
	 * Process CLI-Appends markers in view templates
	 */
	private string function processViewMarkers(required string template, required struct context, string belongsTo = "") {
		var processed = arguments.template;

		if (find("<!--- CLI-Appends-thead-Here --->", processed)) {
			processed = replace(processed, "<!--- CLI-Appends-thead-Here --->", generateIndexTableHeaders(arguments.context.properties, arguments.belongsTo), "all");
		}

		if (find("<!--- CLI-Appends-tbody-Here --->", processed)) {
			processed = replace(processed, "<!--- CLI-Appends-tbody-Here --->", generateIndexTableBody(arguments.context.properties, arguments.belongsTo), "all");
		}

		if (find("<!--- CLI-Appends-Here --->", processed)) {
			if (structKeyExists(arguments.context, "action") && arguments.context.action == "show") {
				processed = replace(processed, "<!--- CLI-Appends-Here --->", generateShowViewProperties(arguments.context.properties, arguments.context.modelName, arguments.belongsTo), "all");
			} else {
				processed = replace(processed, "<!--- CLI-Appends-Here --->", "", "all");
			}
		}

		return processed;
	}

	/**
	 * Generate table headers for index view
	 */
	private string function generateIndexTableHeaders(required array properties, string belongsTo = "") {
		var headers = [];
		var foreignKeys = buildForeignKeyList(arguments.belongsTo);

		for (var prop in arguments.properties) {
			var headerName = variables.helpers.capitalize(prop.name);
			if (arrayFindNoCase(foreignKeys, prop.name)) {
				headerName = variables.helpers.capitalize(left(prop.name, len(prop.name) - 2));
			}
			arrayAppend(headers, '<th>#headerName#</th>');
		}
		return arrayToList(headers, chr(10) & chr(9) & chr(9) & chr(9) & chr(9) & chr(9));
	}

	/**
	 * Generate table body cells for index view
	 */
	private string function generateIndexTableBody(required array properties, string belongsTo = "") {
		var cells = [];
		var foreignKeys = buildForeignKeyList(arguments.belongsTo);

		for (var prop in arguments.properties) {
			var cellCode = '<td>' & chr(10);
			if (arrayFindNoCase(foreignKeys, prop.name)) {
				var assocName = left(prop.name, len(prop.name) - 2);
				cellCode &= chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & '##|ObjectNamePlural|.' & assocName & '.name##' & chr(10);
			} else {
				cellCode &= chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & '##|ObjectNamePlural|.#prop.name###' & chr(10);
			}
			cellCode &= chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & '</td>';
			arrayAppend(cells, cellCode);
		}
		return arrayToList(cells, chr(10) & chr(9) & chr(9) & chr(9) & chr(9) & chr(9));
	}

	/**
	 * Generate show view property display
	 */
	private string function generateShowViewProperties(required array properties, required string modelName, string belongsTo = "") {
		var displayCode = [];
		var foreignKeys = buildForeignKeyList(arguments.belongsTo);

		for (var prop in arguments.properties) {
			var propDisplay = '<p>' & chr(10);
			if (arrayFindNoCase(foreignKeys, prop.name)) {
				var assocName = left(prop.name, len(prop.name) - 2);
				propDisplay &= chr(9) & '<strong>#variables.helpers.capitalize(assocName)#:</strong> ##encodeForHTML(|ObjectNameSingular|.' & assocName & '.name)##' & chr(10);
			} else {
				propDisplay &= chr(9) & '<strong>#variables.helpers.capitalize(prop.name)#:</strong> ##encodeForHTML(|ObjectNameSingular|.#prop.name#)##' & chr(10);
			}
			propDisplay &= '</p>';
			arrayAppend(displayCode, propDisplay);
		}

		arrayAppend(displayCode, '');
		arrayAppend(displayCode, '<p>');
		arrayAppend(displayCode, chr(9) & '##linkTo(route="edit|ObjectNameSingularC|", key=|ObjectNameSingular|.key(), text="Edit", class="btn btn-primary")##');
		arrayAppend(displayCode, chr(9) & '##linkTo(route="|ObjectNamePlural|", text="Back to List", class="btn btn-default")##');
		arrayAppend(displayCode, '</p>');

		return arrayToList(displayCode, chr(10));
	}

	/**
	 * Add include params to controller CRUD patterns for associations
	 */
	private string function addControllerIncludes(required string template, required string belongsTo) {
		var processed = arguments.template;
		var associations = listToArray(arguments.belongsTo);
		var includeList = [];

		for (var association in associations) {
			arrayAppend(includeList, lCase(association));
		}

		var includeParam = 'include="' & arrayToList(includeList) & '"';

		processed = replace(processed, '=model("|ObjectNameSingular|").findAll();', '=model("|ObjectNameSingular|").findAll(#includeParam#);', 'all');
		processed = replace(processed, '=model("|ObjectNameSingular|").findByKey(params.key);', '=model("|ObjectNameSingular|").findByKey(params.key, #includeParam#);', 'all');
		processed = replace(processed, 'local.|ObjectNamePlural| = model("|ObjectNameSingular|").findAll();', 'local.|ObjectNamePlural| = model("|ObjectNameSingular|").findAll(#includeParam#);', 'all');
		processed = replace(processed, 'local.|ObjectNameSingular| = model("|ObjectNameSingular|").findByKey(params.key);', 'local.|ObjectNameSingular| = model("|ObjectNameSingular|").findByKey(params.key, #includeParam#);', 'all');

		return processed;
	}

	/**
	 * Build list of foreign key field names from belongsTo relationship string
	 */
	private array function buildForeignKeyList(string belongsTo = "") {
		var foreignKeys = [];
		if (len(arguments.belongsTo)) {
			for (var parent in listToArray(arguments.belongsTo)) {
				arrayAppend(foreignKeys, lCase(trim(parent)) & "Id");
			}
		}
		return foreignKeys;
	}

}
