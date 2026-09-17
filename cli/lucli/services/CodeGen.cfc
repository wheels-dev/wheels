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
	 * plus per-property validatesFormatOf for email and URL types, and
	 * validatesLengthOf when a string-like property carries a brace `{N}` limit.
	 */
	private string function buildModelValidations(required array properties) {
		if (!arrayLen(arguments.properties)) return "";

		var presenceProps = [];
		var extraLines = [];

		for (var prop in arguments.properties) {
			arrayAppend(presenceProps, prop.name);
			var propType = structKeyExists(prop, "type") ? lCase(prop.type) : "string";
			if (propType == "email") {
				arrayAppend(extraLines, "validatesFormatOf(property=""#prop.name#"", type=""email"");");
			} else if (propType == "url") {
				arrayAppend(extraLines, "validatesFormatOf(property=""#prop.name#"", type=""URL"");");
			}
			if (isStringLikeLengthLimit(prop, propType)) {
				// allowBlank=true so an empty value only surfaces the
				// validatesPresenceOf "can't be empty" error instead of also
				// triggering a confusing "is the wrong length" duplicate.
				arrayAppend(extraLines, "validatesLengthOf(property=""#prop.name#"", maximum=#prop.limit#, allowBlank=true);");
			}
		}

		var lines = ["validatesPresenceOf(""#arrayToList(presenceProps)#"");"];
		lines.append(extraLines, true);
		// Join with newline + 2 tabs so subsequent lines align with the template's
		// `\t\t{{validations}}` placeholder indent. The first line gets its indent
		// from the placeholder's leading whitespace at fill time.
		return arrayToList(lines, chr(10) & chr(9) & chr(9));
	}

	/**
	 * True when the property is string-like and carries a numeric `{N}` limit
	 * from the generator parser. Integer `{N}` is a column display width, not
	 * a string length, so it is excluded. Decimal `{p,s}` uses precision/scale
	 * and never sets limit.
	 */
	private boolean function isStringLikeLengthLimit(required struct prop, required string propType) {
		if (listFindNoCase("string,varchar,text,binary", arguments.propType) == 0) {
			return false;
		}
		if (!structKeyExists(arguments.prop, "limit")) {
			return false;
		}
		return isNumeric(arguments.prop.limit) && val(arguments.prop.limit) > 0;
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
	 * Generate a test file.
	 *
	 * `properties` (scaffold / api-resource) drive sample attribute literals so
	 * create/update/destroy assertions have valid data. `modelName` overrides
	 * the singular derived from `name` (api-resource already knows both).
	 */
	public struct function generateTest(
		required string type,
		required string name,
		array properties = [],
		string modelName = "",
		string belongsTo = "",
		boolean force = false
	) {
		var meta = $testFileMeta(arguments.type, arguments.name);
		var testName = meta.testName;
		var testDir = meta.testDir;
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
		var context = $buildTestContext(
			type = arguments.type,
			testName = testName,
			targetName = meta.targetName,
			modelName = arguments.modelName,
			properties = arguments.properties,
			belongsTo = arguments.belongsTo
		);

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
			if (request.$wheelsGenerateDryRun ?: false) {
				arrayAppend(request.$wheelsDryRunPaths, filePath);
				result = {success: true, path: filePath, message: "Dry run — not written", dryRun: true};
			} else {
				fileWrite(filePath, content);
				result = {success: true, path: filePath, message: "Generated from inline template"};
			}
		}

		return result;
	}

	/**
	 * Resolve dest directory, file stem, and the unsuffixed target name for a
	 * generated spec. `api` writes Api<Name>ControllerSpec under controllers/.
	 */
	private struct function $testFileMeta(required string type, required string name) {
		var testName = arguments.name;
		var testDir = "tests/specs/";
		var suffix = "Spec";

		switch (arguments.type) {
			case "model":
				testDir &= "models/";
				break;
			case "controller":
				testDir &= "controllers/";
				suffix = "ControllerSpec";
				break;
			case "api":
				testDir &= "controllers/";
				suffix = "ControllerSpec";
				if (!reFindNoCase("^Api", testName)) {
					testName = "Api" & testName;
				}
				break;
			default:
				testDir &= "unit/";
		}

		testName = reReplaceNoCase(testName, "(Test|Spec|ControllerSpec|ViewSpec|IntegrationSpec)$", "");
		testName &= suffix;
		return {
			testDir: testDir,
			testName: testName,
			targetName: reReplaceNoCase(testName, "(Spec|Test|ControllerSpec)$", "")
		};
	}

	/**
	 * Template context for model / controller / API specs, including Rails-style
	 * sample attributes derived from scaffold properties.
	 */
	private struct function $buildTestContext(
		required string type,
		required string testName,
		required string targetName,
		string modelName = "",
		array properties = [],
		string belongsTo = ""
	) {
		var resolvedModel = len(arguments.modelName) ? arguments.modelName : arguments.targetName;
		var controllerName = arguments.targetName;
		if (arguments.type == "api") {
			controllerName = reReplaceNoCase(arguments.targetName, "^Api", "");
			if (!len(arguments.modelName)) {
				resolvedModel = variables.helpers.singularize(controllerName);
			}
		} else if (arguments.type == "controller" && !len(arguments.modelName)) {
			resolvedModel = variables.helpers.singularize(arguments.targetName);
		} else if (arguments.type == "model") {
			controllerName = variables.helpers.pluralize(resolvedModel);
		}
		resolvedModel = variables.helpers.capitalize(resolvedModel);
		var modelNameLower = lCase(resolvedModel);
		var pluralLower = lCase(controllerName);
		// Bracket-assign keys so they stay camelCase. CFML struct literals
		// uppercase keys, and processTemplate matches {{key}} case-sensitively
		// (TemplatesSpec: "CodeGen builds context with lowercase keys via
		// explicit struct assignment").
		var context = {};
		context["testName"] = arguments.testName;
		context["targetName"] = arguments.targetName;
		context["type"] = arguments.type;
		context["name"] = resolvedModel;
		context["modelName"] = resolvedModel;
		context["modelNameLower"] = modelNameLower;
		context["controllerName"] = controllerName;
		context["pluralLower"] = pluralLower;
		context["collectionRoute"] = "api" & variables.helpers.capitalize(pluralLower);
		context["memberRoute"] = "api" & variables.helpers.capitalize(modelNameLower);

		// belongsTo-aware: the child's FK must reference a real parent, but the
		// generated spec hard-coded `<name>_id: 1`. The controller eager-loads the
		// parent via findByKey(include="<name>"), which inner-joins — so a child
		// with no parent yet came back false and the first `wheels test` run
		// failed the show/edit/update/delete specs. Create each parent in
		// beforeEach (validation skipped: the generator can't know the parent's
		// required fields) and reference its id for the FK.
		var belongsToInfo = $belongsToInfo(arguments.belongsTo, arguments.properties);
		context["belongsToSetup"] = $belongsToSetupLines(belongsToInfo);
		context["validAttributes"] = $buildValidAttributesLiteral(arguments.properties, belongsToInfo);
		context["validationExamples"] = $buildValidationExamples(resolvedModel, arguments.properties);
		context["timestamp"] = dateTimeFormat(now(), "yyyy-mm-dd HH:nn:ss");
		return context;
	}

	/**
	 * CFML struct literal used as model().create(properties=...) / params.<model>.
	 * Use quoted keys + colon (`{"title": "MyString"}`). Unquoted `{title = ...}`
	 * uppercases the key to TITLE. Quoted keys with equals (`{"title" = ...}`)
	 * are a boolean equality expression, not a keyed entry — create() then
	 * receives a boolean and Wheels looks up TITLE on it.
	 */
	private string function $buildValidAttributesLiteral(required array properties, array belongsToInfo = []) {
		if (!arrayLen(arguments.properties)) {
			return "{}";
		}
		var parts = [];
		for (var prop in arguments.properties) {
			var literal = $samplePropertyLiteral(prop);
			// Replace a belongsTo FK sample value with the created parent's id.
			for (var info in arguments.belongsToInfo) {
				if (prop.name == info.fkColumn) {
					literal = "variables." & info.parentVar & ".id";
					break;
				}
			}
			arrayAppend(parts, '"' & prop.name & '": ' & literal);
		}
		return "{" & arrayToList(parts, ", ") & "}";
	}

	/**
	 * Map each belongsTo parent to its parent model, variable name, and the
	 * foreign-key column in the child's properties (matching either `_id` or
	 * `Id` convention). Empty when there are no belongsTo associations.
	 */
	private array function $belongsToInfo(required string belongsTo, required array properties) {
		var result = [];
		if (!len(arguments.belongsTo)) {
			return result;
		}
		for (var parent in listToArray(arguments.belongsTo)) {
			var parentVar = lCase(trim(parent));
			var parentModel = variables.helpers.capitalize(parentVar);
			var fkColumn = "";
			for (var prop in arguments.properties) {
				var propName = lCase(prop.name);
				if (propName == parentVar & "_id" || propName == parentVar & "id") {
					fkColumn = prop.name;
					break;
				}
			}
			if (len(fkColumn)) {
				arrayAppend(result, {parentVar = parentVar, parentModel = parentModel, fkColumn = fkColumn});
			}
		}
		return result;
	}

	/**
	 * beforeEach lines that persist each belongsTo parent with validation
	 * skipped (the generator can't know the parent's required fields). Joined
	 * with a newline + 4 tabs so the template's `{{belongsToSetup}}` placeholder
	 * (already indented under beforeEach) lines up with the sibling statements.
	 */
	private string function $belongsToSetupLines(required array belongsToInfo) {
		if (!arrayLen(arguments.belongsToInfo)) {
			return "";
		}
		var lines = [];
		for (var info in arguments.belongsToInfo) {
			arrayAppend(lines, 'variables.' & info.parentVar & ' = model("' & info.parentModel & '").new();');
			arrayAppend(lines, 'variables.' & info.parentVar & '.save(validate = false);');
		}
		return arrayToList(lines, chr(10) & chr(9) & chr(9) & chr(9) & chr(9));
	}

	/**
	 * One CFML literal matching the property type (Rails fixture spirit).
	 */
	private string function $samplePropertyLiteral(required struct prop) {
		var propType = structKeyExists(prop, "type") ? lCase(prop.type) : "string";
		var propName = structKeyExists(prop, "name") ? lCase(prop.name) : "";

		if (propType == "enum" && structKeyExists(prop, "values") && len(prop.values)) {
			return '"' & listFirst(prop.values) & '"';
		}
		if (propType == "email" || propName == "email") {
			return '"user@example.com"';
		}
		if (propType == "url" || listFindNoCase("url,website", propName)) {
			return '"https://example.com"';
		}
		if (listFindNoCase("integer,int,biginteger,bigint", propType)) {
			return "1";
		}
		if (listFindNoCase("decimal,float,numeric", propType)) {
			return "9.99";
		}
		if (listFindNoCase("boolean,bool", propType)) {
			return "true";
		}
		if (listFindNoCase("datetime,timestamp,date,time", propType)) {
			return "Now()";
		}
		if (listFindNoCase("text,longtext", propType)) {
			return '"MyText"';
		}
		return '"MyString"';
	}

	/**
	 * Optional presence/valid-attributes examples when the scaffold emitted
	 * validatesPresenceOf from properties. Empty string when there are none.
	 */
	private string function $buildValidationExamples(required string modelName, required array properties) {
		if (!arrayLen(arguments.properties)) {
			return "";
		}
		var nl = chr(10);
		var t3 = chr(9) & chr(9) & chr(9);
		var t4 = t3 & chr(9);
		var block = "";
		block &= nl & t3 & 'it("is invalid without required attributes", () => {' & nl;
		block &= t4 & 'var record = model("#arguments.modelName#").new();' & nl;
		block &= t4 & "expect(record.valid()).toBeFalse();" & nl;
		block &= t3 & "});" & nl & nl;
		block &= t3 & 'it("is valid with required attributes", () => {' & nl;
		block &= t4 & 'var record = model("#arguments.modelName#").new(properties = ' & $buildValidAttributesLiteral(arguments.properties) & ');' & nl;
		block &= t4 & "expect(record.valid()).toBeTrue();" & nl;
		block &= t3 & "});";
		return block;
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
	 * Generate an authorization policy CFC file (issue #3156).
	 *
	 * Writes app/policies/<ModelName>Policy.cfc with every standard action
	 * denying (policies are default-deny) plus commented grant examples. Also
	 * scaffolds the app-level app/policies/Policy.cfc base stub when missing so
	 * `extends="Policy"` resolves (mirrors app/models/Model.cfc).
	 */
	public struct function generatePolicy(
		required string name,
		string description = "",
		boolean force = false
	) {
		var modelName = variables.helpers.capitalize(arguments.name);
		// Accept both "Post" and "PostPolicy" — normalize to the model name.
		if (reFindNoCase("Policy$", modelName) && len(modelName) > 6) {
			modelName = left(modelName, len(modelName) - 6);
		}
		var policyName = modelName & "Policy";
		var filePath = variables.projectRoot & "/app/policies/#policyName#.cfc";

		if (fileExists(filePath) && !arguments.force) {
			return {success: false, error: "Policy already exists: app/policies/#policyName#.cfc", path: filePath, baseCreated: false};
		}

		// Ensure the parent Policy.cfc stub exists. Never overwritten.
		var baseCreated = false;
		if (!fileExists(variables.projectRoot & "/app/policies/Policy.cfc")) {
			var baseResult = variables.templateService.generateFromTemplate(
				template = "PolicyBaseContent.txt",
				destination = "app/policies/Policy.cfc",
				context = {timestamp: dateTimeFormat(now(), "yyyy-mm-dd HH:nn:ss")}
			);
			baseCreated = baseResult.success;
		}

		var context = {
			policyName: policyName,
			modelName: modelName,
			description: arguments.description,
			timestamp: dateTimeFormat(now(), "yyyy-mm-dd HH:nn:ss")
		};

		var result = variables.templateService.generateFromTemplate(
			template = "PolicyContent.txt",
			destination = "app/policies/#policyName#.cfc",
			context = context
		);
		result.baseCreated = baseCreated;

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
