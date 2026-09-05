/**
 * Scaffold service for generating complete CRUD resources.
 *
 * Orchestrates model + controller + views + migration + tests + routes
 * using CodeGen and Templates services. Supports rollback on failure.
 *
 * Ported from cli/src/models/ScaffoldService.cfc — no WireBox dependencies.
 */
component {

	public function init(
		required any codeGenService,
		required any helpers,
		required string projectRoot,
		string moduleRoot = ""
	) {
		variables.codeGenService = arguments.codeGenService;
		variables.helpers = arguments.helpers;
		variables.projectRoot = arguments.projectRoot;
		// Optional: only needed by generators that read bundled template
		// directories directly (generateAuth). Ends with a trailing slash
		// when provided (same convention as the Admin service).
		variables.moduleRoot = arguments.moduleRoot;
		return this;
	}


	/**
	 * Dry-run-aware file writer. `wheels generate --dry-run` sets
	 * request.$wheelsGenerateDryRun; writes are then recorded (for the
	 * caller to print) and skipped. Creates the parent directory on the
	 * real path.
	 */
	private string function $write(required string path, required string content) {
		if (request.$wheelsGenerateDryRun ?: false) {
			arrayAppend(request.$wheelsDryRunPaths, arguments.path);
			return arguments.path;
		}
		var dir = getDirectoryFromPath(arguments.path);
		if (!directoryExists(dir)) {
			directoryCreate(dir, true);
		}
		FileWrite(arguments.path, arguments.content);
		return arguments.path;
	}

	/**
	 * Generate a complete scaffold (model, controller, views, migration, tests, routes)
	 */
	public struct function generateScaffold(
		required string name,
		required array properties,
		string belongsTo = "",
		string hasMany = "",
		string hasOne = "",
		boolean api = false,
		boolean tests = true,
		boolean force = false
	) {
		var results = {success: true, generated: [], skipped: [], errors: [], rollback: []};
		var pluralName = variables.helpers.pluralize(arguments.name);

		try {
			// Add foreign key columns for belongsTo relationships
			var props = $addForeignKeyColumns(arguments.properties, arguments.belongsTo);

			// 1. Generate Model. Issue #2327: existing model is no longer fatal —
			// scaffold skips and continues so users can scaffold the controller +
			// views over a hand-edited model. Pass --force to overwrite.
			var modelResult = variables.codeGenService.generateModel(
				name = arguments.name,
				properties = props,
				belongsTo = arguments.belongsTo,
				hasMany = arguments.hasMany,
				hasOne = arguments.hasOne,
				force = arguments.force
			);
			if (modelResult.success) {
				arrayAppend(results.generated, {type: "model", path: modelResult.path});
				arrayAppend(results.rollback, modelResult.path);
			} else if (isExistsError(modelResult.error)) {
				arrayAppend(results.skipped, "model: " & modelResult.error & " (use --force to overwrite)");
			} else {
				throw(type="ScaffoldError", message="Model: #modelResult.error#");
			}

			// 2. Generate Migration. Skip if a *_create_<plural>_table migration
			// already exists — re-running scaffold over a hand-edited model
			// shouldn't produce duplicate migrations.
			if (!migrationAlreadyExists(arguments.name)) {
				var migrationPath = createMigrationWithProperties(arguments.name, props);
				arrayAppend(results.generated, {type: "migration", path: migrationPath});
				arrayAppend(results.rollback, migrationPath);
			} else {
				arrayAppend(results.skipped, "migration: create_" & lCase(pluralName) & "_table already exists");
			}

			// 3. Generate Controller — same skip-on-exists policy as model.
			var controllerResult = variables.codeGenService.generateController(
				name = pluralName,
				crud = true,
				api = arguments.api,
				force = arguments.force,
				belongsTo = arguments.belongsTo,
				hasMany = arguments.hasMany
			);
			if (controllerResult.success) {
				arrayAppend(results.generated, {type: "controller", path: controllerResult.path});
				arrayAppend(results.rollback, controllerResult.path);
			} else if (isExistsError(controllerResult.error)) {
				arrayAppend(results.skipped, "controller: " & controllerResult.error & " (use --force to overwrite)");
			} else {
				throw(type="ScaffoldError", message="Controller: #controllerResult.error#");
			}

			// 4. Generate Views (unless API-only).
			// If a migration exists on disk, parse it for columns the CLI
			// args don't know about (e.g. user followed chapter 2 to add
			// `publishedAt` to the migration, then ran `generate scaffold`
			// in chapter 3 with only the original `title:string body:text
			// status:enum` args — without this merge, the form silently
			// omits `publishedAt`). Onboarding F3.
			var viewProps = props;
			var existingMigration = findExistingMigration(arguments.name);
			if (len(existingMigration)) {
				var migrationCols = parseMigrationColumns(existingMigration);
				if (arrayLen(migrationCols)) {
					viewProps = mergePropsWithMigrationColumns(props, migrationCols);
				}
			}

			if (!arguments.api) {
				for (var action in ["index", "show", "new", "edit", "_form"]) {
					var viewResult = variables.codeGenService.generateView(
						name = pluralName,
						action = action,
						force = arguments.force,
						properties = viewProps,
						belongsTo = arguments.belongsTo,
						hasMany = arguments.hasMany
					);
					if (viewResult.success) {
						arrayAppend(results.generated, {type: "view", path: viewResult.path});
						arrayAppend(results.rollback, viewResult.path);
					} else {
						// Surface the failure instead of silently producing a
						// "complete" scaffold with no views (e.g. unbundled
						// templates, #1944). CLI audit M3.
						arrayAppend(results.skipped, "view " & action & ": " & (viewResult.error ?: "generation failed"));
					}
				}
			}

			// 5. Generate Tests
			if (arguments.tests) {
				var modelTestResult = variables.codeGenService.generateTest(type = "model", name = arguments.name);
				if (modelTestResult.success) {
					arrayAppend(results.generated, {type: "test", path: modelTestResult.path});
					arrayAppend(results.rollback, modelTestResult.path);
				}

				var ctrlTestResult = variables.codeGenService.generateTest(type = "controller", name = pluralName);
				if (ctrlTestResult.success) {
					arrayAppend(results.generated, {type: "test", path: ctrlTestResult.path});
					arrayAppend(results.rollback, ctrlTestResult.path);
				}
			}

			// 6. Update routes — pass the PLURAL form. `.resources("...")` follows
			// Wheels' convention of plural resource names (e.g. `posts` maps to
			// PostsController). Passing the singular `arguments.name` here was an
			// onboarding cliff (finding F4): scaffolding `Post` produced
			// `.resources("post")`, which conflicted with hand-added plural routes
			// and broke the controller convention.
			updateRoutes(pluralName);

		} catch (any e) {
			results.success = false;
			arrayAppend(results.errors, e.message);
			if (e.type == "ScaffoldError") {
				rollbackScaffold(results.rollback);
			}
		}

		return results;
	}

	/**
	 * Append foreign-key columns for belongsTo relationships that aren't
	 * already present in the properties list.
	 */
	private array function $addForeignKeyColumns(required array properties, required string belongsTo) {
		var props = duplicate(arguments.properties);
		if (len(arguments.belongsTo)) {
			for (var parent in listToArray(arguments.belongsTo)) {
				var fkName = lCase(parent) & "Id";
				var hasFK = false;
				for (var p in props) {
					if (p.name == fkName) { hasFK = true; break; }
				}
				if (!hasFK) {
					arrayAppend(props, {name: fkName, type: "integer"});
				}
			}
		}
		return props;
	}

	/**
	 * Detect "already exists" errors from CodeGen so scaffolding can skip them
	 * cleanly rather than treating them as fatal. The error message format is
	 * stable: CodeGen emits "Model already exists: ..." / "Controller already
	 * exists: ..." / "View already exists: ...".
	 */
	private boolean function isExistsError(string error = "") {
		return reFindNoCase("\balready exists:", arguments.error) > 0;
	}

	/**
	 * Check whether a migration that would create the resource's table is
	 * already present. Match on the canonical filename suffix
	 * `_create_<plural>_table.cfc` so timestamped duplicates are avoided
	 * when a user re-runs scaffold over an existing model.
	 */
	private boolean function migrationAlreadyExists(required string name) {
		return len(findExistingMigration(arguments.name)) > 0;
	}

	/**
	 * Return the absolute path to the existing `_create_<plural>_table.cfc`
	 * migration for this resource, or "" if none. Used to merge hand-edited
	 * migration columns back into the scaffold's properties list.
	 */
	private string function findExistingMigration(required string name) {
		var migrationDir = variables.projectRoot & "/app/migrator/migrations";
		if (!directoryExists(migrationDir)) return "";
		var tableName = variables.helpers.pluralize(lCase(arguments.name));
		var suffix = "_create_" & tableName & "_table.cfc";
		var existing = directoryList(migrationDir, false, "name", "*" & suffix);
		if (!arrayLen(existing)) return "";
		return migrationDir & "/" & existing[1];
	}

	/**
	 * Parse a migration file for `t.<type>(columnNames="<name>", ...)` calls
	 * and return them as an array of {name, type} structs. Used to discover
	 * columns added by hand-editing the migration after the original CLI
	 * scaffold call. Onboarding F3.
	 *
	 * Recognized types match what `generateFormFieldsCode` knows how to render:
	 * string / text / longtext / boolean / integer / float / decimal /
	 * date / datetime / timestamp / time / binary / enum.
	 *
	 * Conservative parser — only matches lines that already use the
	 * scaffold-generated shape (`t.string(columnNames="title", ...)`). Custom
	 * column-construction patterns are silently skipped.
	 */
	private array function parseMigrationColumns(required string migrationPath) {
		var result = [];
		if (!fileExists(arguments.migrationPath)) return result;
		var content = fileRead(arguments.migrationPath);

		// Match `t.<type>(columnNames = "<name>"...` allowing optional whitespace
		// and either single or double quotes around the column name.
		var pattern = "t\.([a-zA-Z]+)\s*\(\s*columnNames\s*=\s*[""']([^""']+)[""']";
		var pos = 1;
		var match = reFindNoCase(pattern, content, pos, true);
		while (isStruct(match) && arrayLen(match.pos) > 1 && match.pos[1] > 0) {
			var fnType = lCase(mid(content, match.pos[2], match.len[2]));
			var colName = mid(content, match.pos[3], match.len[3]);
			// Skip the helper that doesn't take columnNames in the same way
			// (we already filter via the regex requiring columnNames= but
			// belt-and-braces if a future helper grows that arg).
			if (
				fnType != "timestamps"
				&& fnType != "create"
				&& fnType != "primarykey"
				&& fnType != "references"
			) {
				arrayAppend(result, {name: colName, type: fnType});
			}
			pos = match.pos[1] + match.len[1];
			match = reFindNoCase(pattern, content, pos, true);
		}
		return result;
	}

	/**
	 * Merge migration-derived columns into the CLI-provided properties list.
	 * CLI args win on name conflict (they may carry enum values etc. that the
	 * parser can't recover). New columns from the migration are appended.
	 */
	private array function mergePropsWithMigrationColumns(
		required array cliProps,
		required array migrationCols
	) {
		var merged = duplicate(arguments.cliProps);
		var seen = {};
		for (var p in arguments.cliProps) {
			seen[lCase(p.name)] = true;
		}
		for (var col in arguments.migrationCols) {
			if (!structKeyExists(seen, lCase(col.name))) {
				arrayAppend(merged, col);
				seen[lCase(col.name)] = true;
			}
		}
		return merged;
	}

	/**
	 * Create a migration with properties for a table
	 */
	public string function createMigrationWithProperties(
		required string name,
		required array properties,
		string primaryKey = "id"
	) {
		var timestamp = variables.helpers.generateMigrationTimestamp();
		var tableName = variables.helpers.pluralize(lCase(arguments.name));
		var className = "create_#tableName#_table";
		var fileName = timestamp & "_" & className & ".cfc";
		var migrationDir = variables.projectRoot & "/app/migrator/migrations";

		if (!directoryExists(migrationDir)) {
			directoryCreate(migrationDir, true);
		}

		var content = generateMigrationContent(className, tableName, arguments.properties, arguments.primaryKey);
		var migrationPath = migrationDir & "/" & fileName;
		$write(migrationPath, content);

		return migrationPath;
	}

	/**
	 * Update routes.cfm with a new resource route
	 */
	public boolean function updateRoutes(required string name) {
		try {
			var routesPath = variables.projectRoot & "/config/routes.cfm";
			if (!fileExists(routesPath)) return false;

			var content = fileRead(routesPath);
			var resourceName = lCase(arguments.name);
			var resourceRoute = '.resources("' & resourceName & '")';

			// Skip if route already exists in any of the canonical forms.
			// The user might have typed .resources("posts") (positional),
			// .resources(name="posts", only="...") (named-arg, from
			// tutorial chapter 2), .resources(name='posts', ...)
			// (single-quoted), or any combination with whitespace.
			if (findNoCase(resourceRoute, content)) return false;
			// Named-arg form (double or single quotes around the resource
			// name). Match .resources( ... name = "<resource>" ... ) — the
			// regex tolerates leading whitespace, varying attribute order,
			// and ignores anything past the closing paren.
			var namedArgPattern = "\.resources\s*\([^)]*name\s*=\s*[""']" & resourceName & "[""']";
			if (REFindNoCase(namedArgPattern, content)) return false;

			// Try CLI-Appends-Here marker first
			var markerPattern = '// CLI-Appends-Here';
			var indent = '';

			if (find(chr(9) & chr(9) & chr(9) & markerPattern, content)) {
				indent = chr(9) & chr(9) & chr(9);
			} else if (find(chr(9) & chr(9) & markerPattern, content)) {
				indent = chr(9) & chr(9);
			} else if (find(chr(9) & markerPattern, content)) {
				indent = chr(9);
			}

			var fullMarker = indent & markerPattern;
			if (find(fullMarker, content)) {
				content = replace(content, fullMarker, indent & resourceRoute & chr(10) & fullMarker, 'all');
				$write(routesPath, content);
				return true;
			}

			// Fallback: insert before last .end()
			if (find('.end()', content)) {
				var lastEnd = content.lastIndexOf('.end()');
				if (lastEnd >= 0) {
					content = mid(content, 1, lastEnd) & resourceRoute & chr(10) & chr(9) & mid(content, lastEnd + 1, len(content));
					$write(routesPath, content);
					return true;
				}
			}
		} catch (any e) {
			// Routes update is non-critical
		}
		return false;
	}

	/**
	 * Generate an API-only resource (model, migration, API controller, API routes, tests)
	 *
	 * Unlike generateScaffold(api=true) which just skips views, this creates:
	 * - A controller in the api/ package (app/controllers/api/)
	 * - Routes scoped under .namespace("api") with except="new,edit"
	 * - API-specific tests that verify JSON responses
	 */
	public struct function generateApiResource(
		required string name,
		required array properties,
		string belongsTo = "",
		string hasMany = "",
		string hasOne = "",
		boolean tests = true,
		boolean force = false
	) {
		var results = {success: true, generated: [], errors: [], rollback: []};
		var pluralName = variables.helpers.pluralize(arguments.name);

		try {
			// Add foreign key columns for belongsTo relationships
			var props = duplicate(arguments.properties);
			if (len(arguments.belongsTo)) {
				for (var parent in listToArray(arguments.belongsTo)) {
					var fkName = lCase(parent) & "Id";
					var hasFK = false;
					for (var p in props) {
						if (p.name == fkName) { hasFK = true; break; }
					}
					if (!hasFK) {
						arrayAppend(props, {name: fkName, type: "integer"});
					}
				}
			}

			// 1. Generate Model
			var modelResult = variables.codeGenService.generateModel(
				name = arguments.name,
				properties = props,
				belongsTo = arguments.belongsTo,
				hasMany = arguments.hasMany,
				hasOne = arguments.hasOne,
				force = arguments.force
			);
			if (modelResult.success) {
				arrayAppend(results.generated, {type: "model", path: modelResult.path});
				arrayAppend(results.rollback, modelResult.path);
			} else {
				throw(type="ScaffoldError", message="Model: #modelResult.error#");
			}

			// 2. Generate Migration
			var migrationPath = createMigrationWithProperties(arguments.name, props);
			arrayAppend(results.generated, {type: "migration", path: migrationPath});
			arrayAppend(results.rollback, migrationPath);

			// 3. Generate API Controller (in api/ package)
			var controllerResult = variables.codeGenService.generateController(
				name = "api/" & pluralName,
				crud = true,
				api = true,
				force = arguments.force,
				belongsTo = arguments.belongsTo,
				hasMany = arguments.hasMany
			);
			if (controllerResult.success) {
				arrayAppend(results.generated, {type: "controller", path: controllerResult.path});
				arrayAppend(results.rollback, controllerResult.path);
			} else {
				throw(type="ScaffoldError", message="Controller: #controllerResult.error#");
			}

			// 4. Generate API-specific tests
			if (arguments.tests) {
				var modelTestResult = variables.codeGenService.generateTest(type="model", name=arguments.name);
				if (modelTestResult.success) {
					arrayAppend(results.generated, {type: "test", path: modelTestResult.path});
					arrayAppend(results.rollback, modelTestResult.path);
				}

				var apiTestResult = generateApiTest(pluralName, arguments.name);
				if (apiTestResult.success) {
					arrayAppend(results.generated, {type: "test", path: apiTestResult.path});
					arrayAppend(results.rollback, apiTestResult.path);
				}
			}

			// 5. Update routes with API namespace.
			// Use the PLURAL name so the route matches the plural controller
			// (api/Products.cfc) and table (products) — mirrors updateRoutes(pluralName)
			// on the non-api scaffold path. Passing singular arguments.name mapped
			// /api/product and never reached the plural controller.
			updateApiRoutes(pluralName);

		} catch (any e) {
			results.success = false;
			arrayAppend(results.errors, e.message);
			if (e.type == "ScaffoldError") {
				rollbackScaffold(results.rollback);
			}
		}

		return results;
	}

	/**
	 * Update routes.cfm with an API-namespaced resource route.
	 *
	 * Inserts or appends to an existing .namespace("api") block:
	 *   .namespace("api")
	 *       .resources(name="products", except="new,edit")
	 *   .end()
	 */
	public boolean function updateApiRoutes(required string name) {
		try {
			var routesPath = variables.projectRoot & "/config/routes.cfm";
			if (!fileExists(routesPath)) return false;

			var content = fileRead(routesPath);
			var resourceName = lCase(arguments.name);
			var nl = chr(10);
			var t = chr(9);

			// Skip if this API resource route already exists
			if (findNoCase('.resources(name="' & resourceName & '", except="new,edit")', content)) return false;
			if (findNoCase(".resources(name='#resourceName#', except='new,edit')", content)) return false;

			// Check if an API namespace block already exists
			if (findNoCase('.namespace("api")', content) || findNoCase(".namespace('api')", content)) {
				// Append inside the existing namespace block — find the .end() that closes it
				var apiNsPos = findNoCase('.namespace("api")', content);
				if (apiNsPos == 0) apiNsPos = findNoCase(".namespace('api')", content);

				// Find the matching .end() after the namespace declaration
				var afterNs = mid(content, apiNsPos, len(content));
				var endPos = findNoCase(".end()", afterNs);
				if (endPos > 0) {
					// Detect indentation of the namespace line
					var nsIndent = detectIndent(content, apiNsPos);
					var resourceLine = nsIndent & t & '.resources(name="#resourceName#", except="new,edit")';
					var insertPos = apiNsPos + endPos - 2;
					var before = mid(content, 1, insertPos);
					var after = mid(content, insertPos + 1, len(content));
					content = before & resourceLine & nl & after;
					$write(routesPath, content);
					return true;
				}
			}

			// No existing API namespace — create one
			var markerPattern = '// CLI-Appends-Here';
			var indent = '';

			if (find(t & t & t & markerPattern, content)) {
				indent = t & t & t;
			} else if (find(t & t & markerPattern, content)) {
				indent = t & t;
			} else if (find(t & markerPattern, content)) {
				indent = t;
			}

			var fullMarker = indent & markerPattern;
			var apiBlock = indent & '.namespace("api")' & nl;
			apiBlock &= indent & t & '.resources(name="#resourceName#", except="new,edit")' & nl;
			apiBlock &= indent & '.end()' & nl;

			if (find(fullMarker, content)) {
				content = replace(content, fullMarker, apiBlock & fullMarker, 'all');
				$write(routesPath, content);
				return true;
			}

			// Fallback: insert before last .end()
			if (find('.end()', content)) {
				var lastEnd = content.lastIndexOf('.end()');
				if (lastEnd >= 0) {
					var before = mid(content, 1, lastEnd);
					var after = mid(content, lastEnd + 1, len(content));
					content = before & t & '.namespace("api")' & nl;
					content &= t & t & '.resources(name="#resourceName#", except="new,edit")' & nl;
					content &= t & '.end()' & nl & t;
					content &= after;
					$write(routesPath, content);
					return true;
				}
			}
		} catch (any e) {
			// Routes update is non-critical
		}
		return false;
	}

	/**
	 * Generate an API-specific controller test that verifies JSON responses
	 */
	public struct function generateApiTest(required string controllerName, required string modelName) {
		var testName = "Api" & arguments.controllerName & "ControllerSpec";
		var testDir = variables.projectRoot & "/tests/specs/controllers/";
		var filePath = testDir & testName & ".cfc";

		if (fileExists(filePath)) {
			return {success: false, error: "Test already exists: #filePath#", path: filePath};
		}

		if (!directoryExists(testDir)) {
			directoryCreate(testDir, true);
		}

		var singular = lCase(arguments.modelName);
		var plural = lCase(arguments.controllerName);
		var nl = chr(10);
		var t = chr(9);

		// processRequest() takes a params STRUCT (with the route NAME inside it,
		// not a URL path) and needs returnAs="struct" for the result to expose
		// `status`. Routes added by updateApiRoutes() live in .namespace("api"),
		// which prefixes child route names: apiProducts / apiProduct.
		var collectionRoute = "api" & variables.helpers.capitalize(plural);
		var memberRoute = "api" & variables.helpers.capitalize(singular);

		var c = 'component extends="wheels.WheelsTest" {' & nl & nl;
		c &= t & 'function run() {' & nl;
		c &= t & t & 'describe("API #arguments.controllerName# Controller", () => {' & nl & nl;
		c &= t & t & t & 'beforeEach(() => {' & nl;
		c &= t & t & t & t & '// Setup test data' & nl;
		c &= t & t & t & '})' & nl & nl;
		c &= t & t & t & 'it("GET /api/#plural# returns JSON list", () => {' & nl;
		c &= t & t & t & t & 'result = processRequest(params={route: "#collectionRoute#", format: "json"}, method="get", returnAs="struct");' & nl;
		c &= t & t & t & t & 'expect(result).toHaveKey("status");' & nl;
		c &= t & t & t & t & 'expect(result.status).toBe(200);' & nl;
		c &= t & t & t & '})' & nl & nl;
		c &= t & t & t & 'it("GET /api/#plural#/:key returns JSON record", () => {' & nl;
		c &= t & t & t & t & 'result = processRequest(params={route: "#memberRoute#", key: 1, format: "json"}, method="get", returnAs="struct");' & nl;
		c &= t & t & t & t & 'expect(result).toHaveKey("status");' & nl;
		c &= t & t & t & '})' & nl & nl;
		c &= t & t & t & 'it("POST /api/#plural# creates record", () => {' & nl;
		c &= t & t & t & t & 'result = processRequest(params={route: "#collectionRoute#", format: "json", #singular#: {}}, method="post", returnAs="struct");' & nl;
		c &= t & t & t & t & 'expect(result).toHaveKey("status");' & nl;
		c &= t & t & t & '})' & nl & nl;
		c &= t & t & t & 'it("PUT /api/#plural#/:key updates record", () => {' & nl;
		c &= t & t & t & t & 'result = processRequest(params={route: "#memberRoute#", key: 1, format: "json", #singular#: {}}, method="put", returnAs="struct");' & nl;
		c &= t & t & t & t & 'expect(result).toHaveKey("status");' & nl;
		c &= t & t & t & '})' & nl & nl;
		c &= t & t & t & 'it("DELETE /api/#plural#/:key deletes record", () => {' & nl;
		c &= t & t & t & t & 'result = processRequest(params={route: "#memberRoute#", key: 1, format: "json"}, method="delete", returnAs="struct");' & nl;
		c &= t & t & t & t & 'expect(result).toHaveKey("status");' & nl;
		c &= t & t & t & '})' & nl & nl;
		c &= t & t & '})' & nl;
		c &= t & '}' & nl;
		c &= '}' & nl;

		$write(filePath, c);
		return {success: true, path: filePath, message: "Generated API controller test"};
	}

	/**
	 * Generate a complete authentication scaffold over the wheels.auth
	 * primitives (issue ##3155): User model with PBKDF2 password hashing,
	 * sessions/passwords/registrations controllers + views (session
	 * strategy), or an api/Sessions controller (token/jwt strategies),
	 * a create-table migration, marked route/service/strategy blocks
	 * injected into config + app events, and generated app specs.
	 *
	 * Generated code is code-you-own: every file carries a stamped header
	 * and re-running with force=true regenerates it (marker blocks are
	 * replaced in place, never duplicated).
	 */
	public struct function generateAuth(
		string model = "User",
		string strategy = "session",
		boolean registration = true,
		boolean force = false,
		string cliVersion = ""
	) {
		var results = {success: true, generated: [], skipped: [], errors: [], rollback: []};
		var nl = chr(10);
		var t = chr(9);

		var strategyName = lCase(trim(arguments.strategy));
		if (!listFindNoCase("session,token,jwt", strategyName)) {
			throw(
				type = "Wheels.InvalidArguments",
				message = "Unknown auth strategy: #arguments.strategy#. Valid strategies: session, token, jwt."
			);
		}
		if (!len(variables.moduleRoot)) {
			throw(
				type = "Wheels.InvalidArguments",
				message = "The Scaffold service needs a moduleRoot to locate the auth templates."
			);
		}

		var modelName = variables.helpers.capitalize(trim(arguments.model));
		var modelVar = lCase(left(modelName, 1)) & (len(modelName) > 1 ? mid(modelName, 2, len(modelName)) : "");
		var tableName = lCase(variables.helpers.pluralize(modelName));
		var isApi = strategyName != "session";
		var withRegistration = arguments.registration && !isApi;

		var ctx = {
			modelName: modelName,
			modelVar: modelVar,
			tableName: tableName,
			strategy: strategyName,
			cliVersion: len(arguments.cliVersion) ? arguments.cliVersion : "dev",
			generatedDate: dateFormat(now(), "yyyy-mm-dd")
		};
		ctx.protectedApiToken = strategyName == "token" ? ",apiTokenDigest" : "";
		ctx.apiTokenMethods = strategyName == "token" ? $renderAuthTemplate("api-token-methods", ctx) : "";
		ctx.apiTokenColumn = strategyName == "token"
			? t & t & t & t & 't.string(columnNames="apiTokenDigest", allowNull=true, limit=64);' & nl
			: "";
		// Emits `#linkTo(...)#` into the login view (## collapses to # in this
		// CFC's string literal; the .txt templates are raw and keep single #).
		ctx.registrationLink = withRegistration
			? '<br>##linkTo(route="register", text="Create an account")##'
			: "";

		try {
			// 1. Model
			$writeAuthFile(
				relPath = "app/models/#modelName#.cfc",
				content = $renderAuthTemplate("model", ctx),
				force = arguments.force,
				results = results,
				label = "model"
			);

			// 2. Migration. Never overwritten (even with force) — rewriting an
			// already-applied migration would desync the tracking table.
			if (!migrationAlreadyExists(modelName)) {
				var migrationDir = variables.projectRoot & "/app/migrator/migrations";
				if (!directoryExists(migrationDir)) {
					directoryCreate(migrationDir, true);
				}
				var migrationPath = migrationDir & "/" & variables.helpers.generateMigrationTimestamp()
					& "_create_" & tableName & "_table.cfc";
				$write(migrationPath, $renderAuthTemplate("migration", ctx));
				arrayAppend(results.generated, {type: "migration", path: migrationPath});
				arrayAppend(results.rollback, migrationPath);
			} else {
				arrayAppend(results.skipped, "migration: create_#tableName#_table already exists (never overwritten — edit it directly)");
			}

			// 3. Controllers + views + specs per strategy
			if (isApi) {
				$writeAuthFile(
					relPath = "app/controllers/api/Sessions.cfc",
					content = $renderAuthTemplate("controller-api-sessions-#strategyName#", ctx),
					force = arguments.force,
					results = results,
					label = "controller"
				);
				$writeAuthFile(
					relPath = "tests/specs/controllers/ApiSessionsControllerSpec.cfc",
					content = $renderAuthTemplate("spec-api-sessions", ctx),
					force = arguments.force,
					results = results,
					label = "test"
				);
				arrayAppend(results.skipped, "registration: not applicable to the #strategyName# strategy (no browser sign-up flow)");
			} else {
				$writeAuthFile(
					relPath = "app/controllers/Sessions.cfc",
					content = $renderAuthTemplate("controller-sessions", ctx),
					force = arguments.force,
					results = results,
					label = "controller"
				);
				$writeAuthFile(
					relPath = "app/controllers/Passwords.cfc",
					content = $renderAuthTemplate("controller-passwords", ctx),
					force = arguments.force,
					results = results,
					label = "controller"
				);
				$writeAuthFile(
					relPath = "app/views/sessions/new.cfm",
					content = $renderAuthTemplate("view-sessions-new", ctx),
					force = arguments.force,
					results = results,
					label = "view"
				);
				$writeAuthFile(
					relPath = "app/views/passwords/new.cfm",
					content = $renderAuthTemplate("view-passwords-new", ctx),
					force = arguments.force,
					results = results,
					label = "view"
				);
				$writeAuthFile(
					relPath = "app/views/passwords/edit.cfm",
					content = $renderAuthTemplate("view-passwords-edit", ctx),
					force = arguments.force,
					results = results,
					label = "view"
				);
				if (withRegistration) {
					$writeAuthFile(
						relPath = "app/controllers/Registrations.cfc",
						content = $renderAuthTemplate("controller-registrations", ctx),
						force = arguments.force,
						results = results,
						label = "controller"
					);
					$writeAuthFile(
						relPath = "app/views/registrations/new.cfm",
						content = $renderAuthTemplate("view-registrations-new", ctx),
						force = arguments.force,
						results = results,
						label = "view"
					);
				}
				$writeAuthFile(
					relPath = "tests/specs/controllers/SessionsControllerSpec.cfc",
					content = $renderAuthTemplate("spec-sessions-controller", ctx),
					force = arguments.force,
					results = results,
					label = "test"
				);
			}

			// Model spec (all strategies)
			$writeAuthFile(
				relPath = "tests/specs/models/#modelName#AuthSpec.cfc",
				content = $renderAuthTemplate("spec-model", ctx),
				force = arguments.force,
				results = results,
				label = "test"
			);

			// 4. Routes — marked block, replaced in place on --force.
			var routesBlock = "";
			if (isApi) {
				routesBlock = $renderAuthTemplate("routes-api", ctx);
			} else {
				ctx.registrationRoutes = withRegistration ? $renderAuthTemplate("routes-registration", ctx) : "";
				routesBlock = $renderAuthTemplate("routes-session", ctx);
			}
			$injectAuthBlock(
				relPath = "config/routes.cfm",
				block = routesBlock,
				beginMarker = "// wheels:generate-auth:routes:begin",
				endMarker = "// wheels:generate-auth:routes:end",
				force = arguments.force,
				results = results,
				anchorMode = "routes",
				label = "routes"
			);

			// 5. Service registrations — config/services.cfm (created if absent).
			$injectAuthBlock(
				relPath = "config/services.cfm",
				block = $renderAuthTemplate(isApi ? "services-api" : "services-session", ctx),
				beginMarker = "// wheels:generate-auth:services:begin",
				endMarker = "// wheels:generate-auth:services:end",
				force = arguments.force,
				results = results,
				anchorMode = "cfscript",
				label = "services"
			);

			// 6. Strategy wiring — app/events/onapplicationstart.cfm (the DI
			// container isn't available yet in config/app.cfm; see the auth
			// chapter in the guides).
			$injectAuthBlock(
				relPath = "app/events/onapplicationstart.cfm",
				block = $renderAuthTemplate("bootstrap-#strategyName#", ctx),
				beginMarker = "// wheels:generate-auth:strategy:begin",
				endMarker = "// wheels:generate-auth:strategy:end",
				force = arguments.force,
				results = results,
				anchorMode = "cfscript",
				label = "strategy"
			);
		} catch (any e) {
			results.success = false;
			arrayAppend(results.errors, e.message);
			// Roll back on ANY failure, not just typed ScaffoldErrors — an IO
			// error mid-run must not leave a half-generated scaffold behind.
			// The rollback list only ever contains files THIS run created, so
			// pre-existing user files are never deleted.
			rollbackScaffold(results.rollback);
		}

		return results;
	}

	// ── Private helpers ──────────────────────────────

	/**
	 * Read and render a template from cli/lucli/templates/auth/.
	 * Simple {{key}} replacement — values are inserted verbatim.
	 */
	private string function $renderAuthTemplate(required string template, required struct context) {
		var path = variables.moduleRoot & "templates/auth/" & arguments.template & ".txt";
		if (!fileExists(path)) {
			throw(type = "ScaffoldError", message = "Auth template not found: #path#");
		}
		var content = fileRead(path);
		for (var key in arguments.context) {
			if (isSimpleValue(arguments.context[key])) {
				content = replaceNoCase(content, "{{" & key & "}}", arguments.context[key], "all");
			}
		}
		return content;
	}

	/**
	 * Write a generated auth file. Existing files are skipped unless force
	 * is set; only newly created files are registered for rollback so a
	 * failed run never deletes a user's pre-existing file.
	 */
	private boolean function $writeAuthFile(
		required string relPath,
		required string content,
		required boolean force,
		required struct results,
		required string label
	) {
		var absPath = variables.projectRoot & "/" & arguments.relPath;
		var existed = fileExists(absPath);
		if (existed && !arguments.force) {
			arrayAppend(arguments.results.skipped, "#arguments.label#: #arguments.relPath# already exists (use --force to overwrite)");
			return false;
		}
		var dir = getDirectoryFromPath(absPath);
		if (!directoryExists(dir)) {
			directoryCreate(dir, true);
		}
		$write(absPath, arguments.content);
		arrayAppend(arguments.results.generated, {type: arguments.label, path: absPath});
		if (!existed) {
			arrayAppend(arguments.results.rollback, absPath);
		}
		return true;
	}

	/**
	 * Inject (or, with force, replace in place) a marker-delimited block into
	 * a config file. anchorMode "routes" inserts inside the mapper() chain —
	 * at // CLI-Appends-Here, else before .root(), else before the last
	 * .end() — so the auth routes always precede root/wildcard. anchorMode
	 * "cfscript" inserts before the file's closing cfscript end tag
	 * (creating the file with a cfscript wrapper when absent). Tag tokens
	 * are chr(60)-concatenated below — a literal tag in a string or
	 * comment trips Lucee's tag scanner and crashes the whole bundle.
	 */
	private void function $injectAuthBlock(
		required string relPath,
		required string block,
		required string beginMarker,
		required string endMarker,
		required boolean force,
		required struct results,
		required string anchorMode,
		required string label
	) {
		var nl = chr(10);
		var t = chr(9);
		var scriptOpenTag = chr(60) & "cfscript" & chr(62);
		var scriptCloseTag = chr(60) & "/cfscript" & chr(62);
		var absPath = variables.projectRoot & "/" & arguments.relPath;
		var blockText = reReplace(arguments.block, "[\r\n]+$", "");

		if (!fileExists(absPath)) {
			if (arguments.anchorMode == "cfscript") {
				var dir = getDirectoryFromPath(absPath);
				if (!directoryExists(dir)) {
					directoryCreate(dir, true);
				}
				$write(absPath, scriptOpenTag & nl & $indentBlock(blockText, t) & nl & scriptCloseTag & nl);
				arrayAppend(arguments.results.generated, {type: arguments.label, path: absPath});
				arrayAppend(arguments.results.rollback, absPath);
				return;
			}
			arrayAppend(
				arguments.results.skipped,
				"#arguments.label#: #arguments.relPath# not found — add this block manually inside the mapper() chain, before .root()/.wildcard():" & nl & blockText
			);
			return;
		}

		var content = fileRead(absPath);
		var beginPos = find(arguments.beginMarker, content);

		// Replace an existing block in place (idempotent under --force).
		if (beginPos > 0) {
			if (!arguments.force) {
				arrayAppend(arguments.results.skipped, "#arguments.label#: block already present in #arguments.relPath# (use --force to regenerate)");
				return;
			}
			var endPos = find(arguments.endMarker, content, beginPos);
			if (endPos == 0) {
				arrayAppend(arguments.results.skipped, "#arguments.label#: begin marker without matching end marker in #arguments.relPath# — fix the file manually");
				return;
			}
			var regionStart = $lineStart(content, beginPos);
			var regionEnd = $lineEnd(content, endPos + len(arguments.endMarker) - 1);
			var indent = $lineIndent(content, beginPos);
			content = left(content, regionStart - 1)
				& $indentBlock(blockText, indent) & nl
				& mid(content, regionEnd + 1, len(content));
			$write(absPath, content);
			arrayAppend(arguments.results.generated, {type: arguments.label, path: absPath});
			return;
		}

		// First-time insertion.
		if (arguments.anchorMode == "routes") {
			var anchorPos = find("// CLI-Appends-Here", content);
			if (anchorPos == 0) {
				// Skip commented-out `.root(` lines (anti-pattern ##14) — the
				// stock routes.cfm ships a commented example above the real one.
				anchorPos = $findCodePosition(content, ".root(");
			}
			// Deliberately NO `.end()` fallback: the last `.end()` closes the
			// mapper chain AFTER `.wildcard()`, so routes inserted there could
			// never match (anti-pattern ##6). When neither anchor exists, make
			// the user place the block instead of injecting dead routes.
			if (anchorPos == 0) {
				arrayAppend(
					arguments.results.skipped,
					"#arguments.label#: could not find an insertion anchor (// CLI-Appends-Here or an uncommented .root()) in #arguments.relPath# — add this block manually inside the mapper() chain, before .root()/.wildcard():" & nl & blockText
				);
				return;
			}
			var insertLineStart = $lineStart(content, anchorPos);
			var anchorIndent = $lineIndent(content, anchorPos);
			content = left(content, insertLineStart - 1)
				& $indentBlock(blockText, anchorIndent) & nl
				& mid(content, insertLineStart, len(content));
			$write(absPath, content);
			arrayAppend(arguments.results.generated, {type: arguments.label, path: absPath});
			return;
		}

		// cfscript mode: insert before the last closing tag, else append a block.
		var closePos = content.lastIndexOf(scriptCloseTag);
		if (closePos >= 0) {
			content = left(content, closePos)
				& nl & $indentBlock(blockText, t) & nl
				& mid(content, closePos + 1, len(content));
		} else {
			content = content & nl & scriptOpenTag & nl & $indentBlock(blockText, t) & nl & scriptCloseTag & nl;
		}
		$write(absPath, content);
		arrayAppend(arguments.results.generated, {type: arguments.label, path: absPath});
	}

	/**
	 * Position of the first occurrence of needle that is NOT on a
	 * line-comment (`// ...`) portion of its line. Returns 0 when only
	 * commented occurrences exist.
	 */
	private numeric function $findCodePosition(required string content, required string needle) {
		var pos = find(arguments.needle, arguments.content);
		while (pos > 0) {
			var lineStartPos = $lineStart(arguments.content, pos);
			var linePrefix = mid(arguments.content, lineStartPos, pos - lineStartPos);
			if (!find("//", linePrefix)) {
				return pos;
			}
			pos = find(arguments.needle, arguments.content, pos + 1);
		}
		return 0;
	}

	/**
	 * 1-based index of the first character of the line containing pos.
	 */
	private numeric function $lineStart(required string content, required numeric pos) {
		var i = arguments.pos;
		while (i > 1 && mid(arguments.content, i - 1, 1) != chr(10)) {
			i--;
		}
		return i;
	}

	/**
	 * 1-based index of the newline terminating the line containing pos
	 * (or of the last character when the file ends without one).
	 */
	private numeric function $lineEnd(required string content, required numeric pos) {
		var i = arguments.pos;
		var total = len(arguments.content);
		while (i <= total && mid(arguments.content, i, 1) != chr(10)) {
			i++;
		}
		return i > total ? total : i;
	}

	/**
	 * Leading whitespace of the line containing pos.
	 */
	private string function $lineIndent(required string content, required numeric pos) {
		var i = $lineStart(arguments.content, arguments.pos);
		var total = len(arguments.content);
		var indent = "";
		while (i <= total) {
			var ch = mid(arguments.content, i, 1);
			if (ch == chr(9) || ch == " ") {
				indent &= ch;
				i++;
			} else {
				break;
			}
		}
		return indent;
	}

	/**
	 * Prefix every non-empty line of a block with the given indentation.
	 */
	private string function $indentBlock(required string block, required string indent) {
		var lines = listToArray(replace(arguments.block, chr(13), "", "all"), chr(10), true);
		var indented = [];
		for (var line in lines) {
			arrayAppend(indented, len(trim(line)) ? arguments.indent & line : line);
		}
		return arrayToList(indented, chr(10));
	}

	/**
	 * Detect the indentation used before a given position in content
	 */
	private string function detectIndent(required string content, required numeric position) {
		var indent = "";
		var i = arguments.position - 1;
		while (i > 0 && mid(arguments.content, i, 1) == chr(9)) {
			indent &= chr(9);
			i--;
		}
		return indent;
	}

	/**
	 * Generate migration content with column definitions
	 */
	private string function generateMigrationContent(
		required string className,
		required string tableName,
		required array properties,
		string primaryKey = "id"
	) {
		var nl = chr(10);
		var t = chr(9);
		var c = "";

		// Failure tracking uses a struct field (state.exception), NOT local.X:
		// `local.X = ...` inside a catch body does not persist on BoxLang
		// (Cross-Engine Invariant #11), which silently turned failed
		// migrations into committed "successes".
		c &= 'component extends="wheels.migrator.Migration" hint="Migration: #arguments.className#" {' & nl & nl;
		c &= t & 'function up() {' & nl;
		c &= t & t & 'var state = {};' & nl;
		c &= t & t & 'transaction {' & nl;
		c &= t & t & t & 'try {' & nl;
		c &= t & t & t & t & "t = createTable(name='#arguments.tableName#', force='false', id='true', primaryKey='#arguments.primaryKey#');" & nl;

		for (var prop in arguments.properties) {
			if (structKeyExists(prop, "association")) continue;
			if (!structKeyExists(prop, "type")) continue;

			var cfType = mapToWheelsType(prop.type);
			var params = "columnNames='#prop.name#'";
			// No `default=''` — the migrator hardener (S14) rejects empty-string
			// defaults on string/text/char columns, and for numeric/temporal
			// types `default=''` just rendered DEFAULT NULL anyway. Omitting the
			// default yields NULL for nullable columns, which is the same thing.
			params &= ", allowNull=" & (structKeyExists(prop, "required") && prop.required ? "false" : "true");

			switch (cfType) {
				case "string": params &= ", limit='255'"; break;
				case "decimal": params &= ", precision='10', scale='2'"; break;
				case "integer": params &= ", limit='11'"; break;
			}

			c &= t & t & t & t & "t.#cfType#(#params#);" & nl;
		}

		c &= t & t & t & t & "t.timestamps();" & nl;
		c &= t & t & t & t & "t.create();" & nl;
		c &= t & t & t & '} catch (any e) {' & nl;
		c &= t & t & t & t & 'state.exception = e;' & nl;
		c &= t & t & t & '}' & nl & nl;
		c &= t & t & t & 'if (StructKeyExists(state, "exception")) {' & nl;
		c &= t & t & t & t & 'transaction action="rollback";' & nl;
		c &= t & t & t & t & 'Throw(errorCode="1", detail=state.exception.detail, message=state.exception.message, type="any");' & nl;
		c &= t & t & t & '} else {' & nl;
		c &= t & t & t & t & 'transaction action="commit";' & nl;
		c &= t & t & t & '}' & nl;
		c &= t & t & '}' & nl;
		c &= t & '}' & nl & nl;

		c &= t & 'function down() {' & nl;
		c &= t & t & 'var state = {};' & nl;
		c &= t & t & 'transaction {' & nl;
		c &= t & t & t & 'try {' & nl;
		c &= t & t & t & t & "dropTable('#arguments.tableName#');" & nl;
		c &= t & t & t & '} catch (any e) {' & nl;
		c &= t & t & t & t & 'state.exception = e;' & nl;
		c &= t & t & t & '}' & nl & nl;
		c &= t & t & t & 'if (StructKeyExists(state, "exception")) {' & nl;
		c &= t & t & t & t & 'transaction action="rollback";' & nl;
		c &= t & t & t & t & 'Throw(errorCode="1", detail=state.exception.detail, message=state.exception.message, type="any");' & nl;
		c &= t & t & t & '} else {' & nl;
		c &= t & t & t & t & 'transaction action="commit";' & nl;
		c &= t & t & t & '}' & nl;
		c &= t & t & '}' & nl;
		c &= t & '}' & nl & nl;

		c &= '}' & nl;
		return c;
	}

	/**
	 * Map property type to Wheels migration column type
	 */
	private string function mapToWheelsType(required string type) {
		var t = lCase(arguments.type);

		var numeric = $mapWheelsNumericType(t);
		if (len(numeric)) return numeric;

		var textual = $mapWheelsTextualType(t);
		if (len(textual)) return textual;

		return $mapWheelsOtherType(t);
	}

	/**
	 * Map numeric property types to their Wheels migration column type.
	 */
	private string function $mapWheelsNumericType(required string type) {
		switch (arguments.type) {
			case "integer": case "int": return "integer";
			case "biginteger": case "bigint": return "biginteger";
			case "float": case "double": return "float";
			case "decimal": case "numeric": return "decimal";
			default: return "";
		}
	}

	/**
	 * Map textual property types to their Wheels migration column type.
	 */
	private string function $mapWheelsTextualType(required string type) {
		switch (arguments.type) {
			case "string": return "string";
			case "text": return "text";
			default: return "";
		}
	}

	/**
	 * Map boolean/temporal/binary/uuid property types (and the default) to
	 * their Wheels migration column type.
	 */
	private string function $mapWheelsOtherType(required string type) {
		switch (arguments.type) {
			case "boolean": case "bool": return "boolean";
			case "date": return "date";
			case "datetime": case "timestamp": return "datetime";
			case "time": return "time";
			case "binary": case "blob": return "binary";
			case "uuid": return "uniqueidentifier";
			default: return "string";
		}
	}

	/**
	 * Rollback created files on error
	 */
	private void function rollbackScaffold(required array files) {
		for (var file in arguments.files) {
			if (fileExists(file)) {
				try { fileDelete(file); } catch (any e) { /* non-critical */ }
			}
		}
	}

}
