/**
 * Code generation service for models, controllers, views, and tests.
 *
 * Orchestrates file generation by preparing template contexts and delegating
 * to the Templates service. Handles name validation, association extraction,
 * and file existence checks.
 *
 * Ported from cli/src/models/CodeGenerationService.cfc — no WireBox dependencies.
 */
component {

	public function init(
		required any templateService,
		required any helpers,
		required string projectRoot
	) {
		variables.templateService = arguments.templateService;
		variables.helpers = arguments.helpers;
		variables.projectRoot = arguments.projectRoot;
		return this;
	}

	/**
	 * Generate a model file
	 */
	public struct function generateModel(
		required string name,
		array properties = [],
		string belongsTo = "",
		string hasMany = "",
		string hasOne = "",
		string description = "",
		string tableName = "",
		boolean force = false
	) {
		var modelName = variables.helpers.capitalize(arguments.name);
		var filePath = variables.projectRoot & "/app/models/#modelName#.cfc";

		if (fileExists(filePath) && !arguments.force) {
			return {success: false, error: "Model already exists: app/models/#modelName#.cfc", path: filePath};
		}

		var context = {
			modelName: modelName,
			name: modelName,
			tableName: len(arguments.tableName) ? arguments.tableName : "",
			description: arguments.description,
			properties: arguments.properties,
			belongsTo: arguments.belongsTo,
			hasMany: arguments.hasMany,
			hasOne: arguments.hasOne,
			validations: buildModelValidations(arguments.properties),
			enums: buildModelEnums(arguments.properties),
			timestamp: dateTimeFormat(now(), "yyyy-mm-dd HH:nn:ss")
		};

		var result = variables.templateService.generateFromTemplate(
			template = "ModelContent.txt",
			destination = "app/models/#modelName#.cfc",
			context = context
		);

		return result;
	}

	/**
	 * Build validation code lines for a model's config() from typed properties.
	 * Emits a single combined validatesPresenceOf("a,b,c") for all properties,
	 * plus per-property validatesFormatOf for email and URL types.
	 */
	private string function buildModelValidations(required array properties) {
		if (!arrayLen(arguments.properties)) return "";

		var presenceProps = [];
		var formatLines = [];

		for (var prop in arguments.properties) {
			arrayAppend(presenceProps, prop.name);
			var propType = structKeyExists(prop, "type") ? lCase(prop.type) : "string";
			if (propType == "email") {
				arrayAppend(formatLines, "validatesFormatOf(property=""#prop.name#"", type=""email"");");
			} else if (propType == "url") {
				arrayAppend(formatLines, "validatesFormatOf(property=""#prop.name#"", type=""URL"");");
			}
		}

		var lines = ["validatesPresenceOf(""#arrayToList(presenceProps)#"");"];
		lines.append(formatLines, true);
		// Join with newline + 2 tabs so subsequent lines align with the template's
		// `\t\t{{validations}}` placeholder indent. The first line gets its indent
		// from the placeholder's leading whitespace at fill time.
		return arrayToList(lines, chr(10) & chr(9) & chr(9));
	}

	/**
	 * Build enum() declarations for any `name:enum:a,b,c` properties. Emits one
	 * `enum(property="name", values="a,b,c")` line per enum property so generated
	 * models carry the auto-checkers/scopes the framework derives from enum().
	 * Previously the enum type was parsed but never emitted. CLI audit M2.
	 */
	private string function buildModelEnums(required array properties) {
		var lines = [];
		for (var prop in arguments.properties) {
			var propType = structKeyExists(prop, "type") ? lCase(prop.type) : "";
			if (propType == "enum" && structKeyExists(prop, "values") && len(prop.values)) {
				arrayAppend(lines, 'enum(property="#prop.name#", values="#prop.values#");');
			}
		}
		// Same newline + 2-tab join as buildModelValidations to align with the
		// template's `\t\t{{enums}}` placeholder indent.
		return arrayToList(lines, chr(10) & chr(9) & chr(9));
	}

	/**
	 * Generate a controller file
	 */
	public struct function generateController(
		required string name,
		array actions = [],
		boolean crud = false,
		boolean api = false,
		string belongsTo = "",
		string hasMany = "",
		string description = "",
		boolean force = false
	) {
		// Support package-prefixed names like "api/Products"
		var packagePath = "";
		var baseName = arguments.name;
		if (find("/", arguments.name)) {
			packagePath = lCase(listFirst(arguments.name, "/")) & "/";
			baseName = listLast(arguments.name, "/");
		}

		var controllerName = variables.helpers.capitalize(baseName);
		var relativePath = "app/controllers/#packagePath##controllerName#.cfc";
		var filePath = variables.projectRoot & "/" & relativePath;

		if (fileExists(filePath) && !arguments.force) {
			return {success: false, error: "Controller already exists: #relativePath#", path: filePath};
		}

		var crudActions = ["index", "show", "new", "create", "edit", "update", "delete"];

		// Normalize the action list: a comma-joined token like "index,show" is the
		// natural guess for anyone used to Wheels list args (validatesPresenceOf("a,b")),
		// but passed through verbatim it produced `function index,show()` — invalid CFML
		// that fails to compile — plus a view file named `index,show.cfm` (#3112). Split
		// each token on commas, trim, and de-duplicate so both forms behave identically.
		arguments.actions = normalizeActions(arguments.actions);

		// Capture the caller-requested list BEFORE the defaulting below. result.actions
		// drives the caller's view loop, and the documented contract is "passing no
		// actions creates an empty controller with no view files" — the index/CRUD
		// defaults applied next shape the controller body only, never the view files.
		var requestedActions = arguments.actions;

		// Default actions based on type
		if (arrayLen(arguments.actions) == 0) {
			arguments.actions = arguments.crud ? crudActions : ["index"];
		}

		var context = {
			controllerName: controllerName,
			modelName: variables.helpers.singularize(controllerName),
			description: arguments.description,
			actions: arguments.actions,
			crud: arguments.crud,
			api: arguments.api,
			belongsTo: arguments.belongsTo,
			hasMany: arguments.hasMany,
			timestamp: dateTimeFormat(now(), "yyyy-mm-dd HH:nn:ss")
		};

		// Select template
		var template = "ControllerContent.txt";
		if (arguments.api && arguments.crud) {
			template = "ApiControllerContent.txt";
		} else if (arguments.crud) {
			var hasCustomActions = (arrayLen(arguments.actions) != arrayLen(crudActions)) ||
				!arrayEvery(arguments.actions, function(action) {
					return arrayFindNoCase(crudActions, action) > 0;
				});
			template = hasCustomActions ? "ControllerContent.txt" : "CRUDContent.txt";
		}

		var result = variables.templateService.generateFromTemplate(
			template = template,
			destination = relativePath,
			context = context
		);

		// Surface the normalized caller-requested action list so callers (e.g.
		// Module.cfc's view loop) render one view file per real action instead of one
		// named after the raw comma-joined token (#3112). Deliberately the pre-default
		// list: when no actions were passed this stays empty, so callers write no view
		// files even though the controller body gets a default index() stub.
		result.actions = requestedActions;
		return result;
	}

	/**
	 * Flatten a positional action list into discrete, trimmed, de-duplicated action
	 * names. Splits comma-joined tokens ("index,show" -> ["index","show"]) so the comma
	 * form matches the documented space-separated form, drops empties, and preserves
	 * first-seen order. Comparison is case-insensitive but the original casing is kept (#3112).
	 */
	private array function normalizeActions(required array actions) {
		var normalized = [];
		for (var token in arguments.actions) {
			for (var part in listToArray(token, ",")) {
				var trimmed = trim(part);
				if (len(trimmed) && !arrayFindNoCase(normalized, trimmed)) {
					arrayAppend(normalized, trimmed);
				}
			}
		}
		return normalized;
	}

	/**
	 * Generate view files
	 */
	public struct function generateView(
		required string name,
		required string action,
		array properties = [],
		string belongsTo = "",
		string hasMany = "",
		string template = "",
		boolean force = false
	) {
		var controllerName = variables.helpers.capitalize(arguments.name);
		var viewDir = variables.projectRoot & "/app/views/#lCase(controllerName)#";
		var fileName = arguments.action & ".cfm";
		var filePath = viewDir & "/" & fileName;

		if (fileExists(filePath) && !arguments.force) {
			return {success: false, error: "View already exists: app/views/#lCase(controllerName)#/#fileName#", path: filePath};
		}

		// Auto-detect template based on action name
		if (!len(arguments.template)) {
			switch (arguments.action) {
				case "index": arguments.template = "crud/index.txt"; break;
				case "show": arguments.template = "crud/show.txt"; break;
				case "new": arguments.template = "crud/new.txt"; break;
				case "edit": arguments.template = "crud/edit.txt"; break;
				case "_form": arguments.template = "crud/_form.txt"; break;
				default: arguments.template = "ViewContent.txt";
			}
		}

		var context = {
			controllerName: controllerName,
			modelName: variables.helpers.singularize(controllerName),
			action: arguments.action,
			properties: arguments.properties,
			belongsTo: arguments.belongsTo,
			hasMany: arguments.hasMany,
			timestamp: dateTimeFormat(now(), "yyyy-mm-dd HH:nn:ss")
		};

		return variables.templateService.generateFromTemplate(
			template = arguments.template,
			destination = "app/views/#lCase(controllerName)#/#fileName#",
			context = context
		);
	}

	/**
	 * Generate a test file
	 */
	public struct function generateTest(
		required string type,
		required string name,
		boolean force = false
	) {
		var testName = arguments.name;
		var testDir = "tests/specs/";
		var suffix = "";

		switch (arguments.type) {
			case "model":
				testDir &= "models/";
				suffix = "Spec";
				break;
			case "controller":
				testDir &= "controllers/";
				suffix = "ControllerSpec";
				break;
			default:
				testDir &= "unit/";
				suffix = "Spec";
		}

		// Remove existing suffixes before adding the correct one
		testName = reReplaceNoCase(testName, "(Test|Spec|ControllerSpec|ViewSpec|IntegrationSpec)$", "");
		testName &= suffix;

		var fileName = testName & ".cfc";
		// Refuse to clobber an existing spec unless --force (mirrors generateHelper).
		// Previously generateTest silently overwrote and still printed "create".
		var existingPath = variables.projectRoot & "/" & testDir & fileName;
		if (fileExists(existingPath) && !arguments.force) {
			return {success: false, error: "Test already exists: #testDir##fileName# (pass --force to overwrite)", path: existingPath};
		}
		var destDir = variables.projectRoot & "/" & testDir;
		if (!directoryExists(destDir)) {
			directoryCreate(destDir, true);
		}

		var template = "tests/#arguments.type#.txt";
		var context = {
			testName: testName,
			targetName: reReplaceNoCase(testName, "(Spec|Test|ControllerSpec)$", ""),
			type: arguments.type,
			timestamp: dateTimeFormat(now(), "yyyy-mm-dd HH:nn:ss")
		};

		var result = variables.templateService.generateFromTemplate(
			template = template,
			destination = testDir & fileName,
			context = context
		);

		// Fallback: generate inline BDD template if template file not found
		if (!result.success) {
			var filePath = variables.projectRoot & "/" & testDir & fileName;
			var nl = chr(10);
			var t = chr(9);
			var targetName = context.targetName;
			var content = 'component extends="wheels.WheelsTest" {' & nl & nl;
			content &= t & 'function run() {' & nl;
			content &= t & t & 'describe("#targetName#", () => {' & nl & nl;
			content &= t & t & t & 'beforeEach(() => {' & nl;
			content &= t & t & t & t & '// Setup' & nl;
			content &= t & t & t & '})' & nl & nl;
			content &= t & t & t & 'it("should exist", () => {' & nl;
			content &= t & t & t & t & 'expect(true).toBeTrue();' & nl;
			content &= t & t & t & '})' & nl & nl;
			content &= t & t & '})' & nl;
			content &= t & '}' & nl;
			content &= '}' & nl;
			fileWrite(filePath, content);
			result = {success: true, path: filePath, message: "Generated from inline template"};
		}

		return result;
	}

	/**
	 * Generate a helper CFC file
	 */
	public struct function generateHelper(
		required string name,
		array functions = [],
		string description = "",
		boolean force = false
	) {
		var helperName = variables.helpers.capitalize(arguments.name);
		if (!reFindNoCase("Helper$", helperName)) {
			helperName &= "Helper";
		}
		var filePath = variables.projectRoot & "/app/helpers/#helperName#.cfc";

		if (fileExists(filePath) && !arguments.force) {
			return {success: false, error: "Helper already exists: app/helpers/#helperName#.cfc", path: filePath};
		}

		var context = {
			helperName: helperName,
			name: helperName,
			description: arguments.description,
			functions: arguments.functions,
			timestamp: dateTimeFormat(now(), "yyyy-mm-dd HH:nn:ss")
		};

		var result = variables.templateService.generateFromTemplate(
			template = "HelperContent.txt",
			destination = "app/helpers/#helperName#.cfc",
			context = context
		);

		return result;
	}

	/**
	 * Validate name for code generation
	 */
	public struct function validateName(required string name, required string type) {
		var errors = [];

		if (!len(trim(arguments.name))) {
			arrayAppend(errors, "Name cannot be empty");
		}

		if (!reFindNoCase("^[a-zA-Z][a-zA-Z0-9_]*$", arguments.name)) {
			arrayAppend(errors, "Name must start with a letter and contain only letters, numbers, and underscores");
		}

		var reservedWords = ["application", "session", "request", "server", "form", "url", "cgi", "cookie"];
		if (arrayFindNoCase(reservedWords, arguments.name)) {
			arrayAppend(errors, "'#arguments.name#' is a reserved word");
		}

		switch (arguments.type) {
			case "model":
				if (reFindNoCase("(Controller|Test|Service)$", arguments.name)) {
					arrayAppend(errors, "Model name should not end with 'Controller', 'Test', or 'Service'");
				}
				break;
			case "controller":
				if (reFindNoCase("(Model|Test|Service)$", arguments.name)) {
					arrayAppend(errors, "Controller name should not end with 'Model', 'Test', or 'Service'");
				}
				break;
		}

		return {valid: arrayLen(errors) == 0, errors: errors};
	}

}
