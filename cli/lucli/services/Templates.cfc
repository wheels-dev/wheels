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
	 * Return the resolved shared template directory path
	 */
	public string function getTemplateDir() {
		return variables.templateDir;
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

		// Process {{validations}} placeholder. Prefer the pre-built `validations`
		// code string from context (populated by CodeGen.generateModel); fall back
		// to deriving from the legacy `attributes` string shape for callers that
		// still use it.
		var validationCode = "";
		if (structKeyExists(arguments.context, "validations") && isSimpleValue(arguments.context.validations)) {
			validationCode = arguments.context.validations;
		} else if (structKeyExists(arguments.context, "attributes") && len(arguments.context.attributes)) {
			var attributesStruct = parseAttributes(arguments.context.attributes);
			validationCode = generateValidationCode(attributesStruct);
		}
		processed = reReplace(processed, "\{\{validations\}\}", validationCode, "all");

		// Process {{enums}} placeholder. Mirrors {{validations}}: CodeGen.generateModel
		// pre-builds an `enums` code string of enum(property=..., values=...) lines for
		// any name:enum:a,b,c properties. Explicit (not just the generic {{key}} loop)
		// so it's substituted even when empty. CLI audit M2.
		var enumCode = (structKeyExists(arguments.context, "enums") && isSimpleValue(arguments.context.enums)) ? arguments.context.enums : "";
		processed = reReplace(processed, "\{\{enums\}\}", enumCode, "all");

		// Process actions for controllers
		if (structKeyExists(arguments.context, "actions") && isArray(arguments.context.actions)) {
			var actionsCode = generateActionsCode(arguments.context.actions);
			processed = replace(processed, "|Actions|", actionsCode, "all");
		} else {
			processed = replace(processed, "|Actions|", "", "all");
		}

		// Process helper functions
		if (structKeyExists(arguments.context, "functions") && isArray(arguments.context.functions)) {
			var helperFunctionsCode = generateHelperFunctionsCode(arguments.context.functions, arguments.context);
			processed = replace(processed, "|HelperFunctions|", helperFunctionsCode, "all");
		} else {
			processed = replace(processed, "|HelperFunctions|", "", "all");
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

		// Process |DisplayProperty| — the column name used for human-readable
		// scaffold headings/links. Defaults to `id` (matches legacy behavior),
		// but if the properties list contains a string column we use that
		// instead so scaffolded show.cfm/index.cfm don't lead with a numeric
		// primary key. Onboarding F4.
		processed = replace(
			processed,
			"|DisplayProperty|",
			pickDisplayProperty(arguments.context.properties ?: []),
			"all"
		);

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

		// Final cleanup: remove orphan whitespace-only lines left behind by
		// empty placeholders (e.g. `\t\t{{hasManyRelationships}}` when no
		// hasMany relationships exist), and collapse runs of consecutive blank
		// lines to a single blank line. Without this, generated files end up
		// with 4+ blank lines inside config() — see issue #2329.
		processed = collapseEmptyLines(processed);

		return processed;
	}

	/**
	 * Normalise whitespace-only lines to genuinely empty, then collapse runs
	 * of 2+ consecutive empty lines down to one. Used after placeholder
	 * substitution to clean up template-fill leftovers.
	 */
	private string function collapseEmptyLines(required string content) {
		var lines = listToArray(arguments.content, chr(10), true);
		var cleaned = [];
		var prevWasEmpty = false;

		for (var line in lines) {
			var normalised = reFind("^[[:space:]]+$", line) ? "" : line;
			var isEmpty = (normalised == "");
			if (isEmpty && prevWasEmpty) continue;
			cleaned.append(normalised);
			prevWasEmpty = isEmpty;
		}

		return arrayToList(cleaned, chr(10));
	}

	// ── Private helpers ──────────────────────────────

	/**
	 * Resolve the shared template directory.
	 *
	 * Search order:
	 *   1. Bundled templates at moduleRoot/templates/codegen/ (standalone install)
	 *   2. Monorepo layout: walk up from cli/lucli/ to cli/src/templates/
	 *   3. Project vendor: projectRoot/vendor/wheels/cli/src/templates/
	 *   4. Legacy fallback: projectRoot/cli/src/templates/
	 */
	private string function resolveTemplateDir() {
		// 1. Bundled codegen templates (standalone / distribution install)
		var bundledPath = variables.moduleRoot & "templates/codegen";
		if (directoryExists(bundledPath)) {
			return bundledPath;
		}

		// 2. Monorepo: walk up from cli/lucli/ to cli/src/templates/
		var File = createObject("java", "java.io.File");
		var lucliDir = File.init(variables.moduleRoot);
		var cliDir = lucliDir.getParentFile(); // cli/
		if (!isNull(cliDir)) {
			var srcTemplates = cliDir.getCanonicalPath() & "/src/templates";
			if (directoryExists(srcTemplates)) {
				return srcTemplates;
			}
		}

		// 3. Project vendor (Wheels vendored into project)
		var vendorPath = variables.projectRoot & "/vendor/wheels/cli/src/templates";
		if (directoryExists(vendorPath)) {
			return vendorPath;
		}

		// 4. Legacy fallback: projectRoot/cli/src/templates
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
			arrayAppend(code, "#arguments.type#('#trim(rel)#');");
		}
		// Join with newline + 2 tabs so subsequent lines align with the template's
		// `\t\t{{...Relationships}}` placeholder indent. The first line gets its
		// indent from the placeholder's leading whitespace at fill time.
		return arrayToList(code, chr(10) & chr(9) & chr(9));
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
	 * Generate helper function stubs
	 */
	private string function generateHelperFunctionsCode(required array functions, required struct context) {
		var code = [];
		var nl = chr(10);
		var helperName = structKeyExists(arguments.context, "helperName") ? arguments.context.helperName : "";
		var baseName = reFindNoCase("Helper$", helperName) ? reReplaceNoCase(helperName, "Helper$", "") : helperName;

		if (arrayLen(arguments.functions)) {
			for (var funcName in arguments.functions) {
				arrayAppend(code, "");
				arrayAppend(code, "	public string function #funcName#(required string value) {");
				arrayAppend(code, "		return arguments.value;");
				arrayAppend(code, "	}");
			}
		} else {
			// Default sample function based on helper name
			var sampleName = len(baseName) ? lCase(baseName) & "Format" : "format";
			arrayAppend(code, "");
			arrayAppend(code, "	public string function #sampleName#(required string value) {");
			arrayAppend(code, "		// TODO: Implement formatting logic");
			arrayAppend(code, "		return arguments.value;");
			arrayAppend(code, "	}");
		}

		return arrayToList(code, nl);
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
	 * Pick the best column to use as a human-readable display name in scaffold
	 * views. Preference order:
	 *   1. First property typed `string` (Rails-style — `title`, `name`, etc.)
	 *   2. First property typed `text`
	 *   3. Fallback to `id` so legacy templates without scaffold context still
	 *      render (and so non-scaffold users of the placeholder don't break).
	 */
	private string function pickDisplayProperty(required array properties) {
		// First pass: prefer a `string` column. Skip foreign-key-shaped names
		// (ending in "Id") which are typically not user-facing labels.
		for (var prop in arguments.properties) {
			var t = lCase(prop.type ?: "string");
			var n = prop.name ?: "";
			if (t == "string" && right(n, 2) != "Id" && n != "id") {
				return n;
			}
		}
		// Second pass: text columns. Useful when the user only provides
		// `body:text`-shaped scaffolds with no string column at all.
		for (var prop in arguments.properties) {
			if (lCase(prop.type ?: "string") == "text") {
				return prop.name ?: "id";
			}
		}
		return "id";
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
					case "enum":
						// Render a <select> with the enum's values. The
						// values come from either the inline form
						// (status:enum:draft,published,archived) or, when
						// missing, from the existing model's enum(...)
						// declaration via $resolveEnumValuesFromModel.
						var enumValues = prop.keyExists("values") ? prop.values : "";
						if (!len(enumValues)) {
							enumValues = $resolveEnumValuesFromModel(arguments.modelName, fieldName);
						}
						if (len(enumValues)) {
							fieldCode = '##select(objectName="|ObjectNameSingular|", property="#fieldName#", options="#enumValues#", label="#fieldLabel#")##';
						} else {
							// Fall back to a textField if we couldn't find
							// the values — better than crashing the scaffold.
							fieldCode = '##textField(objectName="|ObjectNameSingular|", property="#fieldName#", label="#fieldLabel#")##';
						}
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
			} else if (structKeyExists(arguments.context, "action") && arguments.context.action == "index") {
				// Inside the article-style index loop, emit per-property
				// <p> blocks that reference the query's row columns. The
				// caller's loop tag scopes those references.
				processed = replace(processed, "<!--- CLI-Appends-Here --->", generateIndexArticleBody(arguments.context.properties, arguments.belongsTo), "all");
			} else {
				processed = replace(processed, "<!--- CLI-Appends-Here --->", "", "all");
			}
		}

		return processed;
	}

	/**
	 * Generate per-property <p> blocks for the article-style index view.
	 * Inside the cfloop the column names are accessible directly (the loop
	 * scopes them), so column references work without a query alias.
	 */
	private string function generateIndexArticleBody(required array properties, string belongsTo = "") {
		var blocks = [];
		var foreignKeys = buildForeignKeyList(arguments.belongsTo);

		for (var prop in arguments.properties) {
			var label = variables.helpers.capitalize(prop.name);
			if (arrayFindNoCase(foreignKeys, prop.name)) {
				// findAll() returns a flat query — association objects are not
				// reachable inside a query-driven cfloop, so posts.author.name throws.
				// Keep the friendly label but render the raw FK column value.
				label = variables.helpers.capitalize(left(prop.name, len(prop.name) - 2));
			}
			arrayAppend(blocks, '<p>' & label & ': ##|ObjectNamePlural|.' & prop.name & '##</p>');
		}
		return arrayToList(blocks, chr(10) & chr(9) & chr(9));
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

		// findAll() returns a flat query — association objects are not reachable
		// inside a query-driven cfloop, so FK columns render their raw value (e.g.
		// authorId); the table header still shows the association label.
		for (var prop in arguments.properties) {
			var cellCode = '<td>' & chr(10);
			cellCode &= chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & chr(9) & '##|ObjectNamePlural|.#prop.name###' & chr(10);
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

		// Action footer (Edit / Delete / Back) is now part of the
		// show.txt template directly, with no Bootstrap classes.
		// generateShowViewProperties only emits per-property <p> blocks.

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

		// CRUD controller template (CRUDContent.txt) uses the capitalized
		// |ObjectNameSingularC| placeholder inside model() and no spaces around
		// the assignment `=`. findByKey must be all-named (key=...) — Wheels
		// rejects mixing the positional key with the named include at runtime.
		processed = replace(processed, '=model("|ObjectNameSingularC|").findAll();', '=model("|ObjectNameSingularC|").findAll(#includeParam#);', 'all');
		processed = replace(processed, '=model("|ObjectNameSingularC|").findByKey(params.key);', '=model("|ObjectNameSingularC|").findByKey(key=params.key, #includeParam#);', 'all');
		// API controller template (ApiControllerContent.txt) assigns into the
		// `local.` scope with spaces around `=` and the lowercase placeholder.
		processed = replace(processed, 'local.|ObjectNamePlural| = model("|ObjectNameSingular|").findAll();', 'local.|ObjectNamePlural| = model("|ObjectNameSingular|").findAll(#includeParam#);', 'all');
		processed = replace(processed, 'local.|ObjectNameSingular| = model("|ObjectNameSingular|").findByKey(params.key);', 'local.|ObjectNameSingular| = model("|ObjectNameSingular|").findByKey(key=params.key, #includeParam#);', 'all');

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

	/**
	 * Read app/models/<ModelName>.cfc and look for an enum(property="<prop>", values="...")
	 * declaration. Returns the comma-separated values list or "" when not
	 * found. Lets `wheels generate scaffold Post status:enum` (the
	 * tutorial's chapter 3 command) emit a <select> populated from the
	 * model's chapter-2 enum() declaration without requiring the user to
	 * re-type values on the command line.
	 *
	 * @modelName Capitalized model name (e.g. "Post")
	 * @propertyName Lowercase property name (e.g. "status")
	 */
	private string function $resolveEnumValuesFromModel(
		required string modelName,
		required string propertyName
	) {
		var modelPath = variables.projectRoot & "/app/models/" & arguments.modelName & ".cfc";
		if (!fileExists(modelPath)) return "";

		var modelSource = fileRead(modelPath);
		// Match either order of property= / values= attributes. Captures
		// only the values-list payload (string-form). Struct-form (e.g.
		// {low:0, high:1}) isn't supported here — the scaffold falls back
		// to a textField when this returns empty.
		var pattern = 'enum\([^)]*property\s*=\s*"' & arguments.propertyName & '"[^)]*values\s*=\s*"([^"]+)"';
		var match = REFindNoCase(pattern, modelSource, 1, true);
		if (match.pos[1] > 0 && arrayLen(match.len) > 1) {
			return mid(modelSource, match.pos[2], match.len[2]);
		}

		// Try the reversed argument order (values= before property=).
		pattern = 'enum\([^)]*values\s*=\s*"([^"]+)"[^)]*property\s*=\s*"' & arguments.propertyName & '"';
		match = REFindNoCase(pattern, modelSource, 1, true);
		if (match.pos[1] > 0 && arrayLen(match.len) > 1) {
			return mid(modelSource, match.pos[2], match.len[2]);
		}

		return "";
	}

}
