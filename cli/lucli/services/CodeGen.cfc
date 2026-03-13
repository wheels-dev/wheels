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
		var controllerName = variables.helpers.capitalize(arguments.name);
		var filePath = variables.projectRoot & "/app/controllers/#controllerName#.cfc";

		if (fileExists(filePath) && !arguments.force) {
			return {success: false, error: "Controller already exists: app/controllers/#controllerName#.cfc", path: filePath};
		}

		var crudActions = ["index", "show", "new", "create", "edit", "update", "delete"];

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

		return variables.templateService.generateFromTemplate(
			template = template,
			destination = "app/controllers/#controllerName#.cfc",
			context = context
		);
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
		required string name
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
